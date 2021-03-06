//
//  Dump.swift
//  CLI
//
//  Created by Jake Heiser on 9/6/17.
//

import Foundation
import SwiftCLI
import Core

class DumpCommand: Command {
    
    let name = "dump"
    let shortDescription = "Dumps the current package in JSON format"
    
    func execute() throws {
        let data = try SPM().dumpPackage()
        FileHandle.standardOutput.write(data)
    }
    
}
