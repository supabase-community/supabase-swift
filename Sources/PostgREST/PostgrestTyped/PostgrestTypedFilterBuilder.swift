//
//  PostgrestTypedFilterBuilder.swift
//
//
//  Created by Guilherme Souza on 21/06/24.
//

import Foundation

public class PostgrestTypedFilterBuilder<Model: PostgrestModel, Response: Sendable>: PostgrestTypedTransformBuilder<Model, Response> {
  public func not<Value: URLQueryRepresentable & Sendable>(
    _ column: KeyPath<Model.Metadata.TypedAttributes, PropertyMetadata<Model, Value>>,
    _ value: Value
  ) -> PostgrestTypedFilterBuilder<Model, Response> {
    let name = Model.Metadata.typedAttributes[keyPath: column].name
    request.withValue {
      $0.query.append(
        URLQueryItem(
          name: name,
          value: value.queryValue
        )
      )
    }

    return self
  }
}
