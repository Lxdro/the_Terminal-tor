import Foundation
import SwiftUI
import Combine

class Level6ViewModel: LevelViewModel {
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
    let isRedTTY: Bool = true
    
    let commands = ["cd", "ls", "touch", "mkdir", "cp", "mv", "rm", "clear"]
    let fileOptions: [FileOption] = []
    
    let instructionTitle = "Instructions: Run Sarah!"
    let instructionText = """
    Beat the Terminal-tor...
    Your structure should be the same as the expected one below.
    Keep moving to dodge Terminal-tor.
    """
    
    let hasTreeView = true
    let treeTitle = "Expected File System"
    @Published var treeText = ""
    
    @Published var hitCount: Int = 0
    private var phase = 0
    private var timeDifficulty = 13
    private var oldDirectory: File?
    
    private var expectedStructure: File!
    
    private var timer: Timer? = nil
    
    var currentPath: String {
        engine.getCurrentPath(file: engine.currentDirectory)
    }
    
    init() {
        let factory = File(name: "factory", isDirectory: true)
        self.engine = TerminalEngine(root: factory)
    }
    
    func initializeView() {
        hitCount = 0
        phase = 0
        timeDifficulty = 13
        
        let factory = engine.root
        factory.children?.removeAll()
        engine.currentDirectory = factory
        engine.realDirectory = factory
        oldDirectory = factory
        
        let door = File(name: "door", isDirectory: true, parent: factory)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        factory.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let off1 = File(name: "off", isDirectory: false, parent: automatedRobots)
        let off2 = File(name: "off", isDirectory: false, parent: hydraulicPress)
        
        automatedRobots.children = [off1]
        hydraulicPress.children = [off2]
        
        expectedStructure = initializeGoal()
        updateTreeText()
        
        welcomeMessage = """
        say Welcome to the Terminal-tor
        Write yourself commands to save your life!
        
        """
    }
    
    private func initializeGoal() -> File {
        let goal = File(name: "factory", isDirectory: true, parent: nil)
        
        let door = File(name: "door", isDirectory: true, parent: goal)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        goal.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let on1 = File(name: "on", isDirectory: false, parent: automatedRobots)
        let on2 = File(name: "on", isDirectory: false, parent: hydraulicPress)
        
        automatedRobots.children = [on1]
        hydraulicPress.children = [on2]
        
        let trap = File(name: "trap", isDirectory: true, parent: stairs)
        let pipeBomb = File(name: "pipeBomb", isDirectory: false, parent: trap)
        
        stairs.children = [trap]
        trap.children = [pipeBomb]
        return goal
    }
    
    private func initializePhase2() {
        let goal = File(name: "factory", isDirectory: true, parent: nil)
        
        let door = File(name: "door", isDirectory: true, parent: engine.root)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        goal.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let on1 = File(name: "on", isDirectory: false, parent: automatedRobots)
        let on2 = File(name: "on", isDirectory: false, parent: hydraulicPress)
        
        automatedRobots.children = [on1]
        hydraulicPress.children = [on2]
        
        let trap = File(name: "trap", isDirectory: true, parent: stairs)
        let legs = File(name: "legs", isDirectory: false, parent: trap)
        
        stairs.children = [trap]
        trap.children = [legs]
        
        engine.realDirectory = trap
        engine.root = goal
        
        expectedStructure = initializeGoal2()
        updateTreeText()
    }
    
    private func initializeGoal2() -> File {
        let goal = File(name: "factory", isDirectory: true, parent: nil)
        
        let door = File(name: "door", isDirectory: true, parent: engine.root)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        goal.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let on1 = File(name: "on", isDirectory: false, parent: automatedRobots)
        let on2 = File(name: "on", isDirectory: false, parent: hydraulicPress)
        
        automatedRobots.children = [on1]
        hydraulicPress.children = [on2]
        
        let trap = File(name: "trap", isDirectory: true, parent: stairs)
        
        stairs.children = [trap]
        trap.children = []
        return goal
    }
    
    private func initializePhase3() {
        let goal = File(name: "factory", isDirectory: true, parent: nil)
        
        let door = File(name: "door", isDirectory: true, parent: engine.root)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        goal.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let on1 = File(name: "on", isDirectory: false, parent: automatedRobots)
        
        automatedRobots.children = [on1]
        hydraulicPress.children = []
        
        let trap = File(name: "trap", isDirectory: true, parent: stairs)
        
        stairs.children = [trap]
        trap.children = []
        
        engine.root = goal
        expectedStructure = initializeGoal3()
        updateTreeText()
    }
    
    private func initializeGoal3() -> File {
        let goal = File(name: "factory", isDirectory: true, parent: nil)
        
        let door = File(name: "door", isDirectory: true, parent: engine.root)
        let machineRoom = File(name: "machineRoom", isDirectory: true, parent: door)
        let hydraulicPress = File(name: "hydraulicPress", isDirectory: true, parent: machineRoom)
        let automatedRobots = File(name: "automatedRobots", isDirectory: true, parent: machineRoom)
        let stairs = File(name: "stairs", isDirectory: true, parent: machineRoom)
        
        goal.children = [door]
        door.children = [machineRoom]
        machineRoom.children = [automatedRobots, hydraulicPress, stairs]
        
        let on1 = File(name: "on", isDirectory: false, parent: automatedRobots)
        let term = File(name: "terminal_tor", isDirectory: false, parent: hydraulicPress)
        
        automatedRobots.children = [on1]
        hydraulicPress.children = [term]
        
        let trap = File(name: "trap", isDirectory: true, parent: stairs)
        
        stairs.children = [trap]
        trap.children = []
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
        if hitCount >= 3 {
            return
        }
        
        if timer == nil {
            timeElapsed = 0
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.timeElapsed += 1
                self.checkTimeElapsed()
            }
        }
        executeCommand()
        commandCount += 1
        checkLevelCompletion()
    }
    
    private func checkTimeElapsed() {
        if timeElapsed > 0 && timeElapsed % timeDifficulty == 0 {
            if oldDirectory?.name == engine.realDirectory?.name {
                if hitCount == 2 {
                    commandHistory = []
                    welcomeMessage = "The Terminal-tor killed you... Restart.\\n"
                    realCommand = ""
                    hitCount += 1
                    stopTimer()
                } else {
                    commandHistory = []
                    welcomeMessage = "The Terminal-tor attacked! You got hit!\\n"
                    realCommand = ""
                    hitCount += 1
                }
            } else {
                commandHistory = []
                welcomeMessage = "The Terminal-tor attacked! You dodged!\\n"
                realCommand = ""
            }
            oldDirectory = engine.realDirectory
        }
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
            if command == "rm" && phase == 2 {
                setError("Cannot remove him", path: cmdPath)
                realCommand = ""
                return
            }
            
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
        
        // updateTreeText() is not needed, we display `expectedStructure` tree in Level 6
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
            phase += 1
            if phase == 1 {
                timeDifficulty = 15
                commandHistory = []
                welcomeMessage = "Well done, blow the Termial-tor up!\\n"
                initializePhase2()
            } else if phase == 2 {
                timeDifficulty = 20
                commandHistory = []
                welcomeMessage = "He can't walk anymore! Move the Terminal-tor inside the hydraulic press!\\n"
                initializePhase3()
            } else if phase == 3 {
                stopTimer()
                isLevelComplete = true
                showCompletion = true
            }
        }
    }
    
    private func updateTreeText() {
        treeText = engine.generateTreeText(for: expectedStructure)
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
