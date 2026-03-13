import Foundation
import Combine

class Level1ViewModel: LevelViewModel {
    @Published var commandCount: Int = 0
    @Published var timeElapsed: Int = 0
    @Published var isLevelComplete: Bool = false
    @Published var showCompletion: Bool = false
    @Published var welcomeMessage: String = ""
    
    @Published var commandHistory: [Command] = []
    @Published var realCommand: String = ""
    @Published var selectedCommand: String? = nil
    @Published var selectedFiles: [String] = []
    
    // Engine
    private var engine: TerminalEngine
    var realDirectory: File? { engine.realDirectory }
    
    let hasTimer: Bool = true
    let hasTextField: Bool = false
    let isRedTTY: Bool = false
    
    let commands = ["cd", "ls", "here"]
    
    let fileOptions = [
        FileOption(emoji: "🔙", name: ".."),
        FileOption(emoji: "⬆️", name: "up"),
        FileOption(emoji: "⬇️", name: "down"),
        FileOption(emoji: "➡️", name: "right"),
        FileOption(emoji: "⬅️", name: "left")
    ]
    
    let instructionTitle = "Instructions: find TeddyBear"
    let instructionText = """
    Oh no! You've lost your TeddyBear in a vast field of tall grass!  
    Use commands to search through each patch of grass and find it.
    
    \"here\" is a special command for this level — once you've found your TeddyBear, use it to pick it up. 
    
    For every level:
       • Help tab is your best friend
       • Remember to clear your terminal when it gets too cluttered!
    """
    
    let hasTreeView = false
    let treeTitle = ""
    let treeText = ""
    
    private var timer: Timer? = nil
    
    var currentPath: String {
        engine.getCurrentPath(file: engine.currentDirectory)
    }
    
    init() {
        let root = File(name: "root", isDirectory: true)
        self.engine = TerminalEngine(root: root)
    }
    
    func initializeView() {
        let root = engine.root
        root.children?.removeAll()
        engine.currentDirectory = root
        engine.realDirectory = root
        
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
        if let randomParent = possibleParents.randomElement() {
            let teddyBear = File(name: "TeddyBear", isDirectory: false, parent: randomParent)
            randomParent.children?.append(teddyBear)
        }
        
        welcomeMessage = """
        Welcome to the Terminal-tor
        Press buttons to make real commands!
        
        """
    }
    
    func restartLevel() {
        stopTimer()
        commandCount = 0
        isLevelComplete = false
        commandHistory = []
        initializeView()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func executeWrapped() {
        if timer == nil {
            timeElapsed = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.timeElapsed += 1
            }
        }
        executeCommand()
        commandCount += 1
        realCommand = ""
        selectedCommand = nil
    }
    
    private func executeCommand() {
        let cmdPath = engine.getCurrentPath(file: engine.currentDirectory)
        let components = realCommand.trimmingCharacters(in: .whitespaces).split(separator: " ")
        guard !components.isEmpty else {
            setError("Please enter a command", path: cmdPath)
            return
        }
        
        let command = String(components[0])
        let args = components.dropFirst().map(String.init)
        
        guard commands.contains(command) else {
            setError("Unknown command: \(command)", path: cmdPath)
            return
        }
        
        switch command {
        case "ls":
            if let output = engine.executeLsCommand(args: args) {
                engine.currentDirectory = engine.realDirectory
                addToHistory(command: "ls " + args.joined(separator: " "), output: output, path: cmdPath)
            } else if let error = engine.errorMessage {
                setError(error, path: cmdPath)
            }
        case "cd":
            engine.executeCdCommand(args: args, currentDirectoryState: &engine.currentDirectory)
            if let error = engine.errorMessage {
                setError(error, path: cmdPath)
            } else {
                addToHistory(command: args.isEmpty ? "cd" : "cd " + args[0], path: cmdPath)
            }
        case "here":
            checkAnswer(args: args, path: cmdPath)
        default:
            setError("Command not implemented: \(command)", path: cmdPath)
        }
    }
    
    private func checkAnswer(args: [String], path: String) {
        if !args.isEmpty {
            setError("\"here\" doesn't take any argument.", path: path)
        } else if let currentRealDir = engine.realDirectory, currentRealDir.hasFile(named: "TeddyBear") {
            stopTimer()
            isLevelComplete = true
            showCompletion = true
        } else {
            setError("No TeddyBear here... seek before saying you saw him!", path: path)
        }
    }
    
    private func setError(_ message: String, path: String) {
        addToHistory(command: realCommand, error: message, path: path)
    }
    
    private func addToHistory(command: String, output: String? = nil, error: String? = nil, path: String) {
        let newCommand = Command(
            path: path,
            command: command,
            error: error,
            output: output
        )
        commandHistory.append(newCommand)
    }
    
    func selectCommand(_ command: String) {
        selectedCommand = command
        realCommand = "\(command) "
        selectedFiles = []
    }
    
    func isFileSelectable(_ option: FileOption) -> Bool {
        let currentDir = engine.currentDirectory ?? engine.root
        return currentDir.isFileSelectable(name: option.name, forCommand: selectedCommand)
    }
    
    func handleFileSelection(_ option: FileOption) {
        if selectedFiles.isEmpty {
            realCommand += option.name
        } else {
            realCommand += "/\(option.name)"
        }
        selectedFiles.append(option.name)
    }
    
    func resetCommandState() {
        realCommand = ""
        selectedCommand = nil
        selectedFiles = []
    }
}
