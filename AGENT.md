# AGENT.md

## Project Overview

TrackpadAir is a macOS SwiftUI app that lets users control the mouse with hand gestures.
It captures camera frames, recognizes hand poses, transforms fingertip coordinates, and uses SwiftAutoGUI for mouse movement, clicking, and scrolling.

The app is intended for Apple Silicon Macs.

## Repository Layout

- `TrackpadAir.xcodeproj`: Xcode project.
- `TrackpadAir/TrackpadAirApp.swift`: SwiftUI app entry point.
- `TrackpadAir/AppDelegate.swift`: App delegate. Status bar behavior is currently present but commented out.
- `TrackpadAir/View/HandGesture/`: Main camera and gesture UI.
- `TrackpadAir/Manager/`: Gesture processing, hand pose recognition, and video capture.
- `TrackpadAir/Helper/`: Image and coordinate helper utilities.
- `TrackpadAir/Model/`: Gesture-related model types.
- `TrackpadAir/View/Settings/`: Settings UI.
- `TrackpadAirTests/`: Swift Testing tests.
- `img/`: README/demo assets.

## Development Guidelines

- Follow the existing Swift and SwiftUI style in the project.
- Keep changes focused and avoid unrelated refactors.
- Prefer small, readable functions over broad abstractions.
- Keep UI work consistent with the existing macOS SwiftUI app structure.
- Be careful with camera, Vision, and mouse-control behavior because small changes can affect runtime ergonomics.
- Do not remove user-facing behavior unless explicitly requested.
- Avoid changing generated Xcode project settings unless the task requires it.

## Gesture Behavior

Gesture interpretation lives primarily in `HandGestureProcessor`.

Current gesture mapping:

- Thumb + index pinch: move mouse.
- Thumb + middle pinch: left click.
- Index + middle pinch: scroll.
- Other recognized pinches currently do not trigger app behavior.

When changing gesture behavior:

- Update or add tests in `TrackpadAirTests`.
- Consider gesture ambiguity and ordering. The first matching state wins.
- Keep thresholds easy to reason about.

## Testing

Use the Xcode project and the `TrackpadAirTests` target for tests.

Recommended verification after code changes:

```sh
xcodebuild test -project TrackpadAir.xcodeproj -scheme TrackpadAir -destination 'platform=macOS'
```

If full tests are not practical, at least verify the files compile or explain what could not be run.

## Notes For Agents

- The git worktree may contain user changes. Do not revert unrelated changes.
- Use `rg` for searching when possible.
- Use `apply_patch` for manual file edits.
- Keep final summaries short and include what was changed plus any verification performed.
