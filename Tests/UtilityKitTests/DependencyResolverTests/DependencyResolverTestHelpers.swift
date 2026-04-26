import Foundation
import Factory
@testable import DependencyResolver

// MARK: - Test Protocols

protocol TestService: Sendable {
    var identifier: String { get }
}

protocol AnotherService: Sendable {
    var tag: Int { get }
}

// MARK: - Test Implementations

final class TestServiceImpl: TestService, @unchecked Sendable {
    let identifier: String
    init(identifier: String = "default") { self.identifier = identifier }
}

final class AnotherServiceImpl: AnotherService, @unchecked Sendable {
    let tag: Int
    init(tag: Int = 0) { self.tag = tag }
}

struct ValueDependency: Equatable, Sendable {
    let value: Int
}

// MARK: - Protocol Conformers

final class StubbedResolver: DependencyResolver { }

enum TestModule: DependencyRegistrar {
    nonisolated(unsafe) static var didRegister = false

    static func registerDependencies(_ resolver: Resolver) {
        didRegister = true
        _ = resolver.register(TestServiceImpl.self) { TestServiceImpl(identifier: "from-registrar") }
    }
}

// MARK: - Container Extension for ParameterFactory Tests

extension Container {
    var parameterizedService: ParameterFactory<String, TestServiceImpl> {
        self { identifier in TestServiceImpl(identifier: identifier) }
    }
}

struct TestRegistration: DependencyRegistration {
    typealias Parameter = String
    typealias Registration = ParameterFactory<String, TestServiceImpl>

    func registration(for resolver: Resolver) -> Registration {
        Container.shared.parameterizedService
    }

    func resolve(parameter: String, resolver: Resolver) -> TestServiceImpl? {
        registration(for: resolver).resolve(parameter)
    }
}
