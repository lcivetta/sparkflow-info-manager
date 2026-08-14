# Sparkflow Architecture

## Objective

Sparkflow reduces the friction of capturing ideas while preventing an agent from silently changing a user's notes. Its architecture deliberately separates interpretation, review, and execution.

## Request lifecycle

```text
Typed request / microphone / Siri
                 |
                 v
          SparkInterpreter
                 |
                 v
          SparkProposal (pending)
                 |
          Human review card
             /       \
        reject       approve
          |             |
          v             v
     audit event   ProposalApplier
                        |
                        v
                 SparkNote mutation
                        |
                        v
                   audit event
```

## Major components

### SwiftUI presentation

- `RootView.swift` owns the Notes, Review, and Activity tab structure.
- `EntryViews.swift` implements folders, note lists, search, and editing.
- `CaptureView.swift` implements Spark's request composer, proposal preview, review cards, and approval controls.

### Persistence

`Models.swift` defines the SwiftData domain:

- `NoteFolder` groups notes.
- `SparkNote` stores user-authored content.
- `SparkProposal` stores an interpreted but unapplied change.
- `ChangeAuditEvent` records proposal resolution.

Proposal targets use stable note identifiers rather than view state. SwiftData persists the local-first experience without a server dependency.

### Interpretation

`SparkInterpreter` converts supported natural-language patterns into a `SparkInterpretation`. The MVP recognizes four operations:

1. Create a note.
2. Append content.
3. Replace matching content.
4. Delete a note.

The interpreter is deterministic by design. Ambiguous, open-ended reasoning is deferred to a future authenticated agent service rather than simulated as a production AI capability.

### Review and execution

`SparkProposal` is the safety boundary. Interpreting a request only creates a pending proposal. `ProposalApplier` is invoked after explicit user approval and validates that the target note and replacement text still exist before mutation.

Rejected, approved, and failed proposals retain status and resolution timestamps. `ChangeAuditEvent` provides a human-readable activity record.

### Voice and system integration

- `VoiceCaptureService.swift` uses Speech and AVFAudio for in-app transcription.
- `SparkflowIntents.swift` exposes capture and review actions through App Intents and Siri.
- Siri-created requests enter the same pending proposal queue and cannot bypass review.

## Safety invariants

- Generated instructions never mutate notes directly.
- Every material agent action must be represented as a proposal.
- Destructive actions require the same approval path as non-destructive actions.
- Rewrite proposals show before-and-after text.
- Execution revalidates targets because note state may change after interpretation.
- API keys and service credentials must never be embedded in the app or committed to GitHub.
- Newer-device intelligence cannot bypass approval or become a requirement for the core workflow.

## Device strategy

The deployment target is iOS 18. The notes, review, Siri, and voice workflows run without Apple Intelligence. Future on-device intelligence can be conditionally adopted on compatible hardware while older devices use deterministic rules or an explicitly disclosed cloud service.

## Future agent-service boundary

A production agent should return a versioned, structured proposal rather than free-form text. A future backend would be responsible for:

- Authenticating the app without exposing provider secrets.
- Selecting relevant note context with user consent.
- Producing schema-validated proposal output.
- Enforcing timeouts, rate limits, and cost controls.
- Logging operational metrics without collecting private note content unnecessarily.
- Running adversarial and destructive-action evaluations.

The iPhone app remains responsible for displaying the proposal, collecting approval, validating current local state, and applying the change.

## Current tradeoffs

- Local persistence is simple and private but does not yet sync across devices.
- Deterministic interpretation is testable and offline but intentionally limited in language coverage.
- The activity log records decisions but cross-session undo is not yet implemented.
- Free Personal Team installation is accessible but requires weekly reprovisioning under Apple's rules.
