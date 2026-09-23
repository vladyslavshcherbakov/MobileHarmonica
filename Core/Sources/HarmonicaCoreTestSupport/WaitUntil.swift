private let longestWaitInMilliseconds = 3000
private let millisecondsBetweenLooks = 5

@MainActor
public func waitUntil(_ condition: @MainActor () -> Bool) async -> Bool {
    for _ in 0..<(longestWaitInMilliseconds / millisecondsBetweenLooks) {
        guard !condition() else { return true }

        try? await Task.sleep(for: .milliseconds(millisecondsBetweenLooks))
    }
    return condition()
}
