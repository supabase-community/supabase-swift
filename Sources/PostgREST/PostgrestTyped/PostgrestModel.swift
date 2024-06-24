//
//  PostgrestModel.swift
//
//
//  Created by Guilherme Souza on 21/06/24.
//

import Foundation

public protocol PostgrestModel: Decodable, Sendable {
  associatedtype Insert: PostgrestType & PostgrestEncodable
  associatedtype Update: PostgrestType & PostgrestEncodable
  associatedtype Metadata: SchemaMetadata
}

public protocol SchemaMetadata {
  associatedtype Attributes: Sendable
  associatedtype TypedAttributes: Sendable

  static var tableName: String { get }

  static var attributes: Attributes { get }
  static var typedAttributes: TypedAttributes { get }
}
