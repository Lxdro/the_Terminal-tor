import Foundation

class TerminalEngine {
    var root: File
    var realDirectory: File?
    var currentDirectory: File?
    var errorMessage: String? = nil
    
    init(root: File) {
        self.root = root
        self.realDirectory = root
        self.currentDirectory = root
    }
    
    func getCurrentPath(file: File?) -> String {
        var path = [String]()
        var currentFile: File? = file
        
        while let dir = currentFile {
            path.insert(dir.name, at: 0)
            currentFile = dir.parent
        }
        
        return "/" + path.joined(separator: "/")
    }
    
    func parsePath(_ path: String) -> (File, String)? {
        var currentFile = path.hasPrefix("/") ? root : (realDirectory ?? root)
        var components = path.split(separator: "/")
        
        if path.hasPrefix("/") {
            components.removeFirst()
        }
        
        if components.isEmpty && path.hasPrefix("/") {
            return (root, "")
        }
        
        guard !components.isEmpty else { return nil }
        
        let targetName = String(components.removeLast())
        
        for component in components {
            let name = String(component)
            
            if name == ".." {
                currentFile = currentFile.parent ?? root
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
    
    func resolvePath(_ path: String, from currentDir: File) -> File? {
        var currentFile: File = path.hasPrefix("/") ? root : currentDir
        let components = path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        
        if components.isEmpty && path.hasPrefix("/") {
            return root
        }
        
        for component in components {
            switch component {
            case "..":
                currentFile = currentFile.parent ?? currentFile
            case ".":
                continue
            default:
                if let nextFile = currentFile.children?.first(where: { $0.name == component }) {
                    currentFile = nextFile
                } else {
                    return nil
                }
            }
        }
        
        return currentFile
    }
    
    func executeLsCommand(args: [String]) -> String? {
        guard let currentDir = realDirectory else {
            errorMessage = "No current directory"
            return nil
        }
        
        let targetDir: File
        if let path = args.first {
            if let resolved = resolvePath(path, from: currentDir) {
                targetDir = resolved
            } else {
                errorMessage = "ls: no such file or directory: \(path)"
                return nil
            }
        } else {
            targetDir = currentDir
        }
        
        return targetDir.ls(nil)
    }
    
    func executeCdCommand(args: [String], currentDirectoryState: inout File?) {
        guard let currentDir = realDirectory else {
            errorMessage = "No current directory"
            return
        }
        
        if args.isEmpty {
            realDirectory = root
            currentDirectoryState = root
            return
        }
        
        guard args.count == 1 else {
            errorMessage = "cd: wrong number of arguments"
            return
        }
        
        let path = args[0]
        if let newDir = resolvePath(path, from: currentDir) {
            if newDir.isDirectory {
                realDirectory = newDir
                currentDirectoryState = newDir
            } else {
                errorMessage = "cd: not a directory: \(path)"
            }
        } else {
            errorMessage = "cd: no such directory: \(path)"
        }
    }
    
    func executeMkdirTouchRm(command: String, path: String, currentDirectoryState: inout File?) {
        errorMessage = nil
        
        switch command {
        case "touch":
            if path == ".." {
                errorMessage = "Invalid file name: .."
            } else if let (parent, filename) = parsePath(path) {
                if filename == ".." {
                    errorMessage = "Invalid file name: .."
                } else if parent.children?.contains(where: { $0.name == filename && !$0.isDirectory }) == true {
                    errorMessage = "File already exists: \(path)"
                } else {
                    parent.touch(filename)
                }
            } else {
                errorMessage = "Invalid path: \(path)"
            }
            
        case "mkdir":
            if path == ".." {
                errorMessage = "Invalid directory name: .."
            } else if let (parent, dirname) = parsePath(path) {
                if dirname == ".." {
                    errorMessage = "Invalid directory name: .."
                } else if parent.children?.contains(where: { $0.name == dirname && $0.isDirectory }) == true {
                    errorMessage = "Directory already exists: \(path)"
                } else {
                    parent.mkdir(dirname)
                }
            } else {
                errorMessage = "Invalid path: \(path)"
            }
            
        case "rm":
            if path == ".." {
                errorMessage = "Cannot remove directory: .."
            } else if let (parent, name) = parsePath(path) {
                if name == ".." {
                    errorMessage = "Cannot remove directory: .."
                } else if parent.children?.contains(where: { $0.name == name && !$0.isDirectory }) == true {
                    parent.children?.removeAll(where: { $0.name == name && !$0.isDirectory })
                } else {
                    errorMessage = "No such file or directory: \(path)"
                }
            } else {
                errorMessage = "Invalid path: \(path)"
            }
            
        default:
            break
        }
    }
    
    func executeMvCp(command: String, sourcePath: String, destPath: String) {
        errorMessage = nil
        
        guard let (sourceParent, sourceFileName) = parsePath(sourcePath) else {
            errorMessage = "Error: Invalid source path"
            return
        }
        
        guard let sourceFile = sourceParent.getChild(named: sourceFileName) else {
            errorMessage = "Error: Source file not found"
            return
        }
        
        guard let (destParent, destFileName) = parsePath(destPath) else {
            errorMessage = "Error: Invalid destination path"
            return
        }
        
        if let existingDest = destParent.getChild(named: destFileName) {
            if existingDest.isDirectory {
                executeFileOperation(command: command, sourceFile: sourceFile,
                                     destParent: existingDest, destFileName: sourceFile.name)
            } else {
                errorMessage = "Error: Destination already exists and is not a directory"
                return
            }
        } else {
            executeFileOperation(command: command, sourceFile: sourceFile,
                                 destParent: destParent, destFileName: destFileName)
        }
    }
    
    private func executeFileOperation(command: String, sourceFile: File, destParent: File, destFileName: String) {
        switch command {
        case "mv":
            if let oldParent = sourceFile.parent {
                oldParent.children?.removeAll(where: { $0.name == sourceFile.name })
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
    
    func generateTreeText(for file: File, indent: String = "") -> String {
        var lines = [indent + (file.isDirectory ? "📂" : "📄") + " " + file.name]
        
        if let children = file.children {
            lines.append(contentsOf: children.map { generateTreeText(for: $0, indent: indent + "  ") })
        }
        
        return lines.joined(separator: "\n")
    }
}
