//
//  RecoveryPhrase+Chips.swift
//  
//
//  Created by Matthew Watt on 8/1/23.
//

import Models
import Utils

public enum PhraseChipKind: Hashable {
    case empty
    case unassigned(word: RedactableString)
    case ordered(position: Int, word: RedactableString)
}

extension RecoveryPhrase {
    public func words(fromMissingIndices indices: [Int]) -> [PhraseChipKind] {
        assert((indices.count - 1) * groupSize <= self.words.count)
        
        return indices.enumerated().map { index, position in
                .unassigned(word: self.words[(index * groupSize) + position])
        }
    }
}
