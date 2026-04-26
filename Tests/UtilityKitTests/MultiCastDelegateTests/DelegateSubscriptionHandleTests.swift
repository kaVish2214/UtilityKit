import Testing
import Foundation
@testable import MultiCastDelegate

@Suite("DelegateSubscriptionHandle")
struct DelegateSubscriptionHandleTests {

    // MARK: - Subscribe

    @Test("Subscribing adds the delegate to subscribers")
    func subscribe() {
        let handle = DelegateSubscriptionHandle()
        let delegate = MockDelegate()

        handle.subscribe(delegate, receive: .main)

        #expect(handle.subscribers.count == 1)
        #expect(handle.subscribers.first === delegate)
    }

    @Test("Multiple subscribers are tracked independently")
    func multipleSubscribers() {
        let handle = DelegateSubscriptionHandle()
        let delegate1 = MockDelegate()
        let delegate2 = MockDelegate()
        let delegate3 = MockDelegate()

        handle.subscribe(delegate1, receive: .main)
        handle.subscribe(delegate2, receive: .main)
        handle.subscribe(delegate3, receive: .main)

        #expect(handle.subscribers.count == 3)
    }

    @Test("Subscribing the same delegate twice does not duplicate it")
    func duplicateSubscription() {
        let handle = DelegateSubscriptionHandle()
        let delegate = MockDelegate()

        handle.subscribe(delegate, receive: .main)
        handle.subscribe(delegate, receive: .main)

        #expect(handle.subscribers.count == 1)
    }

    // MARK: - Unsubscribe

    @Test("Unsubscribing removes the delegate")
    func unsubscribe() {
        let handle = DelegateSubscriptionHandle()
        let delegate = MockDelegate()

        handle.subscribe(delegate, receive: .main)
        handle.unsubscribe(delegate)

        #expect(handle.subscribers.isEmpty)
    }

    @Test("Unsubscribing one delegate does not affect others")
    func unsubscribeSelectivity() {
        let handle = DelegateSubscriptionHandle()
        let delegate1 = MockDelegate()
        let delegate2 = MockDelegate()

        handle.subscribe(delegate1, receive: .main)
        handle.subscribe(delegate2, receive: .main)
        handle.unsubscribe(delegate1)

        #expect(handle.subscribers.count == 1)
        #expect(handle.subscribers.first === delegate2)
    }

    @Test("Unsubscribing a delegate that was never registered is a no-op")
    func unsubscribeNonRegistered() {
        let handle = DelegateSubscriptionHandle()
        let registered = MockDelegate()
        let unregistered = MockDelegate()

        handle.subscribe(registered, receive: .main)
        handle.unsubscribe(unregistered)

        #expect(handle.subscribers.count == 1)
        #expect(handle.subscribers.first === registered)
    }

    // MARK: - Queue Mapping

    @Test("Returns the queue a subscriber was registered with")
    func queueMapping() {
        let handle = DelegateSubscriptionHandle()
        let delegate = MockDelegate()
        let customQueue = DispatchQueue(label: "test.custom.queue")

        handle.subscribe(delegate, receive: customQueue)

        #expect(handle.queue(for: delegate) === customQueue)
    }

    @Test("Returns main queue for an unknown subscriber")
    func defaultQueue() {
        let handle = DelegateSubscriptionHandle()
        let delegate = MockDelegate()

        #expect(handle.queue(for: delegate) === DispatchQueue.main)
    }

    @Test("Re-subscribing with a different queue updates the stored queue")
    func resubscribeUpdatesQueue() {
        let handle = DelegateSubscriptionHandle()
        let delegate = MockDelegate()
        let firstQueue = DispatchQueue(label: "test.first")
        let secondQueue = DispatchQueue(label: "test.second")

        handle.subscribe(delegate, receive: firstQueue)
        #expect(handle.queue(for: delegate) === firstQueue)

        handle.subscribe(delegate, receive: secondQueue)
        #expect(handle.queue(for: delegate) === secondQueue)
    }

    @Test("Each subscriber can have a different queue")
    func perSubscriberQueues() {
        let handle = DelegateSubscriptionHandle()
        let delegate1 = MockDelegate()
        let delegate2 = MockDelegate()
        let queue1 = DispatchQueue(label: "test.queue1")
        let queue2 = DispatchQueue(label: "test.queue2")

        handle.subscribe(delegate1, receive: queue1)
        handle.subscribe(delegate2, receive: queue2)

        #expect(handle.queue(for: delegate1) === queue1)
        #expect(handle.queue(for: delegate2) === queue2)
    }

    // MARK: - Weak References

    @Test("Deallocated subscribers are removed automatically via weak references")
    func weakReferenceCleanup() {
        let handle = DelegateSubscriptionHandle()

        autoreleasepool {
            let delegate = MockDelegate()
            handle.subscribe(delegate, receive: .main)
            #expect(handle.subscribers.count == 1)
        }

        #expect(handle.subscribers.isEmpty)
    }

    @Test("Only deallocated subscribers are removed; live ones remain")
    func partialWeakReferenceCleanup() {
        let handle = DelegateSubscriptionHandle()
        let survivingDelegate = MockDelegate()

        handle.subscribe(survivingDelegate, receive: .main)

        autoreleasepool {
            let temporaryDelegate = MockDelegate()
            handle.subscribe(temporaryDelegate, receive: .main)
            #expect(handle.subscribers.count == 2)
        }

        #expect(handle.subscribers.count == 1)
        #expect(handle.subscribers.first === survivingDelegate)
    }

    // MARK: - Thread Safety

    @Test("Concurrent subscribe and unsubscribe operations do not crash")
    func concurrentAccess() async {
        let handle = DelegateSubscriptionHandle()
        let delegates = (0..<100).map { _ in MockDelegate() }

        await withTaskGroup(of: Void.self) { group in
            for delegate in delegates {
                group.addTask {
                    handle.subscribe(delegate, receive: .main)
                }
            }
        }

        #expect(handle.subscribers.count == delegates.count)

        await withTaskGroup(of: Void.self) { group in
            for delegate in delegates {
                group.addTask {
                    handle.unsubscribe(delegate)
                }
            }
        }

        #expect(handle.subscribers.isEmpty)
    }

    @Test("Concurrent reads and writes do not crash")
    func concurrentReadWrite() async {
        let handle = DelegateSubscriptionHandle()
        let delegates = (0..<50).map { _ in MockDelegate() }

        await withTaskGroup(of: Void.self) { group in
            for delegate in delegates {
                group.addTask { handle.subscribe(delegate, receive: .main) }
                group.addTask { _ = handle.subscribers }
                group.addTask { _ = handle.queue(for: delegate) }
            }
        }
    }
}
