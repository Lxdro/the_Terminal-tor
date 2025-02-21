import SwiftUI

struct Level6View: View {
    // MARK: - State
    @StateObject private var town = File(name: "town", isDirectory: true)
    @State private var currentDirectory: File?
    @State private var selectedCommand: String?
    @State private var commandHistory: [Command] = []
    @State private var realCommand: String = ""
    @State private var realDirectory: File?
    @State private var errorMessage: String? = nil
    @State private var commandCount: Int = 0
    @State private var isLevelComplete: Bool = false
    
    @State private var historyIndex: Int? = nil
    
    @FocusState private var isFocused: Bool
    @State private var treeText: String = ""
    
    @State var welcomeMessage =
    """
    Welcome to the Terminal-tor
    Write yourself commands to solve the level!
    
    """
    
    @State private var expectedStructure: File? = nil
    
    private let username = UserDefaults.standard.string(forKey: "username") ?? "user"
    private let commands = ["cd", "ls", "mkdir", "cp", "mv", "rm", "clear"]
    
    @Binding var selectedLevel: Int
    @State private var showCompletion = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 50) {
            HStack(spacing: 0) {
                GeometryReader { proxy in
                    VStack(spacing: 0) {
                        instructions
                            .frame(height: proxy.size.height * (1/3))
                        
                        fileTreeView
                            .frame(height: proxy.size.height * (2/3))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                ttyView
            }
            .frame(height: UIScreen.main.bounds.height / 2)
            
            VStack(spacing: 50) {
                HStack {
                    Text("$")
                        .font(.custom("Glass_TTY_VT220", size: 18))
                        .foregroundColor(.red)
                    TextField("> Enter command", text: $realCommand)
                        .font(.custom("Glass_TTY_VT220", size: 18))
                        .foregroundColor(TTYColors.text)
                        .background(TTYColors.terminalBlack)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isFocused)
                        .onSubmit {
                            executeCommand()
                            commandCount += 1
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
        .padding()
        .onAppear(perform: initializeView)
        .sheet(isPresented: $showCompletion) {
            LevelCompletionView(selectedLevel: $selectedLevel)
        }
        
    }
    
    private var instructions: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Instructions: make a good garden")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            
            ScrollView {
                Text("""
                     Firstly, clean everything from your house, then build a garden!
                     Pick some flower and some trees from the nature around your house to fill your garden.
                     """)
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
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.leading)
    }
    
    private var actionButtons: some View {
        HStack {
            Spacer()
            ActionButton(title: "Restart", baseColor: .red) {
                restartLevel()
            }
            Spacer()
            Spacer()
            ActionButton(title: "Clear", baseColor: .white) {
                commandHistory = []
                welcomeMessage = ""
            }
            Spacer()
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
        town.children?.removeAll()
        currentDirectory = town
        realDirectory = town
        
        // Reset game state
        commandCount = 0
        isLevelComplete = false
        commandHistory = []
        
        initializeView()
        
        // Reset command state
        //resetCommandState()
        welcomeMessage = """
    Welcome to the Terminal-tor
    Write yourself commands to solve the level!
    
    """
    }
    
    private func parsePath(_ path: String) -> [String] {
        // Handle empty path
        guard !path.isEmpty else { return [] }
        
        // Split path into components
        let components = path.split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
        
        return components
    }
    
    private func parsePath2(_ path: String) -> (File, String)? {
        
        var currentFile = path.hasPrefix("/") ? town : (realDirectory ?? town)
        var components = path.split(separator: "/")
        if path.hasPrefix("/") {
            components.removeFirst()
        }
        
        if components.isEmpty && path.hasPrefix("/") {
            return (town, "")
        }
        
        let targetName = String(components.removeLast())
        
        for component in components {
            let name = String(component)
            
            if name == ".." {
                currentFile = currentFile.parent ?? town
                continue
            }
            
            guard let nextDir = currentFile.cd(name) else {
                return nil
            }
            
            guard nextDir.isDirectory else {
                return nil
            }
            
            currentFile = nextDir
        }
        return (currentFile, targetName)
    }
    
    private func resolvePath(_ path: String, from currentDir: File) -> File? {
        // Handle absolute vs relative paths
        let components = parsePath(path)
        var currentFile: File = path.hasPrefix("/") ? town : currentDir
        
        for component in components {
            switch component {
            case "..":
                currentFile = currentFile.parent ?? currentFile
            case ".":
                continue
            default:
                guard let nextFile = currentFile.children?.first(where: { file in
                    file.name == component
                }) else {
                    return nil
                }
                currentFile = nextFile
            }
        }
        
        return currentFile
    }
    
    // MARK: - Command Processing
    
    private func executeCommand() {
        let components = realCommand.trimmingCharacters(in: .whitespaces).split(separator: " ")
        guard !components.isEmpty else {
            setError("Please enter a command")
            return
        }
        
        let command = String(components[0])
        let args: [String] = components.dropFirst().map(String.init)
        
        guard commands.contains(command) else {
            setError("Unknown command: \(command)")
            return
        }
        
        switch command {
        case "clear":
            commandHistory = []
            welcomeMessage = ""
        case "ls":
            executeLsCommand(args: args)
        case "cd":
            executeCdCommand(args: args)
        case "mv":
            executeMvCp()
        case "cp":
            executeMvCp()
        case "mkdir":
            executeMkdirTouchRm(command: command)
        case "touch":
            executeMkdirTouchRm(command: command)
        case "rm":
            executeMkdirTouchRm(command: command)
        default:
            setError("Command not found: \(command)")
        }
        
        realCommand = ""
    }
    
    private func inputPath() -> String {
        let components = realCommand.split(separator: " ", maxSplits: 1)
        if components.count > 1 {
            return String(components[1])
        }
        return ""
    }
    
    private func resetCommandState() {
        realCommand = ""
    }
    
    private func executeMkdirTouchRm(command: String) {
        let oldRealDir = realDirectory
        
        let path = inputPath()
        
        switch command {
        case "cd":
            if path.isEmpty || path == "/" {
                currentDirectory = town
                realDirectory = town
            } else {
                // Special case for "cd .."
                if path == ".." {
                    currentDirectory = (realDirectory ?? town).parent ?? town
                    realDirectory = currentDirectory
                } else {
                    // For cd with path
                    if let (parent, dirname) = parsePath2(path) {
                        if dirname == ".." {
                            currentDirectory = parent.parent ?? town
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
            } else if let (parent, filename) = parsePath2(path) {
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
            } else if let (parent, dirname) = parsePath2(path) {
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
            } else if let (parent, name) = parsePath2(path) {
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
        
        addToHistory(command: realCommand, file: oldRealDir)
        updateTreeText()
        resetCommandState()
    }
    
    private func executeMvCp() {
        let components = realCommand.split(separator: " ")
        guard components.count == 3 else {
            errorMessage = "Error: Both source and destination paths are required"
            addToHistory(command: realCommand, file: realDirectory)
            return
        }
        
        let command = String(components[0])
        let sourcePath = String(components[1])
        let destPath = String(components[2])
        
        guard let (sourceParent, sourceFileName) = parsePath2(sourcePath) else {
            errorMessage = "Error: Invalid source path"
            addToHistory(command: realCommand, file: realDirectory)
            return
        }
        
        guard let sourceFile = sourceParent.getChild(named: sourceFileName) else {
            errorMessage = "Error: Source file not found"
            addToHistory(command: realCommand, file: realDirectory)
            return
        }
        
        guard let (destParent, destFileName) = parsePath2(destPath) else {
            errorMessage = "Error: Invalid destination path"
            addToHistory(command: realCommand, file: realDirectory)
            return
        }
        
        if let existingDest = destParent.getChild(named: destFileName) {
            if existingDest.isDirectory {
                let actualDestParent = existingDest
                let actualDestFileName = sourceFile.name
                
                executeFileOperation(command: command, sourceFile: sourceFile, 
                                     destParent: actualDestParent, destFileName: actualDestFileName)
            } else {
                errorMessage = "Error: Destination already exists and is not a directory"
                addToHistory(command: realCommand, file: realDirectory)
                return
            }
        } else {
            executeFileOperation(command: command, sourceFile: sourceFile, 
                                 destParent: destParent, destFileName: destFileName)
        }
        
        addToHistory(command: realCommand, file: realDirectory)
        updateTreeText()
        resetCommandState()
    }
    
    private func executeFileOperation(command: String, sourceFile: File, destParent: File, destFileName: String) {
        switch command {
        case "mv":
            if let oldParent = sourceFile.parent {
                oldParent.children?.removeAll(where: { file in
                    file.name == sourceFile.name
                })
            }
            
            let newFile = File(name: destFileName, isDirectory: sourceFile.isDirectory)
            newFile.children = sourceFile.children
            newFile.children?.forEach { $0.parent = newFile }
            
            newFile.parent = destParent
            destParent.setChild(newFile)
            
        case "cp":
            let newFile = File(name: destFileName, isDirectory: sourceFile.isDirectory)
            if let sourceChildren = sourceFile.children {
                newFile.children = sourceChildren.map { childFile in
                    let copiedChild = File(name: childFile.name, isDirectory: childFile.isDirectory)
                    copiedChild.children = childFile.children
                    copiedChild.parent = newFile
                    return copiedChild
                }
            }
            
            newFile.parent = destParent
            destParent.setChild(newFile)
            
        default:
            errorMessage = "Error: Unknown command"
        }
    }
    
    private func executeLsCommand(args: [String]) {
        guard let currentDir = realDirectory else {
            setError("No current directory")
            return
        }
        
        // Handle path argument if provided
        let targetDir: File
        if let path = args.first {
            if let resolved = resolvePath(path, from: currentDir) {
                targetDir = resolved
            } else {
                setError("ls: no such file or directory: \(path)")
                return
            }
        } else {
            targetDir = currentDir
        }
        
        let output = targetDir.ls(nil) // We're not passing the path here since we've already resolved it
        
        /*
         if output.isEmpty {
         setError("No such file or directory")
         return
         }*/
        
        addToHistory(command: "ls " + args.joined(separator: " "), output: output)
    }
    
    private func executeCdCommand(args: [String]) {
        guard let currentDir = realDirectory else {
            setError("No current directory")
            return
        }
        
        if args.isEmpty {
            currentDirectory = realDirectory
            realDirectory = town
            addToHistory(command: "cd")
            currentDirectory = realDirectory
            return
        }
        
        guard args.count == 1 else {
            setError("cd: wrong number of arguments")
            return
        }
        
        let path = args[0]
        if let newDir = resolvePath(path, from: currentDir) {
            if newDir.isDirectory {
                currentDirectory = realDirectory
                realDirectory = newDir
                addToHistory(command: "cd " + path)
                currentDirectory = realDirectory
            } else {
                setError("cd: not a directory: \(path)")
            }
        } else {
            setError("cd: no such directory: \(path)")
        }
    }
    
    private func setError(_ message: String) {
        errorMessage = message
        addToHistory(command: realCommand, error: message)
    }
    
    private func addToHistory(command: String, file: File? = nil, output: String? = nil, error: String? = nil) {
        let f = file == nil ? currentDirectory : file
        let newCommand = Command(
            path: getCurrentPath(file: f),
            command: command,
            error: error ?? errorMessage,
            output: output
        )
        commandHistory.append(newCommand)
        errorMessage = nil
    }
    
    // MARK: - Helper Functions
    
    private func getCurrentPath(file: File?) -> String {
        var path = [String]()
        var currentFile: File? = file
        
        while let dir = currentFile {
            path.insert(dir.name, at: 0)
            currentFile = dir.parent
        }
        
        return "/" + path.joined(separator: "/")
    }
    
    private func checkLevelCompletion() {
        if town.equals(expectedStructure!) {
            isLevelComplete = true
            showCompletion = true
        }
    }
    
    private func updateTreeText() {
        treeText = generateTreeText(for: town)
    }
    
    private func generateTreeText(for file: File, indent: String = "") -> String {
        var lines = [indent + (file.isDirectory ? "📂" : "📄") + " " + file.name]
        
        if let children = file.children {
            lines.append(contentsOf: children.map { generateTreeText(for: $0, indent: indent + "  ") })
        }
        
        return lines.joined(separator: "\n")
    }
    
    private var ttyView: some View {
        TTYView(
            isRed: true,
            commandHistory: commandHistory,
            username: username,
            currentPath: getCurrentPath(file: realDirectory),
            currentCommand: realCommand,
            welcomeMessage: welcomeMessage
        )
        .frame(width: UIScreen.main.bounds.width / 1.8)
    }
    
    private func initializeView() {
        town.children?.removeAll()
        currentDirectory = town
        realDirectory = town
        
        // Creating directories under town
        let house = File(name: "house", isDirectory: true, parent: town)
        let forest = File(name: "forest", isDirectory: true, parent: town)
        let field = File(name: "field", isDirectory: true, parent: town)
        
        // Creating directories inside house
        let gardenShed = File(name: "gardenshed", isDirectory: true, parent: house)
        let brokenPot = File(name: "brokenpot", isDirectory: false, parent: gardenShed)
        let rustyRake = File(name: "rustyrake", isDirectory: false, parent: gardenShed)
        let oldWheelbarrow = File(name: "oldwheelbarrow", isDirectory: false, parent: gardenShed)
        
        gardenShed.children = [brokenPot, oldWheelbarrow, rustyRake]
        house.children = [gardenShed]
        
        let oak = File(name: "oak", isDirectory: false, parent: forest)
        let pine = File(name: "pine", isDirectory: false, parent: forest)
        let birch = File(name: "birch", isDirectory: false, parent: forest)
        
        let rose = File(name: "rose", isDirectory: false, parent: field)
        let tulip = File(name: "tulip", isDirectory: false, parent: field)
        let daisy = File(name: "daisy", isDirectory: false, parent: field)
        
        forest.children = [birch, oak, pine]
        field.children = [daisy, rose, tulip]
        town.children = [field, forest, house]
        
        updateTreeText()
    }
    
    private func initializeGoal() {
        let goal = File(name: "town", isDirectory: true, parent: nil)
        
        let goalHouse = File(name: "house", isDirectory: true, parent: goal)
        let goalForest = File(name: "forest", isDirectory: true, parent: goal)
        let goalField = File(name: "field", isDirectory: true, parent: goal)
        
        let goalGarden = File(name: "garden", isDirectory: true, parent: goalHouse)
        
        let oak = File(name: "oak", isDirectory: false, parent: goalGarden)
        let pine = File(name: "pine", isDirectory: false, parent: goalGarden)
        let birch = File(name: "birch", isDirectory: false, parent: goalGarden)
        let rose = File(name: "rose", isDirectory: false, parent: goalGarden)
        let tulip = File(name: "tulip", isDirectory: false, parent: goalGarden)
        let daisy = File(name: "daisy", isDirectory: false, parent: goalGarden)
        
        goalGarden.children = [birch, daisy, oak, pine, rose, tulip]
        goalHouse.children = [goalGarden]
        
        goalForest.children = [
            File(name: "birch", isDirectory: false, parent: goalForest),
            File(name: "oak", isDirectory: false, parent: goalForest),
            File(name: "pine", isDirectory: false, parent: goalForest)
        ]
        
        goalField.children = [
            File(name: "daisy", isDirectory: false, parent: goalField),
            File(name: "rose", isDirectory: false, parent: goalField),
            File(name: "tulip", isDirectory: false, parent: goalField)
        ]
        
        goal.children = [goalField, goalForest, goalHouse]
        
        expectedStructure = goal
    }
}
