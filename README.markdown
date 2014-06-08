Modern development is highly asynchronous: isn’t it about time iOS developers had tools that made programming asynchronously powerful, easy and delightful?

```swift
CLLocationManager.promise.catch {
    CLLocation(latitude: 41.89, longitude: -87.63)  // fail to Chicago
}.then {
    NSURLConnection.GET("http://user.net/\($0.latitude)/\($0.longitude)")
}.then { (user: [String:AnyObject]) in
    let alert = UIAlertView()
    alert.title = "Hi \(user.name)"
    alert.addButtonWithTitle("Bye")
    alert.addButtonWithTitle("Hi")
    return alert.promise()
}.then { (tappedButtonIndex: Int, alert: UIAlertView) in
    if tappedButtonIndex == alert.cancelButtonIndex {
        return nil
    }
    let vc = HelloViewController()
    return promiseViewController(vc, animated:true completion:nil).then { (resultFromViewController:AnyObject)
            //…
    }
}.catch { (error: NSError) in
    //…
}
```

The Swift version is still a work in progress.

For guides and complete documentation visit [promisekit.org](http://promisekit.org).
