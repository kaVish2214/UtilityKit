import Foundation
@testable import MultiCastDelegate

final class MockDelegate: NSObject, DelegateSubscriber, @unchecked Sendable {
    private let lock = NSLock()
    private var _receivedValues: [Int] = []

    var receivedValues: [Int] {
        lock.lock()
        defer { lock.unlock() }
        return _receivedValues
    }

    func didReceiveValue(_ value: Int) {
        lock.lock()
        defer { lock.unlock() }
        _receivedValues.append(value)
    }
}

final class TestMultiCaster: DelegateMultiCasting, @unchecked Sendable {
    typealias Delegate = MockDelegate
    let delegates: any DelegateSubscription = DelegateSubscriptionHandle()
}

extension DispatchQueue {
    func drainAsync() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.async(flags: .barrier) {
                continuation.resume()
            }
        }
    }
}
