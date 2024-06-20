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
      macros: [PostgrestModelMacro.self]
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
      }
      """
    } expansion: {
      """
      struct Book {
        let id: UUID
        var name: String
      }

      extension Book: PostgREST.PostgrestModel {
        static var tableName: String {
          "books"
        }

        enum CodingKeys: String, CodingKey {

        }

        struct Attributes {

        }

        static var attributes: Attributes {
          Attributes()
        }

        struct TypedAttributes {

        }

        static var typedAttributes: TypedAttributes {
          TypedAttributes()
        }

        @PostgrestInsertModel
        struct Insert {

        }

        @PostgrestUpdateModel
        struct Update {

        }
      }
      """
    }
  }
}
