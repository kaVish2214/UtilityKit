// Copyright (c) 2026 kaVi Gevariya (@kaVish2214)
//
// This Source Code Form is subject to the terms of the Mozilla Public License,
// v. 2.0. If a copy of the MPL was not distributed with this file, You can
// obtain one at https://mozilla.org/MPL/2.0/.
// SPDX-License-Identifier: MPL-2.0

import Testing
import Foundation
import Factory
@testable import DependencyResolver

extension DependencyResolverModuleTests {

    @Suite("DependencyRegistration")
    struct RegistrationTests {

        let sut = TestRegistration()

        init() {
            Container.shared.manager.reset()
        }

        // MARK: - registration(for:)

        @Test("registration returns a valid ParameterFactory")
        func registrationReturnsFactory() {
            let factory = sut.registration(for: Container.shared)
            let result = factory.resolve("test-id")
            #expect(result.identifier == "test-id")
        }

        // MARK: - resolve(parameter:resolver:)

        @Test("resolve produces an instance using the given parameter")
        func resolveWithParameter() {
            let result = sut.resolve(parameter: "hello", resolver: Container.shared)
            #expect(result != nil)
            #expect(result?.identifier == "hello")
        }

        @Test("different parameters produce distinct instances")
        func differentParametersDifferentResults() {
            let first = sut.resolve(parameter: "alpha", resolver: Container.shared)
            let second = sut.resolve(parameter: "beta", resolver: Container.shared)

            #expect(first?.identifier == "alpha")
            #expect(second?.identifier == "beta")
            #expect(first !== second)
        }

        @Test("empty parameter is handled correctly")
        func emptyParameter() {
            let result = sut.resolve(parameter: "", resolver: Container.shared)
            #expect(result?.identifier == "")
        }

        @Test("each resolve call creates a new instance")
        func resolveCreatesFreshInstances() {
            let first = sut.resolve(parameter: "same", resolver: Container.shared)
            let second = sut.resolve(parameter: "same", resolver: Container.shared)

            #expect(first !== second)
            #expect(first?.identifier == second?.identifier)
        }
    }
}
