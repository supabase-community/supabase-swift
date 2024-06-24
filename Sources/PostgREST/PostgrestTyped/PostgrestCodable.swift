//
//  PostgrestCodable.swift
//
//
//  Created by Guilherme Souza on 21/06/24.
//

import Foundation

public protocol PostgrestEncodable: Encodable {
  static var encoder: JSONEncoder { get }
}

extension PostgrestEncodable {
  public static var encoder: JSONEncoder {
    PostgrestClient.Configuration.jsonEncoder
  }
}

public protocol PostgrestDecodable: Decodable {
  static var decoder: JSONDecoder { get }
}

extension PostgrestDecodable {
  public static var decoder: JSONDecoder {
    PostgrestClient.Configuration.jsonDecoder
  }
}

public typealias PostgrestCodable = PostgrestDecodable & PostgrestEncodable
