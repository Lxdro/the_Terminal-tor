import SwiftUI

struct TypewriterText: UIViewRepresentable {
    let text: String
    let font: UIFont
    let textColor: UIColor
    var typingTimeInterval: TimeInterval = 0.1
    var startImmediately: Bool = true
    var showCursor: Bool = false
    var startDelay: TimeInterval = 0.1
    
    func makeUIView(context: Context) -> TypewriterLabel {
        let label = TypewriterLabel()
        label.font = font
        label.textColor = textColor
        // If showing cursor, append a space for it
        label.text = showCursor ? text + " " : text
        label.typingTimeInterval = typingTimeInterval
        label.numberOfLines = 0
        label.textAlignment = .center
        
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        
        if startImmediately {
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                label.startTypewritingAnimation {
                    if showCursor {
                        context.coordinator.startCursorBlink(label)
                    }
                }
            }
        }
        
        return label
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func updateUIView(_ uiView: TypewriterLabel, context: Context) {
        if uiView.text != (showCursor ? text + " " : text) {
            uiView.text = showCursor ? text + " " : text
            uiView.restartTypewritingAnimation()
        }
    }
    
    class Coordinator {
        var cursorTimer: Timer?
        var isBlinkVisible = false
        
        func startCursorBlink(_ label: TypewriterLabel) {
            cursorTimer?.invalidate()
            cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.isBlinkVisible.toggle()
                
                let attributedText = NSMutableAttributedString(string: label.text ?? "")
                if self.isBlinkVisible {
                    attributedText.replaceCharacters(in: NSRange(location: attributedText.length - 1, length: 1), with: "_")
                } else {
                    let invisibleChar = NSAttributedString(string: "_", attributes: [.foregroundColor: UIColor.clear])
                    
                    attributedText.replaceCharacters(in: NSRange(location: attributedText.length - 1, length: 1), with: invisibleChar)
                }
                label.attributedText = attributedText
            }
        }
        
        deinit {
            cursorTimer?.invalidate()
        }
    }
}
