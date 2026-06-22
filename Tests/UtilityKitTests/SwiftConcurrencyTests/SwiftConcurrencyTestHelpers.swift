import Foundation
@testable import SwiftConcurrency

/// A non-Sendable reference type used to verify that `withLockUnchecked` can mutate
/// values that don't conform to `Sendable`.
final class NonSendableBox {
    var value: Int
    init(_ value: Int) { self.value = value }
}
