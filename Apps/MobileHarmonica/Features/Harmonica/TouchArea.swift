import SwiftUI
import UIKit

struct TouchArea: UIViewRepresentable {
    let touchesChanged: ([CGPoint]) -> Void

    func makeUIView(context: Context) -> TouchTrackingView {
        TouchTrackingView(touchesChanged: touchesChanged)
    }

    func updateUIView(_ view: TouchTrackingView, context: Context) {
        view.touchesChanged = touchesChanged
    }
}

// MARK: - TouchTrackingView

final class TouchTrackingView: UIView {
    var touchesChanged: ([CGPoint]) -> Void

    // MARK: - Public

    init(touchesChanged: @escaping ([CGPoint]) -> Void) {
        self.touchesChanged = touchesChanged
        super.init(frame: .zero)
        isMultipleTouchEnabled = true
    }

    required init?(coder: NSCoder) {
        preconditionFailure("TouchTrackingView is built in code and never loaded from a nib")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        reportTouches(of: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        reportTouches(of: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        reportTouches(of: event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        reportTouches(of: event)
    }

    // MARK: - Private

    private func reportTouches(of event: UIEvent?) {
        let stillDown = (event?.allTouches ?? []).filter { $0.phase != .ended && $0.phase != .cancelled }
        touchesChanged(stillDown.map { $0.location(in: self) })
    }
}
