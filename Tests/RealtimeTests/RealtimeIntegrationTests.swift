import ConcurrencyExtras
@testable import Realtime
import XCTest

final class RealtimeIntegrationTests: XCTestCase {
  var timeoutTimer: TimeoutTimer = .unimplemented
  var heartbeatTimer: HeartbeatTimer = .unimplemented

  private func makeSUT(file: StaticString = #file, line: UInt = #line) -> RealtimeClient {
    Dependencies.makeTimeoutTimer = {
      self.timeoutTimer
    }

    Dependencies.heartbeatTimer = { _ in
      self.heartbeatTimer
    }

    let sut = RealtimeClient(
      url: URL(string: "https://nixfbjgqturwbakhnwym.supabase.co/realtime/v1")!,
      params: [
        "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5peGZiamdxdHVyd2Jha2hud3ltIiwicm9sZSI6ImFub24iLCJpYXQiOjE2NzAzMDE2MzksImV4cCI6MTk4NTg3NzYzOX0.Ct6W75RPlDM37TxrBQurZpZap3kBy0cNkUimxF50HSo",
      ]
    )
    addTeardownBlock { [weak sut] in
      XCTAssertNil(sut, "RealtimeClient leaked.", file: file, line: line)
    }
    return sut
  }

  func testConnection() async {
    timeoutTimer = .noop
    heartbeatTimer = .noop

    let sut = makeSUT()

    let onOpenExpectation = expectation(description: "onOpen")
    sut.onOpen { [weak sut] in
      onOpenExpectation.fulfill()
      sut?.disconnect()
    }

    sut.onError { error, _ in
      XCTFail("connection failed with: \(error)")
    }

    let onCloseExpectation = expectation(description: "onClose")
    onCloseExpectation.assertForOverFulfill = false
    sut.onClose {
      onCloseExpectation.fulfill()
    }

    sut.connect()

    await fulfillment(of: [onOpenExpectation, onCloseExpectation])
  }

  func testOnChannelEvent() async {
    timeoutTimer = .noop
    heartbeatTimer = .noop
    let sut = makeSUT()

    sut.connect()

    let expectation = expectation(description: "subscribe")
    expectation.expectedFulfillmentCount = 2

    let channel = LockIsolated(RealtimeChannel?.none)
    addTeardownBlock { [weak channel = channel.value] in
      XCTAssertNil(channel, "RealtimeChannel leaked.")
    }

    let states = LockIsolated<[RealtimeSubscribeStates]>([])
    channel.setValue(
      sut
        .channel("public")
        .subscribe { state, error in
          states.withValue { $0.append(state) }

          if let error {
            XCTFail("Error subscribing to channel: \(error)")
          }

          expectation.fulfill()

          if state == .subscribed {
            channel.value?.unsubscribe()
          }
        }
    )

    await fulfillment(of: [expectation])
    XCTAssertEqual(states.value, [.subscribed, .closed])

    sut.disconnect()
  }
}
