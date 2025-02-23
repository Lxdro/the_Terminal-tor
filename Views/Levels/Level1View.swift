import SwiftUI

struct Level1View: View {
    @StateObject private var root = File(name: "root", isDirectory: true)
    
    @State private var currentDirectory: File?
    @State private var selectedCommand: String?
    @State private var selectedFiles: [String] = []
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
    
    @State private var timeElapsed: Int = 0
    @State private var timer: Timer? = nil
    
    private let username = UserDefaults.standard.string(forKey: "username") ?? "user"
    private let commands = ["cd", "ls", "here"]
    
    private let fileOptions = [
        FileOption(emoji: "🔙", name: ".."),
        FileOption(emoji: "⬆️", name: "up"),
        FileOption(emoji: "⬇️", name: "down"),
        FileOption(emoji: "➡️", name: "right"),
        FileOption(emoji: "⬅️", name: "left")
    ]
    
    
    @Binding var selectedLevel: Int
    @State private var showCompletion = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                VStack {
                    instructionView
                }
                ttyView
            }
            .frame(height: UIScreen.main.bounds.height / 2.5)
            
            commandSection
            
        }
        .onAppear(perform: initializeView)
        .sheet(isPresented: $showCompletion) {
            LevelCompletionView(selectedLevel: $selectedLevel, commandCount: commandCount, timeElapsed: timeElapsed)
        }
    }
    
    private func handleFileSelection(_ option: FileOption) {
        if selectedFiles.isEmpty {
            realCommand += option.name
        } else {
            realCommand += "/\(option.name)"
        }
        
        selectedFiles.append(option.name)
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
                isEnabled: selectedCommand != nil
            ) {
                if timer == nil {
                    timeElapsed = 0
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        timeElapsed += 1
                    }
                }
                executeCommand()
                commandCount += 1
                realCommand = ""
                selectedCommand = nil
            }
            Spacer()
        }
    }
    
    private func resetCommandState() {
        realCommand = ""
        selectedCommand = nil
        selectedFiles = []
    }
    
    private func restartLevel() {
        stopTimer()
        root.children?.removeAll()
        currentDirectory = root
        realDirectory = root
        
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
    
    private func resolvePath(_ path: String, from currentDir: File) -> File? {
        let components = parsePath(path)
        var currentFile: File = path.hasPrefix("/") ? root : currentDir
        
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
        let args = components.dropFirst().map(String.init)
        
        guard commands.contains(command) || command == "try" else {
            setError("Unknown command: \(command)")
            return
        }
        
        switch command {
        case "ls":
            executeLsCommand(args: args)
        case "cd":
            executeCdCommand(args: args)
        case "here":
            checkAnswer(args: args)
        default:
            setError("Command not implemented: \(command)")
        }
        
        //userCommand = ""
        realCommand = ""
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
        
        /*if output.isEmpty {
            setError("No such file or directory")
            return
        }*/
        
        currentDirectory = realDirectory
        addToHistory(command: "ls " + args.joined(separator: " "), output: output)
    }
    
    private func executeCdCommand(args: [String]) {
        guard let currentDir = realDirectory else {
            setError("No current directory")
            return
        }
        
        if args.isEmpty {
            currentDirectory = realDirectory
            realDirectory = root
            addToHistory(command: "cd")
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
    
    private func addToHistory(command: String, output: String? = nil, error: String? = nil) {
        let newCommand = Command(
            path: getCurrentPath(file: currentDirectory),
            command: command,
            error: error,
            output: output
        )
        commandHistory.append(newCommand)
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
    
    private func checkAnswer(args: [String]) {
        if !args.isEmpty {
            setError("\"here\" doesn't take any argument.")
        }
        else if realDirectory!.hasFile(named: "TeddyBear") {
            stopTimer()
            isLevelComplete = true
            showCompletion = true
        } else {
            setError("No TeddyBear here... seek before saying you saw him!")
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private var instructionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Instructions: find TeddyBear")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
            
            ScrollView {
                Text(
                     """
                     Oh no! You've lost your TeddyBear in a vast field of tall grass!  
                     Use commands to search through each patch of grass and find it.
                     
                     \"here\" is a special command for this level — once you've found your TeddyBear, use it to pick it up. 
                     
                     For every level:
                        • Help tab is your best friend
                        • Remember to clear your terminal when it gets too cluttered!
                     """
                )
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
        .shadow(radius: 2)
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
    }
    
    private func initializeView() {
        root.children?.removeAll()
        currentDirectory = root
        realDirectory = root
        
        let up = File(name: "up", isDirectory: true, parent: root)
        let down = File(name: "down", isDirectory: true, parent: root)
        let upLeft = File(name: "left", isDirectory: true, parent: up)
        let upRight = File(name: "right", isDirectory: true, parent: up)
        let downLeft = File(name: "left", isDirectory: true, parent: down)
        let downRight = File(name: "right", isDirectory: true, parent: down)
        
        up.children = [upLeft, upRight]
        down.children = [downLeft, downRight]
        root.children = [up, down]
        
        let possibleParents = [up, down, upLeft, upRight, downLeft, downRight]
        let randomParent = possibleParents.randomElement()!
        let teddyBear = File(name: "TeddyBear", isDirectory: false, parent: randomParent)
        randomParent.children?.append(teddyBear)
    }

}

