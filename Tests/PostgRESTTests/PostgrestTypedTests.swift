//
//  PostgrestTypedTests.swift
//
//
//  Created by Guilherme Souza on 20/06/24.
//

import Foundation
@testable import PostgREST
import XCTest

class PostgrestTypedTests: XCTestCase {
  let client = PostgrestClient(url: URL(string: "http://localhost:54321/rest")!, logger: nil)

  func testBasics() async throws {
//    let query = try await client
//      .from(Book.self)
//      .select(\.id, \.name)
//      .not(\.id, UUID())
//      .order(\.name)
//      .single()
//      .execute()
  }

  func testSelect() {
    var query = client.from(Book.self).select(\.id, \.name)
    XCTAssertEqual(query.request.method, .get)
    XCTAssertEqual(
      query.request.query,
      [
        URLQueryItem(name: "select", value: "id,name"),
      ]
    )

    query = client.from(Book.self).select()
    XCTAssertEqual(
      query.request.query,
      [
        URLQueryItem(name: "select", value: "*"),
      ]
    )
  }

  func testInsert() throws {
    let book = Book.Insert(
      name: "The Night Circus",
      authorId: UUID()
    )

    let encodedData = try book.encoded()

    let query = try client.from(Book.self)
      .insert(book)
      .select(\.id)

    XCTAssertEqual(query.request.method, .post)
    XCTAssertEqual(query.request.body, encodedData)

    XCTAssertEqual(
      query.request.query,
      [
        URLQueryItem(name: "select", value: "id"),
      ]
    )

    XCTAssertEqual(query.request.headers["prefer"], "return=representation")
  }

  func testInsertMany() throws {
    let books = [
      Book.Insert(
        name: "The Lord of The Rings",
        authorId: UUID()
      ),
      Book.Insert(
        name: "The Hobbit",
        authorId: UUID()
      ),
    ]

    let encodedData = try books.encoded()

    let query = try client.from(Book.self)
      .insert(books)
      .select(\.id)

    XCTAssertEqual(query.request.method, .post)
    XCTAssertEqual(query.request.body, encodedData)

    XCTAssertEqual(
      query.request.query,
      [
        URLQueryItem(name: "columns", value: "author_id,name"),
        URLQueryItem(name: "select", value: "id"),
      ]
    )

    XCTAssertEqual(query.request.headers["prefer"], "return=representation")
  }
}

// @PostgrestModel(tableName: "authors")
struct Author {
  let id: UUID
  var name: String
}

// @PostgrestModel(tableName: "books")
struct Book {
  let id: UUID
  var name: String

  // @Attribute(name: "author_id")
  var authorId: UUID

  // @Relationship(id: \.authorId)
  var author: Author
}

extension Author: PostgrestModel {
  static var tableName: String {
    "authors"
  }

  enum CodingKeys: String, CodingKey {
    case id, name
  }

  struct Attributes {
    let id = AnyAttributeMetadata(codingKey: CodingKeys.id, keyPath: \Author.id)
    let name = AnyAttributeMetadata(codingKey: CodingKeys.name, keyPath: \Author.name)
  }

  static var attributes = Attributes()

  struct TypedAttributes {
    let id = AttributeMetadata(codingKey: CodingKeys.id, keyPath: \Author.id)
    let name = AttributeMetadata(codingKey: CodingKeys.name, keyPath: \Author.name)
  }

  static var typedAttributes = TypedAttributes()

  struct Insert: PostgrestInsertModel {
    var id: UUID?
    var name: String

    var attributesMetadata: [AnyAttributeMetadata] {
      var attributes = [AnyAttributeMetadata]()

      if id != nil {
        attributes.append(AnyAttributeMetadata(codingKey: CodingKeys.id, keyPath: \Insert.id))
      }

      attributes.append(AnyAttributeMetadata(codingKey: CodingKeys.name, keyPath: \Insert.name))

      return attributes
    }
  }

  struct Update: PostgrestUpdateModel {
    var id: UUID?
    var name: String?

    var attributesMetadata: [AnyAttributeMetadata] {
      var attributes = [AnyAttributeMetadata]()

      if id != nil {
        attributes.append(AnyAttributeMetadata(codingKey: CodingKeys.id, keyPath: \Update.id))
      }

      if name != nil {
        attributes.append(AnyAttributeMetadata(codingKey: CodingKeys.name, keyPath: \Update.name))
      }

      return attributes
    }
  }
}

extension Book: PostgrestModel {
  static var tableName: String {
    "books"
  }

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case authorId = "author_id"
    case author
  }

  struct Attributes {
    let id = AnyAttributeMetadata(codingKey: CodingKeys.id, keyPath: \Book.id)
    let name = AnyAttributeMetadata(codingKey: CodingKeys.name, keyPath: \Book.name)
    let authorId = AnyAttributeMetadata(codingKey: CodingKeys.authorId, keyPath: \Book.authorId)
  }

  struct TypedAttributes {
    let id = AttributeMetadata(codingKey: CodingKeys.id, keyPath: \Book.id)
    let name = AttributeMetadata(codingKey: CodingKeys.name, keyPath: \Book.name)
    let authorId = AttributeMetadata(codingKey: CodingKeys.authorId, keyPath: \Book.authorId)
  }

  static let attributes = Attributes()
  static let typedAttributes = TypedAttributes()

  struct Insert: PostgrestInsertModel {
    var id: UUID?
    var name: String
    var authorId: UUID

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case authorId = "author_id"
    }

    var attributesMetadata: [AnyAttributeMetadata] {
      var attributes = [AnyAttributeMetadata]()

      if id != nil {
        attributes.append(AnyAttributeMetadata(codingKey: CodingKeys.id, keyPath: \Insert.id))
      }

      attributes.append(AnyAttributeMetadata(codingKey: CodingKeys.name, keyPath: \Insert.name))
      attributes.append(AnyAttributeMetadata(codingKey: CodingKeys.authorId, keyPath: \Insert.authorId))

      return attributes
    }
  }

  struct Update: PostgrestUpdateModel {
    var id: UUID?
    var name: String?
    var authorId: UUID?

    enum CodingKeys: String, CodingKey {
      case id
      case name
      case authorId = "author_id"
    }

    var attributesMetadata: [AnyAttributeMetadata] {
      var attributes = [AnyAttributeMetadata]()

      if id != nil {
        attributes.append(AnyAttributeMetadata(codingKey: CodingKeys.id, keyPath: \Update.id))
      }

      if name != nil {
        attributes.append(AnyAttributeMetadata(codingKey: CodingKeys.name, keyPath: \Update.name))
      }

      if authorId != nil {
        attributes.append(AnyAttributeMetadata(codingKey: CodingKeys.authorId, keyPath: \Update.authorId))
      }

      return attributes
    }
  }
}
