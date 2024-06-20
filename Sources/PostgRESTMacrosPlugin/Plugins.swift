//
//  Plugins.swift
//
//
//  Created by Guilherme Souza on 20/06/24.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct MacrosPlugin: CompilerPlugin {
  let providingMacros: [any Macro.Type] = [
    PostgrestModelMacro.self,
  ]
}
