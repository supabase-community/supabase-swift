//
//  BaseTest.swift
//
//
//  Created by Guilherme Souza on 20/06/24.
//

import MacroTesting
import XCTest

class BaseTestCase: XCTestCase {
  override func invokeTest() {
    withMacroTesting(
      isRecording: true
    ) {
      super.invokeTest()
    }
  }
}
