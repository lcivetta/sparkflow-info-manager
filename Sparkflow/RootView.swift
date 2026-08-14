import SwiftData
import SwiftUI

struct RootView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \NoteFolder.sortOrder) private var folders: [NoteFolder]
  @Query(filter: #Predicate<SparkProposal> { $0.statusRawValue == "pending" }) private var pending:
    [SparkProposal]
  @State private var selectedTab = 0
  @State private var showingSpark = false

  var body: some View {
    TabView(selection: $selectedTab) {
      NavigationStack { NotesHomeView(showingSpark: $showingSpark) }
        .tabItem { Label("Notes", systemImage: "note.text") }
        .tag(0)

      NavigationStack { ReviewQueueView() }
        .tabItem { Label("Review", systemImage: "checkmark.circle") }
        .badge(pending.count)
        .tag(1)

      NavigationStack { ActivityView() }
        .tabItem {
          Label("Activity", systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90")
        }
        .tag(2)
    }
    .tint(.orange)
    .sheet(isPresented: $showingSpark) { SparkCommandView() }
    .task { seedIfNeeded() }
  }

  private func seedIfNeeded() {
    guard folders.isEmpty else { return }
    let ideas = NoteFolder(name: "Ideas", systemImage: "lightbulb", sortOrder: 0)
    let projects = NoteFolder(name: "Projects", systemImage: "hammer", sortOrder: 1)
    let personal = NoteFolder(name: "Personal", systemImage: "person", sortOrder: 2)
    [ideas, projects, personal].forEach(modelContext.insert)

    modelContext.insert(
      SparkNote(
        title: "Ideas",
        body:
          "• A calmer way to capture thoughts\n• Multitrophic aquaculture system\n• Explore boats with retractable wheels",
        folder: ideas))
    modelContext.insert(
      SparkNote(
        title: "Sparkflow launch",
        body:
          "From spark to flow in seconds.\n\nBuild a familiar notes experience with human-reviewed agent changes.",
        folder: projects))
    modelContext.insert(
      SparkNote(
        title: "Reading list", body: "Designing Data-Intensive Applications\nThe Creative Act",
        folder: personal))
  }
}

struct ActivityView: View {
  @Query(sort: \ChangeAuditEvent.timestamp, order: .reverse) private var events: [ChangeAuditEvent]

  var body: some View {
    List {
      if events.isEmpty {
        ContentUnavailableView(
          "No Activity Yet", systemImage: "clock",
          description: Text("Approved and rejected Spark changes will appear here."))
      } else {
        ForEach(events) { event in
          VStack(alignment: .leading, spacing: 5) {
            Text(event.action).font(.headline)
            Text(event.summary).font(.subheadline).foregroundStyle(.secondary)
            Text(event.timestamp.formatted(date: .abbreviated, time: .shortened)).font(.caption)
              .foregroundStyle(.tertiary)
          }
          .padding(.vertical, 4)
        }
      }
    }
    .navigationTitle("Activity")
  }
}
