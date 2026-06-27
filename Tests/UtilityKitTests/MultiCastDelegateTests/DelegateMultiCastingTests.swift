// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

import Testing
import Foundation
@testable import MultiCastDelegate

@Suite("DelegateMultiCasting")
struct DelegateMultiCastingTests {

    // MARK: - Subscribe / Unsubscribe

    @Test("subscribeDelegate and unsubscribeDelegate manage subscribers")
    func subscribeAndUnsubscribe() {
        let multicaster = TestMultiCaster()
        let delegate = MockDelegate()

        multicaster.subscribeDelegate(delegate, receive: .main)
        #expect(multicaster.delegates.subscribers.count == 1)

        multicaster.unsubscribeDelegate(delegate)
        #expect(multicaster.delegates.subscribers.isEmpty)
    }

    // MARK: - Invoke Delivery

    @Test("invoke delivers the callback to all registered subscribers")
    func invokeDeliversToAll() async {
        let multicaster = TestMultiCaster()
        let delegate1 = MockDelegate()
        let delegate2 = MockDelegate()
        let queue = DispatchQueue(label: "test.invoke")

        multicaster.subscribeDelegate(delegate1, receive: queue)
        multicaster.subscribeDelegate(delegate2, receive: queue)

        multicaster.invoke { $0?.didReceiveValue(42) }
        await queue.drainAsync()

        #expect(delegate1.receivedValues == [42])
        #expect(delegate2.receivedValues == [42])
    }

    @Test("Multiple invocations deliver independently")
    func multipleInvocations() async {
        let multicaster = TestMultiCaster()
        let delegate = MockDelegate()
        let queue = DispatchQueue(label: "test.multi")

        multicaster.subscribeDelegate(delegate, receive: queue)

        multicaster.invoke { $0?.didReceiveValue(1) }
        multicaster.invoke { $0?.didReceiveValue(2) }
        multicaster.invoke { $0?.didReceiveValue(3) }
        await queue.drainAsync()

        #expect(delegate.receivedValues.count == 3)
        #expect(delegate.receivedValues.contains(1))
        #expect(delegate.receivedValues.contains(2))
        #expect(delegate.receivedValues.contains(3))
    }

    // MARK: - Queue Dispatch

    @Test("invoke delivers on the queue the subscriber was registered with")
    func invokeDeliversOnCorrectQueue() async {
        let multicaster = TestMultiCaster()
        let delegate = MockDelegate()
        let queueKey = DispatchSpecificKey<String>()
        let queueID = "test.queue.id"
        let queue = DispatchQueue(label: "test.queue")
        queue.setSpecific(key: queueKey, value: queueID)

        multicaster.subscribeDelegate(delegate, receive: queue)

        nonisolated(unsafe) var deliveredOnCorrectQueue = false

        multicaster.invoke { _ in
            deliveredOnCorrectQueue = DispatchQueue.getSpecific(key: queueKey) == queueID
        }
        await queue.drainAsync()

        #expect(deliveredOnCorrectQueue)
    }

    @Test("Subscribers on different queues each receive on their own queue")
    func perSubscriberQueueDispatch() async {
        let multicaster = TestMultiCaster()
        let delegate1 = MockDelegate()
        let delegate2 = MockDelegate()

        let key1 = DispatchSpecificKey<String>()
        let key2 = DispatchSpecificKey<String>()
        let queue1 = DispatchQueue(label: "test.queue1")
        let queue2 = DispatchQueue(label: "test.queue2")
        queue1.setSpecific(key: key1, value: "q1")
        queue2.setSpecific(key: key2, value: "q2")

        multicaster.subscribeDelegate(delegate1, receive: queue1)
        multicaster.subscribeDelegate(delegate2, receive: queue2)

        nonisolated(unsafe) var delegate1OnQ1 = false
        nonisolated(unsafe) var delegate2OnQ2 = false

        multicaster.invoke { delegate in
            if delegate === delegate1 {
                delegate1OnQ1 = DispatchQueue.getSpecific(key: key1) == "q1"
            } else if delegate === delegate2 {
                delegate2OnQ2 = DispatchQueue.getSpecific(key: key2) == "q2"
            }
            delegate?.didReceiveValue(1)
        }

        await queue1.drainAsync()
        await queue2.drainAsync()

        #expect(delegate1OnQ1)
        #expect(delegate2OnQ2)
    }

    // MARK: - Empty / No Subscribers

    @Test("invoke with no subscribers does not crash")
    func invokeWithNoSubscribers() {
        let multicaster = TestMultiCaster()
        multicaster.invoke { $0?.didReceiveValue(99) }
    }

    @Test("invoke after unsubscribing all delegates does not deliver")
    func invokeAfterFullUnsubscribe() async {
        let multicaster = TestMultiCaster()
        let delegate = MockDelegate()
        let queue = DispatchQueue(label: "test.unsub")

        multicaster.subscribeDelegate(delegate, receive: queue)
        multicaster.unsubscribeDelegate(delegate)

        multicaster.invoke { $0?.didReceiveValue(99) }
        await queue.drainAsync()

        #expect(delegate.receivedValues.isEmpty)
    }

    // MARK: - Weak Reference Behavior

    @Test("invoke is safe when subscribers have been deallocated")
    func invokeAfterDeallocation() async {
        let multicaster = TestMultiCaster()
        let queue = DispatchQueue(label: "test.dealloc")

        autoreleasepool {
            let delegate = MockDelegate()
            multicaster.subscribeDelegate(delegate, receive: queue)
        }

        nonisolated(unsafe) var receivedNonNilDelegate = false

        multicaster.invoke { delegate in
            if delegate != nil {
                receivedNonNilDelegate = true
            }
        }
        await queue.drainAsync()

        #expect(!receivedNonNilDelegate)
    }

    @Test("Only live subscribers receive the invocation after partial deallocation")
    func invokeWithPartialDeallocation() async {
        let multicaster = TestMultiCaster()
        let survivingDelegate = MockDelegate()
        let queue = DispatchQueue(label: "test.partial")

        multicaster.subscribeDelegate(survivingDelegate, receive: queue)

        autoreleasepool {
            let temporaryDelegate = MockDelegate()
            multicaster.subscribeDelegate(temporaryDelegate, receive: queue)
        }

        multicaster.invoke { $0?.didReceiveValue(7) }
        await queue.drainAsync()

        #expect(survivingDelegate.receivedValues == [7])
    }
}
