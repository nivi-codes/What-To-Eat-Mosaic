// Speaks lines with a macOS voice and writes each to a 16-bit WAV file.
//   swift apple_tts.swift <voice identifier> <rate | default> <out.wav> <text> [<out.wav> <text> ...]
// Voice identifiers: run with "list" as the only argument.
// Rate is AVSpeechUtterance's 0–1 scale; "default" is the voice's own pace (0.5).
// Run it with `swift`, not as a compiled binary: a compiled binary is not shown the Siri voices.
import AVFoundation

let args = CommandLine.arguments
if args.count == 2 && args[1] == "list" {
    for v in AVSpeechSynthesisVoice.speechVoices() where v.language.hasPrefix("en") {
        let quality = v.quality == .premium ? "premium" : v.quality == .enhanced ? "enhanced" : "default"
        print("\(v.identifier)\t\(v.name)\t\(v.language)\t\(quality)")
    }
    exit(0)
}
guard args.count >= 5 && args.count % 2 == 1 else {
    fputs("usage: apple_tts <voice identifier> <rate | default> <out.wav> <text> [<out.wav> <text> ...]\n", stderr)
    exit(1)
}
// Looked up in the installed list: init(identifier:) misses the Siri and premium voices, which
// also join the list a moment after launch.
var found: AVSpeechSynthesisVoice?
for _ in 0..<60 where found == nil {
    found = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.identifier == args[1] })
    if found == nil { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
}
guard let voice = found else {
    fputs("voice not installed: \(args[1])\n", stderr)
    exit(2)
}
let synth = AVSpeechSynthesizer()
for i in stride(from: 3, to: args.count, by: 2) {
    let out = args[i]
    let utterance = AVSpeechUtterance(string: args[i + 1])
    utterance.voice = voice
    if args[2] != "default", let rate = Float(args[2]) { utterance.rate = rate }
    var file: AVAudioFile?
    var done = false
    synth.write(utterance) { buffer in
        guard let pcm = buffer as? AVAudioPCMBuffer, pcm.frameLength > 0 else { done = true; return }
        do {
            if file == nil {
                let settings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: pcm.format.sampleRate,
                    AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false,
                ]
                file = try AVAudioFile(forWriting: URL(fileURLWithPath: out), settings: settings,
                                       commonFormat: pcm.format.commonFormat, interleaved: pcm.format.isInterleaved)
            }
            try file?.write(from: pcm)
        } catch {
            fputs("could not write \(out): \(error)\n", stderr)
            exit(3)
        }
    }
    let deadline = Date().addingTimeInterval(60)
    while !done && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
    file = nil  // closes the file
    if !done {
        fputs("timed out on \(out)\n", stderr)
        exit(4)
    }
}
