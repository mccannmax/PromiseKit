import UIKit
import CoreLocation
import PromiseKit
import MapKit  // interestingly you have to import again, so imports inside frameworks aren't public?


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions: NSDictionary?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = UINavigationController(rootViewController: ViewController())
        self.window!.backgroundColor = UIColor.whiteColor()
        self.window!.makeKeyAndVisible()
        return true
    }
}


class ViewController: UIViewController, CLLocationManagerDelegate {
    override func loadView() {
        let iv = UIImageView(frame:CGRect(x:0, y:0, width: 100, height: 100))
        self.view = iv
        iv.contentMode = .Center

        NSURLConnection.GET("http://placekitten.com/250/250").then{ (img:UIImage) in
            self.title = "Cat"
            iv.image = img
            return CLGeocoder.geocode(addressString:"Mount Rushmore")
        }.then { (placemark:CLPlacemark) in
            self.title = "Located"
            let opts = MKMapSnapshotOptions()
            opts.region = MKCoordinateRegion(center: placemark.location.coordinate, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
            let snapshotter = MKMapSnapshotter(options:opts)
            return snapshotter.promise()
        }.then { (snapshot:MKMapSnapshot) -> Void in
            self.title = "Map Snapshot"
            iv.image = snapshot.image
        }
    }
}
