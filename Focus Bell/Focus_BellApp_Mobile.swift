//import SwiftUI
//import AVFoundation
//import UIKit // Thay thế Cocoa
//
//enum TimerMode {
//    case once
//    case `repeat`
//}
//
//enum SoundSource {
//    case preset
//    case custom
//}
//
//enum AlertSound: String, CaseIterable {
//    case bikeBell = "bike-bell-ring"
//    case airportAnnouncementBell = "airport-announcement-ding"
//    
//    var displayName: String {
//        switch self {
//        case .bikeBell: return "Bike"
//        case .airportAnnouncementBell: return "Airport"
//        }
//    }
//}
//
//class TimerViewModel: ObservableObject {
//    @Published var timeLeft: Int = 0
//    @Published var initialTime: Int = 0
//    @Published var isRunning = false
//    @Published var mode: TimerMode = .once
//    @Published var taskName: String = ""
//    @Published var selectedSound: AlertSound = .bikeBell
//    @Published var soundSource: SoundSource = .preset
//    @Published var customSoundURL: URL?
//    @Published var customSoundName: String = ""
//    
//    weak var delegate: TimerUpdateDelegate?
//    private var timer: Timer?
//    private var audioPlayer: AVAudioPlayer?
//    
//    init() {
//        setupAudioPlayer()
//    }
//    
//    private func setupAudioPlayer() {
//        loadCurrentSound()
//    }
//    
//    private func loadCurrentSound() {
//        switch soundSource {
//        case .preset:
//            loadPresetSound(selectedSound)
//        case .custom:
//            if let url = customSoundURL {
//                loadCustomSound(from: url)
//            }
//        }
//    }
//    
//    private func loadPresetSound(_ sound: AlertSound) {
//        guard let soundURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else { return }
//        loadCustomSound(from: soundURL)
//    }
//    
//    private func loadCustomSound(from url: URL) {
//        do {
//            audioPlayer = try AVAudioPlayer(contentsOf: url)
//            audioPlayer?.prepareToPlay()
//        } catch {
//            print("Error loading sound file: \(error)")
//        }
//    }
//    
//    // Chỉnh sửa phương thức để sử dụng UIDocumentPickerViewController
//    func selectCustomSound() {
//        delegate?.showDocumentPicker()
//    }
//    
//    func previewSound() {
//        loadCurrentSound()
//        playSound()
//    }
//    
//    func updateSelectedSound(_ sound: AlertSound) {
//        selectedSound = sound
//        soundSource = .preset
//        loadPresetSound(sound)
//    }
//    
//    func startTimer() {
//        isRunning = true
//        timeLeft = initialTime * 60
//        updateTitle()
//        
//        if !taskName.isEmpty {
//            delegate?.showAlert(taskName)
//        }
//        
//        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
//            guard let self = self else { return }
//            
//            if self.timeLeft > 0 {
//                self.timeLeft -= 1
//                self.updateTitle()
//            } else {
//                self.playSound()
//                
//                if !self.taskName.isEmpty {
//                    self.delegate?.showAlert(self.taskName)
//                }
//                
//                if self.mode == .repeat {
//                    self.timeLeft = self.initialTime * 60
//                    self.updateTitle()
//                } else {
//                    self.stopTimer()
//                }
//            }
//        }
//    }
//    
//    private func playSound() {
//        audioPlayer?.currentTime = 0
//        audioPlayer?.play()
//    }
//    
//    func stopTimer() {
//        isRunning = false
//        timer?.invalidate()
//        timer = nil
//        updateTitle()
//    }
//    
//    func formatTime() -> String {
//        let minutes = timeLeft / 60
//        let seconds = timeLeft % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//    
//    private func updateTitle() {
//        if isRunning {
//            delegate?.updateTitle(formatTime())
//        } else {
//            delegate?.updateTitle("")
//        }
//    }
//}
//
//struct SoundSelectionView: View {
//    @ObservedObject var viewModel: TimerViewModel
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Picker("", selection: $viewModel.soundSource) {
//                Text("Preset Sounds").tag(SoundSource.preset)
//                Text("Custom Sound").tag(SoundSource.custom)
//            }
//            .pickerStyle(SegmentedPickerStyle())
//            .frame(maxWidth: .infinity)
//            
//            if viewModel.soundSource == .preset {
//                Picker("Alert Sound", selection: $viewModel.selectedSound) {
//                    ForEach(AlertSound.allCases, id: \.self) { sound in
//                        Text(sound.displayName).tag(sound)
//                    }
//                }
//                .pickerStyle(SegmentedPickerStyle())
//                .frame(maxWidth: .infinity)
//            } else {
//                VStack(spacing: 8) {
//                    Button("Choose Sound File") {
//                        viewModel.selectCustomSound()
//                    }
//                    .frame(maxWidth: .infinity)
//                    
//                    if !viewModel.customSoundName.isEmpty {
//                        Text(viewModel.customSoundName)
//                            .font(.caption)
//                            .lineLimit(1)
//                            .truncationMode(.middle)
//                    }
//                }
//            }
//            
//            Button("Preview Sound") {
//                viewModel.previewSound()
//            }
//            .disabled(viewModel.soundSource == .custom && viewModel.customSoundURL == nil)
//        }
//    }
//}
//
//struct ContentView: View {
//    @ObservedObject var viewModel: TimerViewModel
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Task Name")
//                    .foregroundColor(.secondary)
//                TextField("Enter your task", text: $viewModel.taskName)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .frame(maxWidth: .infinity)
//            }
//            
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Duration (minutes)")
//                    .foregroundColor(.secondary)
//                TextField("Minutes", value: $viewModel.initialTime, formatter: NumberFormatter())
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .frame(maxWidth: .infinity)
//            }
//            
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Timer Mode")
//                    .foregroundColor(.secondary)
//                Picker("Mode", selection: $viewModel.mode) {
//                    Text("Once").tag(TimerMode.once)
//                    Text("Repeat").tag(TimerMode.repeat)
//                }
//                .pickerStyle(SegmentedPickerStyle())
//                .frame(maxWidth: .infinity)
//            }
//            
//            VStack(alignment: .leading, spacing: 16) {
//                Text("Sound Settings")
//                    .foregroundColor(.secondary)
//                SoundSelectionView(viewModel: viewModel)
//            }
//            
//            Text(viewModel.formatTime())
//                .font(.system(size: 40, weight: .medium, design: .monospaced))
//                .padding(.vertical, 10)
//            
//            Button(viewModel.isRunning ? "Stop" : "Start") {
//                if viewModel.isRunning {
//                    viewModel.stopTimer()
//                } else {
//                    viewModel.startTimer()
//                }
//            }
//            .frame(maxWidth: .infinity)
//        }
//        .padding(24)
//    }
//}
//
//protocol TimerUpdateDelegate: AnyObject {
//    func updateTitle(_ title: String)
//    func showAlert(_ message: String)
//    func showDocumentPicker()
//}
//
//class TimerViewController: UIViewController, TimerUpdateDelegate, UIDocumentPickerDelegate {
//    var timerViewModel: TimerViewModel!
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupTimerViewModel()
//    }
//    
//    private func setupTimerViewModel() {
//        timerViewModel = TimerViewModel()
//        timerViewModel.delegate = self
//    }
//    
//    func updateTitle(_ title: String) {
//        // Cập nhật title của navigation bar hoặc label tương ứng
//        navigationItem.title = title
//    }
//    
//    func showAlert(_ message: String) {
//        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
//        present(alert, animated: true) {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//                alert.dismiss(animated: true)
//            }
//        }
//    }
//    
//    func showDocumentPicker() {
//        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
//        documentPicker.delegate = self
//        present(documentPicker, animated: true)
//    }
//    
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        guard let url = urls.first else { return }
//        timerViewModel.customSoundURL = url
//        timerViewModel.customSoundName = url.lastPathComponent
//        timerViewModel.soundSource = .custom
//    }
//}
//
//@main
//struct TimerApp: App {
//    var body: some Scene {
//        WindowGroup {
//            ContentView(viewModel: TimerViewModel())
//        }
//    }
//}
