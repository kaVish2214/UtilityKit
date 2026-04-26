import Testing
import Foundation
import Factory
@testable import DependencyResolver

extension DependencyResolverModuleTests {

    @Suite("DependencyRegistrar")
    struct RegistrarTests {

        init() {
            Container.shared.manager.reset()
            TestModule.didRegister = false
        }

        @Test("registerDependencies is called on the conforming type")
        func registrarIsCalled() {
            TestModule.registerDependencies(Container.shared)
            #expect(TestModule.didRegister)
        }

        @Test("dependencies registered via registrar are resolvable")
        func registeredDependenciesAreResolvable() {
            TestModule.registerDependencies(Container.shared)

            let sut = StubbedResolver()
            let result: TestServiceImpl? = sut.resolved()
            #expect(result?.identifier == "from-registrar")
        }

        @Test("registrar can be called multiple times without error")
        func registrarIdempotent() {
            TestModule.registerDependencies(Container.shared)
            TestModule.registerDependencies(Container.shared)

            let sut = StubbedResolver()
            let result: TestServiceImpl? = sut.resolved()
            #expect(result != nil)
        }

        @Test("multiple registrars can register sequentially without error")
        func multipleRegistrars() {
            enum ModuleA: DependencyRegistrar {
                static func registerDependencies(_ resolver: Resolver) {
                    _ = resolver.register(TestServiceImpl.self) { TestServiceImpl(identifier: "A") }
                }
            }

            enum ModuleB: DependencyRegistrar {
                static func registerDependencies(_ resolver: Resolver) {
                    _ = resolver.register(TestServiceImpl.self) { TestServiceImpl(identifier: "B") }
                }
            }

            ModuleA.registerDependencies(Container.shared)
            ModuleB.registerDependencies(Container.shared)

            let sut = StubbedResolver()
            let result: TestServiceImpl? = sut.resolved()
            #expect(result?.identifier == "B")
        }

        @Test("later registrar overrides earlier registration of the same type")
        func registrarOverrides() {
            enum Early: DependencyRegistrar {
                static func registerDependencies(_ resolver: Resolver) {
                    _ = resolver.register(TestServiceImpl.self) { TestServiceImpl(identifier: "early") }
                }
            }

            enum Late: DependencyRegistrar {
                static func registerDependencies(_ resolver: Resolver) {
                    _ = resolver.register(TestServiceImpl.self) { TestServiceImpl(identifier: "late") }
                }
            }

            Early.registerDependencies(Container.shared)
            Late.registerDependencies(Container.shared)

            let sut = StubbedResolver()
            let result: TestServiceImpl? = sut.resolved()
            #expect(result?.identifier == "late")
        }
    }
}
