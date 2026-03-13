import Foundation
import SwiftUI
import Combine

class Level2ViewModel: LevelViewModel {
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
    
    let commands = ["touch", "mkdir", "rm"]
    
    let fileOptions = [
        FileOption(emoji: "🔙", name: ".."),
        FileOption(emoji: "📦", name: "Box"),
        FileOption(emoji: "🧸", name: "TeddyBear"),
        FileOption(emoji: "🚂", name: "Train"),
        FileOption(emoji: "🪁", name: "Kite")
    ]
    
    let instructionTitle = "Instructions: tidy up your room"
    let instructionText = """
    Now, you can see how your File System look like!
    You can't use cd nor ls anymore, you'll probably need to understand how to use path then.
    • Create a box.
    • Remove toys that are outisde of the box
    • Put your toys inside it
    • Your TeddyBear should be inside another box inside the first one, he will feel more secure in this position
    Hint: you can click on multiple file buttons.
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
        let room = File(name: "room", isDirectory: true)
        self.engine = TerminalEngine(root: room)
    }
    
    func initializeView() {
        let room = engine.root
        room.children?.removeAll()
        engine.currentDirectory = room
        engine.realDirectory = room
        
        let teddyBear = File(name: "TeddyBear", isDirectory: false, parent: room)
        let kite = File(name: "Kite", isDirectory: false, parent: room)
        let train = File(name: "Train", isDirectory: false, parent: room)
        
        room.children = [teddyBear, kite, train]
        updateTreeText()
        expectedStructure = initializeGoal()
        
        welcomeMessage = """
        Welcome to the Terminal-tor
        Press buttons to make real commands!
        
        """
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
        if selectedFiles.isEmpty {
            if selectedCommand != "cd" {
                setError("Command \(selectedCommand ?? "") need to specify a file.", path: cmdPath)
            } else {
                engine.realDirectory = engine.root
                engine.currentDirectory = engine.root
                addToHistory(command: realCommand, path: cmdPath)
                updateTreeText()
                resetCommandState()
            }
            return
        }
        
        guard let command = selectedCommand else { return }
        let path = inputPath()
        
        engine.executeMkdirTouchRm(command: command, path: path, currentDirectoryState: &engine.currentDirectory)
        
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
    
    private func inputPath() -> String {
        let components = realCommand.split(separator: " ", maxSplits: 1)
        if components.count > 1 {
            return String(components[1])
        }
        return ""
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
