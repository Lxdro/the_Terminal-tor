import Foundation
import SwiftUI
import Combine

class Level3ViewModel: LevelViewModel {
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
    
    let commands = ["mv", "cp"]
    
    let fileOptions = [
        FileOption(emoji: "🔙", name: ".."),
        FileOption(emoji: "🐭", name: "Mouse"),
        FileOption(emoji: "🐰", name: "Rabbit"),
        FileOption(emoji: "🐓", name: "Rooster"),
        FileOption(emoji: "🐔", name: "Hen"),
        FileOption(emoji: "🐇", name: "BabyRabbit"),
        FileOption(emoji: "🐁", name: "BabyMouse"),
        FileOption(emoji: "🐥", name: "Chick")
    ]
    
    let instructionTitle = "Instructions: reunite families"
    let instructionText = """
    Babies are lost! Your task is to reunite each baby with its parent.
    Be careful, \"mv\" and \"cp\" are taking **2** arguments - as always, help tab is your best friend.
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
        let farm = File(name: "farm", isDirectory: true)
        self.engine = TerminalEngine(root: farm)
    }
    
    func initializeView() {
        let farm = engine.root
        farm.children?.removeAll()
        engine.currentDirectory = farm
        engine.realDirectory = farm
        
        let rabbit = File(name: "Rabbit", isDirectory: true, parent: farm)
        let hen = File(name: "Hen", isDirectory: true, parent: farm)
        let rooster = File(name: "Rooster", isDirectory: true, parent: farm)
        let mouse = File(name: "Mouse", isDirectory: true, parent: farm)
        
        let babyMouse = File(name: "BabyMouse", isDirectory: false, parent: rabbit)
        let chick = File(name: "Chick", isDirectory: false, parent: mouse)
        let babyRabbit = File(name: "BabyRabbit", isDirectory: false, parent: rooster)
        
        rabbit.children = [babyMouse]
        hen.children = []
        rooster.children = [babyRabbit]
        mouse.children = [chick]
        farm.children = [rabbit, hen, rooster, mouse]
        
        updateTreeText()
        expectedStructure = initializeGoal()
        
        welcomeMessage = """
        Welcome to the Terminal-tor
        Press buttons to make real commands!
        
        """
    }
    
    private func initializeGoal() -> File {
        let goal = File(name: "farm", isDirectory: true, parent: nil)
        
        let goalRabbit = File(name: "Rabbit", isDirectory: true, parent: goal)
        let goalHen = File(name: "Hen", isDirectory: true, parent: goal)
        let goalRooster = File(name: "Rooster", isDirectory: true, parent: goal)
        let goalMouse = File(name: "Mouse", isDirectory: true, parent: goal)
        
        let goalBabyMouse = File(name: "BabyMouse", isDirectory: false, parent: goalMouse)
        let goalBabyRabbit = File(name: "BabyRabbit", isDirectory: false, parent: goalRabbit)
        let goalChick1 = File(name: "Chick", isDirectory: false, parent: goalHen)
        let goalChick2 = File(name: "Chick", isDirectory: false, parent: goalRooster)
        
        goalRabbit.children = [goalBabyRabbit]
        goalHen.children = [goalChick1]
        goalRooster.children = [goalChick2]
        goalMouse.children = [goalBabyMouse]
        
        goal.children = [goalRabbit, goalHen, goalRooster, goalMouse]
        
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
        let components = realCommand.split(separator: " ")
        guard components.count == 3 else {
            setError("Error: Both source and destination paths are required", path: cmdPath)
            return
        }
        
        let command = String(components[0])
        let sourcePath = String(components[1])
        let destPath = String(components[2])
        
        engine.executeMvCp(command: command, sourcePath: sourcePath, destPath: destPath)
        
        if let error = engine.errorMessage {
            addToHistory(command: realCommand, error: error, path: cmdPath)
        } else {
            addToHistory(command: realCommand, path: cmdPath)
        }
        
        updateTreeText()
        resetCommandState()
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
        if commandHistory.count > 20 {
            commandHistory.removeFirst()
        }
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
        if selectedFiles.isEmpty || realCommand.last == " " {
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
