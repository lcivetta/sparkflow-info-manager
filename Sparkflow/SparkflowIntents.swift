import AppIntents
import SwiftData

struct CaptureWithSparkflowIntent: AppIntent {
  static let title: LocalizedStringResource = "Capture with Sparkflow"
  static let description = IntentDescription(
    "Send a thought or requested note change to Sparkflow for review.")

  @Parameter(
    title: "Request", description: "The idea or note change for Spark to prepare.",
    requestValueDialog: IntentDialog("What should Spark capture?"))
  var request: String?

  static var parameterSummary: some ParameterSummary { Summary("Ask Spark to \(\.$request)") }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    guard let request, !request.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw $request.requestValue("What should Spark capture?")
    }
    let container = try SparkflowStore.makeContainer()
    let context = ModelContext(container)
    let notes = try context.fetch(FetchDescriptor<SparkNote>())
    let result = SparkInterpreter.interpret(request, notes: notes)
    if let clarification = result.clarification {
      return .result(
        dialog: "Spark needs one clarification: \(clarification) Open Sparkflow to finish the request."
      )
    }
    let target = notes.first { $0.title.caseInsensitiveCompare(result.targetTitle) == .orderedSame }
    context.insert(
      SparkProposal(
        kind: result.kind,
        targetNoteID: target?.id,
        targetTitle: result.targetTitle,
        proposedTitle: result.proposedTitle,
        beforeText: result.originalText,
        afterText: result.newText,
        explanation:
          "Spark prepared this change from Siri. Open Review in Sparkflow to approve or reject it.",
        sourceCommand: request
      ))
    try context.save()
    return .result(
      dialog: "Spark understood: \(result.spokenSummary). It is waiting in Review.")
  }
}

struct OpenSparkflowReviewIntent: AppIntent {
  static let title: LocalizedStringResource = "Review Spark Changes"
  static let description = IntentDescription("Open Sparkflow to review pending changes from Spark.")
  static let openAppWhenRun = true

  func perform() async throws -> some IntentResult & ProvidesDialog {
    .result(dialog: "Opening your Sparkflow review queue.")
  }
}

struct SparkflowShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: CaptureWithSparkflowIntent(),
      phrases: [
        "Talk to \(.applicationName)", "Talk to Spark in \(.applicationName)",
        "Capture with \(.applicationName)", "Tell \(.applicationName)",
        "Ask Spark in \(.applicationName)",
      ],
      shortTitle: "Capture with Spark",
      systemImageName: "sparkles"
    )
    AppShortcut(
      intent: OpenSparkflowReviewIntent(),
      phrases: [
        "Review Spark changes in \(.applicationName)", "Open Spark in \(.applicationName)",
      ],
      shortTitle: "Review Spark Changes",
      systemImageName: "checkmark.circle"
    )
  }

  static var shortcutTileColor: ShortcutTileColor { .orange }
}
