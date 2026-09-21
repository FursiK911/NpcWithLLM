# 3D Dialogue Vertical Slice

Status: ready-for-agent

## Problem Statement

The project is currently an empty Godot 4.7 Mono scaffold. There is no playable scene that demonstrates the core product direction: a player communicating with a 3D character. Without a small end-to-end slice, it is not possible to validate the intended interaction, the screen composition, or the boundary that will later connect the game to a local LLM.

## Solution

Create a single playable 3D scene with a cube as the temporary character and a neutral Russian dialogue overlay. The player can enter a message, submit it with a button or keyboard, see a waiting state, and receive a deterministic mock response after a short delay.

The UI communicates with the response provider through one `ChatResponder` seam. The first implementation uses a mock provider behind that seam, allowing the future local LLM provider to replace it without changing the player-facing scene or interaction flow.

## User Stories

1. As a player, I want to launch the project and see a 3D scene, so that I can understand the intended interaction context.
2. As a player, I want to see a cube representing the temporary character, so that the dialogue has a visible 3D counterpart.
3. As a player, I want the character to remain visible while I use the dialogue controls, so that the UI does not hide the main scene.
4. As a player, I want to see a neutral Russian dialogue panel on the right side of the screen, so that the controls are easy to find without requiring final art direction.
5. As a player, I want to type a multi-line message, so that I can test realistic input rather than only a single short phrase.
6. As a player, I want to submit a message with an `Отправить` button, so that the interaction is usable without remembering keyboard shortcuts.
7. As a player, I want to submit a message with Enter, so that common keyboard interaction is fast.
8. As a player, I want Shift+Enter to insert a line break, so that the input remains multi-line while Enter remains a submit shortcut.
9. As a player, I want empty or whitespace-only input to be ignored, so that accidental submissions do not create meaningless responses.
10. As a player, I want the controls to become unavailable while a response is being generated, so that I cannot accidentally start overlapping requests.
11. As a player, I want to see a waiting status while the character is preparing an answer, so that the interface explains why the response has not appeared yet.
12. As a player, I want the temporary character to acknowledge my exact message, so that I can verify that the input reached the response provider.
13. As a player, I want the response to appear after a short simulated delay, so that the first slice demonstrates the same asynchronous shape as a future LLM request.
14. As a player, I want the latest character response to replace the previous one, so that the first slice remains visually simple and focused.
15. As a player, I want the input to clear after a successful response, so that I can immediately write the next message.
16. As a player, I want the input to remain available for retry after a failed response, so that I do not lose the message I wrote.
17. As a player, I want the scene to remain usable when the window is resized, so that the dialogue panel stays on the right and the character remains visible.
18. As a developer, I want the mock response provider to be replaceable through one seam, so that connecting a local LLM does not require rewriting the UI.
19. As a developer, I want response start, success, and failure states to be observable by the UI, so that asynchronous providers can expose their lifecycle consistently.
20. As a developer, I want the first slice to use the existing Godot Mono setup, so that the project remains aligned with its selected C# implementation path.

## Implementation Decisions

- Use Godot 4.7 Mono and C# for the implementation.
- Build one main 3D scene containing the camera, lighting, background, cube placeholder, and dialogue overlay.
- Keep the 3D view static for this slice: no player movement, camera orbit, character animation, or world interaction.
- Use a cube mesh as the temporary character representation.
- Place the dialogue overlay as a screen-space panel anchored to the right side of the window. Keep the cube visible in the left portion of the view.
- Use a Russian, neutral presentation with no final character art, branding, or elaborate visual theme.
- Use a multi-line text input, an adjacent `Отправить` button, a latest-response display, and a status display.
- Treat Enter as submit and Shift+Enter as a line break.
- Trim submitted text before validation. Do not send blank or whitespace-only input.
- Allow only one response request at a time. Disable the input and submit control while the request is pending.
- Keep the submitted text while the request is pending. Clear it only after a successful response; preserve it after a failure so it can be retried.
- Use one `ChatResponder` seam between the scene controller and response generation.
- The seam exposes a request operation and three lifecycle notifications: response started, response received, and response failed.
- Implement the first provider as a deterministic mock that waits 800 milliseconds and returns an echo-style response containing the submitted message.
- Reserve the mock-only message `/fail` as a deterministic way to exercise the provider failure and retry path during manual acceptance testing.
- Replace the displayed response instead of accumulating chat history.
- Handle provider failure in the UI even though the initial mock provider is expected to succeed; show an error status and re-enable retry.
- Keep the seam at the highest useful level: test the player-facing submission flow through `ChatResponder`, rather than testing individual Godot nodes or layout properties separately.
- Do not add a real local LLM connection, HTTP protocol, persistence, authentication, conversation history, movement, animation, or final art in this slice.

## Testing Decisions

- Test externally visible behavior rather than private C# methods, node wiring details, or exact layout implementation.
- Use one test seam at `ChatResponder` to keep the complete submission lifecycle deterministic; exercise it through the manual acceptance flow rather than introducing a separate automated UI framework.
- Verify the scene manually in the Godot Mono Editor because camera framing, cube visibility, panel placement, focus behavior, and responsive layout are visual concerns.
- There is no existing test infrastructure or comparable feature in the repository, so do not introduce a broad test framework for this slice.
- The manual acceptance run must verify:
  - the scene launches and shows the cube and right-side dialogue panel;
  - the panel remains usable after window resizing;
  - blank input does not start a request;
  - button submission starts the waiting state;
  - Enter submission behaves like button submission;
  - Shift+Enter inserts a line break;
  - the input and button cannot trigger overlapping requests;
  - the mock response appears after the simulated delay and contains the submitted text;
  - the previous response is replaced by the latest response;
  - the input clears after success;
  - a failure state re-enables retry without discarding the input.
  - submitting `/fail` produces the failure status, re-enables the controls, and preserves the input for retry.
- Verify that the C# project builds successfully with the installed Godot Mono toolchain before considering the slice complete.

## Out of Scope

- Connecting to Ollama, LocalAI, or any other local LLM service.
- Selecting, downloading, configuring, or prompting a real language model.
- Streaming tokens or displaying partial responses.
- Conversation history, transcripts, persistence, save/load, or multiple characters.
- Player movement, camera controls, collision, navigation, animation, voice, or gestures.
- Final 3D character assets, materials, environment art, sound, or production UI styling.
- Multiplayer, remote services, authentication, telemetry, and deployment packaging.
- A full automated UI test framework.

## Further Notes

The project currently contains only the Godot project scaffold and setup documentation, so the implementation should establish the first scene and C# project structure without preserving existing gameplay behavior. The local Markdown issue tracker treats this specification as `ready-for-agent`; it should move directly to ticket creation or implementation without an additional triage pass.
