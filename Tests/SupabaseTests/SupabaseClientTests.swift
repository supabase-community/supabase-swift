@testable import Auth
import CustomDump
@testable import Functions
@testable import Realtime
@testable import Supabase
import XCTest

final class AuthLocalStorageMock: AuthLocalStorage {
  func store(key _: String, value _: Data) throws {}

  func retrieve(key _: String) throws -> Data? {
    nil
  }

  func remove(key _: String) throws {}
}

final class SupabaseClientTests: XCTestCase {
  func testClientInitialization() async {
    final class Logger: SupabaseLogger {
      func log(message _: SupabaseLogMessage) {
        // no-op
      }
    }

    let logger = Logger()
    let customSchema = "custom_schema"
    let localStorage = AuthLocalStorageMock()
    let customHeaders = ["header_field": "header_value"]

    let client = SupabaseClient(
      supabaseURL: URL(string: "https://project-ref.supabase.co")!,
      supabaseKey: "ANON_KEY",
      options: SupabaseClientOptions(
        db: SupabaseClientOptions.DatabaseOptions(schema: customSchema),
        auth: SupabaseClientOptions.AuthOptions(
          storage: localStorage,
          autoRefreshToken: false
        ),
        global: SupabaseClientOptions.GlobalOptions(
          headers: customHeaders,
          session: .shared,
          logger: logger
        ),
        functions: SupabaseClientOptions.FunctionsOptions(
          region: .apNortheast1
        ),
        realtime: RealtimeClientOptions(
          headers: ["custom_realtime_header_key": "custom_realtime_header_value"]
        )
      )
    )

    XCTAssertEqual(client.supabaseURL.absoluteString, "https://project-ref.supabase.co")
    XCTAssertEqual(client.supabaseKey, "ANON_KEY")
    XCTAssertEqual(client.storageURL.absoluteString, "https://project-ref.supabase.co/storage/v1")
    XCTAssertEqual(client.databaseURL.absoluteString, "https://project-ref.supabase.co/rest/v1")
    XCTAssertEqual(
      client.functionsURL.absoluteString,
      "https://project-ref.supabase.co/functions/v1"
    )

    XCTAssertEqual(
      client.defaultHeaders,
      [
        "X-Client-Info": "supabase-swift/\(Supabase.version)",
        "Apikey": "ANON_KEY",
        "header_field": "header_value",
        "Authorization": "Bearer ANON_KEY",
      ]
    )

    XCTAssertEqual(client.functions.region, "ap-northeast-1")

    let realtimeURL = client.realtimeV2.url
    XCTAssertEqual(realtimeURL.absoluteString, "https://project-ref.supabase.co/realtime/v1")

    let realtimeOptions = client.realtimeV2.options
    let expectedRealtimeHeader = client.defaultHeaders.merged(
      with: ["custom_realtime_header_key": "custom_realtime_header_value"]
    )
    XCTAssertNoDifference(realtimeOptions.headers, expectedRealtimeHeader)
    XCTAssertIdentical(realtimeOptions.logger as? Logger, logger)

    XCTAssertFalse(client.auth.configuration.autoRefreshToken)

    XCTAssertNotNil(
      client.mutableState.listenForAuthEventsTask,
      "should listen for internal auth events"
    )
  }

  #if !os(Linux)
    func testClientInitWithDefaultOptionsShouldBeAvailableInNonLinux() {
      _ = SupabaseClient(
        supabaseURL: URL(string: "https://project-ref.supabase.co")!,
        supabaseKey: "ANON_KEY"
      )
    }
  #endif

  func testClientInitWithCustomAccessToken() async {
    let client = SupabaseClient(
      supabaseURL: URL(string: "https://project-ref.supabase.co")!,
      supabaseKey: "ANON_KEY",
      options: .init(
        auth: .init(
          accessToken: { "jwt" }
        )
      )
    )

    XCTAssertNil(
      client.mutableState.listenForAuthEventsTask,
      "should not listen for internal auth events when using 3p authentication"
    )

    overridedPreconditionHandler.setValue { _, message, _, _ in
      XCTAssertEqual(
        message(),
        "Supabase Client is configured with the auth.accessToken option, accessing supabase.auth is not possible."
      )
    }

    _ = client.auth
  }
}
