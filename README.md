# Sparkflow

> From spark to flow in seconds.

Sparkflow is a native iPhone notes app with a human-in-the-loop agent named Spark. Users describe a note or change in natural language, Spark converts the request into a structured proposal, and the user reviews the exact result before anything is applied.

Sparkflow is currently a local-first MVP and reference application. It does not require a paid API or backend to demonstrate its core workflow.

## Technical highlights

- Advanced a one-sentence product concept into a buildable native iPhone reference application using an AI-native development workflow.
- Separates agent reasoning from execution through typed proposals and an explicit human-approval boundary.
- Supports multi-surface interaction through SwiftUI, live speech transcription, Siri App Intents, and Shortcuts.
- Uses capability-aware architecture so the core workflow runs on iPhone 13 while leaving room for future on-device intelligence.
- Maintains a living product decision record connecting user needs, technical constraints, deferred ideas, and roadmap changes.
- Builds without third-party packages, external services, or embedded credentials.

## Why I built Sparkflow

I personally think the world is now experiencing information overflow. We need help digesting and managing our information.

I've always wondered: what would happen if everyone acted on the ideas they had? I like to think about this equation:

> **Ideas that revolutionize the world = 0.00001% success rate × number of ideas**

So let's increase the number of ideas.

Writing down every idea can involve a lot of friction. Personally, I get many ideas right before going to sleep, when I'm trying not to look at my phone. I used to pick up my phone and write them down just so I wouldn't forget them. Then I thought, “There's got to be a better way.”

So I made it. And here it is.

It's not a full app yet, although I'll likely explore that possibility. For now, it is meant to reduce friction in my daily habits. Although this is a tool I originally built for myself, I hope it is helpful to others.

Let me know what you think—I'm always happy to hear feedback.

## What it does

- Creates and organizes notes in folders using SwiftData.
- Searches and edits notes with a familiar iOS interface.
- Accepts typed or spoken natural-language requests.
- Interprets create, append, rewrite, and delete instructions.
- Converts every instruction into a reviewable proposal.
- Shows before-and-after content for rewrites.
- Requires explicit approval before modifying a note.
- Records approved and rejected proposals in an activity history.
- Exposes capture and review actions through Siri App Intents.

## Who can use it

Anyone with a Mac capable of running the required Xcode version can clone the repository, build Sparkflow, and install it on a compatible iPhone. A free Apple Account is sufficient for personal on-device testing; broader TestFlight or App Store distribution requires Apple Developer Program membership.

This means GitHub users can run Sparkflow the same way its developer does, but it is a **self-build workflow**, not a one-tap consumer download. Each user needs their own Mac, Xcode installation, Apple Account, and signing setup.

The app targets iOS 18 and later. The core experience works on iPhone 13 and newer supported devices and does not depend on Apple Intelligence hardware.

## Requirements

- macOS with Xcode 26.6 or later
- The iOS platform component installed through Xcode Settings > Components
- An iPhone or an installed iPhone Simulator running iOS 18 or later
- An Apple Account selected as the development team for physical-device installation

No external packages, package manager, database server, or API key are required for the local MVP.

## Clone and run

```bash
git clone <repository-url>
cd Sparkflow
open Sparkflow.xcodeproj
```

Then in Xcode:

1. Select the blue Sparkflow project in the Project navigator.
2. Select the Sparkflow target.
3. Open Signing & Capabilities.
4. Enable Automatically manage signing.
5. Select your Apple Account under Team.
6. Choose an iPhone Simulator or connected iPhone as the run destination.
7. Press Run.

Each developer may need to change the bundle identifier from `com.lucacive.sparkflow` to a unique value, such as `com.yourname.sparkflow`, before installing on a physical device.

## Free iPhone installation limitations

Apple calls free signing through Xcode a **Personal Team**. It is intended for personal development and device testing rather than permanent distribution.

With a free Apple Account:

- The provisioning profile expires after 7 days.
- Sparkflow must be rebuilt and reinstalled from Xcode after the profile expires.
- Up to 3 development-signed apps can be installed per device.
- Up to 3 test devices can be registered per platform.
- Up to 10 temporary App IDs can be registered at once.
- Test devices and App IDs associated with the free workflow also expire after 7 days.
- TestFlight, App Store distribution, and normal one-tap installation are not included.

These limitations come from Apple, not Sparkflow. Joining the paid Apple Developer Program removes the weekly Personal Team workflow and enables TestFlight and App Store distribution.

## Does the iPhone need to stay connected?

For an iPhone running iOS 26, plan to connect it to the Mac with a cable for initial pairing, trust, Developer Mode, signing, and installation.

After the device has been paired with Xcode by cable, Xcode can normally run and reinstall the app over Wi-Fi while the Mac and iPhone are on the same compatible network. The cable does not need to remain connected for everyday use of the already installed app.

The phone does not need a Mac connection while using Sparkflow during the valid signing period. When the free 7-day profile expires, the user needs access to the Mac and Xcode again to rebuild and reinstall it.

## Using Sparkflow

### Create and edit notes

Open Notes, choose a folder, and create or edit notes directly. Notes remain on the device in the app's local SwiftData store.

### Ask Spark for a change

Tap the Spark icon and enter or speak a request such as:

- `Create a note called Boat ideas that says Explore boats with wheels.`
- `In Ideas, add a bullet that says Research amphibious vehicles.`
- `In Ideas, replace “boats” with “boats with wheels”.`
- `Delete the note Ideas.`

Spark prepares a proposal instead of immediately changing the note.

### Review proposals

Open the Review tab to inspect pending changes:

- Tap the checkmark to apply the proposal.
- Tap X to reject it.
- Review before-and-after content for rewrites.
- Check Activity for a history of resolved proposals.

## Siri and voice

After installing and launching Sparkflow, try:

- “Hey Siri, talk to Sparkflow.”
- “Hey Siri, talk to Spark in Sparkflow.”
- “Hey Siri, capture with Sparkflow.”
- “Hey Siri, ask Spark in Sparkflow.”
- “Hey Siri, review Spark changes in Sparkflow.”

The first in-app voice request prompts for microphone and speech-recognition permission. Siri and voice capture create proposals; they never bypass the Review queue.

App Shortcut discovery can take a short time after the first launch. Opening the Shortcuts app once may help iOS refresh the available Sparkflow actions.

## iPhone 13 versus Apple Intelligence devices

| Capability | iPhone 13 | Apple Intelligence-capable iPhone |
| --- | --- | --- |
| Notes, folders, and search | Yes | Yes |
| Spark proposal workflow | Yes | Yes |
| Siri App Shortcuts | Yes | Yes |
| In-app speech transcription | Yes | Yes |
| Current local command interpreter | Yes | Yes |
| Future eligible on-device model enhancements | No | Planned |

The current repository does not claim to use Apple Intelligence. Its architecture allows future capability-gated enhancements without making newer hardware a requirement.

## Architecture

- **SwiftUI** for the native interface
- **SwiftData** for folders, notes, proposals, and audit events
- **App Intents** for Siri and Shortcuts integration
- **Speech** and **AVFAudio** for live voice transcription
- A deterministic local interpreter for converting supported commands into structured proposals

The key safety boundary is `SparkProposal`: interpretation and execution are separate steps. `ProposalApplier` is only called after the user approves a pending proposal.

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for the system flow, data model, safety invariants, extension points, and current technical tradeoffs.

## Privacy

The current MVP stores notes locally and performs its command interpretation in the app. Speech recognition behavior depends on Apple's Speech framework and the language/device configuration. Sparkflow does not currently send notes to a third-party AI service.

A future cloud-model integration must use an authenticated backend. Do not embed private model API keys in the iPhone app or commit them to GitHub.

## Current limitations

- Spark uses a deterministic interpreter rather than an open-ended cloud model.
- Complex or ambiguous requests may need to be rewritten more explicitly.
- Cross-session undo is not yet implemented.
- Data does not yet sync between devices.
- Sparkflow owns its notes and does not directly edit the Apple Notes database.
- Test coverage and production migration handling are still being expanded.

## Project roadmap

See [PRODUCT_DECISIONS.md](PRODUCT_DECISIONS.md) for the living decision history, implementation checklist, deferred ideas, and open product questions.

Near-term priorities:

1. Complete simulator and physical-device QA.
2. Add automated tests for interpretation and proposal application.
3. Add proposal revision and durable undo.
4. Design a secure optional cloud-agent backend.
5. Add sync and TestFlight distribution.

## Contributing

Issues and focused pull requests are welcome once the repository is published. Please preserve the human-approval safety boundary: new agent actions should produce proposals and must not silently mutate user notes.

For meaningful behavior changes, update `PRODUCT_DECISIONS.md` so accepted and deferred product choices remain traceable.

## License

Sparkflow is available under the [MIT License](LICENSE).
