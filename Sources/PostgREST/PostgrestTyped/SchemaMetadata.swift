//
//  SchemaMetadata.swift
//
//
//  Created by Guilherme Souza on 21/06/24.
//

import Foundation

public struct AnyPropertyMetadata {
  let name: String
  let keyPath: AnyKeyPath
}

extension AnyPropertyMetadata {
  public init(codingKey: any CodingKey, keyPath: AnyKeyPath) {
    self.init(name: codingKey.stringValue, keyPath: keyPath)
  }
}

public struct PropertyMetadata<Model, Value> {
  let name: String
  let keyPath: KeyPath<Model, Value>
}

extension PropertyMetadata {
  public init(codingKey: any CodingKey, keyPath: KeyPath<Model, Value>) {
    self.init(name: codingKey.stringValue, keyPath: keyPath)
  }
}

public protocol PostgrestType: Sendable {
  var propertiesMetadata: [AnyPropertyMetadata] { get }
}
