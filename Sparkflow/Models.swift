import Foundation
import SwiftData

@Model
final class NoteFolder {
  var id: UUID
  var name: String
  var systemImage: String
  var sortOrder: Int
  var createdAt: Date

  @Relationship(deleteRule: .cascade, inverse: \SparkNote.folder)
  var notes: [SparkNote]

  init(name: String, systemImage: String = "folder", sortOrder: Int = 0) {
    self.id = UUID()
    self.name = name
    self.systemImage = systemImage
    self.sortOrder = sortOrder
    self.createdAt = .now
    self.notes = []
  }
}

@Model
final class SparkNote {
  var id: UUID
  var title: String
  var body: String
  var createdAt: Date
  var modifiedAt: Date
  var isPinned: Bool
  var folder: NoteFolder?

  init(title: String, body: String = "", folder: NoteFolder? = nil) {
    self.id = UUID()
    self.title = title
    self.body = body
    self.createdAt = .now
    self.modifiedAt = .now
    self.isPinned = false
    self.folder = folder
  }

  var preview: String {
    body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No additional text" : body
  }
}

enum ProposalKind: String, Codable, CaseIterable {
  case create
  case append
  case replace
  case delete

  var title: String {
    switch self {
    case .create: "New Note"
    case .append: "Add to Note"
    case .replace: "Rewrite"
    case .delete: "Delete Note"
    }
  }

  var systemImage: String {
    switch self {
    case .create: "square.and.pencil"
    case .append: "text.append"
    case .replace: "arrow.trianglehead.2.clockwise.rotate.90"
    case .delete: "trash"
    }
  }
}

enum ProposalStatus: String, Codable {
  case pending
  case approved
  case rejected
  case failed
}

@Model
final class SparkProposal {
  var id: UUID
  var kindRawValue: String
  var statusRawValue: String
  var targetNoteID: UUID?
  var targetTitle: String
  var proposedTitle: String
  var beforeText: String
  var afterText: String
  var explanation: String
  var sourceCommand: String
  var createdAt: Date
  var resolvedAt: Date?

  init(
    kind: ProposalKind,
    targetNoteID: UUID? = nil,
    targetTitle: String = "",
    proposedTitle: String = "",
    beforeText: String = "",
    afterText: String,
    explanation: String,
    sourceCommand: String
  ) {
    self.id = UUID()
    self.kindRawValue = kind.rawValue
    self.statusRawValue = ProposalStatus.pending.rawValue
    self.targetNoteID = targetNoteID
    self.targetTitle = targetTitle
    self.proposedTitle = proposedTitle
    self.beforeText = beforeText
    self.afterText = afterText
    self.explanation = explanation
    self.sourceCommand = sourceCommand
    self.createdAt = .now
  }

  var kind: ProposalKind {
    get { ProposalKind(rawValue: kindRawValue) ?? .create }
    set { kindRawValue = newValue.rawValue }
  }

  var status: ProposalStatus {
    get { ProposalStatus(rawValue: statusRawValue) ?? .pending }
    set { statusRawValue = newValue.rawValue }
  }
}

@Model
final class ChangeAuditEvent {
  var id: UUID
  var proposalID: UUID
  var action: String
  var summary: String
  var timestamp: Date

  init(proposalID: UUID, action: String, summary: String) {
    self.id = UUID()
    self.proposalID = proposalID
    self.action = action
    self.summary = summary
    self.timestamp = .now
  }
}

struct SparkInterpretation {
  var kind: ProposalKind
  var targetTitle: String
  var proposedTitle: String
  var originalText: String
  var newText: String
}

enum SparkInterpreter {
  static func interpret(_ command: String, notes: [SparkNote]) -> SparkInterpretation {
    let clean = command.trimmingCharacters(in: .whitespacesAndNewlines)
    let lower = clean.lowercased()

    if lower.contains("delete") || lower.contains("remove the note") {
      let target = bestMatchingNote(in: clean, notes: notes)
      return SparkInterpretation(
        kind: .delete, targetTitle: target?.title ?? extractedQuotedStrings(clean).first ?? "",
        proposedTitle: "", originalText: target?.body ?? "", newText: "")
    }

    if lower.contains("replace") || lower.contains("rephrase") || lower.contains("rewrite")
      || lower.contains("change")
    {
      let quoted = extractedQuotedStrings(clean)
      let target = bestMatchingNote(in: clean, notes: notes)
      let original = quoted.count > 1 ? quoted[quoted.count - 2] : ""
      let replacement = quoted.last ?? textAfterAnyMarker(in: clean, markers: [" with ", " to "])
      return SparkInterpretation(
        kind: .replace, targetTitle: target?.title ?? "", proposedTitle: "", originalText: original,
        newText: replacement)
    }

    if lower.contains("add") || lower.contains("append") || lower.contains("bullet") {
      let target = bestMatchingNote(in: clean, notes: notes)
      let quoted = extractedQuotedStrings(clean)
      let addition =
        quoted.last ?? textAfterAnyMarker(in: clean, markers: ["that says ", "saying ", "add "])
      return SparkInterpretation(
        kind: target == nil ? .create : .append, targetTitle: target?.title ?? "",
        proposedTitle: target == nil ? inferredTitle(from: addition) : "", originalText: "",
        newText: addition)
    }

    let title = inferredTitle(from: clean)
    return SparkInterpretation(
      kind: .create, targetTitle: "", proposedTitle: title, originalText: "", newText: clean)
  }

  private static func bestMatchingNote(in command: String, notes: [SparkNote]) -> SparkNote? {
    let lower = command.lowercased()
    return
      notes
      .filter { lower.contains($0.title.lowercased()) }
      .max { $0.title.count < $1.title.count }
  }

  private static func extractedQuotedStrings(_ value: String) -> [String] {
    let pattern = #"[\"“]([^\"”]+)[\"”]"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
    let range = NSRange(value.startIndex..., in: value)
    return regex.matches(in: value, range: range).compactMap { match in
      guard let swiftRange = Range(match.range(at: 1), in: value) else { return nil }
      return String(value[swiftRange])
    }
  }

  private static func textAfterAnyMarker(in value: String, markers: [String]) -> String {
    let lower = value.lowercased()
    for marker in markers {
      if let range = lower.range(of: marker) {
        return String(value[range.upperBound...]).trimmingCharacters(
          in: .whitespacesAndNewlines.union(.punctuationCharacters))
      }
    }
    return value
  }

  private static func inferredTitle(from text: String) -> String {
    let words = text.split(separator: " ").prefix(6).map(String.init).joined(separator: " ")
    return words.isEmpty ? "Untitled Note" : words.prefix(1).uppercased() + words.dropFirst()
  }
}
