@preconcurrency import AVFAudio
@preconcurrency import Speech
import SwiftUI

@MainActor
final class VoiceCaptureService: ObservableObject {
  @Published var transcript = ""
  @Published var isListening = false
  @Published var isStarting = false
  @Published var errorMessage: String?

  private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
  private let audioEngine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?
  private var hasInputTap = false

  func toggle() {
    guard !isStarting else { return }
    if isListening { stop() } else { Task { await requestPermissionAndStart() } }
  }

  func stop() {
    audioEngine.stop()
    if hasInputTap {
      audioEngine.inputNode.removeTap(onBus: 0)
      hasInputTap = false
    }
    request?.endAudio()
    task?.cancel()
    task = nil
    request = nil
    isListening = false
  }

  private func requestPermissionAndStart() async {
    isStarting = true
    defer { isStarting = false }

    let microphoneAllowed = await AVAudioApplication.requestRecordPermission()
    guard microphoneAllowed else {
      errorMessage =
        "Microphone access is turned off for Sparkflow. Enable it in Settings → Privacy & Security → Microphone."
      return
    }

    let speechStatus = await Self.requestSpeechAuthorization()
    guard speechStatus == .authorized else {
      errorMessage =
        "Speech Recognition is turned off for Sparkflow. Enable it in Settings → Privacy & Security → Speech Recognition."
      return
    }
    guard let recognizer, recognizer.isAvailable else {
      errorMessage = "Speech recognition is temporarily unavailable. Check your connection and try again."
      return
    }
    do { try start() } catch {
      errorMessage = error.localizedDescription
      stop()
    }
  }

  nonisolated private static func requestSpeechAuthorization() async
    -> SFSpeechRecognizerAuthorizationStatus
  {
    await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { status in
        continuation.resume(returning: status)
      }
    }
  }

  private func start() throws {
    stop()
    transcript = ""
    guard let recognizer else {
      throw VoiceCaptureError.recognizerUnavailable
    }
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
    try session.setActive(true, options: .notifyOthersOnDeactivation)
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    self.request = request
    let input = audioEngine.inputNode
    let format = input.outputFormat(forBus: 0)
    Self.installAudioTap(on: input, format: format, request: request)
    hasInputTap = true
    audioEngine.prepare()
    try audioEngine.start()
    isListening = true
    task = Self.beginRecognition(recognizer: recognizer, request: request, owner: self)
  }

  nonisolated private static func installAudioTap(
    on input: AVAudioInputNode,
    format: AVAudioFormat,
    request: SFSpeechAudioBufferRecognitionRequest
  ) {
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
      request.append(buffer)
    }
  }

  nonisolated private static func beginRecognition(
    recognizer: SFSpeechRecognizer,
    request: SFSpeechAudioBufferRecognitionRequest,
    owner: VoiceCaptureService
  ) -> SFSpeechRecognitionTask {
    recognizer.recognitionTask(with: request) { [weak owner] result, error in
      let transcript = result?.bestTranscription.formattedString
      let shouldStop = error != nil || result?.isFinal == true
      Task { @MainActor [weak owner] in
        if let transcript { owner?.transcript = transcript }
        if shouldStop { owner?.stop() }
      }
    }
  }
}

private enum VoiceCaptureError: LocalizedError {
  case recognizerUnavailable

  var errorDescription: String? {
    "Speech recognition is unavailable for the current language."
  }
}
