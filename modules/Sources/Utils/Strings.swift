import Foundation

extension String: Error {}

extension String {
    public var isWholeNumber: Bool {
        allSatisfy { $0.isWholeNumber }
    }
}
