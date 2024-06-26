//
//  NighthawkTransactionAmountTextField.swift
//  
//
//  Created by Matthew Watt on 7/19/23.
//

import Generated
import SwiftUI
import Utils

public struct NighthawkTransactionAmountTextField: UIViewRepresentable {
    private var text: Binding<String>
    private let tokenName: String
    private let decimalSeparator = Locale.current.decimalSeparator ?? "."
    
    public init(text: Binding<String>, tokenName: String) {
        self.text = text
        self.tokenName = tokenName
    }
    
    public func makeUIView(context: Context) -> ZecAmountRenderingView {
        let view = ZecAmountRenderingView(tokenName: tokenName, decimalSeparator: decimalSeparator)
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textColor = .white
        view.font = FontFamily.PulpDisplay.medium.font(size: 28)
        view.textAlignment = .center
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        view.isUserInteractionEnabled = true
        view.becomeFirstResponder()
        return view
    }
    
    public func updateUIView(_ uiView: ZecAmountRenderingView, context: Context) {
        uiView.input = text.wrappedValue
    }
    
    public class Coordinator: NSObject, ZecAmountRenderingViewDelegate {
        var parent: NighthawkTransactionAmountTextField
        
        init(_ parent: NighthawkTransactionAmountTextField) {
            self.parent = parent
        }
        
        public func textDidChange(_ text: String) {
            parent.text.wrappedValue = text
        }
    }
    
    public func makeCoordinator() -> Coordinator { Coordinator(self) }
}

protocol ZecAmountRenderingViewDelegate: AnyObject {
    func textDidChange(_ text: String)
}

public class ZecAmountRenderingView: UILabel {
    weak var delegate: ZecAmountRenderingViewDelegate?
    
    var input: String = "0" {
        didSet {
            text = "\(input) \(tokenName)"
            set(color: Asset.Colors.Nighthawk.peach.systemColor, on: [tokenName])
        }
    }
    
    private let tokenName: String
    private let decimalSeparator: String
    
    required init(tokenName: String, decimalSeparator: String) {
        self.tokenName = tokenName
        self.decimalSeparator = decimalSeparator
        super.init(frame: .zero)
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init?(coder:) has not been implemented")
    }
    
    @objc private func handleTap() {
        becomeFirstResponder()
    }
}

// MARK: - UIKeyInput, UITextInputTraits, UIResponder
extension ZecAmountRenderingView: UIKeyInput, UITextInputTraits {
    public override var canBecomeFirstResponder: Bool { true }
    
    public var hasText: Bool { input.isEmpty == false }
    
    public var keyboardType: UIKeyboardType {
        get { .decimalPad }
        set {}
    }
    
    public func insertText(_ text: String) {
        guard text.count == 1 && fractionalPlaces < 8 else { return }
        
        if text.isWholeNumber {
            delegate?.textDidChange(
                input == "0" ? text : "\(input)\(text)"
            )
        } else if text == decimalSeparator && !input.contains(decimalSeparator) {
            delegate?.textDidChange("\(input)\(decimalSeparator)")
        }
    }
    
    public func deleteBackward() {
        guard input.count > 1 else {
            delegate?.textDidChange("0")
            return
        }
        
        delegate?.textDidChange(String(input.dropLast()))
    }
}

// MARK: - Private implementation
private extension ZecAmountRenderingView {
    var fractionalPlaces: Int {
        let parts = input.split(separator: decimalSeparator)
        if parts.count < 2 {
            return 0
        }
                
        return parts[1].count
    }
}

private extension UILabel {
    func set(color: UIColor, on substrings: [String]) {
        
        guard let text = self.text else {
            return
        }
        
        // Calculates the ranges of the substrings that needs the color change
        let ranges = substrings.map { substring -> NSRange in
            return (text as NSString).range(of: substring)
        }
        
        // Creates an attributed string and adds the color atrribute for each range
        let styledText = NSMutableAttributedString(string: text)
        
        for range in ranges {
            styledText.addAttribute(.foregroundColor, value: color, range: range)
        }
        
        // Sets the attributed text to the label
        attributedText = styledText
    }
}

