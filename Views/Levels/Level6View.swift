import SwiftUI

struct Level6View: View {
    @State private var factory = File(name: "factory", isDirectory: true)
    @State private var currentDirectory: File?
    @State private var selectedCommand: String?
    @State private var commandHistory: [Command] = []
    @State private var realCommand: String = ""
    @State private var realDirectory: File?
    @State private var errorMessage: String? = nil
    @State private var commandCount: Int = 0
    @State private var isLevelComplete: Bool = false
    @State private var oldDirectory: File?
    @State private var historyIndex: Int? = nil
    
    @FocusState private var isFocused: Bool
    @State private var treeText: String = ""
    
    @State var welcomeMessage =
    """
    say Welcome to the Terminal-tor
    Write yourself commands to save your life!
    
    """
    
    @State private var hitCount: Int = 0
    @State private var phase = 0
    
    @State private var expectedStructure: File = File(name: "door", isDirectory: true)
    
    private let username = UserDefaults.standard.string(forKey: "username") ?? "user"
    private let commands = ["cd", "ls", "touch", "mkdir", "cp", "mv", "rm", "clear"]
    
    @State private var timeElapsed: Int = 0
    @State private var timer: Timer? = nil
    @State private var timeDifficulty = 13
    
    @Binding var selectedLevel: Int
    @State private var showCompletion = false
    
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
                        .foregroundColor(TTYColors.red)
                    TextField("> Enter command", text: $realCommand)
                        .font(.custom("Glass_TTY_VT220", size: 18))
                        .foregroundColor(TTYColors.red)
                        .background(TTYColors.terminalBlack)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused($isFocused)
                        .disabled(hitCount == 3)
                        .tint(TTYColors.red)
                        .onSubmit {
                            executeWrapped()
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
            LevelCompletionView(selectedLevel: $selectedLevel, commandCount: commandCount, timeElapsed: timeElapsed)
        }
        
    }
    
    private var instructions: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Instructions: Run Sarah!")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            
            ScrollView {
                Text("""
                     Beat the Terminal-tor...
                     Your structure should be the same as the expected one below.
                     Keep moving to doge Terminal-tor.
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
            Text("Expected File System")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            
            ScrollView {
                Text(generateTreeText(for: expectedStructure))
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
                executeWrapped()
            }
            Spacer()
        }
    }
    
    private func executeWrapped() {
        if timer == nil {
            timeElapsed = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                timeElapsed += 1
                checkTimeElapsed()
            }
        }
        executeCommand()
        commandCount += 1
        checkLevelCompletion()
    }
    
    private func checkTimeElapsed() {
        //print((oldDirectory?.name ?? "nil") + " " + (realDirectory?.name ?? "nil"))
        if timeElapsed > 0 && timeElapsed % timeDifficulty == 0 {
            if oldDirectory?.name == realDirectory?.name {
                if hitCount == 2 {
                    commandHistory = []
                    welcomeMessage = "The Terminal-tor killed you... Restart.\n"
                    realCommand = ""
                    hitCount += 1
                    stopTimer()
                } else {
                    commandHistory = []
                    welcomeMessage = "The Terminal-tor attacked! You got hit!\n"
                    realCommand = ""
                    hitCount += 1
                }
            } else {
                commandHistory = []
                welcomeMessage = "The Terminal-tor attacked! You dodged!\n"
                realCommand = ""
            }
            oldDirectory = realDirectory
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func restartLevel() {
        stopTimer()
        timer = nil
        timeElapsed = 0
        factory.children?.removeAll()
        currentDirectory = factory
        realDirectory = factory
        oldDirectory = factory
        
        commandCount = 0
        isLevelComplete = false
        commandHistory = []
        
        initializeView()
        
        //resetCommandState()
        welcomeMessage = """
    Welcome to the Terminal-tor
    Write yourself commands to solve the level!
    
    """
    }
    
    private func parsePath(_ path: String) -> [String] {
        guard !path.isEmpty else { return [] }
        
        let components = path.split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
        
        return components
    }
    
    private func parsePath2(_ path: String) -> (File, String)? {
        
        var currentFile = path.hasPrefix("/") ? factory : (realDirectory ?? factory)
        var components = path.split(separator: "/")
        if path.hasPrefix("/") {
            components.removeFirst()
        }
        
        if components.isEmpty && path.hasPrefix("/") {
            return (factory, "")
        }
        
        let targetName = String(components.removeLast())
        
        for component in components {
            let name = String(component)
            
            if name == ".." {
                currentFile = currentFile.parent ?? factory
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
        let components = parsePath(path)
        var currentFile: File = path.hasPrefix("/") ? factory : currentDir
        
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
                oldDirectory = oldRealDir
                currentDirectory = factory
                realDirectory = factory
            } else {
                if path == ".." {
                    oldDirectory = oldRealDir
                    currentDirectory = (realDirectory ?? factory).parent ?? factory
                    realDirectory = currentDirectory
                } else {
                    if let (parent, dirname) = parsePath2(path) {
                        if dirname == ".." {
                            oldDirectory = oldRealDir
                            currentDirectory = parent.parent ?? factory
                            realDirectory = currentDirectory
                        } else if let targetDir = parent.cd(dirname) {
                            oldDirectory = oldRealDir
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
            if phase == 2 {
                errorMessage = "Cannot remove him"
            }
            if path == ".." {
                errorMessage = "Cannot remove directory: .."
            } else if let (parent, name) = parsePath2(path) {
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
        
        let output = targetDir.ls(nil)
        
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
            oldDirectory = realDirectory
            currentDirectory = realDirectory
            realDirectory = factory
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
                oldDirectory = realDirectory
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
        if factory.equals(expectedStructure) {
            phase += 1
            if phase == 1 {
                timeDifficulty = 15
                commandHistory = []
                welcomeMessage = "Well done, blow the Termial-tor up!\n"
                initializePhase2()
            } else if phase == 2 {
                timeDifficulty = 20
                commandHistory = []
                welcomeMessage = "He can't walk anymore! Move the Terminal-tor inside the hydraulic press!\n"
                initializePhase3()
            } else if phase == 3 {
                stopTimer()
                isLevelComplete = true
                showCompletion = true
            }
        }
    }
    
    private func updateTreeText() {
        treeText = generateTreeText(for: factory)
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
        factory.children?.removeAll()
        currentDirectory = factory
        realDirectory = factory
        oldDirectory = realDirectory
        
        let door = File(name: "door", isDirectory: true, parent: factory)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        //let treadmill = File(name: "treadmill", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        factory.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let off1 = File(name: "off", isDirectory: false, parent: automatedRobots)
        let off2 = File(name: "off", isDirectory: false, parent: hydraulicPress)
        //let off3 = File(name: "off", isDirectory: false, parent: treadmill)
        
        automatedRobots.children = [off1]
        hydraulicPress.children = [off2]
        //treadmill.children = [off3]
        
        updateTreeText()
        initializeGoal()
    }
    
    private func initializeGoal() {
        let goal = File(name: "factory", isDirectory: true, parent: nil)
        
        let door = File(name: "door", isDirectory: true, parent: factory)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        //let treadmill = File(name: "treadmill", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        goal.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let on1 = File(name: "on", isDirectory: false, parent: automatedRobots)
        let on2 = File(name: "on", isDirectory: false, parent: hydraulicPress)
        //let on3 = File(name: "on", isDirectory: false, parent: treadmill)
        
        automatedRobots.children = [on1]
        hydraulicPress.children = [on2]
        //treadmill.children = [on3]
        
        let trap = File(name: "trap", isDirectory: true, parent: stairs)
        let pipeBomb = File(name: "pipeBomb", isDirectory: false, parent: trap)
        
        stairs.children = [trap]
        trap.children = [pipeBomb]
        updateTreeText()
        expectedStructure = goal
    }
    
    private func initializePhase2() {
        let goal = File(name: "factory", isDirectory: true, parent: nil)
        
        let door = File(name: "door", isDirectory: true, parent: factory)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        //let treadmill = File(name: "treadmill", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        goal.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let on1 = File(name: "on", isDirectory: false, parent: automatedRobots)
        let on2 = File(name: "on", isDirectory: false, parent: hydraulicPress)
        //let on3 = File(name: "on", isDirectory: false, parent: treadmill)
        
        automatedRobots.children = [on1]
        hydraulicPress.children = [on2]
        //treadmill.children = [on3]
        
        let trap = File(name: "trap", isDirectory: true, parent: stairs)
        let legs = File(name: "legs", isDirectory: false, parent: trap)
        
        stairs.children = [trap]
        trap.children = [legs]
        
        realDirectory = trap
        factory = goal
        updateTreeText()
        initializeGoal2()
    }
    
    private func initializeGoal2() {
        let goal = File(name: "factory", isDirectory: true, parent: nil)
        
        let door = File(name: "door", isDirectory: true, parent: factory)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        //let treadmill = File(name: "treadmill", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        goal.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let on1 = File(name: "on", isDirectory: false, parent: automatedRobots)
        let on2 = File(name: "on", isDirectory: false, parent: hydraulicPress)
        //let on3 = File(name: "on", isDirectory: false, parent: treadmill)
        
        automatedRobots.children = [on1]
        hydraulicPress.children = [on2]
        //treadmill.children = [on3]
        
        let trap = File(name: "trap", isDirectory: true, parent: stairs)
        
        stairs.children = [trap]
        trap.children = []
        updateTreeText()
        expectedStructure = goal
    }
    
    private func initializePhase3() {
        let goal = File(name: "factory", isDirectory: true, parent: nil)
        
        let door = File(name: "door", isDirectory: true, parent: factory)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        //let treadmill = File(name: "treadmill", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        goal.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let on1 = File(name: "on", isDirectory: false, parent: automatedRobots)
        let on2 = File(name: "on", isDirectory: false, parent: hydraulicPress)
        //let on3 = File(name: "on", isDirectory: false, parent: treadmill)
        
        automatedRobots.children = [on1]
        hydraulicPress.children = [on2]
        //treadmill.children = [on3]
        
        let trap = File(name: "trap", isDirectory: true, parent: stairs)
        let terminaltor = File(name: "Terminal-tor", isDirectory: false, parent: trap)
        
        stairs.children = [trap]
        trap.children = [terminaltor]
        
        realDirectory = trap
        factory = goal
        updateTreeText()
        initializeGoal3()
    }
    
    private func initializeGoal3() {
        let goal = File(name: "factory", isDirectory: true, parent: nil)
        
        let door = File(name: "door", isDirectory: true, parent: factory)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        //let treadmill = File(name: "treadmill", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        goal.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let on1 = File(name: "on", isDirectory: false, parent: automatedRobots)
        let on2 = File(name: "on", isDirectory: false, parent: hydraulicPress)
        let terminaltor = File(name: "Terminal-tor", isDirectory: false, parent: hydraulicPress)
        
        automatedRobots.children = [on1]
        hydraulicPress.children = [on2, terminaltor]
        //treadmill.children = [on3]
        
        let trap = File(name: "trap", isDirectory: true, parent: stairs)
        
        stairs.children = [trap]
        trap.children = []
        updateTreeText()
        expectedStructure = goal
    }
}
