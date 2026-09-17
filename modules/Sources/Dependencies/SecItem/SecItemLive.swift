//
//  SecItemLive.swift
//  stealth
//

import Foundation
import Security

extension SecItemClient {
    public static let live = SecItemClient(
        copyMatching: { query, result in
            SecItemCopyMatching(query, &result)
        },
        add: { attributes, result in
            SecItemAdd(attributes, &result)
        },
        update: { query, attributesToUpdate in
            SecItemUpdate(query, attributesToUpdate)
        },
        delete: { query in
            SecItemDelete(query)
        }
    )
}
