//
//  PostgrestModelMacroTests.swift
//
//
//  Created by Guilherme Souza on 20/06/24.
//

import Foundation
import MacroTesting
import PostgRESTMacrosPlugin
import XCTest

final class PostgrestModelMacroTests: BaseTestCase {
  override func invokeTest() {
    withMacroTesting(
      isRecording: true,
      macros: [
        PostgrestModelMacro.self,
      ]
    ) {
      super.invokeTest()
    }
  }

  func testBasics() {
    assertMacro {
      """
      @PostgrestModel(tableName: "books")
      struct Book {
        let id: UUID
        var name: String
        var authorId: UUID?
      }
      """
    } expansion: {
      """
      struct Book {
        let id: UUID
        var name: String
        var authorId: UUID?

        enum CodingKeys: String, CodingKey {
          case id = "id"
          case name = "name"
          case authorId = "authorId"
        }

        enum Metadata: SchemaMetadata {
          static let tableName = "books"

          static let attributes = Attributes()
          struct Attributes {
          }

          static let typedAttributes = TypedAttributes()
          struct TypedAttributes {
          }
        }

        struct Insert {
          let id: UUID?
          let name: String?
          let authorId: UUID?
        }

        struct Update {
        }
      }

      extension Book: PostgREST.PostgrestModel {
      }
      """
    }
  }
}
