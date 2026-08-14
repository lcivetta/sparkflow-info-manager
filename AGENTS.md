# Sparkflow Project Context

This file provides product context and working guidance for AI agents and contributors modifying Sparkflow.

## What Sparkflow is

Sparkflow is a self-built, native iPhone tool for capturing ideas with less friction and managing them through a human-reviewed agent workflow. The in-app agent is named Spark.

Users can type or speak a request. Spark converts it into a structured proposal to create, append, rewrite, or delete note content. The proposal must be reviewed and explicitly approved before it changes a note.

Sparkflow is currently a local-first MVP and reference application, not a finished consumer app. It is intended to improve the creator's own daily habits while remaining useful and understandable to other people who want to try it.

## Product principles

- Capturing an idea should feel immediate.
- Intelligent changes should be understandable before they are applied.
- Spark must propose changes rather than silently mutating notes.
- The user must remain in control of approval and rejection.
- The core workflow must work without Apple Intelligence hardware.
- Newer-device enhancements must be capability-gated and optional.
- Personal notes and credentials must never be committed to source control.

## How others can use Sparkflow

Sparkflow can be published on GitHub so other people can download its source and use it similarly to its creator. This is a self-build development workflow, not a one-tap consumer download.

Each user needs:

- A compatible Mac.
- Xcode 26.6 or later with the required iOS platform installed.
- An iPhone running iOS 18 or later, or a compatible Simulator.
- An Apple Account added to Xcode.
- Their own signing team and, when necessary, a unique bundle identifier.

The repository has no external package, database server, or model API-key requirement for the local MVP.

## Free Apple Account limitations

Apple allows people to test their own development builds on an iPhone for free through an Xcode Personal Team. Agents and contributors must describe this accurately:

- The development provisioning profile expires after 7 days.
- The user must rebuild and reinstall Sparkflow after expiration.
- A free account can install up to 3 development-signed apps per device.
- A free account can register up to 3 test devices per platform.
- A free account can register up to 10 temporary App IDs at once.
- App IDs and test-device registrations in this workflow expire after 7 days.
- Free Personal Team signing does not include TestFlight, App Store distribution, or a permanent one-tap installation.

These restrictions are imposed by Apple rather than Sparkflow. Normal TestFlight or App Store distribution requires membership in the paid Apple Developer Program.

## Cable and wireless use

For an iPhone running iOS 26, users should plan to connect the phone to the Mac with a cable for initial pairing, trust, Developer Mode, signing, and installation.

After the phone has been paired with Xcode by cable, Xcode can generally run and reinstall Sparkflow over Wi-Fi when the Mac and iPhone are on the same compatible network. The cable does not need to remain connected during normal use of the installed app.

During the valid free-signing period, Sparkflow can run without an active Mac connection. When the 7-day Personal Team profile expires, the user needs access to the Mac and Xcode again to rebuild and reinstall it.

## Device behavior

### iPhone 13 and other non-Apple-Intelligence devices

- Full notes, folders, search, proposal review, and activity history.
- Siri capture through App Intents and App Shortcuts.
- In-app speech transcription.
- The current deterministic local Spark interpreter.
- Future sophisticated reasoning may use a disclosed, authenticated cloud service.

### Apple Intelligence-capable iPhones

- The same core experience and human-approval requirements.
- Potential future on-device enhancements where Apple APIs and hardware permit them.
- No feature may bypass the proposal review boundary merely because newer hardware is available.

The current repository does not claim to use Apple Intelligence.

## Architecture and safety boundary

- SwiftUI provides the native interface.
- SwiftData stores folders, notes, proposals, and audit events.
- App Intents exposes supported actions to Siri and Shortcuts.
- Speech and AVFAudio provide live voice transcription.
- SparkInterpreter converts supported commands into structured proposals.
- ProposalApplier executes a proposal only after explicit approval.

Any new agent capability must produce a reviewable proposal. Do not add code paths that allow generated content to silently alter or delete user notes.

## Working documentation

- `README.md` is the public setup, usage, architecture, and limitation guide.
- `PRODUCT_DECISIONS.md` is the canonical living decision history and roadmap.
- Update `PRODUCT_DECISIONS.md` when accepting, superseding, or deferring a meaningful product decision.
- Preserve deferred ideas rather than deleting their history.

## Current status

The project completes a full unsigned generic iPhone build with Xcode 26.6 and the iOS 26.5 SDK. Signed physical-device installation and interactive device QA still require the user's Apple Account, development team, and connected or paired iPhone.
