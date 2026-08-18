import SwiftData
import SwiftUI

enum SparkflowStore {
  static let schema = Schema([
    NoteFolder.self, SparkNote.self, SparkProposal.self, ChangeAuditEvent.self,
  ])

  static func makeContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
    return try ModelContainer(for: schema, configurations: [configuration])
  }
}

@main
struct SparkflowApp: App {
  private let container: ModelContainer = {
    do {
      return try SparkflowStore.makeContainer()
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
