# Sparkflow Product Decisions

> Living document. Update this file whenever a product, architecture, platform, or naming decision changes. Preserve superseded ideas in the history instead of deleting them.

Last updated: 2026-08-14 (native implementation milestone 2)

## Product identity

- App: **Sparkflow**
- Agent: **Spark**
- Hook: **From spark to flow in seconds.**
- Feeling: effortless, energetic, organized, and frictionless
- Audience: creators, writers, developers, and entrepreneurs who need to capture ideas quickly and organize them later

## Current product definition

Sparkflow is a native iPhone notes application with a familiar Apple Notes-style structure. Spark can propose precise changes to the user's notes, but material changes do not become real until the user approves them.

The core promise is:

> Capture immediately. Understand the proposed change. Stay in control of what is applied.

## Accepted decisions

### Notes experience

- Use an Apple Notes-style information architecture: folders, notes list, search, and editor.
- Sparkflow owns and stores its notes initially.
- Do not depend on direct access to the Apple Notes database.
- Support iOS 18 and later in one universal iPhone app.

### Spark and change safety

- Spark creates structured proposals instead of silently editing notes.
- Initial proposal types:
  - Create a note.
  - Append content to a note.
  - Replace or rephrase selected content.
  - Reorganize note content.
  - Delete a note or content.
- Each proposal can be approved, rejected, or inspected and revised.
- Replacements and destructive changes show an exact before-and-after comparison.
- Applied changes should support undo and retain an audit history.

### Review experience

- Present pending proposals as an approachable card queue.
- Primary actions are checkmark to approve and X to reject.
- Swiping may supplement the buttons, but buttons remain visible for clarity and accessibility.
- Nothing should be presented as applied until persistence succeeds.

### Siri and voice

- Reliable shipped phrase: **“Hey Siri, capture with Sparkflow.”**
- Offer an optional user Shortcut named **“Tell Spark.”**
- A phrase such as **“Open Spark in Sparkflow”** may open directly into listening mode.
- Siri captures or routes the request; Spark interprets it; the review queue controls application.
- Siri cannot seamlessly transfer its active conversation to Spark. Sparkflow begins its own listening session after opening.

### Device behavior

#### iPhone 13 and other non-Apple-Intelligence devices

- Full notes and proposal-review experience.
- Siri capture through App Intents and App Shortcuts.
- In-app speech transcription.
- Sophisticated Spark reasoning through a disclosed cloud model.
- Deterministic local commands can remain available offline.

#### Apple Intelligence-compatible iPhones

- The same core experience and approval requirements.
- Prefer eligible on-device processing where it improves privacy or latency.
- Add supported Apple Intelligence enhancements progressively and conditionally.
- Never make the core notes or review workflow depend on Apple Intelligence hardware.

## Implementation roadmap

### Phase 1 - Native foundation

- [x] Create an iPhone SwiftUI/Xcode project.
- [x] Establish local SwiftData models and starter content.
- [x] Implement preliminary section, list, search, and editing views.
- [x] Rename the remaining internal project and target references from Nest to Sparkflow.
- [x] Replace the preliminary section-first interface with the approved Notes-style structure.
- [ ] Add automated model and persistence tests.
- [x] Complete unsigned generic physical-iPhone build verification.
- [ ] Complete interactive simulator and signed physical-device QA.

### Phase 2 - Review queue

- [x] Define persistent proposal and audit-history models.
- [x] Implement create, append, replace, and delete proposals.
- [x] Build approval cards with visible approve and reject controls.
- [x] Add before-and-after diffs.
- [ ] Support revising a proposal before approval.
- [x] Add safe application and visible failure handling.
- [ ] Add cross-session undo for approved changes.

### Phase 3 - Voice and Siri

- [x] Add microphone permission and live speech transcription.
- [x] Add Sparkflow App Intents and App Shortcuts.
- [x] Implement “capture with Sparkflow.”
- [ ] Provide setup guidance for the optional “Tell Spark” Shortcut.
- [x] Add an in-app Spark listening mode.

### Phase 4 - Agent intelligence

- [x] Define the local agent command-to-proposal contract.
- [ ] Add secure cloud-model integration without embedding a secret API key in the app.
- [ ] Implement note retrieval and target disambiguation.
- [ ] Add privacy disclosure, cost controls, timeout handling, and offline fallback behavior.
- [ ] Test adversarial, ambiguous, and destructive instructions.

### Phase 5 - Sync and release

- [ ] Add account and sync architecture.
- [ ] Handle concurrent edits and conflicts.
- [ ] Complete accessibility and performance testing.
- [ ] Create the final app icon and App Store assets.
- [ ] Configure signing and install on Luca's iPhone.
- [ ] Distribute family testing builds through TestFlight.

## Deferred ideas

These ideas are preserved for possible reconsideration:

- A section-first dashboard centered on Ideas, To-Do, and Journal.
- Direct integration with the Apple Notes database.
- Fully automatic edits without review; this could return as an explicitly trusted automation mode.
- Deep automatic organization before the editor and review workflow are proven.
- A continuous Siri-to-Spark conversation without an app handoff.
- Earlier names: Nest, Sift, Amend, Margin, Proof, Nudge, Vellum, and Clover.

## Decision history

### 2026-08-14

- Began with a native adaptation of the existing Nest web prototype.
- Considered a section-first organizer with Ideas, To-Do, and Journal.
- Changed the core direction to a Notes-style app with a human-reviewed agent workflow.
- Selected **Sparkflow** as the app name and **Spark** as the agent name.
- Selected a universal iPhone strategy supporting iOS 18 and later.
- Chose a reliable Sparkflow App Shortcut plus an optional personalized “Tell Spark” Shortcut.
- Created the first roadmap PDF; this Markdown file is now the canonical ongoing record.
- Rebuilt the native interface around folders, notes, review, and activity tabs.
- Added persistent Spark proposals, approval and rejection, exact diffs, and audit events.
- Added deterministic Spark interpretation for create, append, rewrite, and delete requests.
- Added live microphone transcription and Siri App Intents.
- Completed a full unsigned iPhone build with Xcode 26.6 and the iOS 26.5 SDK, including App Intents metadata validation.

## Open decisions

- Exact Notes-style folder and navigation behavior.
- Whether the review queue is a tab, inbox, overlay, or combination.
- Cloud model/provider and the production authentication architecture.
- Sync provider and account strategy.
- Whether approved changes should enter a short grace period before final application.
