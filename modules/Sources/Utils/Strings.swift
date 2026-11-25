import Foundation

extension String: @retroactive Error {}

extension String {
    public var isWholeNumber: Bool {
        allSatisfy { $0.isWholeNumber }
    }
}
