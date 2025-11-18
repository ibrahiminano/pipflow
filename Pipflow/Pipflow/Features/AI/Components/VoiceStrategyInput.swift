//
//  VoiceStrategyInput.swift
//  Pipflow
//
//  Voice input for natural language strategy creation
//

import SwiftUI
import Speech
import AVFoundation

struct VoiceStrategyInput: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var promptText: String
    @State private var isRecording = false
    @State private var showPermissionAlert = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Recording Button
            ZStack {
                // Pulse animation
                if isRecording {
                    Circle()
                        .stroke(themeManager.currentTheme.accentColor, lineWidth: 2)
                        .scaleEffect(pulseAnimation ? 1.5 : 1)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(
                            Animation.easeOut(duration: 1)
                                .repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                        .onAppear {
                            pulseAnimation = true
                        }
                        .onDisappear {
                            pulseAnimation = false
                        }
                }
                
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : themeManager.currentTheme.accentColor)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isRecording ? 1.1 : 1)
                .animation(.spring(response: 0.3), value: isRecording)
            }
            
            // Status Text
            Text(statusText)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                .multilineTextAlignment(.center)
                .frame(height: 40)
            
            // Transcribed Text Preview
            if !speechRecognizer.transcript.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Transcribed Strategy")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryTextColor)
                        
                        Spacer()
                        
                        Button("Clear") {
                            speechRecognizer.transcript = ""
                        }
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.accentColor)
                    }
                    
                    Text(speechRecognizer.transcript)
                        .font(.system(size: 14))
                        .foregroundColor(themeManager.currentTheme.textColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(themeManager.currentTheme.secondaryBackgroundColor)
                        .cornerRadius(8)
                }
            }
            
            // Voice Commands Help
            VoiceCommandsHelp(theme: themeManager.currentTheme)
        }
        .padding()
        .onAppear {
            speechRecognizer.requestAuthorization { authorized in
                if !authorized {
                    showPermissionAlert = true
                }
            }
        }
        .onChange(of: speechRecognizer.transcript) { _, newValue in
            promptText = newValue
        }
        .alert("Microphone Permission Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable microphone access in Settings to use voice input for strategy creation.")
        }
    }
    
    private var statusText: String {
        if isRecording {
            return "Listening... Speak your trading strategy"
        } else if !speechRecognizer.transcript.isEmpty {
            return "Tap to add more or use the text above"
        } else {
            return "Tap to describe your strategy using voice"
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            speechRecognizer.stopRecording()
        } else {
            speechRecognizer.startRecording()
        }
        isRecording.toggle()
    }
}

// MARK: - Voice Commands Help

struct VoiceCommandsHelp: View {
    let theme: Theme
    @State private var isExpanded = false
    
    let examples = [
        "Buy EURUSD when RSI is below 30",
        "Set stop loss at 20 pips",
        "Use 2% risk per trade",
        "Trade only during London session",
        "Take profit at resistance level"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(theme.accentColor)
                    
                    Text("Voice Command Examples")
                        .font(.caption)
                        .foregroundColor(theme.textColor)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(theme.secondaryTextColor)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(examples, id: \.self) { example in
                        HStack {
                            Image(systemName: "mic")
                                .font(.caption2)
                                .foregroundColor(theme.accentColor)
                            
                            Text(example)
                                .font(.caption2)
                                .foregroundColor(theme.secondaryTextColor)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(theme.secondaryBackgroundColor.opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Speech Recognizer

class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    completion(true)
                default:
                    completion(false)
                }
            }
        }
    }
    
    func startRecording() {
        // Stop any ongoing recognition task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // Keep existing transcript and append new speech
        let existingTranscript = transcript
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            var isFinal = false
            
            if let result = result {
                // Append to existing transcript
                if existingTranscript.isEmpty {
                    self?.transcript = result.bestTranscription.formattedString
                } else {
                    // Add a space and continue from where we left off
                    let newText = result.bestTranscription.formattedString
                    self?.transcript = existingTranscript + " " + newText
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self?.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self?.recognitionRequest = nil
                self?.recognitionTask = nil
                self?.isRecording = false
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        isRecording = false
    }
}

