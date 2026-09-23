#if arch(wasm32)
import HarmonicaCore

struct JavaScriptLog: LogProtocol {
    func record(_ line: String) {
        write(line, asSample: false)
    }

    func recordSample(_ line: String) {
        write(line, asSample: true)
    }

    private func write(_ line: String, asSample: Bool) {
        var utf8 = Array(line.utf8)
        utf8.withUnsafeMutableBufferPointer { buffer in
            logInJavaScript(buffer.baseAddress, Int32(buffer.count), asSample ? 1 : 0)
        }
    }
}
#endif
