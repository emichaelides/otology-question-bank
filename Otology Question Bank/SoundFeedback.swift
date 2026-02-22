import AVFoundation

enum SoundFeedback {
    private static var engines: [AVAudioEngine] = []

    static func playCorrect() {
        // Two ascending sine notes: A5 (880 Hz) → C#6 (1108 Hz)
        playSynth(notes: [880.0, 1108.0], noteDuration: 0.10, gap: 0.045, amplitude: 0.35)
    }

    static func playIncorrect() {
        // Single low sawtooth buzz: D3 (147 Hz)
        playSynth(notes: [147.0], noteDuration: 0.22, gap: 0, amplitude: 0.45, sawtooth: true)
    }

    private static func playSynth(notes: [Double], noteDuration: Double, gap: Double,
                                   amplitude: Float, sawtooth: Bool = false) {
        let sr: Double = 44100
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1) else { return }
        let noteSamps = Int(sr * noteDuration)
        let gapSamps  = Int(sr * gap)
        let total = noteSamps * notes.count + gapSamps * max(0, notes.count - 1)
        guard let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(total)) else { return }
        buf.frameLength = AVAudioFrameCount(total)
        let ch = buf.floatChannelData![0]
        var offset = 0
        for (i, freq) in notes.enumerated() {
            for s in 0..<noteSamps {
                let t = Double(s) / sr
                let attack  = min(1.0, Double(s) / (sr * 0.008))
                let release = min(1.0, Double(noteSamps - s) / (sr * 0.04))
                let wave = sawtooth
                    ? 2.0 * (t * freq - floor(t * freq + 0.5))
                    : sin(2.0 * .pi * freq * t)
                ch[offset + s] = Float(wave * Double(amplitude) * attack * release)
            }
            offset += noteSamps
            if i < notes.count - 1 {
                for s in 0..<gapSamps { ch[offset + s] = 0 }
                offset += gapSamps
            }
        }
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: fmt)
        engines.append(engine)          // retain until done
        try? engine.start()
        player.scheduleBuffer(buf) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                engine.stop()
                engines.removeAll { $0 === engine }
            }
        }
        player.play()
    }
}
