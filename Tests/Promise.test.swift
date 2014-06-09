import XCTest
import PromiseKit

var expectation:XCTestExpectation = XCTestExpectation()


class TestPromise: XCTestCase {
    var random:UInt32 = 0

    func sealed() -> Promise<UInt32> {
        random = arc4random()
        expectation = self.expectationWithDescription("test value: \(random)")
        return Promise(value:random)
    }

    func unsealed() -> Promise<UInt32> {
        random = arc4random()
        expectation = self.expectationWithDescription("test value: \(random)")

        return Promise<UInt32> { (fulfiller, rejecter) in
            dispatch_async(dispatch_get_main_queue()){
                fulfiller(self.random)
            }
        }
    }

    func wait() {
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func test_001_hasValue() {
        let p:Promise<Int> = Promise(value:1)
        XCTAssertEqual(p.value!, 1)
    }

    func test_002_sealedCanThen() {
        sealed().then { (v:UInt32) -> Void in
            XCTAssertEqual(v, self.random)
            expectation.fulfill()
            return
        }
        wait()

        sealed().then {
            XCTAssertEqual($0, self.random)
        }.then {
            expectation.fulfill()
        }
        wait()
    }

    func test_003_unsealedCanThen() {
        unsealed().then { (v:UInt32) -> Void in
            XCTAssertEqual(v, self.random)
            expectation.fulfill()
        }
        wait()

        unsealed().then {
            XCTAssertEqual($0, self.random)
        }.then {
            expectation.fulfill()
        }
        wait()

        unsealed().then {
            XCTAssertEqual($0, self.random)
        }.then { () -> Void in
            
        }.then {
            expectation.fulfill()
        }
        wait()
    }

    func test_004_returnPromise() {
        sealed().then { (value) -> Promise<UInt32> in
            XCTAssertEqual(value, self.random)
            expectation.fulfill()
            return self.unsealed()
        }.then { (value) -> Void in
            XCTAssertEqual(value, self.random)
            expectation.fulfill()
        }
        wait()
    }

    func test_005_catch() {
        Promise<UInt32>{ (fulfiller, rejecter) -> Void in
            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: [:]))
        }.catch { (err:NSError) -> Void in
            XCTAssertEqual(err.code, 123)
        }
    }

    func test_006_catchAndContinue() {
        Promise<UInt32>{ (fulfiller, rejecter) -> Void in
            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: [:]))
        }.catch { (err:NSError) -> UInt32 in
            return 123  //TODO return err.code
        }.then{ (value:UInt32) -> Void in
            XCTAssertEqual(123, value)
        }
    }

    func test_007_finally() {
        expectation = self.expectationWithDescription("")
        Promise<UInt32>{ (fulfiller, rejecter) in
            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: [:]))
        }.finally {
            expectation.fulfill()
        }
        wait()

        expectation = self.expectationWithDescription("")
        Promise<Int>{ (fulfiller, rejecter) in
            fulfiller(123)
        }.finally {
            expectation.fulfill()
        }
        wait()

        let e1 = self.expectationWithDescription("")
        let e2 = self.expectationWithDescription("")

        Promise<UInt32>{ (fulfiller, rejecter) in
            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: [:]))
        }.finally {
            e1.fulfill()
        }.catch{ (err:NSError) -> Void in
            e2.fulfill()
            XCTAssertEqualObjects(err.domain, PMKErrorDomain)
        }
        wait()

        let e3 = self.expectationWithDescription("")
        let e4 = self.expectationWithDescription("")

        Promise<Int>{ (fulfiller, rejecter) in
            fulfiller(123)
        }.finally {
            e3.fulfill()
        }.then { (value:Int) -> Void in
            e4.fulfill()
            XCTAssertEqual(value, 123)
        }
        wait()
    }

//    func test_008_thenOffVoid() {
//        unsealed().then { (value:UInt32) -> Void in
//
//        }.then { (value:Void) -> Void
//
//        }
//    }

//    func test_008_catchReturnsVoid() {
//        Promise<UInt32>{ (fulfiller, rejecter) in
//            rejecter(NSError(domain: PMKErrorDomain, code: 123, userInfo: [:]))
//        }.catch { (err:NSError) -> Void
//            XCTAssertEqualObjects(err.code, 123)
//        }
//    }
}
