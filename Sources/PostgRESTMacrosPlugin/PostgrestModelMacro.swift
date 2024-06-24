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

public enum PostgrestModelMacro {
  static let moduleName = "PostgREST"
  static let conformanceName = "PostgrestModel"
  static var qualifiedConformanceName: String { "\(moduleName).\(conformanceName)" }
  static var conformanceNames: [String] { [conformanceName, qualifiedConformanceName] }
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

    let ext: DeclSyntax = """
    extension \(type.trimmed): \(raw: Self.qualifiedConformanceName) {}
    """
    return [ext.cast(ExtensionDeclSyntax.self)]
  }
}

extension PostgrestModelMacro: MemberMacro {
  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    in _: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let arguments = node.arguments?.as(LabeledExprListSyntax.self) else { return [] }

    guard let tableName = arguments.first(where: { $0.label?.trimmedDescription == "tableName" })?.expression.trimmedDescription else { return [] }

    return [
      generateCodingKeysEnumDecl(declaration: declaration),
      generateSchemaMetadataEnumDecl(tableName: tableName),
      generateInsertModelDecl(declaration: declaration),
      generateUpdateModelDecl(),
    ]
  }

  private static func generateCodingKeysEnumDecl(
    declaration: some DeclGroupSyntax
  ) -> DeclSyntax {
    let members = declaration.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
    let bindings = members.compactMap {
      $0.bindings.first?.pattern.trimmedDescription
    }

    let codingKeysDecl: DeclSyntax = """
    enum CodingKeys: String, CodingKey {
      \(raw: bindings.map { "case \($0) = \"\($0)\"" }.joined(separator: "\n"))
    }
    """

    return codingKeysDecl
  }

  private static func generateSchemaMetadataEnumDecl(
    tableName: String
  ) -> DeclSyntax {
    let tableNameDecl: DeclSyntax = """
    static let tableName = \(raw: tableName)
    """

    let attributesStructDecl: DeclSyntax = """
    struct Attributes {}
    """

    let typedAttributesStructDecl: DeclSyntax = """
    struct TypedAttributes {}
    """

    let enumMetadataDecl: DeclSyntax = """
    enum Metadata: SchemaMetadata {
    \(tableNameDecl)

    static let attributes = Attributes()
    \(attributesStructDecl)

    static let typedAttributes = TypedAttributes()
    \(typedAttributesStructDecl)
    }
    """

    return enumMetadataDecl
  }

  private static func generateInsertModelDecl(declaration: some DeclGroupSyntax) -> DeclSyntax {
    let members: [DeclSyntax] = declaration.memberBlock.members
      .compactMap { $0.decl.as(VariableDeclSyntax.self) }
      .compactMap(\.bindings.first)
      .map {
        let propertyName = $0.pattern.trimmedDescription

        var type: OptionalTypeSyntax? = if let optionalType = $0.typeAnnotation?.type.as(OptionalTypeSyntax.self) {
          optionalType
        } else {
          $0.typeAnnotation.map { OptionalTypeSyntax(wrappedType: $0.type) }
        }

        return """
        let \(raw: propertyName): \(raw: type?.trimmedDescription ?? "")
        """
      }

    let insertModelDecl: DeclSyntax = """
    struct Insert {
    \(raw: members.map(\.trimmedDescription).joined(separator: "\n"))
    }
    """

    return insertModelDecl
  }

  private static func generateUpdateModelDecl() -> DeclSyntax {
    let updateModelDecl: DeclSyntax = """
    struct Update {}
    """

    return updateModelDecl
  }
}

/*
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
 */

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
