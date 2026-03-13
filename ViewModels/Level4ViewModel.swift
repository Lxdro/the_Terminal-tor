import Foundation
import SwiftUI
import Combine

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

class Level4ViewModel: LevelViewModel {
    @Published var commandCount: Int = 0
    @Published var timeElapsed: Int = 0
    @Published var isLevelComplete: Bool = false
    @Published var showCompletion: Bool = false
    @Published var welcomeMessage: String = ""
    
    @Published var commandHistory: [Command] = []
    @Published var realCommand: String = ""
    @Published var selectedCommand: String? = nil
    @Published var selectedFiles: [String] = []
    
    @Published var tryCount: Int = 0
    private var correctCountry: String? = nil
    private var cityToFind: String? = nil
    
    // Engine
    private var engine: TerminalEngine
    var realDirectory: File? { engine.realDirectory }
    
    let hasTimer: Bool = true
    let hasTextField: Bool = true
    let isRedTTY: Bool = false
    
    let commands = ["cd", "ls", "clear"]
    let fileOptions: [FileOption] = []
    
    var instructionTitle: String {
        "Instructions: find \(cityToFind ?? "a city")"
    }
    
    var instructionText: String {
        """
        Use commands to navigate through the files and discover which country \(cityToFind ?? "a city") is located in.  
        
        Available commands:  
        - **ls**  
        - **cd** 
        - **try**
        
        \"try\" is a special command for this level — when you think you've found the answer, type **"try"** followed by the country's name.  
        Be careful! You can only use this command **3 times**.  
        
        Remember to clear your terminal when it gets too cluttered.  
        
        (Don't check online, cheater!)
        """
    }
    
    let hasTreeView = false
    let treeTitle = ""
    let treeText = ""
    
    private var timer: Timer? = nil
    
    var currentPath: String {
        engine.getCurrentPath(file: engine.currentDirectory)
    }
    
    init() {
        let map = File(name: "map", isDirectory: true)
        self.engine = TerminalEngine(root: map)
    }
    
    func initializeView() {
        let map = engine.root
        map.children?.removeAll()
        engine.currentDirectory = map
        engine.realDirectory = map
        
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
        
        welcomeMessage = """
        Welcome to the Terminal-tor
        Write yourself commands to solve the level!
        
        """
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
        
        guard commands.contains(command) || command == "try" else {
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
        case "try":
            checkAnswer(args: args, path: cmdPath)
        default:
            setError("Command not implemented: \(command)", path: cmdPath)
        }
        
        realCommand = ""
    }
    
    private func checkAnswer(args: [String], path: String) {
        if args.isEmpty {
            setError("\"try\" take a country as argument.", path: path)
        }
        else if args[0].lowercased() == correctCountry?.lowercased() {
            stopTimer()
            isLevelComplete = true
            showCompletion = true
        } else {
            tryCount += 1
            if tryCount == 3 {
                initializeView()
                tryCount = 0
                if let newCity = cityToFind {
                    setError("Wrong answer! New location is \(newCity)", path: path)
                }
            } else {
                setError("Wrong answer! \(3 - tryCount) use of command \"try\" left before a new location get selected!", path: path)
            }
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
    
    func selectCommand(_ command: String) {}
    func isFileSelectable(_ option: FileOption) -> Bool { return false }
    func handleFileSelection(_ option: FileOption) {}
    func resetCommandState() {
        realCommand = ""
    }
}
