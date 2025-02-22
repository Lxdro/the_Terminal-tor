import SwiftUI

struct Level1View: View {
    // MARK: - State
    @StateObject private var room = File(name: "room", isDirectory: true)
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
    private let commands = ["touch", "mkdir", "rm"]
    private let fileOptions = [
        FileOption(emoji: "🔙", name: ".."),
        FileOption(emoji: "📦", name: "Box"),
        FileOption(emoji: "🧸", name: "TeddyBear"),
        FileOption(emoji: "🚂", name: "Train"),
        FileOption(emoji: "🪁", name: "Kite")
    ]
    
    // Expected file structure for the level
    @State private var expectedStructure: File? = nil
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack {
                    instructions
                    fileTreeView
                }
                ttyView
            }
            .frame(height: UIScreen.main.bounds.height / 2.5)
            commandSection
        }
        //.background(TTYColors.terminalBlack)
        .onAppear(perform: initializeView)
        .sheet(isPresented: $showCompletion) {
            LevelCompletionView(selectedLevel: $selectedLevel)
        }
        
    }
    
    private var instructions: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Instructions: tidy up your room")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            
            ScrollView {
                Text("""
                     Now, you can see how your File System look like!
                     You can't use cd nor ls anymore, you'll probably need to use about path then.
                     
                     • Create a box.
                     • Remove toys that are outisde of the box
                     • Put your toys inside it
                     • Your TeddyBear should be inside another box inside the first one, he will feel more secure in this position
                     
                     Hint: you can click on multiple file buttons.
                     """)
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
    
    private var fileTreeView: some View {
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
        .background(Color.gray.opacity(0.2))
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
        .frame(width: UIScreen.main.bounds.width / 1.8)
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
            //Spacer()
            //ActionButton(title: "Restart", baseColor: .red) {
            //    restartLevel()
            //}

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
        room.children?.removeAll()
        currentDirectory = room
        realDirectory = room
        
        // Reset game state
        commandCount = 0
        isLevelComplete = false
        commandHistory = []
        
        // Reset command state
        resetCommandState()
        
        // Update views
        updateTreeText()
        welcomeMessage = """
    Welcome to Terminal-tor
    Press buttons to make real commands!
    
    """
    }
    
    private func checkLevelCompletion() {
        if room.equals(expectedStructure!) {
            isLevelComplete = true
            showCompletion = true
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
    
    private func selectCommand(_ command: String) {
        selectedCommand = command
        realCommand = "\(command) "
        selectedFiles = []
    }
    
    private func isFileSelectable(_ option: FileOption) -> Bool {
        let currentDir = currentDirectory ?? room
        return currentDir.isFileSelectable(name: option.name, forCommand: selectedCommand)
    }
    
    private func handleFileSelection(_ option: FileOption) {
        //guard isFileSelectable(option) else { return }
        
        //let currentDir = currentDirectory ?? room
        
        /*
        // Handle directory navigation for cd
        if selectedCommand == "cd" {
            if option.name == ".." {
                currentDirectory = currentDirectory!.parent ?? room
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
        var currentFile = path.hasPrefix("/") ? room : (realDirectory ?? room)
        var components = path.split(separator: "/")
        
        // If path starts with /, remove empty first component
        if path.hasPrefix("/") {
            components.removeFirst()
        }
        
        // Handle special case where path is just "/"
        if components.isEmpty && path.hasPrefix("/") {
            return (room, "")
        }
        
        // Get the file/directory name (last component)
        let targetName = String(components.removeLast())
        
        // Traverse the path
        for component in components {
            let name = String(component)
            
            // Handle ".." navigation
            if name == ".." {
                currentFile = currentFile.parent ?? room
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
                realDirectory = room
                currentDirectory = room
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
                currentDirectory = room
                realDirectory = room
            } else {
                // Special case for "cd .."
                if path == ".." {
                    currentDirectory = (realDirectory ?? room).parent ?? room
                    realDirectory = currentDirectory
                } else {
                    // For cd with path
                    if let (parent, dirname) = parsePath(path) {
                        if dirname == ".." {
                            currentDirectory = parent.parent ?? room
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
        treeText = generateTreeText(for: room)
    }
    
    private func generateTreeText(for file: File, indent: String = "") -> String {
        var lines = [indent + (file.isDirectory ? "📂" : "📄") + " " + file.name]
        
        if let children = file.children {
            lines.append(contentsOf: children.map { generateTreeText(for: $0, indent: indent + "  ") })
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func initializeView() {
        room.children?.removeAll()
        currentDirectory = room
        realDirectory = room
        
        // Initial files
        let teddyBear = File(name: "TeddyBear", isDirectory: false, parent: room)
        let kite = File(name: "Kite", isDirectory: false, parent: room)
        let train = File(name: "Train", isDirectory: false, parent: room)
        
        room.children = [teddyBear, kite, train]
        updateTreeText()
        expectedStructure = initializeGoal()
    }
    
    private func initializeGoal() -> File {
        let goalRoot = File(name: "room", isDirectory: true, parent: nil)
        let box1 = File(name: "Box", isDirectory: true, parent: goalRoot)
        let train = File(name: "Train", isDirectory: false, parent: box1)
        let kite = File(name: "Kite", isDirectory: false, parent: box1)
        let box2 = File(name: "Box", isDirectory: true, parent: box1)
        let teddyBear = File(name: "TeddyBear", isDirectory: false, parent: box2)
        
        box1.children = [train, kite, box2]
        box2.children = [teddyBear]
        goalRoot.children = [box1]
        
        return goalRoot
    }
}

