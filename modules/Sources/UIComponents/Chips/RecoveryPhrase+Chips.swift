//
//  RecoveryPhrase+Chips.swift
//  
//
//  Created by Matthew Watt on 8/1/23.
//

import Models

extension RecoveryPhrase {
    public func words(fromMissingIndices indices: [Int]) -> [PhraseChip.Kind] {
        assert((indices.count - 1) * groupSize <= self.words.count)

        return indices.enumerated().map { index, position in
                .unassigned(word: self.words[(index * groupSize) + position])
        }
    }
}
