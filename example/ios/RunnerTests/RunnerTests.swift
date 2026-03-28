import Flutter
import UIKit
import XCTest

@testable import lankapay_justpay_flutter

class RunnerTests: XCTestCase {

  func testGetDeviceIdReturnsString() {
    let plugin = LankapayJustpayFlutterPlugin()
    let call = FlutterMethodCall(methodName: "getDeviceId", arguments: [:])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssert(result is String)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 5)
  }
}
