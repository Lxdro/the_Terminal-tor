import SwiftUI
import UIKit

struct TabView: View {
    @State private var showLevels = false
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var showAchievements = false
    @State private var selectedLevel: Int = 0
    @State private var selectedLevelInstructions = [
        "Grass Maze",
        "Organisation is Key",
        "Family Rescuer",
        "A File Globtrotter",
        "My Tiny File Garden",
        "The Final Boss"
    ]
    @State private var terminalInput = ""
    @State private var terminalOutput: [String] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                TTYColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    if selectedLevel != 0 {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("TTY00\(selectedLevel) - Level \(selectedLevel): \(selectedLevelInstructions[selectedLevel - 1])")
                                .font(.custom("Glass_TTY_VT220", size: 24))
                                .foregroundColor(selectedLevel == 6 ? TTYColors.red : TTYColors.text)
                            
                            LevelContentView(selectedLevel: $selectedLevel)
                                .padding()
                                .background(TTYColors.background)
                                .cornerRadius(5)
                        }
                        .padding(20)
                    } else {
                        ZStack {
                            PlayerView()
                                .ignoresSafeArea()
                                .edgesIgnoringSafeArea(.all)
                                .frame(width: 600, height: 360)
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(.black.opacity(0.6))
                                    .frame(width: 600, height: 360)
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.ultraThinMaterial)
                                    .stroke(TTYColors.text, lineWidth: 3)
                                    .frame(width: 600, height: 360)
                                
                                VStack(spacing: 20) {
                                    TypewriterText(
                                        text: "The Terminal Simulator",
                                        font: UIFont(name: "Glass_TTY_VT220", size: 36) ?? UIFont.systemFont(ofSize: 36),
                                        textColor: UIColor(TTYColors.text),
                                        typingTimeInterval: 0.10,
                                        showCursor: true
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .shadow(color: TTYColors.text, radius: 3, x: 0, y: 0)
                                    
                                    TypewriterText(
                                        text: "Learn most useful commands by validating levels.\nNo fancy tutorial here, the help tab is your best friend.",
                                        font: UIFont(name: "Glass_TTY_VT220", size: 18) ?? UIFont.systemFont(ofSize: 18),
                                        textColor: UIColor(TTYColors.dimText),
                                        typingTimeInterval: 0.03,
                                        startDelay: 3.0
                                    )
                                    .frame(maxWidth: .infinity, minHeight: 60)
                                    .padding(.bottom, 60)
                                    
                                    Button(action: { showLevels.toggle() }) {
                                        Text("SELECT LEVEL")
                                            .font(.custom("Glass_TTY_VT220", size: 20))
                                            .foregroundColor(TTYColors.background)
                                            .padding()
                                            .background(TTYColors.text)
                                            .cornerRadius(5)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 25) {
                        TTYToolbarButton(title: "HOME", systemImage: "house", action: { selectedLevel = 0 }, level: $selectedLevel)
                        TTYToolbarButton(title: "LEVELS", systemImage: "terminal", action: { showLevels.toggle() }, level: $selectedLevel)
                        TTYToolbarButton(title: "HELP", systemImage: "questionmark.circle", action: { showHelp.toggle() }, level: $selectedLevel)
                        TTYToolbarButton(title: "STATS", systemImage: "trophy", action: { showAchievements.toggle() }, level: $selectedLevel)
                        TTYToolbarButton(title: "CONFIG", systemImage: "slider.horizontal.3", action: { showSettings.toggle() }, level: $selectedLevel)
                    }
                }
            }
            .sheet(isPresented: $showLevels) {
                LevelsView(selectedLevel: $selectedLevel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct LevelContentView: View {
    @Binding var selectedLevel: Int
    
    var body: some View {
        switch selectedLevel {
        case 1:
            Level1View(selectedLevel: $selectedLevel)
        case 2:
            Level2View(selectedLevel: $selectedLevel)
        case 3:
            Level3View(selectedLevel: $selectedLevel)
        case 4:
            Level4View(selectedLevel: $selectedLevel)
        case 5:
            Level5View(selectedLevel: $selectedLevel)
        case 6:
            Level6View(selectedLevel: $selectedLevel)
        default:
            Text("Invalid level")
                .font(.custom("Glass_TTY_VT220", size: 18))
                .foregroundColor(TTYColors.text)
        }
    }
}

struct TTYToolbarButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    @Binding var level: Int
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.custom("Glass_TTY_VT220", size: 16))
                .foregroundColor(level == 6 ? TTYColors.red : TTYColors.text)
                .shadow(color: level == 6 ? TTYColors.red : TTYColors.text, radius: 3, x: 0, y: 0)
        }
    }
}

struct LevelsView: View {
    @Binding var selectedLevel: Int
    @Environment(\.dismiss) var dismiss
    
    let columns = [
        GridItem(.adaptive(minimum: 200), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(1...6, id: \.self) { level in
                        Button {
                            selectedLevel = level
                            dismiss()
                        } label: {
                            ZStack {
                                PlayerView()
                                    .ignoresSafeArea()
                                    .edgesIgnoringSafeArea(.all)
                                ZStack {
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.black.opacity(0.6))
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                    VStack(spacing: 15) {
                                        Text("LEVEL \(level)")
                                            .font(.custom("Glass_TTY_VT220", size: 20))
                                        
                                        Text("CMD_SET_\(level)")
                                            .font(.custom("Glass_TTY_VT220", size: 16))
                                        
                                        HStack {
                                            ForEach(0..<3) { command in
                                                Image(systemName: command < (level % 3 + 1) ? "star.fill" : "star")
                                                    .foregroundColor(TTYColors.text)
                                            }
                                        }
                                    }
                                }
                            }
                            .frame(width: 200, height: 160)
                            .foregroundColor(TTYColors.text)
                            .background(TTYColors.terminalBlack)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(TTYColors.text, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding()
                .offset(y: 50)
            }
            .background(TTYColors.background)
            .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    )
            .ignoresSafeArea()
            .navigationTitle("SELECT LEVEL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("EXIT") {
                        dismiss()
                    }
                    .font(.custom("Glass_TTY_VT220", size: 16))
                    .foregroundColor(TTYColors.text)
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var soundEnabled = false
    @State private var typingSound = false
    @State private var cursorStyle = 0
    
    var body: some View {
        NavigationView {
            List {
                Section("TERMINAL") {
                    Toggle("ENABLE_SOUND", isOn: $soundEnabled)
                        .toggleStyle(TTYToggleStyle())
                    Toggle("KEY_FEEDBACK", isOn: $typingSound)
                        .toggleStyle(TTYToggleStyle())
                    Picker("CURSOR_STYLE", selection: $cursorStyle) {
                        Text("BLOCK").tag(0)
                        Text("UNDERLINE").tag(1)
                        Text("BEAM").tag(2)
                    }
                }
                .listRowBackground(Color.gray.opacity(0.2))
                
            }
            .offset(y: 50)
            .font(.custom("Glass_TTY_VT220", size: 16))
            .foregroundColor(TTYColors.text)
            .scrollContentBackground(.hidden)
            .background(TTYColors.background)
            .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    )
            .ignoresSafeArea()
            .navigationTitle("CONFIG")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("EXIT") {
                        dismiss()
                    }
                    .font(.custom("Glass_TTY_VT220", size: 16))
                    .foregroundColor(TTYColors.text)
                }
            }
        }
    }
}

struct TTYToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 5)
                .fill(configuration.isOn ? TTYColors.text : TTYColors.dimText)
                .frame(width: 50, height: 25)
                .overlay(
                    Circle()
                        .fill(TTYColors.background)
                        .padding(4)
                        .offset(x: configuration.isOn ? 11 : -11)
                )
                .onTapGesture {
                    withAnimation {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("BASIC COMMANDS")
                            .font(.custom("Glass_TTY_VT220", size: 24))
                        CommandHelpRow(command: "man", description: "Display a guide on how to use the command passed as argument. Like here.")
                        CommandHelpRow(command: "ls", description: "List directory contents, no argument needed")
                        CommandHelpRow(command: "cd", description: "Change to the directory specified as argument")
                        CommandHelpRow(command: "rm", description: "Remove the file specified as argument")
                        CommandHelpRow(command: "mkdir", description: "Create the directory specified as argument")
                        CommandHelpRow(command: "touch", description: "Create the file specified as argument")
                        CommandHelpRow(command: "mv", description: "Move the source to destination (2 arguments). If destination don't exist, it will rename the source to destination.")
                        CommandHelpRow(command: "cp", description: "Copy the source to destination (2 arguments)")
                        CommandHelpRow(command: "clear", description: "Same as the \"Clear\" button")
                    }
                    
                    Divider()
                        .background(TTYColors.text)
                    
                    Group {
                        Text("NOTES")
                            .font(.custom("Glass_TTY_VT220", size: 24))
                        
                        Text("• Directories are a special kind of file. Therefore, \"file\" design also directories.")
                        Text("• \"..\" represent the parent directory.")
                        Text("• An argument is the word following a command by a space.")
                        Text("• Every command requiring a file as argument can accept a path. Select multiplle files to create one.")
                         Text("• A path is a sequence of parents and their child, separated by \"/\".")
                        Text("• In the Terminal-tor, files are represented as buttons. However, in a real one, you can press \"Tab\" key to autocomplete your command, or double press it to see all available options.")
                        Text("• In a real Terminal, use arrow keys to naviagte threw command history.")
                    }
                    .font(.custom("Glass_TTY_VT220", size: 16))
                }
                .padding()
                
            }
            .offset(y: 50)
            .foregroundColor(TTYColors.text)
            .background(TTYColors.background)
            .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    )
            .ignoresSafeArea()
            .navigationTitle("MANUAL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("EXIT") {
                        dismiss()
                    }
                    .font(.custom("Glass_TTY_VT220", size: 16))
                    .foregroundColor(TTYColors.text)
                }
            }
        }
    }
}

struct CommandHelpRow: View {
    let command: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("$ \(command)")
                .font(.custom("Glass_TTY_VT220", size: 18))
            Text(description)
                .font(.custom("Glass_TTY_VT220", size: 16))
                .foregroundColor(TTYColors.dimText)
        }
        .padding(.vertical, 5)
    }
}

struct AchievementsView: View {
    @Environment(\.dismiss) var dismiss
    
    let achievements = [
        Achievement(title: "FIRST_CMD", description: "Execute first command", isUnlocked: false),
        Achievement(title: "DIR_MASTER", description: "Navigate 10 directories", isUnlocked: false),
        Achievement(title: "PATH_PRO", description: "Finish a level in 3 commands", isUnlocked: false),
        Achievement(title: "THE_FASTEST", description: "Finish a level in less than 9.58s", isUnlocked: false)
    ]
    
    var body: some View {
        NavigationView {
            List(achievements) { achievement in
                AchievementRow(achievement: achievement)
                    .listRowBackground(Color.gray.opacity(0.2))
            }
            .offset(y: 50)
            .font(.custom("Glass_TTY_VT220", size: 16))
            .scrollContentBackground(.hidden)
            .foregroundColor(TTYColors.text)
            .background(TTYColors.background)
            .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    )
            .ignoresSafeArea()
            .navigationTitle("ACHIEVEMENTS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("EXIT") {
                        dismiss()
                    }
                    .font(.custom("Glass_TTY_VT220", size: 16))
                    .foregroundColor(TTYColors.text)
                }
            }
            
        }
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let isUnlocked: Bool
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(achievement.title)
                    .font(.custom("Glass_TTY_VT220", size: 18))
                Text(achievement.description)
                    .font(.custom("Glass_TTY_VT220", size: 16))
                    .foregroundColor(TTYColors.dimText)
            }
            
            Spacer()
            
            Text(achievement.isUnlocked ? "[UNLOCKED]" : "[LOCKED]")
                .font(.custom("Glass_TTY_VT220", size: 16))
                .foregroundColor(achievement.isUnlocked ? TTYColors.text : TTYColors.dimText)
        }
        .padding(.vertical, 5)
    }
}
