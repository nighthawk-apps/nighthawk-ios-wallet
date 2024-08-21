//
//  Recipient+CasePathable.swift
//
//
//  Created by Matthew Watt on 8/17/24.
//

import ZcashLightClientKit
import CasePaths

extension Recipient: CasePathable, CasePathIterable {
    public struct AllCasePaths: CasePathReflectable, Sendable {
        public subscript(root: Recipient) -> PartialCaseKeyPath<Recipient> {
            switch root {
            case .transparent: return \.transparent
            case .sapling: return \.sapling
            case .unified: return \.unified
            case .tex: return \.tex
            }
        }
        
        /// A success case path, for embedding or extracting a `TransparentAddress` value.
        public var transparent: AnyCasePath<Recipient, TransparentAddress> {
            AnyCasePath(
                embed: { .transparent($0) },
                extract: {
                    guard case let .transparent(value) = $0 else { return nil }
                    return value
                }
            )
        }
        
        /// A success case path, for embedding or extracting a `SaplingAddress` value.
        public var sapling: AnyCasePath<Recipient, SaplingAddress> {
            AnyCasePath(
                embed: { .sapling($0) },
                extract: {
                    guard case let .sapling(value) = $0 else { return nil }
                    return value
                }
            )
        }
        
        /// A success case path, for embedding or extracting a `SaplingAddress` value.
        public var unified: AnyCasePath<Recipient, UnifiedAddress> {
            AnyCasePath(
                embed: { .unified($0) },
                extract: {
                    guard case let .unified(value) = $0 else { return nil }
                    return value
                }
            )
        }
        
        /// A success case path, for embedding or extracting a `TexAddress` value.
        public var tex: AnyCasePath<Recipient, TexAddress> {
            AnyCasePath(
                embed: { .tex($0) },
                extract: {
                    guard case let .tex(value) = $0 else { return nil }
                    return value
                }
            )
        }
    }
    
    public static var allCasePaths: AllCasePaths {
        AllCasePaths()
    }
}

extension Recipient.AllCasePaths: Sequence {
  public func makeIterator() -> some IteratorProtocol<PartialCaseKeyPath<Recipient>> {
      [\.transparent, \.sapling, \.unified, \.tex].makeIterator()
  }
}
