@preconcurrency import AVFAudio
@preconcurrency import Speech
import SwiftUI

@MainActor
final class VoiceCaptureService: ObservableObject {
  @Published var transcript = ""
  @Published var isListening = false
  @Published var errorMessage: String?

  private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
  private let audioEngine = AVAudioEngine()
  private var request: SFSpeechAudioBufferRecognitionRequest?
  private var task: SFSpeechRecognitionTask?

  func toggle() {
    if isListening { stop() } else { Task { await requestPermissionAndStart() } }
  }

  func stop() {
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    request?.endAudio()
    task?.cancel()
    task = nil
    request = nil
    isListening = false
  }

  private func requestPermissionAndStart() async {
    let speechStatus = await withCheckedContinuation { continuation in
      SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
    }
    guard speechStatus == .authorized else {
      errorMessage = "Speech recognition permission is required to talk to Spark."
      return
    }
    let microphoneAllowed = await AVAudioApplication.requestRecordPermission()
    guard microphoneAllowed else {
      errorMessage = "Microphone permission is required to talk to Spark."
      return
    }
    do { try start() } catch {
      errorMessage = error.localizedDescription
      stop()
    }
  }

  private func start() throws {
    stop()
    transcript = ""
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.record, mode: .measurement, options: .duckOthers)
    try session.setActive(true, options: .notifyOthersOnDeactivation)
    let request = SFSpeechAudioBufferRecognitionRequest()
    request.shouldReportPartialResults = true
    self.request = request
    let input = audioEngine.inputNode
    let format = input.outputFormat(forBus: 0)
    input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
      request.append(buffer)
    }
    audioEngine.prepare()
    try audioEngine.start()
    isListening = true
    task = recognizer?.recognitionTask(with: request) { [weak self] result, error in
      Task { @MainActor in
        if let result { self?.transcript = result.bestTranscription.formattedString }
        if error != nil || result?.isFinal == true { self?.stop() }
      }
    }
  }
}
