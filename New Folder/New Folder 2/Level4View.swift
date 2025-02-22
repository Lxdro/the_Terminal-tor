import SwiftUI

struct Level4View: View {
    // MARK: - State
    @StateObject private var farm = File(name: "farm", isDirectory: true)
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
    private let commands = ["mv", "cp"]
    private let fileOptions = [
        FileOption(emoji: "🔙", name: ".."),
        FileOption(emoji: "🐭", name: "Mouse"),
        FileOption(emoji: "🐰", name: "Rabbit"),
        FileOption(emoji: "🐓", name: "Rooster"),
        FileOption(emoji: "🐔", name: "Hen"),
        FileOption(emoji: "🐇", name: "BabyRabbit"),
        FileOption(emoji: "🐁", name: "BabyMouse"),
        FileOption(emoji: "🐥", name: "Chick")
    ]
    
    // Expected file structure for the level
    @State private var expectedStructure: File? = nil
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                GeometryReader { proxy in
                    VStack(spacing: 0) { // No spacing to strictly control proportions
                        instructions
                            .frame(height: proxy.size.height * (2/5)) // Takes 1/3 of available height
                        
                        fileTreeView
                            .frame(height: proxy.size.height * (3/5)) // Takes 2/3 of available height
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Ensure VStack expands fully
                }
                ttyView
            }
            .frame(height: UIScreen.main.bounds.height / 2)
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
                     Babies are lost! Your task is to reunite each baby with its parent.
                     
                     Be careful, \"mv\" and \"cp\" are taking **2** arguments - as always, help tab is your best friend.
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
            ActionButton(title: "Space", baseColor: .cyan) {
                realCommand += " "
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
        farm.children?.removeAll()
        currentDirectory = farm
        realDirectory = farm
        
        // Reset game state
        commandCount = 0
        isLevelComplete = false
        commandHistory = []
        
        // Reset command state
        resetCommandState()
        
        // Update views
        initializeView()
        updateTreeText()
        welcomeMessage = """
    Welcome to Terminal-tor
    Press buttons to make real commands!
    
    """
    }
    
    private func checkLevelCompletion() {
        if farm.equals(expectedStructure!) {
            isLevelComplete = true
            showCompletion = true
        }
    }
    
    private func selectCommand(_ command: String) {
        selectedCommand = command
        realCommand = "\(command) "
        selectedFiles = []
    }
    
    private func isFileSelectable(_ option: FileOption) -> Bool {
        let currentDir = currentDirectory ?? farm
        return currentDir.isFileSelectable(name: option.name, forCommand: selectedCommand)
    }
    
    private func handleFileSelection(_ option: FileOption) {
        
        // Update command string
        if selectedFiles.isEmpty || realCommand.last == " " {
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
        
        var currentFile = path.hasPrefix("/") ? farm : (realDirectory ?? farm)
        var components = path.split(separator: "/")
        
        if path.hasPrefix("/") {
            components.removeFirst()
        }
        
        if components.isEmpty && path.hasPrefix("/") {
            return (farm, "")
        }
        
        let targetName = String(components.removeLast())
        
        for component in components {
            let name = String(component)
            
            if name == ".." {
                currentFile = currentFile.parent ?? farm
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

    
    private func executeCommand() {
        let components = realCommand.split(separator: " ")
        guard components.count == 3 else {
            errorMessage = "Error: Both source and destination paths are required"
            addToCommandHistory(realCommand, realDirectory)
            return
        }
        
        let command = String(components[0])
        let sourcePath = String(components[1])
        let destPath = String(components[2])
        
        guard let (sourceParent, sourceFileName) = parsePath(sourcePath) else {
            errorMessage = "Error: Invalid source path"
            addToCommandHistory(realCommand, realDirectory)
            return
        }
        
        guard let sourceFile = sourceParent.getChild(named: sourceFileName) else {
            errorMessage = "Error: Source file not found"
            addToCommandHistory(realCommand, realDirectory)
            return
        }
        
        guard let (destParent, destFileName) = parsePath(destPath) else {
            errorMessage = "Error: Invalid destination path"
            addToCommandHistory(realCommand, realDirectory)
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
                addToCommandHistory(realCommand, realDirectory)
                return
            }
        } else {
            executeFileOperation(command: command, sourceFile: sourceFile, 
                                 destParent: destParent, destFileName: destFileName)
        }
        
        addToCommandHistory(realCommand, realDirectory)
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
    
    private func addToCommandHistory(_ command: String, _ file: File?) {
        commandHistory.append(Command(path: getCurrentPath(file: file), command: command, error: errorMessage ?? nil))
        if commandHistory.count > 20 {
            commandHistory.removeFirst()
        }
        errorMessage = nil
    }
    
    private func updateTreeText() {
        treeText = generateTreeText(for: farm)
    }
    
    private func generateTreeText(for file: File, indent: String = "") -> String {
        var lines = [indent + (file.isDirectory ? "📂" : "📄") + " " + file.name]
        
        if let children = file.children {
            lines.append(contentsOf: children.map { generateTreeText(for: $0, indent: indent + "  ") })
        }
        
        return lines.joined(separator: "\n")
    }
    
    private func initializeView() {
        farm.children?.removeAll()
        currentDirectory = farm
        realDirectory = farm
        // Creating directories under root
        let rabbit = File(name: "Rabbit", isDirectory: true, parent: farm)
        let hen = File(name: "Hen", isDirectory: true, parent: farm)
        let rooster = File(name: "Rooster", isDirectory: true, parent: farm)
        let mouse = File(name: "Mouse", isDirectory: true, parent: farm)
        
        // Creating files inside directories
        let babyMouse = File(name: "BabyMouse", isDirectory: false, parent: rabbit)
        let chick = File(name: "Chick", isDirectory: false, parent: mouse)
        let babyRabbit = File(name: "BabyRabbit", isDirectory: false, parent: rooster)
        
        // Assigning children
        rabbit.children = [babyMouse]
        hen.children = [] // Hen has no children
        rooster.children = [babyRabbit]
        mouse.children = [chick]
        farm.children = [rabbit, hen, rooster, mouse]
        updateTreeText()
        expectedStructure = initializeGoal()
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
        
        // Assigning children for the goal structure
        goalRabbit.children = [goalBabyRabbit]
        goalHen.children = [goalChick1]
        goalRooster.children = [goalChick2]
        goalMouse.children = [goalBabyMouse]
        
        goal.children = [goalRabbit, goalHen, goalRooster, goalMouse]
        
        return goal
    }

}
