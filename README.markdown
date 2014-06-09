Modern development is highly asynchronous: isn’t it about time iOS developers had tools that made programming asynchronously powerful, easy and delightful?

**Please note; the Swift version is still a work in progress.**

```swift
CLLocationManager.promise().catch { (_) -> CLLocation in
    // If location cannot be determined, default to Chicago
    return CLLocation(latitude: 41.89, longitude: -87.63)
}.then{ (ll:CLLocation) -> Promise<Dictionary<String, Any>> in
    let (lat, lon) = (ll.coordinate.latitude, ll.coordinate.longitude)
    return NSURLConnection.GET("http://user.net/\(lat)/\(lon)")
}.then { (user: Dictionary<String, Any>) -> Promise<Int> in
    let alert = UIAlertView()
    alert.title = "Hi " + (user["name"] as String)
    alert.addButtonWithTitle("Bye")
    alert.addButtonWithTitle("Hi")
    return alert.promise()
}.then { (tappedButtonIndex: Int) -> Promise<Void>? in
    if tappedButtonIndex == 0 {
        return nil
    }
    let vc = HelloViewController()
    return self.promiseViewController(vc).then { (modallyPresentedResult:String) -> Void in
        //…
    }
}.catch { (error:NSError) -> Void in
    //…
}
```

A little more explicit than we’d like. Once the Swift compiler is better with generics, the following should be possible:

```swift
CLLocationManager.promise().catch {
    // If location cannot be determined, default to Chicago
    return CLLocation(latitude: 41.89, longitude: -87.63)
}.then {
    let (lat, lon) = ($0.coordinate.latitude, $0.coordinate.longitude)
    return NSURLConnection.GET("http://user.net/\(lat)/\(lon)")
}.then { (user: Dictionary<String, String>) in
    let alert = UIAlertView()
    alert.title = "Hi " + user["name"]
    alert.addButtonWithTitle("Bye")
    alert.addButtonWithTitle("Hi")
    return alert.promise()
}.then { (tappedButtonIndex: Int) -> Promise<Void>? in
    if tappedButtonIndex == 0 {
        return nil
    }
    let vc = HelloViewController()
    return self.promiseViewController(vc).then { (modallyPresentedResult:String) -> Void in
        //…
    }
}.catch { (error:NSError) in
    //…
}
```

For guides and complete documentation visit [promisekit.org](http://promisekit.org).
