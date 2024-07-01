//
//  FoundationExtensions.swift
//
//
//  Created by Guilherme Souza on 23/04/24.
//

import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking

  package let NSEC_PER_SEC: UInt64 = 1000000000
  package let NSEC_PER_MSEC: UInt64 = 1000000
#endif

extension Result {
  package var value: Success? {
    if case let .success(value) = self {
      value
    } else {
      nil
    }
  }

  package var error: Failure? {
    if case let .failure(error) = self {
      error
    } else {
      nil
    }
  }
}

extension URL {
  package mutating func appendQueryItems(_ queryItems: [URLQueryItem]) {
    guard !queryItems.isEmpty else {
      return
    }

    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
      return
    }

    let currentQueryItems = components.percentEncodedQueryItems ?? []

    components.percentEncodedQueryItems = currentQueryItems + queryItems.map {
      URLQueryItem(
        name: escape($0.name),
        value: $0.value.map(escape)
      )
    }

    if let newURL = components.url {
      self = newURL
    }
  }

  package func appendingQueryItems(_ queryItems: [URLQueryItem]) -> URL {
    var url = self
    url.appendQueryItems(queryItems)
    return url
  }
}

extension [URLQueryItem] {
  package mutating func appendOrUpdate(_ queryItem: URLQueryItem) {
    if let index = firstIndex(where: { $0.name == queryItem.name }) {
      self[index] = queryItem
    } else {
      append(queryItem)
    }
  }
}

func escape(_ string: String) -> String {
  string.addingPercentEncoding(withAllowedCharacters: .sbURLQueryAllowed) ?? string
}

extension CharacterSet {
  /// Creates a CharacterSet from RFC 3986 allowed characters.
  ///
  /// RFC 3986 states that the following characters are "reserved" characters.
  ///
  /// - General Delimiters: ":", "#", "[", "]", "@", "?", "/"
  /// - Sub-Delimiters: "!", "$", "&", "'", "(", ")", "*", "+", ",", ";", "="
  ///
  /// In RFC 3986 - Section 3.4, it states that the "?" and "/" characters should not be escaped to allow
  /// query strings to include a URL. Therefore, all "reserved" characters with the exception of "?" and "/"
  /// should be percent-escaped in the query string.
  static let sbURLQueryAllowed: CharacterSet = {
    let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
    let subDelimitersToEncode = "!$&'()*+,;="
    let encodableDelimiters = CharacterSet(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")

    return CharacterSet.urlQueryAllowed.subtracting(encodableDelimiters)
  }()
}
