//
//  RealtimeJoinPayload.swift
//
//
//  Created by Guilherme Souza on 24/12/23.
//

import Foundation

struct RealtimeJoinPayload: Codable, Hashable {
  var config: RealtimeJoinConfig
}

struct RealtimeJoinConfig: Codable, Hashable {
  var broadcast: BroadcastJoinConfig = .init()
  var presence: PresenceJoinConfig = .init()
  var postgresChanges: [PostgresJoinConfig] = []

  enum CodingKeys: String, CodingKey {
    case broadcast
    case presence
    case postgresChanges = "postgres_changes"
  }
}

public struct BroadcastJoinConfig: Codable, Hashable {
  public var acknowledgeBroadcasts: Bool = false
  public var receiveOwnBroadcasts: Bool = false

  enum CodingKeys: String, CodingKey {
    case acknowledgeBroadcasts = "ack"
    case receiveOwnBroadcasts = "self"
  }
}

public struct PresenceJoinConfig: Codable, Hashable {
  public var key: String = ""
}

public enum PostgresChangeEvent: String, Codable {
  case insert = "INSERT"
  case update = "UPDATE"
  case delete = "DELETE"
  case select = "SELECT"
  case all = "*"
}

struct PostgresJoinConfig: Codable, Hashable {
  var event: PostgresChangeEvent?
  var schema: String
  var table: String?
  var filter: String?
  var id: Int = 0

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.schema == rhs.schema
      && lhs.table == rhs.table
      && lhs.filter == rhs.filter
      && (lhs.event == rhs.event || rhs.event == .all)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(schema)
    hasher.combine(table)
    hasher.combine(filter)
    hasher.combine(event)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(event, forKey: .event)
    try container.encode(schema, forKey: .schema)
    try container.encode(table, forKey: .table)
    try container.encode(filter, forKey: .filter)

    if id != 0 {
      try container.encode(id, forKey: .id)
    }
  }
}
