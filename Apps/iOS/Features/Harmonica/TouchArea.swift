import SwiftUI
import UIKit

struct TouchArea: UIViewRepresentable {
    let touchesChanged: @MainActor ([FingerTouch]) -> Void
    var pinched: (@MainActor (CGFloat) -> Void)?

    func makeUIView(context: Context) -> TouchTrackingView {
        TouchTrackingView(touchesChanged: touchesChanged, pinched: pinched)
    }

    func updateUIView(_ view: TouchTrackingView, context: Context) {
        view.touchesChanged = touchesChanged
        view.pinched = pinched
    }
}

// MARK: - FingerTouch

struct FingerTouch: Equatable {
    let location: CGPoint
    let radius: CGFloat
}

// MARK: - TouchTrackingView

final class TouchTrackingView: UIView {
    var touchesChanged: @MainActor ([FingerTouch]) -> Void
    var pinched: (@MainActor (CGFloat) -> Void)?

    // MARK: - Public

    init(
        touchesChanged: @escaping @MainActor ([FingerTouch]) -> Void,
        pinched: (@MainActor (CGFloat) -> Void)?
    ) {
        self.touchesChanged = touchesChanged
        self.pinched = pinched
        super.init(frame: .zero)
        isMultipleTouchEnabled = true
        guard pinched != nil else { return }

        addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(reportPinch)))
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

    @objc private func reportPinch(_ recogniser: UIPinchGestureRecognizer) {
        guard recogniser.state == .changed else { return }

        pinched?(recogniser.scale)
        recogniser.scale = 1
    }

    private func reportTouches(of event: UIEvent?) {
        let mine = (event?.allTouches ?? []).filter(isStillDownHere)
        touchesChanged(mine.map(finger))
    }

    private func finger(_ touch: UITouch) -> FingerTouch {
        FingerTouch(location: touch.location(in: self), radius: touch.majorRadius)
    }

    private func isStillDownHere(_ touch: UITouch) -> Bool {
        touch.view === self && touch.phase != .ended && touch.phase != .cancelled
    }
}
