//
//  PostgrestModelMacro.swift
//
//
//  Created by Guilherme Souza on 20/06/24.
//

import SwiftDiagnostics
import SwiftOperators
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

#if !canImport(SwiftSyntax600)
  import SwiftSyntaxMacroExpansion
#endif

public enum PostgrestModelMacro: MemberMacro, MemberAttributeMacro {
  static let moduleName = "PostgREST"
  static let conformanceName = "PostgrestModel"
  static var qualifiedConformanceName: String { "\(moduleName).\(conformanceName)" }
  static var conformanceNames: [String] { [conformanceName, qualifiedConformanceName] }

  public static func expansion(
    of _: AttributeSyntax,
    attachedTo _: some DeclGroupSyntax,
    providingAttributesFor _: some DeclSyntaxProtocol,
    in _: some MacroExpansionContext
  ) throws -> [AttributeSyntax] {
    []
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let declaration = declaration.as(StructDeclSyntax.self) else {
      context.diagnose(
        Diagnostic(
          node: declaration,
          message: MacroExpansionErrorMessage(
            "'@PostgrestModel' can only be applied to struct types.'"
          )
        )
      )
      return []
    }

    return [
    ]
  }
}

extension PostgrestModelMacro: ExtensionMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo _: [SwiftSyntax.TypeSyntax],
    in _: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    if let inheritanceClause = declaration.inheritanceClause,
       inheritanceClause.inheritedTypes.contains(where: { Self.conformanceNames.contains($0.type.trimmedDescription) })
    {
      return []
    }

    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
          let tableNameArgument = arguments.first(where: { $0.label?.trimmedDescription == "tableName" })
    else {
      return []
    }

    let tableName = tableNameArgument.expression.trimmedDescription

    let ext: DeclSyntax = """
    extension \(type.trimmed): \(raw: Self.qualifiedConformanceName) {
      static var tableName: String {
        \(raw: tableName)
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
    return [ext.cast(ExtensionDeclSyntax.self)]
  }
}

extension AttributeListSyntax {
  var availability: AttributeListSyntax? {
    var elements = [AttributeListSyntax.Element]()
    for element in self {
      if let availability = element.availability {
        elements.append(availability)
      }
    }
    if elements.isEmpty {
      return nil
    }
    return AttributeListSyntax(elements)
  }
}

extension AttributeListSyntax.Element {
  var availability: AttributeListSyntax.Element? {
    switch self {
    case let .attribute(attribute):
      if let availability = attribute.availability {
        return .attribute(availability)
      }
    case let .ifConfigDecl(ifConfig):
      if let availability = ifConfig.availability {
        return .ifConfigDecl(availability)
      }
    }
    return nil
  }
}

extension AttributeSyntax {
  var availability: AttributeSyntax? {
    if attributeName.identifier == "available" {
      self
    } else {
      nil
    }
  }
}

extension IfConfigClauseSyntax {
  var availability: IfConfigClauseSyntax? {
    if let availability = elements?.availability {
      with(\.elements, availability)
    } else {
      nil
    }
  }

  var clonedAsIf: IfConfigClauseSyntax {
    detached.with(\.poundKeyword, .poundIfToken())
  }
}

extension IfConfigClauseSyntax.Elements {
  var availability: IfConfigClauseSyntax.Elements? {
    switch self {
    case let .attributes(attributes):
      if let availability = attributes.availability {
        .attributes(availability)
      } else {
        nil
      }
    default:
      nil
    }
  }
}

extension IfConfigDeclSyntax {
  var availability: IfConfigDeclSyntax? {
    var elements = [IfConfigClauseListSyntax.Element]()
    for clause in clauses {
      if let availability = clause.availability {
        if elements.isEmpty {
          elements.append(availability.clonedAsIf)
        } else {
          elements.append(availability)
        }
      }
    }
    if elements.isEmpty {
      return nil
    } else {
      return with(\.clauses, IfConfigClauseListSyntax(elements))
    }
  }
}

extension TypeSyntax {
  var identifier: String? {
    for token in tokens(viewMode: .all) {
      switch token.tokenKind {
      case let .identifier(identifier):
        return identifier
      default:
        break
      }
    }
    return nil
  }
}
