import SwiftData
import SwiftUI

struct SparkCommandView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \SparkNote.modifiedAt, order: .reverse) private var notes: [SparkNote]
  @State private var command = ""
  @State private var preview: SparkInterpretation?
  @StateObject private var voice = VoiceCaptureService()
  @FocusState private var focused: Bool

  var body: some View {
    NavigationStack {
      VStack(spacing: 22) {
        sparkMark
        VStack(spacing: 7) {
          Text(preview == nil ? "What should Spark change?" : "Spark understood this")
            .font(.title.bold()).multilineTextAlignment(.center)
          Text(
            preview == nil
              ? "Describe a new note or a precise change in your own words."
              : "Confirm the action, heading, and content before it enters Review."
          )
          .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }

        if let preview {
          proposalPreview(preview)
        } else {
          commandComposer
        }
        Spacer()
        Label("Nothing changes without your approval", systemImage: "checkmark.shield")
          .font(.caption).foregroundStyle(.secondary)
      }
      .padding(22)
      .navigationTitle("Spark")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
      .task { focused = true }
      .onChange(of: voice.transcript) { _, transcript in
        if !transcript.isEmpty { command = transcript }
      }
      .onDisappear { voice.stop() }
      .alert(
        "Voice Capture",
        isPresented: Binding(
          get: { voice.errorMessage != nil },
          set: { if !$0 { voice.errorMessage = nil } }
        )
      ) {
        Button("OK", role: .cancel) {}
      } message: {
        Text(voice.errorMessage ?? "Voice capture is unavailable.")
      }
    }
  }

  private var sparkMark: some View {
    Image(systemName: "sparkles")
      .font(.title)
      .foregroundStyle(.white)
      .frame(width: 66, height: 66)
      .background(
        LinearGradient(
          colors: [.orange, .pink, .purple], startPoint: .bottomLeading, endPoint: .topTrailing),
        in: .rect(cornerRadius: 21)
      )
      .shadow(color: .orange.opacity(0.25), radius: 18, y: 8)
  }

  private var commandComposer: some View {
    VStack(spacing: 14) {
      TextField("Try “In Ideas, add a bullet that says…”", text: $command, axis: .vertical)
        .lineLimit(4...8)
        .textFieldStyle(.roundedBorder)
        .focused($focused)

      Button {
        focused = false
        voice.toggle()
      } label: {
        Label(
          voice.isStarting
            ? "Starting Microphone…"
            : (voice.isListening ? "Listening… Tap to Stop" : "Talk to Spark"),
          systemImage: voice.isStarting ? "ellipsis" : (voice.isListening ? "waveform" : "mic.fill")
        )
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .buttonBorderShape(.capsule)
      .tint(voice.isListening ? .red : .orange)
      .disabled(voice.isStarting)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack {
          example("Create a note called Boat ideas that says Explore boats with wheels")
          example("In Ideas, add a bullet that says Research amphibious vehicles")
          example("In Ideas, replace “boats” with “boats with wheels”")
        }
      }

      Button("Preview Change", systemImage: "arrow.right") {
        preview = SparkInterpreter.interpret(command, notes: notes)
      }
      .buttonStyle(.borderedProminent)
      .buttonBorderShape(.capsule)
      .controlSize(.large)
      .disabled(command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
  }

  private func example(_ text: String) -> some View {
    Button(text) { command = text }
      .buttonStyle(.bordered)
      .buttonBorderShape(.capsule)
      .lineLimit(1)
  }

  private func proposalPreview(_ interpretation: SparkInterpretation) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      Label(interpretation.kind.title, systemImage: interpretation.kind.systemImage)
        .font(.caption.bold()).foregroundStyle(.orange)
      LabeledContent("Action", value: interpretation.kind.title)
      if !interpretation.targetTitle.isEmpty {
        LabeledContent("Note", value: interpretation.targetTitle)
      }
      if !interpretation.proposedTitle.isEmpty {
        LabeledContent("Heading", value: interpretation.proposedTitle)
      }
      if !interpretation.originalText.isEmpty {
        diffBlock("BEFORE", interpretation.originalText, color: .red)
      }
      if !interpretation.newText.isEmpty {
        diffBlock(
          interpretation.kind == .replace ? "AFTER" : "PROPOSED", interpretation.newText,
          color: .green)
      }
      if let clarification = interpretation.clarification {
        Label(clarification, systemImage: "questionmark.bubble")
          .font(.subheadline)
          .foregroundStyle(.orange)
          .padding(12)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.orange.opacity(0.1), in: .rect(cornerRadius: 12))
      } else {
        Label(interpretation.spokenSummary, systemImage: "quote.bubble")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      HStack {
        Button("Edit Request") { preview = nil }
          .buttonStyle(.bordered).frame(maxWidth: .infinity)
        Button("Confirm & Add") { saveProposal(interpretation) }
          .buttonStyle(.borderedProminent).frame(maxWidth: .infinity)
          .disabled(interpretation.clarification != nil)
      }
      .buttonBorderShape(.capsule)
    }
    .padding(18)
    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
  }

  private func diffBlock(_ label: String, _ value: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 5) {
      Text(label).font(.caption2.bold()).foregroundStyle(color)
      Text(value).font(.body).frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(12)
    .background(color.opacity(0.08), in: .rect(cornerRadius: 12))
  }

  private func saveProposal(_ result: SparkInterpretation) {
    let target = notes.first { $0.title.caseInsensitiveCompare(result.targetTitle) == .orderedSame }
    let proposal = SparkProposal(
      kind: result.kind,
      targetNoteID: target?.id,
      targetTitle: result.targetTitle,
      proposedTitle: result.proposedTitle,
      beforeText: result.originalText,
      afterText: result.newText,
      explanation: explanation(for: result),
      sourceCommand: command
    )
    modelContext.insert(proposal)
    dismiss()
  }

  private func explanation(for result: SparkInterpretation) -> String {
    switch result.kind {
    case .create: "Spark will create a new note after you approve it."
    case .append: "Spark will add this content to the bottom of \(result.targetTitle)."
    case .replace: "Spark will replace matching text in \(result.targetTitle)."
    case .delete: "Spark will delete \(result.targetTitle)."
    }
  }
}

struct ReviewQueueView: View {
  @Environment(\.modelContext) private var modelContext
  @Query(sort: \SparkProposal.createdAt) private var proposals: [SparkProposal]
  @Query(sort: \SparkNote.modifiedAt, order: .reverse) private var notes: [SparkNote]
  @Query(sort: \NoteFolder.sortOrder) private var folders: [NoteFolder]
  @State private var index = 0
  @State private var errorMessage: String?

  private var pending: [SparkProposal] { proposals.filter { $0.status == .pending } }

  var body: some View {
    Group {
      if pending.isEmpty {
        ContentUnavailableView(
          "You’re All Caught Up", systemImage: "checkmark.circle",
          description: Text("Ask Spark for a change and its proposal will appear here."))
      } else {
        VStack(spacing: 18) {
          HStack {
            Text("\(min(index + 1, pending.count)) of \(pending.count)").font(.caption.bold())
              .foregroundStyle(.secondary)
            Spacer()
            Label("Pending", systemImage: "sparkles").font(.caption).foregroundStyle(.orange)
          }
          .padding(.horizontal)

          ProposalCard(proposal: pending[min(index, pending.count - 1)])
            .id(pending[min(index, pending.count - 1)].id)
            .transition(
              .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

          HStack(spacing: 34) {
            decisionButton("Reject", symbol: "xmark", color: .red) { rejectCurrent() }
            decisionButton("Approve", symbol: "checkmark", color: .green) { approveCurrent() }
          }
          .padding(.bottom)
        }
        .padding(.top)
      }
    }
    .navigationTitle("Review")
    .alert(
      "Spark Couldn’t Apply This",
      isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage ?? "Unknown error")
    }
  }

  private func decisionButton(
    _ label: String, symbol: String, color: Color, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 6) {
        Image(systemName: symbol).font(.title2.bold()).frame(width: 58, height: 58).background(
          color, in: .circle
        ).foregroundStyle(.white)
        Text(label).font(.caption.bold()).foregroundStyle(color)
      }
    }
    .accessibilityLabel(label)
  }

  private func current() -> SparkProposal? {
    guard !pending.isEmpty else { return nil }
    return pending[min(index, pending.count - 1)]
  }

  private func rejectCurrent() {
    guard let proposal = current() else { return }
    withAnimation {
      proposal.status = .rejected
      proposal.resolvedAt = .now
      modelContext.insert(
        ChangeAuditEvent(proposalID: proposal.id, action: "Rejected", summary: proposal.explanation)
      )
      index = 0
    }
  }

  private func approveCurrent() {
    guard let proposal = current() else { return }
    do {
      try ProposalApplier.apply(proposal, notes: notes, folders: folders, context: modelContext)
      proposal.status = .approved
      proposal.resolvedAt = .now
      modelContext.insert(
        ChangeAuditEvent(proposalID: proposal.id, action: "Approved", summary: proposal.explanation)
      )
      try modelContext.save()
      withAnimation { index = 0 }
    } catch {
      proposal.status = .failed
      errorMessage = error.localizedDescription
    }
  }
}

struct ProposalCard: View {
  let proposal: SparkProposal

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        HStack {
          Label(proposal.kind.title, systemImage: proposal.kind.systemImage)
            .font(.headline).foregroundStyle(.orange)
          Spacer()
          Text(proposal.createdAt.formatted(.relative(presentation: .named))).font(.caption)
            .foregroundStyle(.secondary)
        }
        if !proposal.targetTitle.isEmpty { field("NOTE", proposal.targetTitle) }
        if !proposal.proposedTitle.isEmpty { field("HEADING", proposal.proposedTitle) }
        if !proposal.beforeText.isEmpty { diff("BEFORE", proposal.beforeText, color: .red) }
        if !proposal.afterText.isEmpty {
          diff(proposal.kind == .replace ? "AFTER" : "PROPOSED", proposal.afterText, color: .green)
        }
        Divider()
        Text(proposal.explanation).font(.subheadline).foregroundStyle(.secondary)
        DisclosureGroup("Original request") {
          Text(proposal.sourceCommand).font(.subheadline).foregroundStyle(.secondary).padding(
            .top, 5)
        }
      }
      .padding(22)
    }
    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 26))
    .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color(.separator).opacity(0.4)))
    .shadow(color: .black.opacity(0.08), radius: 22, y: 10)
    .padding(.horizontal)
  }

  private func field(_ label: String, _ value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label).font(.caption2.bold()).foregroundStyle(.secondary)
      Text(value).font(.title3.bold())
    }
  }

  private func diff(_ label: String, _ value: String, color: Color) -> some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(label).font(.caption2.bold()).foregroundStyle(color)
      Text(value).frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(14)
    .background(color.opacity(0.08), in: .rect(cornerRadius: 14))
  }
}

enum ProposalApplicationError: LocalizedError {
  case noteNotFound
  case textNotFound
  case noFolder

  var errorDescription: String? {
    switch self {
    case .noteNotFound: "The target note no longer exists."
    case .textNotFound: "The text Spark planned to replace is no longer in the note."
    case .noFolder: "Sparkflow could not find a folder for the new note."
    }
  }
}

enum ProposalApplier {
  static func apply(
    _ proposal: SparkProposal, notes: [SparkNote], folders: [NoteFolder], context: ModelContext
  ) throws {
    switch proposal.kind {
    case .create:
      guard let folder = folders.first else { throw ProposalApplicationError.noFolder }
      context.insert(
        SparkNote(
          title: proposal.proposedTitle.isEmpty ? "Untitled Note" : proposal.proposedTitle,
          body: proposal.afterText, folder: folder))
    case .append:
      guard let note = notes.first(where: { $0.id == proposal.targetNoteID }) else {
        throw ProposalApplicationError.noteNotFound
      }
      let prefix = note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\n"
      note.body += prefix + proposal.afterText
      note.modifiedAt = .now
    case .replace:
      guard let note = notes.first(where: { $0.id == proposal.targetNoteID }) else {
        throw ProposalApplicationError.noteNotFound
      }
      guard !proposal.beforeText.isEmpty,
        note.body.localizedCaseInsensitiveContains(proposal.beforeText)
      else { throw ProposalApplicationError.textNotFound }
      note.body = note.body.replacingOccurrences(
        of: proposal.beforeText, with: proposal.afterText, options: .caseInsensitive)
      note.modifiedAt = .now
    case .delete:
      guard let note = notes.first(where: { $0.id == proposal.targetNoteID }) else {
        throw ProposalApplicationError.noteNotFound
      }
      context.delete(note)
    }
  }
}
