using System;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Security.Cryptography;
using System.Threading;
using System.Threading.Tasks;

/// <summary>Starts the bundled Ollama server only when no loopback service is answering.</summary>
public sealed class OllamaServerController : IDisposable
{
    public const string BundledOllamaSha256 = "0A9D42EABC59FDAFDE8D2D3E7964F6050B31A17B3E3795BFACB367C12DF790F4";

    private static readonly SemaphoreSlim ProcessLifecycleGate = new(1, 1);
    private static readonly TimeSpan ProbeTimeout = TimeSpan.FromMilliseconds(750);
    private static readonly TimeSpan PollInterval = TimeSpan.FromMilliseconds(250);

    private readonly string _baseUrl;
    private readonly string _executablePath;
    private readonly string _expectedSha256;
    private readonly TimeSpan _startupTimeout;
    private readonly HttpClient _http;
    private readonly object _stateLock = new();
    private readonly bool _ownsHttp;
    private Process _ownedProcess;
    private Uri _baseUri;
    private bool _serverReady;
    private bool _disposed;

    public OllamaServerController(
        string baseUrl,
        string executablePath,
        string expectedSha256 = BundledOllamaSha256,
        TimeSpan? startupTimeout = null,
        HttpClient http = null)
    {
        _baseUrl = baseUrl ?? string.Empty;
        _executablePath = executablePath ?? string.Empty;
        _expectedSha256 = expectedSha256 ?? string.Empty;
        _startupTimeout = startupTimeout ?? TimeSpan.FromSeconds(30);
        if (_startupTimeout <= TimeSpan.Zero)
            throw new ArgumentOutOfRangeException(nameof(startupTimeout), "Startup timeout must be positive.");
        _ownsHttp = http == null;
        _http = http ?? new HttpClient { Timeout = Timeout.InfiniteTimeSpan };
    }

    public bool OwnsProcess
    {
        get
        {
            lock (_stateLock)
                return IsRunning(_ownedProcess);
        }
    }

    public int? OwnedProcessId
    {
        get
        {
            lock (_stateLock)
                return IsRunning(_ownedProcess) ? _ownedProcess.Id : null;
        }
    }

    public async Task EnsureServerAvailableAsync(CancellationToken cancellationToken = default)
    {
        await ProcessLifecycleGate.WaitAsync(cancellationToken);
        try
        {
            ThrowIfDisposed();
            if (_serverReady)
                return;

            _baseUri ??= ParseBaseUri(_baseUrl);
            if (await EndpointRespondsAsync(cancellationToken))
            {
                // A pre-existing Ollama process belongs to its launcher, not to this game.
                _serverReady = true;
                return;
            }

            Process existing;
            lock (_stateLock)
            {
                existing = _ownedProcess;
                if (!IsRunning(existing))
                {
                    existing?.Dispose();
                    _ownedProcess = null;
                    existing = null;
                }
            }

            if (existing == null)
            {
                StartOwnedProcess();
                lock (_stateLock) existing = _ownedProcess;
            }

            await WaitForEndpointAsync(existing, cancellationToken);
            _serverReady = true;
        }
        finally
        {
            ProcessLifecycleGate.Release();
        }
    }

    /// <summary>Invalidates a failed connection so a later request can retry startup.</summary>
    public void MarkServerUnavailable() => _serverReady = false;

    /// <summary>Stops only the process started by this controller and permits a later retry.</summary>
    public void StopOwnedProcess()
    {
        Process process;
        lock (_stateLock)
        {
            process = _ownedProcess;
            _ownedProcess = null;
            if (process != null)
                _serverReady = false;
        }

        StopProcess(process);
    }

    public void Dispose()
    {
        lock (_stateLock)
        {
            if (_disposed) return;
            _disposed = true;
        }

        StopOwnedProcess();
        if (_ownsHttp)
            _http.Dispose();
    }

    private async Task<bool> EndpointRespondsAsync(CancellationToken cancellationToken)
    {
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(ProbeTimeout);
        using var request = new HttpRequestMessage(HttpMethod.Get, new Uri(_baseUri, "api/tags"));
        try
        {
            using var response = await _http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, timeout.Token);
            // Any HTTP response proves something already owns the endpoint. Let the chat request
            // report an API/model error instead of starting a second process on the same port.
            return true;
        }
        catch (OperationCanceledException) when (!cancellationToken.IsCancellationRequested)
        {
            return false;
        }
        catch (HttpRequestException)
        {
            return false;
        }
        catch (IOException)
        {
            return false;
        }
    }

    private void StartOwnedProcess()
    {
        if (_baseUri.Scheme != Uri.UriSchemeHttp)
            throw Failure(LocalLlmFailureKind.Configuration,
                "Bundled Ollama can only serve an HTTP loopback URL.");

        string executablePath = Path.GetFullPath(_executablePath);
        if (!File.Exists(executablePath))
            throw Failure(LocalLlmFailureKind.OllamaExecutableMissing,
                $"Bundled Ollama executable not found: {executablePath}");

        string actualHash;
        try
        {
            using var executable = File.OpenRead(executablePath);
            actualHash = Convert.ToHexString(SHA256.HashData(executable));
        }
        catch (Exception exception) when (exception is IOException or UnauthorizedAccessException)
        {
            throw Failure(LocalLlmFailureKind.OllamaExecutableIntegrity,
                $"Could not read bundled Ollama executable: {exception.GetType().Name}.");
        }

        if (!string.Equals(actualHash, _expectedSha256, StringComparison.OrdinalIgnoreCase))
            throw Failure(LocalLlmFailureKind.OllamaExecutableIntegrity,
                $"Bundled Ollama SHA-256 mismatch. Expected {_expectedSha256}; got {actualHash}.");

        var startInfo = new ProcessStartInfo
        {
            FileName = executablePath,
            WorkingDirectory = Path.GetDirectoryName(executablePath) ?? AppContext.BaseDirectory,
            UseShellExecute = false,
            CreateNoWindow = true,
            WindowStyle = ProcessWindowStyle.Hidden,
        };
        startInfo.ArgumentList.Add("serve");
        startInfo.Environment["OLLAMA_HOST"] = $"{_baseUri.Host}:{_baseUri.Port}";

        var process = new Process { StartInfo = startInfo, EnableRaisingEvents = true };
        try
        {
            if (!process.Start())
                throw new InvalidOperationException("Process.Start returned false.");
        }
        catch (Exception exception) when (exception is InvalidOperationException or IOException or
            UnauthorizedAccessException or System.ComponentModel.Win32Exception)
        {
            process.Dispose();
            throw Failure(LocalLlmFailureKind.OllamaProcessStart,
                $"Could not start bundled Ollama: {exception.GetType().Name}.");
        }

        lock (_stateLock)
        {
            if (_disposed)
            {
                StopProcess(process);
                throw new ObjectDisposedException(nameof(OllamaServerController));
            }
            _ownedProcess = process;
        }
    }

    private async Task WaitForEndpointAsync(Process process, CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        while (stopwatch.Elapsed < _startupTimeout)
        {
            cancellationToken.ThrowIfCancellationRequested();
            if (!IsRunning(process))
            {
                int exitCode;
                try { exitCode = process.ExitCode; }
                catch (InvalidOperationException) { exitCode = -1; }
                throw Failure(LocalLlmFailureKind.OllamaProcessStart,
                    $"Bundled Ollama exited before serving HTTP (exit code {exitCode}).");
            }

            if (await EndpointRespondsAsync(cancellationToken))
                return;

            await Task.Delay(PollInterval, cancellationToken);
        }

        throw Failure(LocalLlmFailureKind.OllamaServerUnavailable,
            $"Ollama did not answer at {_baseUri} within {_startupTimeout.TotalSeconds:0} seconds.");
    }

    private static Uri ParseBaseUri(string baseUrl)
    {
        if (!Uri.TryCreate(baseUrl.TrimEnd('/') + "/", UriKind.Absolute, out Uri baseUri) ||
            (baseUri.Scheme != Uri.UriSchemeHttp && baseUri.Scheme != Uri.UriSchemeHttps) ||
            !baseUri.IsLoopback)
        {
            throw Failure(LocalLlmFailureKind.Configuration,
                "BaseUrl must be a loopback HTTP(S) URL.");
        }

        return baseUri;
    }

    private static bool IsRunning(Process process)
    {
        if (process == null) return false;
        try { return !process.HasExited; }
        catch (ObjectDisposedException) { return false; }
        catch (InvalidOperationException) { return false; }
    }

    private static void StopProcess(Process process)
    {
        if (process == null) return;
        try
        {
            if (!process.HasExited)
            {
                process.Kill(entireProcessTree: true);
                process.WaitForExit(5000);
            }
        }
        catch (ObjectDisposedException) { }
        catch (InvalidOperationException) { }
        catch (System.ComponentModel.Win32Exception) { }
        finally { process.Dispose(); }
    }

    private void ThrowIfDisposed()
    {
        lock (_stateLock)
            if (_disposed) throw new ObjectDisposedException(nameof(OllamaServerController));
    }

    private static LocalLlmRuntimeException Failure(LocalLlmFailureKind kind, string details) =>
        LocalLlmRuntimeException.CreateForKind(kind, details);
}
