#if arch(wasm32)
import Foundation
import HarmonicaCore

@MainActor private let instrument = Instrument()

@_expose(wasm, "harmonica_input_buffer")
@_cdecl("harmonica_input_buffer")
func harmonicaInputBuffer() -> Int32 {
    MainActor.assumeIsolated { instrument.inputAddress }
}

@_expose(wasm, "harmonica_output_buffer")
@_cdecl("harmonica_output_buffer")
func harmonicaOutputBuffer() -> Int32 {
    MainActor.assumeIsolated { instrument.outputAddress }
}

@_expose(wasm, "harmonica_start")
@_cdecl("harmonica_start")
func harmonicaStart() -> Int32 {
    MainActor.assumeIsolated { instrument.start() }
}

@_expose(wasm, "harmonica_play_at")
@_cdecl("harmonica_play_at")
func harmonicaPlayAt(_ fingers: Int32) -> Int32 {
    MainActor.assumeIsolated { instrument.playAt(fingers: Int(fingers)) }
}

@_expose(wasm, "harmonica_play_holes")
@_cdecl("harmonica_play_holes")
func harmonicaPlayHoles(_ count: Int32, _ breath: Int32, _ intensity: Double) -> Int32 {
    MainActor.assumeIsolated { instrument.play(holes: Int(count), blowing: breath == 0, intensity: intensity) }
}

@_expose(wasm, "harmonica_change_key")
@_cdecl("harmonica_change_key")
func harmonicaChangeKey(_ sliderPosition: Int32) -> Int32 {
    MainActor.assumeIsolated { instrument.changeKey(toSliderPosition: Int(sliderPosition)) }
}

@_expose(wasm, "harmonica_change_style")
@_cdecl("harmonica_change_style")
func harmonicaChangeStyle(_ index: Int32) -> Int32 {
    MainActor.assumeIsolated { instrument.changeStyle(at: Int(index)) }
}

@_expose(wasm, "harmonica_change_mouth")
@_cdecl("harmonica_change_mouth")
func harmonicaChangeMouth(_ holesWide: Int32) -> Int32 {
    MainActor.assumeIsolated { instrument.changeMouth(holesWide: Int(holesWide)) }
}

@_expose(wasm, "harmonica_shape_tone")
@_cdecl("harmonica_shape_tone")
func harmonicaShapeTone(_ pitch: Double, _ vibrato: Double) -> Int32 {
    MainActor.assumeIsolated { instrument.shapeTone(pitch: pitch, vibrato: vibrato) }
}

@_expose(wasm, "harmonica_cup_hands")
@_cdecl("harmonica_cup_hands")
func harmonicaCupHands(_ fraction: Double) -> Int32 {
    MainActor.assumeIsolated { instrument.cupHands(to: fraction) }
}

@_expose(wasm, "harmonica_stop_playing")
@_cdecl("harmonica_stop_playing")
func harmonicaStopPlaying(_ release: Int32) -> Int32 {
    MainActor.assumeIsolated { instrument.stopPlaying(ringingDown: release == 0) }
}

@_expose(wasm, "harmonica_tunes")
@_cdecl("harmonica_tunes")
func harmonicaTunes() -> Int32 {
    MainActor.assumeIsolated { instrument.tunes() }
}

@_expose(wasm, "harmonica_timing")
@_cdecl("harmonica_timing")
func harmonicaTiming() -> Int32 {
    MainActor.assumeIsolated { instrument.timing() }
}

@_expose(wasm, "harmonica_reeds")
@_cdecl("harmonica_reeds")
func harmonicaReeds() -> Int32 {
    MainActor.assumeIsolated { instrument.reeds() }
}
#endif
