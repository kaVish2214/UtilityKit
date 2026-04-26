//
//  MultiCastDelegate.swift
//  UtilityKit
//
//  Created by kavi gevariya on 26/04/26.
//

import Foundation

/// A protocol that types must conform to in order to receive multicast delegate callbacks.
///
/// Conforming types must be class-based (`NSObjectProtocol`) to support weak reference storage
/// and identity-based subscription management.
public protocol MultiCastDelegate: NSObjectProtocol, Sendable {

}
