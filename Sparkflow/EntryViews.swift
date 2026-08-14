import SwiftData
import SwiftUI

struct NotesHomeView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \NoteFolder.sortOrder) private var folders: [NoteFolder]
  @Query(sort: \SparkNote.modifiedAt, order: .reverse) private var notes: [SparkNote]
  @Binding var showingSpark: Bool
  @State private var searchText = ""
  @State private var showingNewFolder = false
  @State private var folderName = ""

  private var filteredNotes: [SparkNote] {
    guard !searchText.isEmpty else { return notes }
    return notes.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
        || $0.body.localizedCaseInsensitiveContains(searchText)
    }
  }

  var body: some View {
    List {
      if !searchText.isEmpty {
        Section("Search Results") {
          ForEach(filteredNotes) { note in
            NavigationLink {
              NoteEditorView(note: note)
            } label: {
              NoteRow(note: note)
            }
          }
        }
      } else {
        Section("Folders") {
          NavigationLink {
            AllNotesView(showingSpark: $showingSpark)
          } label: {
            Label {
              countLabel("All Notes", count: notes.count)
            } icon: {
              folderIcon("tray.full", color: .orange)
            }
          }
          ForEach(folders) { folder in
            NavigationLink {
              FolderNotesView(folder: folder, showingSpark: $showingSpark)
            } label: {
              Label {
                countLabel(folder.name, count: folder.notes.count)
              } icon: {
                folderIcon(folder.systemImage, color: .orange)
              }
            }
          }
        }

        if !notes.isEmpty {
          Section("Recent") {
            ForEach(notes.prefix(4)) { note in
              NavigationLink {
                NoteEditorView(note: note)
              } label: {
                NoteRow(note: note)
              }
            }
          }
        }
      }
    }
    .navigationTitle("Sparkflow")
    .searchable(text: $searchText, prompt: "Search notes")
    .toolbar {
      ToolbarItem(placement: .topBarLeading) { EditButton() }
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          showingNewFolder = true
        } label: {
          Image(systemName: "folder.badge.plus")
        }
        Button {
          showingSpark = true
        } label: {
          Image(systemName: "sparkles")
        }
        .accessibilityLabel("Ask Spark")
      }
    }
    .alert("New Folder", isPresented: $showingNewFolder) {
      TextField("Name", text: $folderName)
      Button("Cancel", role: .cancel) { folderName = "" }
      Button("Create") { createFolder() }.disabled(
        folderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
  }

  private func countLabel(_ title: String, count: Int) -> some View {
    HStack {
      Text(title)
      Spacer()
      Text(count, format: .number).foregroundStyle(.secondary)
    }
  }

  private func folderIcon(_ name: String, color: Color) -> some View {
    Image(systemName: name).foregroundStyle(color).frame(width: 28)
  }

  private func createFolder() {
    modelContext.insert(
      NoteFolder(
        name: folderName.trimmingCharacters(in: .whitespacesAndNewlines), sortOrder: folders.count))
    folderName = ""
  }
}

struct AllNotesView: View {
  @Query(sort: \SparkNote.modifiedAt, order: .reverse) private var notes: [SparkNote]
  @Binding var showingSpark: Bool

  var body: some View {
    NoteList(title: "All Notes", notes: notes, folder: nil, showingSpark: $showingSpark)
  }
}

struct FolderNotesView: View {
  let folder: NoteFolder
  @Binding var showingSpark: Bool

  var body: some View {
    NoteList(
      title: folder.name, notes: folder.notes.sorted { $0.modifiedAt > $1.modifiedAt },
      folder: folder, showingSpark: $showingSpark)
  }
}

struct NoteList: View {
  @Environment(\.modelContext) private var modelContext
  let title: String
  let notes: [SparkNote]
  let folder: NoteFolder?
  @Binding var showingSpark: Bool
  @State private var searchText = ""

  private var filtered: [SparkNote] {
    searchText.isEmpty
      ? notes
      : notes.filter {
        $0.title.localizedCaseInsensitiveContains(searchText)
          || $0.body.localizedCaseInsensitiveContains(searchText)
      }
  }

  var body: some View {
    List {
      if filtered.isEmpty {
        ContentUnavailableView(
          "No Notes", systemImage: "note.text",
          description: Text("Create a note or ask Spark to capture one."))
      } else {
        ForEach(filtered) { note in
          NavigationLink {
            NoteEditorView(note: note)
          } label: {
            NoteRow(note: note)
          }
        }
        .onDelete { offsets in offsets.map { filtered[$0] }.forEach(modelContext.delete) }
      }
    }
    .navigationTitle(title)
    .searchable(text: $searchText, prompt: "Search \(title)")
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          createNote()
        } label: {
          Image(systemName: "square.and.pencil")
        }
        Button {
          showingSpark = true
        } label: {
          Image(systemName: "sparkles")
        }
      }
    }
  }

  private func createNote() {
    let note = SparkNote(title: "New Note", folder: folder)
    modelContext.insert(note)
  }
}

struct NoteRow: View {
  let note: SparkNote

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        if note.isPinned { Image(systemName: "pin.fill").font(.caption).foregroundStyle(.orange) }
        Text(note.title.isEmpty ? "New Note" : note.title).font(.headline).lineLimit(1)
      }
      HStack(spacing: 6) {
        Text(note.modifiedAt.formatted(date: .omitted, time: .shortened))
        Text(note.preview.replacingOccurrences(of: "\n", with: " ")).lineLimit(1)
      }
      .font(.subheadline).foregroundStyle(.secondary)
    }
    .padding(.vertical, 3)
  }
}

struct NoteEditorView: View {
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss
  @Bindable var note: SparkNote
  @FocusState private var bodyFocused: Bool

  var body: some View {
    VStack(spacing: 0) {
      TextField("Title", text: $note.title, axis: .vertical)
        .font(.title2.bold())
        .padding(.horizontal)
        .padding(.top, 14)
      TextEditor(text: $note.body)
        .focused($bodyFocused)
        .padding(.horizontal, 12)
        .scrollContentBackground(.hidden)
    }
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: note.title) { _, _ in note.modifiedAt = .now }
    .onChange(of: note.body) { _, _ in note.modifiedAt = .now }
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(note.modifiedAt.formatted(date: .abbreviated, time: .shortened)).font(.caption)
          .foregroundStyle(.secondary)
      }
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          Button(note.isPinned ? "Unpin" : "Pin", systemImage: "pin") { note.isPinned.toggle() }
          Button("Delete", systemImage: "trash", role: .destructive) {
            modelContext.delete(note)
            dismiss()
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
      ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") { bodyFocused = false }
      }
    }
  }
}
