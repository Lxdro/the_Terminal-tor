import SwiftUI

class File: ObservableObject {
    var name: String
    weak var parent: File?
    let isDirectory: Bool
    @Published var children: [File]?
    let emoji: String? = nil
    
    init(name: String, isDirectory: Bool, parent: File? = nil) {
        self.name = name
        self.isDirectory = isDirectory
        self.parent = parent
        self.children = isDirectory ? [] : nil
    }
    
    func equals(_ other: File) -> Bool {
        guard name == other.name, isDirectory == other.isDirectory else { return false }
        
        if isDirectory {
            guard let children = children, let otherChildren = other.children, children.count == otherChildren.count else {
                return false
            }
            
            let sortedChildren = children.sorted { $0.name < $1.name }
            let sortedOtherChildren = otherChildren.sorted { $0.name < $1.name }
            
            for (child, otherChild) in zip(sortedChildren, sortedOtherChildren) {
                if !child.equals(otherChild) {
                    return false
                }
            }
        }
        
        return true
    }
    
    // MARK: - File System Operations
    
    func ls(_ name: String?) -> String {
        let targetFile: File
        
        if let name = name {
            guard let file = (children?.first { $0.name == name }) else {
                return ""
            }
            targetFile = file
        } else {
            targetFile = self
        }
        
        guard targetFile.isDirectory, let children = targetFile.children else {
            return ""
        }
        
        let sortedChildren = children.sorted { $0.name < $1.name }
        
        return sortedChildren.map { $0.isDirectory ? "\($0.name)/" : $0.name }.joined(separator: "\n")
    }
    
    func cd(_ name: String) -> File? {
        if name == ".." {
            return parent
        }
        guard isDirectory, let child = children?.first(where: { $0.name == name && $0.isDirectory }) else {
            return nil
        }
        return child
    }
    
    func mv(_ newParent: File) {
        parent = newParent
        newParent.setChild(self)
    }
    
    func cp(_ newParent: File) {
        let tmp = self
        tmp.parent = newParent
        newParent.setChild(tmp)
    }
    
    func deepCopy() -> File {
        let copy = File(name: self.name, isDirectory: self.isDirectory)
        if let children = self.children {
            copy.children = children.map { $0.deepCopy() }
            copy.children?.forEach { $0.parent = copy }
        }
        return copy
    }
    
    func hasFile(named name: String) -> Bool {
        return children?.contains(where: { $0.name == name }) ?? false
    }
    
    func getChild(named name: String) -> File? {
        return children?.first(where: { $0.name == name })
    }
    
    func setChild(_ file: File) {
        if (isDirectory) {
            children?.append(file)
            children?.sort { $0.name < $1.name }
        }
    }
    
    func touch(_ name: String) {
        guard isDirectory, !hasFile(named: name) else { return }
        let newFile = File(name: name, isDirectory: false, parent: self)
        children?.append(newFile)
        children?.sort { $0.name < $1.name }
        objectWillChange.send()
    }
    
    func mkdir(_ name: String) {
        guard isDirectory, !hasFile(named: name) else { return }
        let newDir = File(name: name, isDirectory: true, parent: self)
        children?.append(newDir)
        children?.sort { $0.name < $1.name }
        objectWillChange.send()
    }
    
    func rm(_ name: String) {
        guard isDirectory, let index = children?.firstIndex(where: { $0.name == name }) else { return }
        children?.remove(at: index)
        objectWillChange.send()
    }
    
    // MARK: - Selection Helper Functions
    
    /// Determines if a file name would be selectable in the current directory given a command
    func isFileSelectable(name: String, forCommand command: String?) -> Bool {
        switch command {
        case "touch", "mkdir":
            // Can create new files/directories only if name doesn't exist
            // Can't create files named ".." or "."
            return isDirectory && 
            !hasFile(named: name) && 
            name != "." &&
            !(self.isRoot && name == "..")
            
        case "cd":
            // Can only cd into directories or go up (except at root)
            if name == ".." {
                return !isRoot
            }
            return isDirectory && 
            hasFile(named: name) && 
            (getChild(named: name)?.isDirectory ?? false)
            
        case "rm":
            // Can remove existing files/directories, but not ".." or "."
            return isDirectory && 
            hasFile(named: name) && 
            name != ".." && 
            name != "."
            
        case nil:
            // When no command is selected, nothing is selectable
            return false
            
        default:
            return false
        }
    }
    
    /// Returns a list of all selectable files for the given command
    func getSelectableFiles(forCommand command: String?) -> [String] {
        var selectableFiles: [String] = []
        
        // Add ".." if appropriate
        if command != nil && command != "touch" && command != "mkdir" && !isRoot {
            selectableFiles.append("..")
        }
        
        // Add children based on command context
        children?.forEach { file in
            if isFileSelectable(name: file.name, forCommand: command) {
                selectableFiles.append(file.name)
            }
        }
        
        return selectableFiles
    }
    
    /// Returns a reason why a file isn't selectable, or nil if it is selectable
    func whyNotSelectable(name: String, forCommand command: String?) -> String? {
        switch command {
        case "touch", "mkdir":
            if hasFile(named: name) {
                return "File already exists"
            }
            if name == ".." && isRoot {
                return "Cannot create file named '..'"
            }
            if name == "." {
                return "Cannot create file named '.'"
            }
            
        case "cd":
            if name == ".." && isRoot {
                return "Already at root directory"
            }
            if !hasFile(named: name) && name != ".." {
                return "Directory does not exist"
            }
            if let file = getChild(named: name), !file.isDirectory {
                return "Not a directory"
            }
            
        case "rm":
            if !hasFile(named: name) {
                return "File does not exist"
            }
            if name == ".." || name == "." {
                return "Cannot remove special directory"
            }
            
        case nil:
            return "No command selected"
            
        default:
            return "Unknown command"
        }
        
        return nil
    }
    
    // MARK: - Helper Properties
    
    /// Returns true if this is the root directory
    var isRoot: Bool {
        return parent == nil || name == "root"
    }
    
    /// Returns the full path to this file
    var path: String {
        var components: [String] = []
        var current: File? = self
        
        while let file = current {
            components.insert(file.name, at: 0)
            current = file.parent
        }
        
        return "/" + components.joined(separator: "/")
    }
}

struct FileOption: Identifiable {
    let id = UUID()
    var emoji: String? = nil
    let name: String
    var fileExtension: String? = nil
}




