# Client Integration Guide

This repository no longer ships with a built-in desktop interface. The runtime
is designed as a headless service that can be embedded into any client (Flutter,
web, CLI, etc.).

## Feedback Surface

Use `input_processing.InputPipeline` (or the `InputSanitizer` alias) with a
`FeedbackChannel` implementation to surface status updates in your UI. The
callback receives rich, human-readable strings and defaults to a no-op, so you
can wire in logging or platform-specific toasts:

```python
from input_processing import InputPipeline, FeedbackChannel

class FlutterBridge:
    def __call__(self, message: str) -> None:
        emit_to_flutter(message)

pipeline = InputPipeline(feedback_hook=FlutterBridge())
```

## Notes Security Policy

If your UI needs custom validation for notes, provide a policy implementation by
calling `database.notes_security.register_security_policy` during start-up or by
setting `NOTES_SECURITY_POLICY_PATH="my_module:get_notes_security"`. The factory
must return an object that implements the `SecurityPolicy` interface.

## Legacy Desktop Cleanup

Legacy Qt modules have been removed. Importing
`tools.pseudocode_translator.client_bridge` yields an empty placeholder meant for
your own adapter code. The former desktop-prefixed modules have been retired in
favor of this client-centric surface.
