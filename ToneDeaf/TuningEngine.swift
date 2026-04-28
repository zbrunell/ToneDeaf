// Project: ToneDeaf
// EID: ztb456
// Course: CS329E

import AVFoundation
import Accelerate

class TunerEngine {

    var onPitchDetected: ((Float, String, Float) -> Void)?

    var audioEngine = AVAudioEngine()
    let bufferSize: AVAudioFrameCount = 2048
    let noteNames = ["C", "C#", "D", "D#", "E", "F",
                     "F#", "G", "G#", "A", "A#", "B"]

    var referencePitch: Float = 440.0
    var targetNotes: [String] = ["E2", "A2", "D3", "G3", "B3", "E4"]

    // MARK: - Bootstrapping confidence state
    let bootstrapWindowSize: Int = 5
    let confidenceThreshold: Float = 0.66
    let centsToleranceForAgreement: Float = 35
    let updateInterval: TimeInterval = 0.04

    var recentReadings: [(note: String, cents: Float, frequency: Float)] = []

    var lastUpdateTime: Date = .distantPast

    // MARK: - Start / Stop

    func start() {
        // Requests microphone permission, configures the audio session, and starts listening
        AVAudioApplication.requestRecordPermission { granted in
            guard granted else { return }
            DispatchQueue.main.async {
                do {
                    let session = AVAudioSession.sharedInstance()
                    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
                    try session.setActive(true)
                    self.startListening()
                } catch {
                    print("Audio session failed: \(error)")
                }
            }
        }
    }

    func stop() {
        // Stops audio input and clears recent pitch readings
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recentReadings.removeAll()
    }

    func startListening() {
        // Installs an audio tap so incoming microphone buffers can be processed
        let inputNode = audioEngine.inputNode
        let format = inputNode.inputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { buffer, _ in
            self.processBuffer(buffer: buffer, sampleRate: Float(format.sampleRate))
        }

        do {
            try audioEngine.start()
        } catch {
            print("Audio engine failed: \(error)")
        }
    }

    // MARK: - Buffer Processing

    func processBuffer(buffer: AVAudioPCMBuffer, sampleRate: Float) {
        // Converts microphone audio into samples, detects pitch, filters unstable readings,
        // and sends stable note/cents values back to the UI
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let frameLength = Int(buffer.frameLength)
        var samples = [Float](repeating: 0, count: frameLength)
        for i in 0..<frameLength { samples[i] = channelData[i] }

        // Silence gate — ignore quiet input
        let rms = sqrt(samples.map { $0 * $0 }.reduce(0, +) / Float(frameLength))
        guard rms > 0.01 else {
            recentReadings.removeAll()
            DispatchQueue.main.async { self.onPitchDetected?(0, "-", 0) }
            return
        }

        // Autocorrelation pitch detection
        let minFrequency: Float = 70
        let maxFrequency: Float = 500
        let minLag = Int(sampleRate / maxFrequency)
        let maxLag = Int(sampleRate / minFrequency)

        var bestLag = minLag
        var bestCorrelation: Float = 0

        for lag in minLag..<maxLag {
            var correlation: Float = 0
            for i in 0..<(frameLength - lag) {
                correlation += samples[i] * samples[i + lag]
            }
            if correlation > bestCorrelation {
                bestCorrelation = correlation
                bestLag = lag
            }
        }

        let frequency = sampleRate / Float(bestLag)
        guard frequency > 50 && frequency < 1500 else { return }

        let (noteWithOctave, cents) = closestTargetNoteAndCents(frequency: frequency)
        let note = String(noteWithOctave.dropLast())

        // Add to bootstrap window
        recentReadings.append((note: note, cents: cents, frequency: frequency))
        if recentReadings.count > bootstrapWindowSize {
            recentReadings.removeFirst()
        }

        // Only report if we have a full window
        guard recentReadings.count >= bootstrapWindowSize else { return }

        // Check confidence — how many readings agree on the same note
        guard let (dominantNote, confidence, averageCents, averageFrequency) = bootstrapConfidence() else { return }
        guard confidence >= confidenceThreshold else { return }

        // Throttle UI updates
        let now = Date()
        guard now.timeIntervalSince(lastUpdateTime) >= updateInterval else { return }
        lastUpdateTime = now

        DispatchQueue.main.async {
            self.onPitchDetected?(averageFrequency, dominantNote, averageCents)
        }
    }

    // MARK: - Bootstrap Confidence

    func bootstrapConfidence() -> (String, Float, Float, Float)? {
        // Finds the most agreed-upon note in the recent window
        // Returns (note, confidence ratio, average cents, average frequency) or nil if no agreement
        guard !recentReadings.isEmpty else { return nil }

        // Count votes per note
        var noteVotes: [String: [(cents: Float, frequency: Float)]] = [:]
        for reading in recentReadings {
            if noteVotes[reading.note] == nil {
                noteVotes[reading.note] = []
            }
            noteVotes[reading.note]?.append((reading.cents, reading.frequency))
        }

        // Find the note with the most votes
        guard let (dominantNote, votes) = noteVotes.max(by: { $0.value.count < $1.value.count }) else {
            return nil
        }

        let confidence = Float(votes.count) / Float(recentReadings.count)

        // Check that the agreeing readings are also close in cents (not just same note name)
        let centValues = votes.map { $0.cents }
        let centsRange = (centValues.max() ?? 0) - (centValues.min() ?? 0)
        guard centsRange < centsToleranceForAgreement else { return nil }

        // Average cents and frequency across agreeing readings only
        let averageCents = centValues.reduce(0, +) / Float(centValues.count)
        let averageFrequency = votes.map { $0.frequency }.reduce(0, +) / Float(votes.count)

        return (dominantNote, confidence, averageCents, averageFrequency)
    }

    // MARK: - Note Helpers

    func frequencyForNote(_ note: String) -> Float {
        // Converts a note name with octave, like "E2", into its frequency
        let noteName = String(note.dropLast())
        let octave = Int(String(note.last!)) ?? 4
        guard let noteIndex = noteNames.firstIndex(of: noteName) else { return referencePitch }
        let midiNumber = (octave + 1) * 12 + noteIndex
        return referencePitch * pow(2, Float(midiNumber - 69) / 12)
    }

    func closestTargetNoteAndCents(frequency: Float) -> (String, Float) {
        // Finds the closest allowed target note and returns how many cents sharp or flat it is
        guard !targetNotes.isEmpty else { return noteAndCents(frequency: frequency) }

        var bestNote = targetNotes[0]
        var bestCents: Float = 9999

        for note in targetNotes {
            let targetFrequency = frequencyForNote(note)
            let cents = 1200 * log2(frequency / targetFrequency)
            if abs(cents) < abs(bestCents) {
                bestCents = cents
                bestNote = note
            }
        }
        return (bestNote, bestCents)
    }

    func noteAndCents(frequency: Float) -> (String, Float) {
        // Converts any frequency into the nearest chromatic note and cents offset
        let midiNote = 12 * log2(frequency / referencePitch) + 69
        let roundedMidi = midiNote.rounded()
        let cents = (midiNote - roundedMidi) * 100
        let noteIndex = Int(roundedMidi) % 12
        let octave = (Int(roundedMidi) - 12) / 12
        let noteName = noteNames[noteIndex] + "\(octave)"
        return (noteName, cents)
    }
}
