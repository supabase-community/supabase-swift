//
//  Macros.swift
//
//
//  Created by Guilherme Souza on 20/06/24.
//

import Foundation

@attached(member)
@attached(memberAttribute)
public macro PostgrestModel(_ tableName: String) = #externalMacro(module: "PostgRESTMacrosPlugin", type: "PostgrestModelMacro")
