import SwiftData
import SwiftUI

@main
struct SparkflowApp: App {
  private let container: ModelContainer = {
    let schema = Schema([
      NoteFolder.self, SparkNote.self, SparkProposal.self, ChangeAuditEvent.self,
    ])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    do {
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Could not create Sparkflow data store: \(error)")
    }
  }()

  init() {
    SparkflowShortcuts.updateAppShortcutParameters()
  }

  var body: some Scene {
    WindowGroup {
      RootView()
    }
    .modelContainer(container)
  }
}
