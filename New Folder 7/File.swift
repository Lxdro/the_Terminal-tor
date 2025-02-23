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
    
    func isFileSelectable(name: String, forCommand command: String?) -> Bool {
        switch command {
        case "touch", "mkdir":
            return isDirectory && 
            !hasFile(named: name) && 
            name != "." &&
            !(self.isRoot && name == "..")
            
        case "cd":
            if name == ".." {
                return !isRoot
            }
            return isDirectory && 
            hasFile(named: name) && 
            (getChild(named: name)?.isDirectory ?? false)
            
        case "rm":
            return isDirectory && 
            hasFile(named: name) && 
            name != ".." && 
            name != "."
            
        case nil:
            return false
            
        default:
            return false
        }
    }
    
    func getSelectableFiles(forCommand command: String?) -> [String] {
        var selectableFiles: [String] = []
        
        if command != nil && command != "touch" && command != "mkdir" && !isRoot {
            selectableFiles.append("..")
        }
        
        children?.forEach { file in
            if isFileSelectable(name: file.name, forCommand: command) {
                selectableFiles.append(file.name)
            }
        }
        
        return selectableFiles
    }
    
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
    
    var isRoot: Bool {
        return parent == nil || name == "root"
    }
    
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




