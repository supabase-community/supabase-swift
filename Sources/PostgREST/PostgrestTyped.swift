//
//  PostgrestTyped.swift
//
//
//  Created by Guilherme Souza on 20/06/24.
//

import Foundation
import Helpers

public protocol PostgrestEncodable: Encodable {
  func encoded() throws -> Data
}

extension PostgrestEncodable {
  public func encoded() throws -> Data {
    try JSONEncoder().encode(self)
  }
}

extension Array: PostgrestEncodable where Element: PostgrestEncodable {
  public func encoded() throws -> Data {
    try JSONEncoder().encode(self)
  }
}

public protocol PostgrestInsertModel: PostgrestEncodable, Sendable {
  var attributesMetadata: [AnyAttributeMetadata] { get }
}

public protocol PostgrestUpdateModel: PostgrestEncodable, Sendable {
  var attributesMetadata: [AnyAttributeMetadata] { get }
}

public protocol PostgrestModel: Decodable, Sendable {
  associatedtype Attributes: Sendable
  associatedtype TypedAttributes: Sendable

  associatedtype Insert: PostgrestInsertModel
  associatedtype Update: PostgrestUpdateModel

  static var tableName: String { get }

  static var attributes: Attributes { get }
  static var typedAttributes: TypedAttributes { get }
}

public struct AnyAttributeMetadata {
  let name: String
  let keyPath: AnyKeyPath
}

extension AnyAttributeMetadata {
  init(codingKey: any CodingKey, keyPath: AnyKeyPath) {
    self.init(name: codingKey.stringValue, keyPath: keyPath)
  }
}

public struct AttributeMetadata<Model, Value> {
  let name: String
  let keyPath: KeyPath<Model, Value>
}

extension AttributeMetadata {
  init(codingKey: any CodingKey, keyPath: KeyPath<Model, Value>) {
    self.init(name: codingKey.stringValue, keyPath: keyPath)
  }
}

public class PostgrestTypedBuilder<Model: PostgrestModel, Response: Sendable> {
  var request: HTTPRequest

  init(request: HTTPRequest) {
    self.request = request
  }

  func execute() async throws -> Response {
    fatalError("unimplemented")
  }
}

extension [URLQueryItem] {
  mutating func appendOrUpdate(_ queryItem: URLQueryItem) {
    if let index = firstIndex(where: { $0.name == queryItem.name }) {
      self[index] = queryItem
    } else {
      append(queryItem)
    }
  }
}

public class PostgrestTypedQueryBuilder<Model: PostgrestModel>: PostgrestTypedBuilder<Model, Void> {
  public func select(
    _ columns: KeyPath<Model.Attributes, AnyAttributeMetadata>...
  ) -> PostgrestTypedFilterBuilder<Model, [Model]> {
    select(columns)
  }

  public func select(
    _ attributes: [KeyPath<Model.Attributes, AnyAttributeMetadata>] = []
  ) -> PostgrestTypedFilterBuilder<Model, [Model]> {
    let columns: String = if attributes.isEmpty {
      "*"
    } else {
      attributes.map { Model.attributes[keyPath: $0].name }.joined(separator: ",")
    }

    request.method = .get
    request.query.appendOrUpdate(URLQueryItem(name: "select", value: columns))

    return PostgrestTypedFilterBuilder(request: request)
  }

  public func insert(
    _ value: Model.Insert
  ) throws -> PostgrestTypedFilterBuilder<Model, Void> {
    request.method = .post
    request.body = try value.encoded()
    return PostgrestTypedFilterBuilder(request: request)
  }

  public func insert(
    _ values: [Model.Insert]
  ) throws -> PostgrestTypedFilterBuilder<Model, Void> {
    request.method = .post
    request.body = try values.encoded()

    var allKeys: Set<String> = []
    for value in values {
      allKeys.formUnion(value.attributesMetadata.map(\.name))
    }
    let allColumns = allKeys.sorted().joined(separator: ",")
    request.query.appendOrUpdate(URLQueryItem(name: "columns", value: allColumns))

    return PostgrestTypedFilterBuilder(request: request)
  }
}

public class PostgrestTypedFilterBuilder<Model: PostgrestModel, Response: Sendable>: PostgrestTypedTransformBuilder<Model, Response> {
  public func not<Value: URLQueryRepresentable>(
    _ column: KeyPath<Model.TypedAttributes, AttributeMetadata<Model, Value>>,
    _ value: Value
  ) -> PostgrestTypedFilterBuilder<Model, Response> {
    request.query.append(
      URLQueryItem(
        name: Model.typedAttributes[keyPath: column].name,
        value: value.queryValue
      )
    )

    return self
  }
}

public class PostgrestTypedTransformBuilder<Model: PostgrestModel, Response: Sendable>: PostgrestTypedBuilder<Model, Response> {
  public func select(
    _ attributes: KeyPath<Model.Attributes, AnyAttributeMetadata>...
  ) -> PostgrestTypedTransformBuilder<Model, [Model]> {
    select(attributes)
  }

  public func select(
    _ attributes: [KeyPath<Model.Attributes, AnyAttributeMetadata>] = []
  ) -> PostgrestTypedTransformBuilder<Model, [Model]> {
    let columns = attributes.map { Model.attributes[keyPath: $0].name }.joined(separator: ",")

    request.query.appendOrUpdate(URLQueryItem(name: "select", value: columns))

    if request.headers["prefer"] != nil {
      request.headers["prefer", default: ""] += ","
    }

    request.headers["prefer", default: ""] += "return=representation"

    return PostgrestTypedTransformBuilder<Model, [Model]>(request: request)
  }

  public func order(
    _ column: KeyPath<Model.Attributes, AnyAttributeMetadata>,
    ascending: Bool = true,
    nullsFirst: Bool = false,
    referencedTable: String? = nil
  ) -> PostgrestTypedTransformBuilder<Model, Response> {
    let key = referencedTable.map { "\($0).order" } ?? "order"
    let existingOrderIndex = request.query.firstIndex { $0.name == key }
    let value =
      "\(column).\(ascending ? "asc" : "desc").\(nullsFirst ? "nullsfirst" : "nullslast")"

    if let existingOrderIndex,
       let currentValue = request.query[existingOrderIndex].value
    {
      request.query[existingOrderIndex] = URLQueryItem(
        name: key,
        value: "\(currentValue),\(value)"
      )
    } else {
      request.query.append(URLQueryItem(name: key, value: value))
    }

    return self
  }

  public func single() -> PostgrestTypedTransformBuilder<Model, Model> where Response == [Model] {
    request.headers["Accept"] = "application/vnd.pgrst.object+json"
    return PostgrestTypedTransformBuilder<Model, Model>(request: request)
  }
}

extension PostgrestClient {
  public func from<Model: PostgrestModel>(_ model: Model.Type) -> PostgrestTypedQueryBuilder<Model> {
    PostgrestTypedQueryBuilder(
      request: HTTPRequest(
        url: configuration.url.appendingPathExtension(model.tableName),
        method: .get
      )
    )
  }
}

// import SwiftData
//
// @available(iOS 17, *)
// @Model
// class Author {
//  var name: String
//
//  init(name: String) {
//    self.name = name
//  }
// }
//
// @available(iOS 17, *)
// @Model
// class Book {
//  var id: UUID
//  var name: String
//
//  @Relationship
//  var author: Author
//
//  init(id: UUID, name: String, author: Author) {
//    self.id = id
//    self.name = name
//    self.author = author
//  }
// }
