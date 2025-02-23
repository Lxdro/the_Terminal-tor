import SwiftUI

struct Level4View: View {
    @StateObject private var map = File(name: "map", isDirectory: true)
    @State private var currentDirectory: File?
    @State private var selectedCommand: String?
    @State private var selectedFiles: [String] = []
    @State private var commandHistory: [Command] = []
    @State private var realCommand: String = ""
    @State private var realDirectory: File?
    @State private var errorMessage: String? = nil
    @State private var commandCount: Int = 0
    @State private var isLevelComplete: Bool = false
    
    @State private var userCommand: String = ""
    //@State private var userAnswer: String = ""
    @State private var correctCountry: String? = nil
    @State private var cityToFind: String? = nil
    
    @FocusState private var isFocused: Bool
    
    @State private var tryCount = 0
    
    @State var welcomeMessage =
    """
    Welcome to the Terminal-tor
    Write yourself commands to solve the level!
    
    """
    
    private let username = UserDefaults.standard.string(forKey: "username") ?? "user"
    private let commands = ["cd", "ls", "clear"]
    
    @Binding var selectedLevel: Int
    @State private var showCompletion = false
    
    @State private var timeElapsed: Int = 0
    @State private var timer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 50) {
            HStack(spacing: 0) {
                VStack {
                    instructionView
                }
                ttyView
            }
            .frame(height: UIScreen.main.bounds.height / 2)
            
            VStack(spacing: 50) {
                HStack {
                    Text("$")
                        .font(.custom("Glass_TTY_VT220", size: 18))
                        .foregroundColor(TTYColors.text)
                    TextField("> Enter command", text: $userCommand)
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
            LevelCompletionView(selectedLevel: $selectedLevel, commandCount: commandCount, timeElapsed: timeElapsed)
        }
        
    }
    
    private var actionButtons: some View {
        HStack {
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
                isEnabled: userCommand != ""
            ) {
                if timer == nil {
                    timeElapsed = 0
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        timeElapsed += 1
                    }
                }
                executeCommand()
                commandCount += 1
            }
            Spacer()
        }
    }
    
    private func restartLevel() {
        stopTimer()
        map.children?.removeAll()
        currentDirectory = map
        realDirectory = map
        
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
        var currentFile: File = path.hasPrefix("/") ? map : currentDir
        
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
        let components = userCommand.trimmingCharacters(in: .whitespaces).split(separator: " ")
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
        case "clear":
            commandHistory = []
            welcomeMessage = ""
        case "ls":
            executeLsCommand(args: args)
        case "cd":
            executeCdCommand(args: args)
        case "try":
            checkAnswer(args: args)
        default:
            setError("Command not implemented: \(command)")
        }
        
        userCommand = ""
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
            currentDirectory = realDirectory
            realDirectory = map
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
        addToHistory(command: userCommand, error: message)
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
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkAnswer(args: [String]) {
        if args.isEmpty {
            setError("\"try\" take a country as argument.")
        }
        else if args[0].lowercased() == correctCountry?.lowercased() {
            stopTimer()
            isLevelComplete = true
            showCompletion = true
        } else {
            tryCount += 1
            if tryCount == 3 {
                initializeView()
                tryCount = 0;
                setError("Wrong answer! New location is \(cityToFind!)")
            } else {
                setError("Wrong answer! \(3 - tryCount) use of command \"try\" left before a new location get selected!")
            }
        }
    }
    
    private var instructionView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Instructions: find \(cityToFind ?? "a city")")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
            
            ScrollView {
                Text("""
                     Use commands to navigate through the files and discover which country \(cityToFind ?? "a city") is located in.  
                     
                     Available commands:  
                     - **ls**  
                     - **cd** 
                     - **try**
                     
                     \"try\" is a special command for this level — when you think you've found the answer, type **"try"** followed by the country's name.  
                     Be careful! You can only use this command **3 times**.  
                     
                     Remember to clear your terminal when it gets too cluttered.  
                     
                     (Don't check online, cheater!)
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
        let map = map
        var cityCountryPairs: [(String, String)] = []
        
        for (continentName, countries) in fileSystemStructure {
            let continent = File(name: continentName, isDirectory: true, parent: map)
            map.children?.append(continent)
            
            for (countryName, cities) in countries {
                let country = File(name: countryName, isDirectory: true, parent: continent)
                continent.children?.append(country)
                
                for cityName in cities {
                    let city = File(name: cityName, isDirectory: false, parent: country)
                    country.children?.append(city)
                    cityCountryPairs.append((cityName, countryName))
                }
            }
        }
        if let randomPair = cityCountryPairs.randomElement() {
            correctCountry = randomPair.1
            cityToFind = randomPair.0
        }
        
        currentDirectory = map
        realDirectory = map
    }
}

let fileSystemStructure: [String: [String: [String]]] = [
    "Europe": [
        "France": ["Paris", "Marseille", "Lyon", "Toulouse"],
        "UK": ["London", "Birmingham", "Manchester", "Glasgow"],
        "Italy": ["Rome", "Milan", "Naples", "Turin"],
        "Sweden": ["Stockholm", "Gothenburg", "Malmo", "Uppsala"]
    ],
    "America": [
        "USA": ["New York", "Los Angeles", "Chicago", "Houston"],
        "Canada": ["Toronto", "Vancouver", "Montreal", "Calgary"],
        "Brazil": ["Sao Paulo", "Rio de Janeiro", "Brasilia", "Salvador"],
        "Mexico": ["Mexico City", "Guadalajara", "Monterrey", "Puebla"]
    ],
    "Asia": [
        "China": ["Beijing", "Shanghai", "Guangzhou", "Shenzhen"],
        "India": ["Mumbai", "Delhi", "Bangalore", "Hyderabad"],
        "Japan": ["Tokyo", "Osaka", "Nagoya", "Sapporo"],
        "Malaysia": ["Kuala Lumpur", "George Town", "Johor Bahru", "Ipoh"]
    ],
    "Africa": [
        "Egypt": ["Cairo", "Alexandria", "Giza", "Shubra El-Kheima"],
        "Morocco": ["Casablanca", "Rabat", "Fes", "Marrakech"],
        "Nigeria": ["Lagos", "Kano", "Ibadan", "Abuja"],
        "Tanzania": ["Dar es Salaam", "Mwanza", "Arusha", "Dodoma"]
    ]
]
