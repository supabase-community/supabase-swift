//
//  _Push.swift
//
//
//  Created by Guilherme Souza on 02/01/24.
//

import Foundation
@_spi(Internal) import _Helpers

actor _Push {
  private weak var channel: RealtimeChannelV2?
  let message: RealtimeMessageV2

  private var receivedContinuation: CheckedContinuation<PushStatus, Never>?

  init(channel: RealtimeChannelV2?, message: RealtimeMessageV2) {
    self.channel = channel
    self.message = message
  }

  func send() async -> PushStatus {
    do {
      try await channel?.socket?.mutableState.ws?.send(message)

      if channel?.config.broadcast.acknowledgeBroadcasts == true {
        return await withCheckedContinuation {
          receivedContinuation = $0
        }
      }

      return .ok
    } catch {
      debug("""
      Failed to send message:
      \(message)

      Error:
      \(error)
      """)
      return .error
    }
  }

  func didReceive(status: PushStatus) {
    receivedContinuation?.resume(returning: status)
    receivedContinuation = nil
  }
}
