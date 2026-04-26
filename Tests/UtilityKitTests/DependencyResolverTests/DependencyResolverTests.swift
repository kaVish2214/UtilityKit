import Testing
import Foundation
import Factory
@testable import DependencyResolver

extension DependencyResolverModuleTests {

    @Suite("DependencyResolver")
    struct ResolverTests {

        let sut = StubbedResolver()

        init() {
            Container.shared.manager.reset()
        }

        // MARK: - resolver Property

        @Test("resolver returns Container.shared")
        func resolverReturnsContainer() {
            #expect(sut.resolver is Container)
        }

        // MARK: - resolved(_:) — Unregistered Types

        @Test("resolved returns nil for an unregistered class type")
        func resolveUnregisteredClass() {
            let result: TestServiceImpl? = sut.resolved()
            #expect(result == nil)
        }

        @Test("resolved returns nil for an unregistered value type")
        func resolveUnregisteredStruct() {
            let result: ValueDependency? = sut.resolved()
            #expect(result == nil)
        }

        // MARK: - resolved(_:) — Registered Types

        @Test("resolved returns an instance for a registered class type")
        func resolveRegisteredClass() {
            _ = Container.shared.register(TestServiceImpl.self) { TestServiceImpl() }
            let result: TestServiceImpl? = sut.resolved()
            #expect(result != nil)
            #expect(result?.identifier == "default")
        }

        @Test("resolved returns an instance for a registered value type")
        func resolveRegisteredStruct() {
            _ = Container.shared.register(ValueDependency.self) { ValueDependency(value: 42) }
            let result: ValueDependency? = sut.resolved()
            #expect(result == ValueDependency(value: 42))
        }

        @Test("resolved with explicit type parameter works the same as inferred")
        func resolveExplicitType() {
            _ = Container.shared.register(TestServiceImpl.self) { TestServiceImpl(identifier: "explicit") }
            let result = sut.resolved(TestServiceImpl.self)
            #expect(result?.identifier == "explicit")
        }

        // MARK: - Re-registration

        @Test("re-registering a type uses the latest factory")
        func reRegisterReplacesFactory() {
            _ = Container.shared.register(TestServiceImpl.self) { TestServiceImpl(identifier: "old") }
            _ = Container.shared.register(TestServiceImpl.self) { TestServiceImpl(identifier: "new") }
            let result: TestServiceImpl? = sut.resolved()
            #expect(result?.identifier == "new")
        }

        // MARK: - Independent Types

        @Test("different types are resolved independently")
        func resolveMultipleTypesIndependently() {
            _ = Container.shared.register(TestServiceImpl.self) { TestServiceImpl(identifier: "svc") }
            _ = Container.shared.register(ValueDependency.self) { ValueDependency(value: 7) }

            let service: TestServiceImpl? = sut.resolved()
            let value: ValueDependency? = sut.resolved()

            #expect(service?.identifier == "svc")
            #expect(value == ValueDependency(value: 7))
        }

        @Test("resolving one type does not affect another unregistered type")
        func resolveDoesNotLeakAcrossTypes() {
            _ = Container.shared.register(TestServiceImpl.self) { TestServiceImpl() }

            let service: TestServiceImpl? = sut.resolved()
            let other: AnotherServiceImpl? = sut.resolved()

            #expect(service != nil)
            #expect(other == nil)
        }

        // MARK: - Multiple Conformers

        @Test("any type conforming to DependencyResolver gets the defaults")
        func multipleConformers() {
            _ = Container.shared.register(ValueDependency.self) { ValueDependency(value: 99) }

            final class ResolverA: DependencyResolver { }
            final class ResolverB: DependencyResolver { }

            let a: ValueDependency? = ResolverA().resolved()
            let b: ValueDependency? = ResolverB().resolved()

            #expect(a == b)
        }

        // MARK: - Factory Provides Fresh Instances

        @Test("each resolved call invokes the factory again")
        func resolveCallsFactoryEachTime() {
            nonisolated(unsafe) var callCount = 0
            _ = Container.shared.register(TestServiceImpl.self) {
                callCount += 1
                return TestServiceImpl(identifier: "call-\(callCount)")
            }

            let first: TestServiceImpl? = sut.resolved()
            let second: TestServiceImpl? = sut.resolved()

            #expect(first?.identifier != second?.identifier)
            #expect(callCount == 2)
        }
    }
}
