import CoreLocation


class LocationManager: CoreLocation.CLLocationManager, CLLocationManagerDelegate {
    let fulfiller: (CLLocation) -> Void
    let rejecter: (NSError) -> Void

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: AnyObject[]!) {
        fulfiller(locations[locations.count - 1] as CLLocation)
    }

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        rejecter(error)
    }

    init(fulfiller: (CLLocation) -> Void, rejecter: (NSError) -> Void) {
        self.fulfiller = fulfiller
        self.rejecter = rejecter
        super.init()
        delegate = self
        PMKRetain(self)
    }
}

extension CLLocationManager {
    class func promise() -> Promise<CLLocation> {
        let deferred = Promise<CLLocation>.defer()
        let manager = LocationManager(deferred.fulfiller, deferred.rejecter)
        manager.startUpdatingLocation()
        deferred.promise.finally {
            manager.delegate = nil
            manager.stopUpdatingLocation()
            PMKRelease(manager)
        }
        return deferred.promise
    }
}

extension CLGeocoder {
    class func reverseGeocode(location:CLLocation) -> Promise<CLPlacemark> {
        return Promise { (fulfiller, rejecter) in
            CLGeocoder().reverseGeocodeLocation(location) {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0[0] as CLPlacemark)
                }
            }
        }
    }

    class func geocode(#addressDictionary:Dictionary<String, String>) -> Promise<CLPlacemark> {
        return Promise { (fulfiller, rejecter) in
            CLGeocoder().geocodeAddressDictionary(addressDictionary) {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0[0] as CLPlacemark)
                }
            }
        }
    }

    class func geocode(#addressString:String) -> Promise<CLPlacemark> {
        return Promise { (fulfiller, rejecter) in
            CLGeocoder().geocodeAddressString(addressString) {
                if $1 {
                    rejecter($1)
                } else {
                    fulfiller($0[0] as CLPlacemark)
                }
            }
        }
    }
}
