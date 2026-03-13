import Foundation
import SwiftUI

protocol LevelViewModel: ObservableObject {
    var commandCount: Int { get set }
    var timeElapsed: Int { get set }
    var isLevelComplete: Bool { get set }
    var showCompletion: Bool { get set }
    var welcomeMessage: String { get set }
    
    var commandHistory: [Command] { get set }
    var realCommand: String { get set }
    var selectedCommand: String? { get set }
    var selectedFiles: [String] { get set }
    
    var hasTimer: Bool { get }
    var hasTextField: Bool { get }
    var isRedTTY: Bool { get }
    var commands: [String] { get }
    var fileOptions: [FileOption] { get }
    
    var instructionTitle: String { get }
    var instructionText: String { get }
    var hasTreeView: Bool { get }
    var treeTitle: String { get }
    var treeText: String { get }
    
    var currentPath: String { get }
    
    func initializeView()
    func restartLevel()
    func clearTerminal()
    func executeWrapped()
    
    func selectCommand(_ command: String)
    func isFileSelectable(_ option: FileOption) -> Bool
    func handleFileSelection(_ option: FileOption)
    func resetCommandState()
    func addSpace()
}

extension LevelViewModel {
    func clearTerminal() {
        commandHistory = []
        welcomeMessage = ""
    }
    
    func addSpace() {
        realCommand += " "
    }
}
