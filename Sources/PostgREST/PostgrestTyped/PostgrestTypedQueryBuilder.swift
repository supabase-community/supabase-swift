//
//  PostgrestTypedQueryBuilder.swift
//
//
//  Created by Guilherme Souza on 21/06/24.
//

import Foundation

public class PostgrestTypedQueryBuilder<Model: PostgrestModel>: PostgrestTypedBuilder<Model, Void> {
  public func select(
    _ columns: KeyPath<Model.Metadata.Attributes, AnyPropertyMetadata>...
  ) -> PostgrestTypedFilterBuilder<Model, [Model]> {
    select(columns)
  }

  public func select(
    _ attributes: [KeyPath<Model.Metadata.Attributes, AnyPropertyMetadata>] = []
  ) -> PostgrestTypedFilterBuilder<Model, [Model]> {
    let columns: String = if attributes.isEmpty {
      "*"
    } else {
      attributes.map { Model.Metadata.attributes[keyPath: $0].name }.joined(separator: ",")
    }

    return request.withValue {
      $0.method = .get
      $0.query.appendOrUpdate(URLQueryItem(name: "select", value: columns))

      return PostgrestTypedFilterBuilder(configuration: configuration, request: $0)
    }
  }

  public func insert(
    _ value: Model.Insert
  ) throws -> PostgrestTypedFilterBuilder<Model, Void> {
    try request.withValue {
      $0.method = .post
      $0.body = try Model.Insert.encoder.encode(value)
      return PostgrestTypedFilterBuilder(configuration: configuration, request: $0)
    }
  }

  public func insert(
    _ values: [Model.Insert]
  ) throws -> PostgrestTypedFilterBuilder<Model, Void> {
    try request.withValue {
      $0.method = .post
      $0.body = try Model.Insert.encoder.encode(values)

      var allKeys: Set<String> = []
      for value in values {
        allKeys.formUnion(value.propertiesMetadata.map(\.name))
      }
      let allColumns = allKeys.sorted().joined(separator: ",")
      $0.query.appendOrUpdate(URLQueryItem(name: "columns", value: allColumns))

      return PostgrestTypedFilterBuilder(configuration: configuration, request: $0)
    }
  }
}
