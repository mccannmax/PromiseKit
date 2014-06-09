import Foundation
import UIKit


class Promise<T>
{
    var _handlers:(() -> Void)[] = []
    var _value:Any?  //HACK because having type T crashes Xcode

    var value:T? {
        get {
            return _value as? T
        }
        set {  //TODO private
            _value = newValue
        }
    }
    var error:NSError?  //TODO wrap T and NSError in Swift Enum

    var  rejected:Bool { return error != nil }
    var fulfilled:Bool { return value != nil }
    var   pending:Bool { return !rejected && !fulfilled }

    class func defer() -> (promise:Promise, fulfiller:(T) -> Void, rejecter:(NSError) -> Void) {
        var f: ((T) -> Void)?
        var r: ((NSError) -> Void)?
        let p = Promise{ f = $0; r = $1 }
        return (p, f!, r!)
    }

    init(_ body:(fulfiller:(T) -> Void, rejecter:(NSError) -> Void) -> Void) {

        func recurse() {
            assert(!pending)
            for handler in _handlers { handler() }
            _handlers.removeAll(keepCapacity: false)
        }

        let rejecter = { (err:NSError) -> Void in
            if self.pending {
                self.error = err;
                recurse();
            }
        }

        let fulfiller = { (obj:T) -> Void in
            if self.pending {
                self.value = obj;
                recurse()
            }
        }

        body(fulfiller, rejecter)
    }

    init(value:T) {
        self.value = value
    }

    init(error:NSError) {
        self.error = error
    }

    func then<U>(body:(T) -> U) -> Promise<U> {
        if rejected {
            return Promise<U>(error: error!);
        }

        if fulfilled {
            return Promise<U>{ (fulfiller, rejecter) in
                let rv = body(self.value!)
                if rv is NSError {
                    rejecter(rv as NSError)
                } else {
                    fulfiller(rv)
                }
            }
        }

        return Promise<U>{ (fulfiller, rejecter) in
            self._handlers.append {
                assert(!self.pending)
                if self.rejected {
                    rejecter(self.error!)
                } else {
                    fulfiller(body(self.value!))
                }
            }
        }
    }

    func then<U>(body:(T) -> Promise<U>) -> Promise<U> {
        if rejected {
            return Promise<U>(error: error!);
        }

        if fulfilled {
            return body(self.value!)
        }

        return Promise<U>{ (fulfiller, rejecter) in
            self._handlers.append {
                assert(!self.pending)
                if self.rejected {
                    rejecter(self.error!)
                } else {
                    body(self.value!).then{ (obj:U) -> Void in
                        fulfiller(obj)
                    }
                }
            }
        }
    }

    func catch(body:(NSError) -> T) -> Promise<T> {
        if fulfilled {
            return Promise<T>(value:value!)
        }
        if rejected {
            let rv = body(self.error!)
            return Promise(value:rv)
        }

        return Promise<T>{ (fulfiller, rejecter) in
            self._handlers.append {
                assert(!self.pending)
                if self.fulfilled {
                    fulfiller(self.value!)
                } else {
                    fulfiller(body(self.error!))
                }
            }
        }
    }

    func catch(body:(NSError) -> Void) -> Void {
        if rejected {
            body(error!)
        } else if pending {
            self._handlers.append{
                assert(!self.pending)
                if self.rejected {
                    body(self.error!)
                }
            }
        }
    }

    func finally(body:() -> Void) -> Promise<T> {
        if !pending {
            body()
            return fulfilled ? Promise(value:value!) : Promise(error:error!)
        } else {
            return Promise { (fulfiller, rejecter) in
                self._handlers.append{
                    body()
                    if self.fulfilled {
                        fulfiller(self.value!)
                    } else {
                        rejecter(self.error!)
                    }
                }
            }
        }
    }
}
