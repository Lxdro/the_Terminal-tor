import SwiftUI

struct Level1View: View {
    // MARK: - State
    @StateObject private var root = File(name: "root", isDirectory: true)
    @State private var currentDirectory: File?
    @State private var selectedCommand: String?
    @State private var selectedFiles: [String] = []
    @State private var treeText: String = ""
    @State private var expectedTreeText: String = ""
    @State private var commandHistory: [Command] = []
    @State private var realCommand: String = ""
    @State private var realDirectory: File?
    @State private var errorMessage: String? = nil
    @State private var commandCount: Int = 0
    @State private var isLevelComplete: Bool = false
    
    @State var welcomeMessage =
    """
    Welcome to the Terminal-tor
    Press buttons to make real commands!
    
    """
    
    @Binding var selectedLevel: Int
    @State private var showCompletion = false
    
    // MARK: - Constants
    private let username = UserDefaults.standard.string(forKey: "username") ?? "user"
    private let commands = ["cd", "touch", "mkdir", "rm"]
    private let fileOptions = [
        FileOption(emoji: "🔙", name: ".."),
        FileOption(emoji: "🎮", name: "game"),
        FileOption(emoji: "📝", name: "note"),
        FileOption(emoji: "📸", name: "photo"),
        FileOption(emoji: "🎵", name: "music")
    ]
    
    // Expected file structure for the level
    private let expectedStructure: [(type: String, path: String)] = [
        ("directory", "/game"),
        ("directory", "/photo"),
        ("file", "/game/note")
    ]
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            //instructionHeader
            HStack(spacing: 0) {
                VStack {
                    fileSystemView
                    expectedTreeView
                }
                //divider
                ttyView
            }
            .frame(height: UIScreen.main.bounds.height / 2)
            
            //gameStatusSection
            commandSection
            Button("Complete Level") {
                showCompletion = true
            }
        }
        //.background(TTYColors.terminalBlack)
        .onAppear(perform: initializeView)
        .sheet(isPresented: $showCompletion) {
            LevelCompletionView(selectedLevel: $selectedLevel)
        }
        
    }
    
    // MARK: - View Components
    private var instructionHeader: some View {
        HStack(spacing: 16) {
            Text("Instructions: create 2 directories and 1 file.")
                .font(.custom("Glass_TTY_VT220", size: 18))
            Spacer()
            if isLevelComplete {
                Text("🎉 Level Complete! 🎉")
                    .foregroundColor(.green)
                    .font(.headline)
            }
        }
        .padding()
    }
    
    private var fileSystemView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Current File System")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            
            ScrollView {
                Text(treeText)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.leading)
    }
    
    private var expectedTreeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Expected Structure")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            
            ScrollView {
                Text(expectedTreeText)
                    .font(.system(.body, design: .monospaced))
                    .frame(width: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.leading)
    }
    
    private var ttyView: some View {
        TTYView(
            commandHistory: commandHistory,
            username: username,
            currentPath: getCurrentPath(file: realDirectory),
            currentCommand: realCommand,
            welcomeMessage: welcomeMessage
        )
        .frame(width: UIScreen.main.bounds.width / 2)
        //.cornerRadius(12)
        //.shadow(radius: 2)
        .padding(.trailing)
    }
    
    private var commandSection: some View {
        VStack(spacing: 26) {
            Spacer()
            commandButtons
            Spacer()
            fileButtons
            Spacer()
                //.padding(.vertical)
            actionButtons
            Spacer()
        }
        .padding(.vertical)
    }
    
    private var commandButtons: some View {
        HStack(spacing: 4) {
            ForEach(commands, id: \.self) { command in
                CommandButton(
                    command: command,
                    isSelected: selectedCommand == command,
                    action: { selectCommand(command) }
                )
            }
        }
    }
    
    private var fileButtons: some View {
        HStack(spacing: 16) {
            ForEach(fileOptions) { option in
                FileButton(
                    option: option,
                    isSelectable: isFileSelectable(option),
                    isSelected: selectedFiles.contains(option.name),
                    action: { handleFileSelection(option) }
                )
            }
        }
    }
    
    private var actionButtons: some View {
        HStack {
            Spacer()
            ActionButton(title: "Restart", baseColor: .red) {
                restartLevel()
            }

            Spacer()
            ActionButton(title: "Cancel", baseColor: .orange) {
                resetCommandState()
            }
            Spacer()
            ActionButton(title: "Clear", baseColor: .white) {
                selectedCommand = nil
                commandHistory = []
                welcomeMessage = ""
            }
            Spacer()
            ActionButton(
                title: "Execute",
                baseColor: .green,
                isEnabled: realCommand != ""
            ) {
                executeCommand()
                commandCount += 1
                checkLevelCompletion()
            }
            Spacer()
        }
    }
    
    private func restartLevel() {
        // Reset file system
        root.children?.removeAll()
        currentDirectory = root
        realDirectory = root
        
        // Reset game state
        commandCount = 0
        isLevelComplete = false
        commandHistory = []
        
        // Reset command state
        resetCommandState()
        
        // Update views
        updateTreeText()
        generateExpectedTree()
        welcomeMessage = """
    Welcome to Terminal-tor
    Press buttons to make real commands!
    
    """
    }
    
    private func generateExpectedTree() {
        var tree = "📂 root\n"
        for item in expectedStructure {
            let components = item.path.split(separator: "/").map(String.init)
            let indent = String(repeating: "  ", count: components.count)
            let icon = item.type == "directory" ? "📂" : "📄"
            tree += "\(indent)\(icon) \(components.last ?? "")\n"
        }
        expectedTreeText = tree
    }
    
    private func checkLevelCompletion() {
        // Create a normalized representation of current file system
        var currentStructure: [(type: String, path: String)] = []
        
        func traverse(_ file: File, currentPath: String) {
            let path = currentPath + "/" + file.name
            if file.name != "root" {
                currentStructure.append((file.isDirectory ? "directory" : "file", path))
            }
            if let children = file.children {
                for child in children {
                    traverse(child, currentPath: path)
                }
            }
        }
        
        currentStructure = []
        if let children = root.children {
            for child in children {
                traverse(child, currentPath: "")
            }
        }
        
        // Sort both arrays to ensure consistent comparison
        let sortedCurrent = currentStructure.sorted { $0.path < $1.path }
        let sortedExpected = expectedStructure.sorted { $0.path < $1.path }
        
        // Compare structures by checking if they have the same length and all elements match
        if sortedCurrent.count == sortedExpected.count {
            isLevelComplete = !zip(sortedCurrent, sortedExpected).contains { current, expected in
                current.type != expected.type || current.path != expected.path
            }
        } else {
            isLevelComplete = false
        }
        
        if isLevelComplete {
            welcomeMessage += "\n Congratulations! Level completed in \(commandCount) commands! \n"
        }
    }
    
    private var gameStatusSection: some View {
        HStack(spacing: 20) {
            Text("Commands Used: \(commandCount)")
                .font(.headline)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.vertical)
    }
    
    // MARK: - Helper Functions
    private func initializeView() {
        currentDirectory = root
        realDirectory = root
        updateTreeText()
        generateExpectedTree()
    }
    
    private func selectCommand(_ command: String) {
        selectedCommand = command
        realCommand = "\(command) "
        selectedFiles = []
    }
    
    private func isFileSelectable(_ option: FileOption) -> Bool {
        let currentDir = currentDirectory ?? root
        return currentDir.isFileSelectable(name: option.name, forCommand: selectedCommand)
    }
    
    private func handleFileSelection(_ option: FileOption) {
        //guard isFileSelectable(option) else { return }
        
        //let currentDir = currentDirectory ?? root
        
        /*
        // Handle directory navigation for cd
        if selectedCommand == "cd" {
            if option.name == ".." {
                currentDirectory = currentDirectory!.parent ?? root
            } else {
                currentDirectory = currentDir.getChild(named: option.name)
            }
        }*/
        
        // Update command string
        if selectedFiles.isEmpty {
            realCommand += option.name
        } else {
            realCommand += "/\(option.name)"
        }
        
        selectedFiles.append(option.name)
    }
    
    private func resetCommandState() {
        realCommand = ""
        selectedCommand = nil
        selectedFiles = []
    }
    
    private func getCurrentPath(file: File?) -> String {
        var path = [String]()
        var currentFile: File? = file
        
        while let dir = currentFile {
            path.insert(dir.name, at: 0)
            currentFile = dir.parent
        }
        
        return "/" + path.joined(separator: "/")
    }
    
    private func inputPath() -> String {
        let components = realCommand.split(separator: " ", maxSplits: 1)
        if components.count > 1 {
            return String(components[1])
        }
        return ""
    }
    
    private func parsePath(_ path: String) -> (File, String)? {
        // Start from current directory or root if path starts with /
        var currentFile = path.hasPrefix("/") ? root : (realDirectory ?? root)
        var components = path.split(separator: "/")
        
        // If path starts with /, remove empty first component
        if path.hasPrefix("/") {
            components.removeFirst()
        }
        
        // Handle special case where path is just "/"
        if components.isEmpty && path.hasPrefix("/") {
            return (root, "")
        }
        
        // Get the file/directory name (last component)
        let targetName = String(components.removeLast())
        
        // Traverse the path
        for component in components {
            let name = String(component)
            
            // Handle ".." navigation
            if name == ".." {
                currentFile = currentFile.parent ?? root
                continue
            }
            
            // Try to find the directory
            guard let nextDir = currentFile.cd(name) else {
                return nil
            }
            
            // Ensure it's a directory
            guard nextDir.isDirectory else {
                return nil
            }
            
            currentFile = nextDir
        }
        
        return (currentFile, targetName)
    }
    
    private func executeCommand() {
        let oldRealDir = realDirectory
        if (selectedFiles == []) {
            if (selectedCommand != "cd") {
                errorMessage = "Command \(selectedCommand!) need to specify a file."
            } else {
                realDirectory = root
                currentDirectory = root
                addToCommandHistory(realCommand, oldRealDir)
                updateTreeText()
                resetCommandState()
            }
            return
        }
        guard let command = selectedCommand else { return }
        
        let path = inputPath()
        
        switch command {
        case "cd":
            if path.isEmpty || path == "/" {
                currentDirectory = root
                realDirectory = root
            } else {
                // Special case for "cd .."
                if path == ".." {
                    currentDirectory = (realDirectory ?? root).parent ?? root
                    realDirectory = currentDirectory
                } else {
                    // For cd with path
                    if let (parent, dirname) = parsePath(path) {
                        if dirname == ".." {
                            currentDirectory = parent.parent ?? root
                            realDirectory = currentDirectory
                        } else if let targetDir = parent.cd(dirname) {
                            currentDirectory = targetDir
                            realDirectory = currentDirectory
                        } else {
                            errorMessage = "Directory not found: \(path)"
                        }
                    } else {
                        errorMessage = "Invalid path: \(path)"
                    }
                }
            }
            
        case "touch":
            if path == ".." {
                errorMessage = "Invalid file name: .."
            } else if let (parent, filename) = parsePath(path) {
                // Check if the final component is ".."
                if filename == ".." {
                    errorMessage = "Invalid file name: .."
                } else if parent.getChild(named: filename) != nil {
                    errorMessage = "File already exists: \(path)"
                } else {
                    parent.touch(filename)
                }
            } else {
                errorMessage = "Invalid path: \(path)"
            }
            
        case "mkdir":
            if path == ".." {
                errorMessage = "Invalid directory name: .."
            } else if let (parent, dirname) = parsePath(path) {
                // Check if the final component is ".."
                if dirname == ".." {
                    errorMessage = "Invalid directory name: .."
                } else if parent.getChild(named: dirname) != nil {
                    errorMessage = "Directory already exists: \(path)"
                } else {
                    parent.mkdir(dirname)
                }
            } else {
                errorMessage = "Invalid path: \(path)"
            }
            
        case "rm":
            if path == ".." {
                errorMessage = "Cannot remove directory: .."
            } else if let (parent, name) = parsePath(path) {
                // Check if trying to remove ".."
                if name == ".." {
                    errorMessage = "Cannot remove directory: .."
                } else if parent.getChild(named: name) != nil {
                    parent.rm(name)
                } else {
                    errorMessage = "No such file or directory: \(path)"
                }
            } else {
                errorMessage = "Invalid path: \(path)"
            }
            
        default:
            break
        }
        
        addToCommandHistory(realCommand, oldRealDir)
        updateTreeText()
        resetCommandState()
    }
    
    private func addToCommandHistory(_ command: String, _ file: File?) {
        commandHistory.append(Command(path: getCurrentPath(file: file), command: command, error: errorMessage ?? nil))
        if commandHistory.count > 20 {
            commandHistory.removeFirst()
        }
        errorMessage = nil
    }
    
    private func updateTreeText() {
        treeText = generateTreeText(for: root)
    }
    
    private func generateTreeText(for file: File, indent: String = "") -> String {
        var lines = [indent + (file.isDirectory ? "📂" : "📄") + " " + file.name]
        
        if let children = file.children {
            lines.append(contentsOf: children.map { generateTreeText(for: $0, indent: indent + "  ") })
        }
        
        return lines.joined(separator: "\n")
    }
}

