import SwiftUI

struct TTYView: View {
    @State var isRed = false
    let commandHistory: [Command]
    let username: String
    let currentPath: String
    let currentCommand: String?
    
    var welcomeMessage: String
    
    var body: some View {
        ZStack {
            PlayerView()
                //.ignoresSafeArea()
                //.edgesIgnoringSafeArea(.all)
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(isRed ? .black.opacity(0.9) : .black.opacity(0.6))
                if isRed {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.red.opacity(0.1))
                }
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isRed ? Color.red : Color.green, lineWidth: 2)
                    .fill(.ultraThinMaterial)
                VStack(alignment: .leading, spacing: 0) {
                    Text(welcomeMessage)
                        .foregroundColor(isRed ? .red : .green)
                        .font(.custom("Glass_TTY_VT220", size: 18))
                        .foregroundColor(.green)
                    
                    ForEach(commandHistory, id: \.self) { command in
                        Text("\(username):\(command.path)$ \(command.command)")
                            .font(.custom("Glass_TTY_VT220", size: 18))
                            .foregroundColor(isRed ? .red : .green)
                            .textSelection(.enabled)
                        
                        if command.error != nil {
                            Text("\n> \(command.error!)\n")
                                .font(.custom("Glass_TTY_VT220", size: 18))
                                .foregroundColor(.red)
                                .textSelection(.enabled)
                        } else if command.output != nil {
                            Text("\n\(command.output!)\n")
                                .font(.custom("Glass_TTY_VT220", size: 18))
                                .foregroundColor(isRed ? .red : .green)
                                .textSelection(.enabled)
                        }
                    }
                    
                    HStack(spacing: 0) {
                        Text("\(username):\(currentPath)$ ")
                            .font(.custom("Glass_TTY_VT220", size: 18))
                            .foregroundColor(isRed ? .red : .green)
                        Text(currentCommand ?? "")
                            .font(.custom("Glass_TTY_VT220", size: 18))
                            .foregroundColor(isRed ? .red : .green)
                        BlinkingCursor(isRed: isRed)
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
            }
        }
    }
}

struct BlinkingCursor: View {
    @State var isRed = false
    @State private var isVisible = true
    
    var body: some View {
        Text("_")
            .font(.custom("Glass_TTY_VT220", size: 18))
            .foregroundColor(isRed ? .red : .green)
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                    isVisible.toggle()
                }
                timer.fire()
            }
    }
}

struct Command: Hashable {
    let path: String
    let command: String
    let error: String?
    var output: String? = nil
}
