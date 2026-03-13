import SwiftUI

struct SharedLevelView<VM: LevelViewModel>: View {
    @ObservedObject var viewModel: VM
    @Binding var selectedLevel: Int
    @FocusState private var isFocused: Bool
    
    private let username = UserDefaults.standard.string(forKey: "username") ?? "user"
    
    var body: some View {
        VStack(spacing: viewModel.hasTextField ? 50 : 0) {
            HStack(spacing: 0) {
                if viewModel.hasTreeView {
                    GeometryReader { proxy in
                        VStack(spacing: 0) {
                            instructions
                                .frame(height: proxy.size.height * (1/3))
                            fileTreeView
                                .frame(height: proxy.size.height * (2/3))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    VStack {
                        instructions
                    }
                }
                ttyView
            }
            .frame(height: UIScreen.main.bounds.height / (viewModel.hasTextField ? 2 : 2.5))
            
            if viewModel.hasTextField {
                textFieldCommandSection
            } else {
                buttonCommandSection
            }
        }
        .padding(viewModel.hasTextField ? .all : [])
        .onAppear {
            viewModel.initializeView()
        }
        .sheet(isPresented: $viewModel.showCompletion) {
            LevelCompletionView(selectedLevel: $selectedLevel, commandCount: viewModel.commandCount, timeElapsed: viewModel.timeElapsed)
        }
    }
    
    private var instructions: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.instructionTitle)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            
            ScrollView {
                if #available(iOS 15.0, *) {
                    Text(try! AttributedString(markdown: viewModel.instructionText))
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                } else {
                    Text(viewModel.instructionText)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(viewModel.hasTreeView ? .leading : .trailing)
    }
    
    private var fileTreeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewModel.treeTitle)
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            
            ScrollView {
                Text(viewModel.treeText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.leading)
    }
    
    private var ttyView: some View {
        TTYView(
            isRed: viewModel.isRedTTY,
            commandHistory: viewModel.commandHistory,
            username: username,
            currentPath: viewModel.currentPath,
            currentCommand: viewModel.realCommand,
            welcomeMessage: viewModel.welcomeMessage
        )
        .frame(width: UIScreen.main.bounds.width / 1.8)
        .padding(viewModel.hasTreeView ? .trailing : [])
    }
    
    private var buttonCommandSection: some View {
        VStack(spacing: 26) {
            Spacer()
            commandButtons
            Spacer()
            fileButtons
            Spacer()
            actionButtons
            Spacer()
        }
        .padding(.vertical)
    }
    
    private var textFieldCommandSection: some View {
        VStack(spacing: 50) {
            HStack {
                Text("$")
                    .font(.custom("Glass_TTY_VT220", size: 18))
                    .foregroundColor(viewModel.isRedTTY ? TTYColors.red : TTYColors.text)
                
                TextField("> Enter command", text: $viewModel.realCommand)
                    .font(.custom("Glass_TTY_VT220", size: 18))
                    .foregroundColor(viewModel.isRedTTY ? TTYColors.red : TTYColors.text)
                    .background(TTYColors.terminalBlack)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .focused($isFocused)
                    .tint(viewModel.isRedTTY ? TTYColors.red : TTYColors.text)
                    .onSubmit {
                        viewModel.executeWrapped()
                        isFocused = true
                    }
            }
            .padding()
            .background(TTYColors.terminalBlack)
            .cornerRadius(5)
            
            actionButtons
        }
        .keyboardShortcut(.return, modifiers: [])
    }
    
    private var commandButtons: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.commands, id: \.self) { command in
                CommandButton(
                    command: command,
                    isSelected: viewModel.selectedCommand == command,
                    action: { viewModel.selectCommand(command) }
                )
            }
        }
    }
    
    private var fileButtons: some View {
        HStack(spacing: 16) {
            ForEach(viewModel.fileOptions) { option in
                FileButton(
                    option: option,
                    isSelectable: viewModel.isFileSelectable(option),
                    isSelected: viewModel.selectedFiles.contains(option.name),
                    action: { viewModel.handleFileSelection(option) }
                )
            }
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Spacer()
            if viewModel.hasTreeView || viewModel.hasTextField {
                ActionButton(title: "Restart", baseColor: .red) {
                    viewModel.restartLevel()
                }
                Spacer()
            }
            if !viewModel.hasTextField {
                ActionButton(title: "Cancel", baseColor: .orange) {
                    viewModel.resetCommandState()
                }
                Spacer()
            }
            ActionButton(title: "Clear", baseColor: .white) {
                viewModel.clearTerminal()
            }
            Spacer()
            if !viewModel.hasTextField && viewModel.commands.contains("mv") {
                ActionButton(title: "Space", baseColor: .cyan) {
                    viewModel.addSpace()
                }
                Spacer()
            }
            ActionButton(
                title: "Execute",
                baseColor: .green,
                isEnabled: (viewModel.selectedCommand != nil && !viewModel.hasTextField) || (viewModel.realCommand != "" && viewModel.hasTextField)
            ) {
                viewModel.executeWrapped()
            }
            Spacer()
        }
    }
}
