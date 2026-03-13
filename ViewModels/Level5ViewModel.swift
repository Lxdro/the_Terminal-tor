import Foundation
import SwiftUI
import Combine

class Level5ViewModel: LevelViewModel {
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
    let hasTextField: Bool = true
    let isRedTTY: Bool = false
    
    let commands = ["cd", "ls", "mkdir", "cp", "mv", "rm", "clear"]
    let fileOptions: [FileOption] = []
    
    let instructionTitle = "Instructions: make a good garden"
    let instructionText = """
    Firstly, clean everything from your house, then build a garden!
    Pick (cp) some flower and some trees from the nature around your house to fill your garden.
    """
    
    let hasTreeView = true
    let treeTitle = "Current File System"
    @Published var treeText = ""
    private var expectedStructure: File!
    
    private var timer: Timer? = nil
    
    var currentPath: String {
        engine.getCurrentPath(file: engine.currentDirectory)
    }
    
    init() {
        let town = File(name: "town", isDirectory: true)
        self.engine = TerminalEngine(root: town)
    }
    
    func initializeView() {
        let town = engine.root
        town.children?.removeAll()
        engine.currentDirectory = town
        engine.realDirectory = town
        
        let house = File(name: "house", isDirectory: true, parent: town)
        let forest = File(name: "forest", isDirectory: true, parent: town)
        let field = File(name: "field", isDirectory: true, parent: town)
        
        let gardenShed = File(name: "wasteland", isDirectory: true, parent: house)
        let brokenPot = File(name: "brokenpot", isDirectory: false, parent: gardenShed)
        let rustyRake = File(name: "rustyrake", isDirectory: false, parent: gardenShed)
        let oldWheelbarrow = File(name: "oldwheelbarrow", isDirectory: false, parent: gardenShed)
        
        gardenShed.children = [brokenPot, oldWheelbarrow, rustyRake]
        house.children = [gardenShed]
        
        let oak = File(name: "oak", isDirectory: false, parent: forest)
        let pine = File(name: "pine", isDirectory: false, parent: forest)
        
        let tulip = File(name: "tulip", isDirectory: false, parent: field)
        let daisy = File(name: "daisy", isDirectory: false, parent: field)
        
        forest.children = [oak, pine]
        field.children = [daisy, tulip]
        town.children = [field, forest, house]
        
        updateTreeText()
        expectedStructure = initializeGoal()
        
        welcomeMessage = """
        Welcome to the Terminal-tor
        Write yourself commands to solve the level!
        
        """
    }
    
    private func initializeGoal() -> File {
        let goal = File(name: "town", isDirectory: true, parent: nil)
        
        let goalHouse = File(name: "house", isDirectory: true, parent: goal)
        let goalForest = File(name: "forest", isDirectory: true, parent: goal)
        let goalField = File(name: "field", isDirectory: true, parent: goal)
        
        let goalGarden = File(name: "garden", isDirectory: true, parent: goalHouse)
        
        let oak = File(name: "oak", isDirectory: false, parent: goalGarden)
        let pine = File(name: "pine", isDirectory: false, parent: goalGarden)
        let tulip = File(name: "tulip", isDirectory: false, parent: goalGarden)
        let daisy = File(name: "daisy", isDirectory: false, parent: goalGarden)
        
        goalGarden.children = [daisy, oak, pine, tulip]
        goalHouse.children = [goalGarden]
        
        goalForest.children = [
            File(name: "oak", isDirectory: false, parent: goalForest),
            File(name: "pine", isDirectory: false, parent: goalForest)
        ]
        
        goalField.children = [
            File(name: "daisy", isDirectory: false, parent: goalField),
            File(name: "tulip", isDirectory: false, parent: goalField)
        ]
        
        goal.children = [goalField, goalForest, goalHouse]
        return goal
    }
    
    func restartLevel() {
        stopTimer()
        commandCount = 0
        isLevelComplete = false
        commandHistory = []
        resetCommandState()
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
        checkLevelCompletion()
    }
    
    private func executeCommand() {
        let cmdPath = engine.getCurrentPath(file: engine.currentDirectory)
        let components = realCommand.trimmingCharacters(in: .whitespaces).split(separator: " ")
        guard !components.isEmpty else {
            setError("Please enter a command", path: cmdPath)
            return
        }
        
        let command = String(components[0])
        let args: [String] = components.dropFirst().map(String.init)
        
        guard commands.contains(command) else {
            setError("Unknown command: \(command)", path: cmdPath)
            return
        }
        
        switch command {
        case "clear":
            commandHistory = []
            welcomeMessage = ""
        case "ls":
            if let output = engine.executeLsCommand(args: args) {
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
        case "mv", "cp":
            guard args.count == 2 else {
                setError("Error: Both source and destination paths are required", path: cmdPath)
                realCommand = ""
                return
            }
            engine.executeMvCp(command: command, sourcePath: args[0], destPath: args[1])
            if let error = engine.errorMessage {
                addToHistory(command: realCommand, error: error, path: cmdPath)
            } else {
                addToHistory(command: realCommand, path: cmdPath)
            }
        case "mkdir", "touch", "rm":
            let pathStr = inputPath()
            engine.executeMkdirTouchRm(command: command, path: pathStr, currentDirectoryState: &engine.currentDirectory)
            if let error = engine.errorMessage {
                addToHistory(command: realCommand, error: error, path: cmdPath)
            } else {
                addToHistory(command: realCommand, path: cmdPath)
            }
        default:
            setError("Command not found: \(command)", path: cmdPath)
        }
        
        updateTreeText()
        realCommand = ""
    }
    
    private func inputPath() -> String {
        let components = realCommand.split(separator: " ", maxSplits: 1)
        if components.count > 1 {
            return String(components[1])
        }
        return ""
    }
    
    private func checkLevelCompletion() {
        if engine.root.equals(expectedStructure) {
            stopTimer()
            isLevelComplete = true
            showCompletion = true
        }
    }
    
    private func updateTreeText() {
        treeText = engine.generateTreeText(for: engine.root)
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
    
    func selectCommand(_ command: String) {}
    func isFileSelectable(_ option: FileOption) -> Bool { return false }
    func handleFileSelection(_ option: FileOption) {}
    func resetCommandState() {
        realCommand = ""
    }
}
