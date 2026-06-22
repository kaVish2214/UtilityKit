import Testing
import Foundation
@testable import SwiftConcurrency

@Suite("ConcurrencyContainerProtocol")
struct ConcurrencyContainerProtocolTests {

    // MARK: - Existential Use

    @Test("Container can be held as an existential ConcurrencyContainerProtocol")
    func usableAsExistential() {
        let container: any ConcurrencyContainerProtocol<Int> = ConcurrencySafeContainer<Int>(uncheckedState: 1)

        container.withLockUnchecked { $0 += 41 }

        let value = container.withLockUnchecked { $0 }
        #expect(value == 42)
    }

    // MARK: - Generic Over Backend

    @Test("Generic functions can accept any ConcurrencyContainerProtocol")
    func genericOverBackend() {
        func bump<C: ConcurrencyContainerProtocol>(_ container: C) where C.State == Int {
            container.withLockUnchecked { $0 += 1 }
        }

        let container = ConcurrencySafeContainer<Int>(uncheckedState: 0)
        bump(container)
        bump(container)
        bump(container)

        #expect(container.withLock { $0 } == 3)
    }
}
