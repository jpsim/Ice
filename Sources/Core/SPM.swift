//
//  SPM.swift
//  Ice
//
//  Created by Jake Heiser on 7/21/17.
//

import Foundation
import Files
import CLISpinner

public class SPM {

    let path: String
    
    public init(path: String = ".") {
        self.path = path
    }
    
    public enum InitType: String {
        case executable
        case library
    }
    
    public func initPackage(type: InitType?) throws {
        var args = ["package", "init"]
        if let type = type {
            args += ["--type", type.rawValue]
        }
        try exec(arguments: args).execute(transform: { (t) in
            t.first("\n")
            t.replace("(Creating .* package): (.*)") { $0[0] + ": " + $0[1].blue + "\n" }
            t.replace("Creating ([^:]+)$") { "    create ".blue + $0[0] }
            t.last("\n")
        })
    }

    public func build(release: Bool = false) throws {
        var args = ["build"]
        if release {
            args += ["-c", "release"]
        }
        try exec(arguments: args).execute(transform: { (t) in
            t.spin("Compile Swift Module '(.*)'", { "Compiling " + $0[0] }, { $0.succeed(text: "Compiled " + $1[0]) })
        })
    }
    
    public func clean() throws {
        try exec(arguments: ["package", "clean"]).execute()
    }

    public func test() throws {
        try exec(arguments: ["test"]).execute(transform: { (t) in
            t.spin("Compile Swift Module '(.*)'", { "Compiling " + $0[0] }, { $0.succeed(text: "Compiled " + $1[0]) })
            t.replaceErr("Test Case .* ([^ ]*)\\]' started", { $0[0] + " started" })
            t.replaceErr("Test Case .* ([^ ]*)\\]' passed", { $0[0] + " passed" })
        })
    }

    public func generateXcodeProject() throws {
        try exec(arguments: ["package", "generate-xcodeproj"]).execute()
    }
    
    func showBinPath(release: Bool = false) throws -> String {
        var args = ["build", "--show-bin-path"]
        if release {
            args += ["-c", "release"]
        }
        let path = try exec(arguments: args).capture()
        guard !path.isEmpty else {
            throw IceError(message: "couldn't retrieve executable path")
        }
        return path.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func dumpPackage() throws -> Data {
        let data = try exec(arguments: ["package", "dump-package"]).captureData()
        guard let jsonStart = data.index(of: UInt8("{".cString(using: .ascii)![0])) else {
            throw IceError(message: "couldn't parse package")
        }
        return data[jsonStart...]
    }

    private func exec(arguments: [String]) -> Exec {
        return Exec(command: "swift", args: arguments, in: path)
    }
    
}
