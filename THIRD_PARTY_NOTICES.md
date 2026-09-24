# Уведомления о сторонних компонентах

## Windows runtime Ollama

Windows runtime в `tools/ollama` взят из официального отдельного релиза Ollama `v0.32.15` для Windows AMD64: <https://github.com/ollama/ollama/releases/tag/v0.32.15>. Код Ollama распространяется по лицензии MIT; копия текста включена в [`LICENSES/Ollama-0.32.15-MIT.txt`](LICENSES/Ollama-0.32.15-MIT.txt).

В исходнике Ollama `v0.32.15` закреплена версия llama.cpp `b10488`. В официальном Windows-архиве нет отдельных файлов уведомлений о лицензиях компонентов runner, поэтому в эту поставку добавлены тексты лицензий, обнаруженные в закреплённом исходном коде llama.cpp:

| Компонент | Лицензия или уведомление | Файл с текстом |
| --- | --- | --- |
| llama.cpp | MIT | [`LICENSES/llama.cpp-b10488-MIT.txt`](LICENSES/llama.cpp-b10488-MIT.txt) |
| cpp-httplib | MIT | [`LICENSES/cpp-httplib-b10488-MIT.txt`](LICENSES/cpp-httplib-b10488-MIT.txt) |
| nlohmann/json | MIT | [`LICENSES/jsonhpp-b10488.txt`](LICENSES/jsonhpp-b10488.txt) |
| rotate-bits | MIT | [`LICENSES/rotate-bits-b10488.txt`](LICENSES/rotate-bits-b10488.txt) |
| Реализация SHA-256 | Уведомление о Public Domain | [`LICENSES/sha256-b10488.txt`](LICENSES/sha256-b10488.txt) |
| xxHash | BSD 2-Clause | [`LICENSES/xxhash-b10488.txt`](LICENSES/xxhash-b10488.txt) |

Архив также содержит DLL бэкендов CUDA 12/13 и DLL среды выполнения Microsoft Visual C++. Использование и распространение этих файлов регулируют условия для соответствующих компонентов в [лицензии NVIDIA CUDA Toolkit](https://docs.nvidia.com/cuda/eula/) и [условиях распространения Microsoft Visual C++](https://learn.microsoft.com/en-us/cpp/windows/redistributing-visual-cpp-files?view=msvc-170). Игра использует только локальный loopback-сервис. Отдельное использование облачных сервисов Ollama регулируется условиями Ollama.

## Модель Qwen3.5-9B

Настроенная модель Ollama `qwen35-9b-q4km-bartowski:latest` основана на Qwen3.5-9B. Исходная модель распространяется по Apache License 2.0. Копия лицензии включена в [`LICENSES/Qwen3.5-9B-Apache-2.0.txt`](LICENSES/Qwen3.5-9B-Apache-2.0.txt); исходные сведения о модели и лицензии опубликованы в [официальной карточке модели](https://huggingface.co/Qwen/Qwen3.5-9B).

Веса модели не входят в этот репозиторий или Windows ZIP. Текст лицензии приведён как справочное уведомление для пользователей, которые получают модель отдельно; файлы модели и checksum модели здесь не публикуются.
