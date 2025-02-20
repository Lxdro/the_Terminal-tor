import SwiftUI

struct KeyButton: ButtonStyle {
    var baseColor: Color
    var selected: Bool = false
    var unselectable: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            let offset: CGFloat = 8
            let darkerColor = baseColor.opacity(0.8)
            let textColor: Color = unselectable ? .gray : .black
            let isPressed = configuration.isPressed && !selected && !unselectable
            
            // Background shadow/base layer
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(unselectable ? Color.black : darkerColor)
                .offset(y: offset)
            
            // Button face layer
            RoundedRectangle(cornerRadius: 6)
                .foregroundStyle(unselectable ? Color(red: 0.2, green: 0.2, blue: 0.2) : baseColor)
                .offset(y: unselectable ? 0 : (selected || isPressed ? offset : 0))
            
            // Label
            configuration.label
                .foregroundColor(textColor)
                .offset(y: unselectable ? 0 : (selected || isPressed ? offset : 0))
        }
        .compositingGroup()
        .shadow(radius: unselectable ? 0 : 6, y: unselectable ? 0 : 4)
        .animation(.easeInOut(duration: 0.1), value: selected)
        .animation(.easeInOut(duration: 0.1), value: unselectable)
        .allowsHitTesting(!unselectable && !selected)  // Prevents interaction when unselectable or selected
    }
}


// MARK: - Supporting Views
struct CommandButton: View {
    let command: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(command, action: action)
            .buttonStyle(KeyButton(
                baseColor: .gray,
                selected: isSelected
            ))
            .frame(width: 70, height: 40)
            .padding(.horizontal, 20)
    }
}

struct FileButton: View {
    let option: FileOption
    let isSelectable: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(option.emoji ?? "")
                    .font(.system(size: 36))
                Text(option.name)
                    .font(.caption)
            }
        }
        .frame(width: 100, height: 100)
        .buttonStyle(KeyButton(
            baseColor: .gray
            //selected: isSelected,
            //unselectable: !isSelectable
        ))
    }
}

struct ActionButton: View {
    let title: String
    let baseColor: Color
    var isEnabled: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(title, action: action)
            .buttonStyle(KeyButton(
                baseColor: baseColor,
                unselectable: !isEnabled
            ))
            .frame(width: 100, height: 50)
    }
}
