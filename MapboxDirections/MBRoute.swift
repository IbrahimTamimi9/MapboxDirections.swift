import Polyline

/**
 A `Route` object defines a single route that the user can follow to visit a series of waypoints in order. The route object includes information about the route, such as its distance and expected travel time. Depending on the criteria used to calculate the route, the route object may also include detailed turn-by-turn instructions.
 
 You do not create instances of this class directly. Instead, you receive route objects when you request directions using the `Directions.calculateDirections(options:completionHandler:)` method.
 */
@objc(MBRoute)
public class Route: NSObject {
    // MARK: Getting the Route Geometry
    
    /**
     An array of geographic coordinates defining the path of the route from start to finish.
     
     This array may be empty or simplified depending on the `routeShapeResolution` property of the original `RouteOptions` object.
     
     Using the [Mapbox iOS SDK](https://www.mapbox.com/ios-sdk/) or [Mapbox OS X SDK](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/osx/), you can create an `MGLPolyline` object using these coordinates to display an overview of the route on an `MGLMapView`.
     */
    public let coordinates: [CLLocationCoordinate2D]
    
    /**
     The number of coordinates.
     
     The value of this property may be zero or reduced depending on the `routeShapeResolution` property of the original `RouteOptions` object.
     
     - note: This initializer is intended for Objective-C usage. In Swift code, use the `coordinates.count` property.
     */
    public var coordinateCount: UInt {
        return UInt(coordinates.count)
    }
    
    /**
     Retrieves the coordinates.
     
     The array may be empty or simplified depending on the `routeShapeResolution` property of the original `RouteOptions` object.
     
     Using the [Mapbox iOS SDK](https://www.mapbox.com/ios-sdk/) or [Mapbox OS X SDK](https://github.com/mapbox/mapbox-gl-native/tree/master/platform/osx/), you can create an `MGLPolyline` object using these coordinates to display an overview of the route on an `MGLMapView`.
     
     - parameter coordinates: A pointer to a C array of `CLLocationCoordinate2D` instances. On output, this array contains all the vertices of the overlay.
     
     - precondition: `coordinates` must be large enough to hold `coordinateCount` instances of `CLLocationCoordinate2D`.
     
     - note: This initializer is intended for Objective-C usage. In Swift code, use the `coordinates` property.
     */
    public func getCoordinates(coordinates: UnsafeMutablePointer<CLLocationCoordinate2D>) {
        for i in 0..<self.coordinates.count {
            coordinates.advancedBy(i).memory = self.coordinates[i]
        }
    }
    
    /**
     An array of `RouteLeg` objects representing the legs of the route.
     
     The number of legs in this array depends on the number of waypoints. A route with two waypoints (the source and destination) has one leg, a route with three waypoints (the source, an intermediate waypoint, and the destination) has two legs, and so on.
     
     To determine the name of the route, concatenate the names of the route’s legs.
     */
    public let legs: [RouteLeg]
    
    // MARK: Getting Additional Route Details
    
    /**
     The route’s distance, measured in meters.
     
     The value of this property accounts for the distance that the user must travel to traverse the path of the route. It is the sum of the `distance` properties of the route’s legs, not the sum of the direct distances between the route’s waypoints. You should not assume that the user would travel along this distance at a fixed speed.
     */
    public let distance: CLLocationDistance
    
    /**
     The route’s expected travel time, measured in seconds.
     
     The value of this property reflects the time it takes to traverse the entire route under ideal conditions. It is the sum of the `expectedTravelTime` properties of the route’s legs. You should not assume that the user would travel along the route at a fixed speed. The actual travel time may vary based on the weather, traffic conditions, road construction, and other variables. If the route makes use of a ferry or train, the actual travel time may additionally be subject to the schedules of those services.
     */
    public let expectedTravelTime: NSTimeInterval
    
    /**
     A string specifying the primary mode of transportation for the route.
     
     The value of this property is `MBDirectionsProfileIdentifierAutomobile`, `MBDirectionsProfileIdentifierCycling`, or `MBDirectionsProfileIdentifierWalking`, depending on the `profileIdentifier` property of the original `RouteOptions` object. This property reflects the primary mode of transportation used for the route. Individual steps along the route might use different modes of transportation as necessary.
     */
    public let profileIdentifier: String
    
    // MARK: Creating a Route
    
    internal init(json: JSONDictionary, waypoints: [Waypoint], profileIdentifier: String) {
        self.profileIdentifier = profileIdentifier
        
        // Associate each leg JSON with a source and destination. The sequence of destinations is offset by one from the sequence of sources.
        let legInfo = zip(zip(waypoints.prefixUpTo(waypoints.endIndex - 1), waypoints.suffixFrom(1)),
                          json["legs"] as? [JSONDictionary] ?? [])
        legs = legInfo.map { (endpoints, json) -> RouteLeg in
            RouteLeg(json: json, source: endpoints.0, destination: endpoints.1, profileIdentifier: profileIdentifier)
        }
        distance = json["distance"] as! Double
        expectedTravelTime = json["duration"] as! Double
        coordinates = decodePolyline(json["geometry"] as! String, precision: 1e5)!
    }
}
