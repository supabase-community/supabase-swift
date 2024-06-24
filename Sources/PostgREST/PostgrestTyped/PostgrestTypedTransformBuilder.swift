//
//  PostgrestTypedTransformBuilder.swift
//
//
//  Created by Guilherme Souza on 21/06/24.
//

import Foundation

public class PostgrestTypedTransformBuilder<Model: PostgrestModel, Response: Sendable>: PostgrestTypedBuilder<Model, Response> {
  public func select(
    _ attributes: KeyPath<Model.Metadata.Attributes, AnyPropertyMetadata>...
  ) -> PostgrestTypedTransformBuilder<Model, [Model]> {
    select(attributes)
  }

  public func select(
    _ attributes: [KeyPath<Model.Metadata.Attributes, AnyPropertyMetadata>] = []
  ) -> PostgrestTypedTransformBuilder<Model, [Model]> {
    let columns = attributes.map { Model.Metadata.attributes[keyPath: $0].name }.joined(separator: ",")

    return request.withValue {
      $0.query.appendOrUpdate(URLQueryItem(name: "select", value: columns))
      if $0.headers["prefer"] != nil {
        $0.headers["prefer", default: ""] += ","
      }

      $0.headers["prefer", default: ""] += "return=representation"

      return PostgrestTypedTransformBuilder<Model, [Model]>(configuration: configuration, request: $0)
    }
  }

  public func order(
    _ column: KeyPath<Model.Metadata.Attributes, AnyPropertyMetadata>,
    ascending: Bool = true,
    nullsFirst: Bool = false,
    referencedTable: String? = nil
  ) -> PostgrestTypedTransformBuilder<Model, Response> {
    let columnName = Model.Metadata.attributes[keyPath: column].name

    request.withValue {
      let key = referencedTable.map { "\($0).order" } ?? "order"
      let existingOrderIndex = request.query.firstIndex { $0.name == key }
      let value =
        "\(columnName).\(ascending ? "asc" : "desc").\(nullsFirst ? "nullsfirst" : "nullslast")"

      if let existingOrderIndex,
         let currentValue = $0.query[existingOrderIndex].value
      {
        $0.query[existingOrderIndex] = URLQueryItem(
          name: key,
          value: "\(currentValue),\(value)"
        )
      } else {
        $0.query.append(URLQueryItem(name: key, value: value))
      }
    }

    return self
  }

  public func single() -> PostgrestTypedTransformBuilder<Model, Model> where Response == [Model] {
    request.withValue {
      $0.headers["Accept"] = "application/vnd.pgrst.object+json"
      return PostgrestTypedTransformBuilder<Model, Model>(configuration: configuration, request: $0)
    }
  }
}
