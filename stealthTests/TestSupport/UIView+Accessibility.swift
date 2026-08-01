//
//  UIView+Accessibility.swift
//  stealthTests
//
//  Helpers for driving SwiftUI views through the UIKit accessibility hierarchy.
//

import SwiftUI
import UIKit
import XCTest

extension UIView {
    func findSubview(accessibilityIdentifier: String) -> UIView? {
        if self.accessibilityIdentifier == accessibilityIdentifier {
            return self
        }
        if let elements = accessibilityElements {
            for element in elements {
                if let view = element as? UIView,
                   let found = view.findSubview(accessibilityIdentifier: accessibilityIdentifier) {
                    return found
                }
            }
        }
        for subview in subviews {
            if let found = subview.findSubview(accessibilityIdentifier: accessibilityIdentifier) {
                return found
            }
        }
        return nil
    }

    func tapSubview(
        accessibilityIdentifier: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        guard let view = findSubview(accessibilityIdentifier: accessibilityIdentifier) else {
            XCTFail(
                "No view with accessibility identifier \(accessibilityIdentifier)",
                file: file,
                line: line
            )
            return
        }

        var target: UIView? = view
        while let current = target {
            if let control = current as? UIControl {
                control.sendActions(for: .touchUpInside)
                return
            }
            target = current.superview
        }

        XCTAssertTrue(
            view.accessibilityActivate(),
            "Failed to activate view with accessibility identifier \(accessibilityIdentifier)",
            file: file,
            line: line
        )
    }
}

enum HomeViewTestHarness {
    @MainActor
    static func host<Content: View>(
        _ view: Content,
        size: CGSize = CGSize(width: 393, height: 852)
    ) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(origin: .zero, size: size)

        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        window.rootViewController = hostingController
        window.makeKeyAndVisible()

        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        return hostingController
    }
}
