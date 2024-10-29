/*
Group Name: Byte_Buddies
Group Members:
- Tran Thanh Ngan Vu 991663076
- Chahat Jain 991668960
- Fizza Imran 991670304
- Chakshita Gupta 991653663
Description: This class manages the functionality related to searching for and selecting the location on the map.
*/

import UIKit
import MapKit
import CoreLocation

class MapScreen: BaseViewController, UITextFieldDelegate, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let locationManager = CLLocationManager()
    let initialLocation = CLLocation(latitude: 43.655787, longitude: -79.739534)
    
    @IBOutlet var myMapView: MKMapView!
    @IBOutlet var tbLocEntered: UITextField!
    @IBOutlet var myTableView: UITableView!
    
    var routeStep = ["Enter Destination To See Steps"] as NSMutableArray
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    let regionRadius: CLLocationDistance = 1000
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        myMapView.setRegion(coordinateRegion, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        centerMapOnLocation(location: initialLocation)
        
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = initialLocation.coordinate
        dropPin.title = "Starting at Sheridan College"
        myMapView.addAnnotation(dropPin)
        myMapView.selectAnnotation(dropPin, animated: true)
        
        myMapView.delegate = self  // Set the map view delegate
    }
    
    @IBAction func findNewLocation(sender: UIButton) {
        guard let locEnteredText = tbLocEntered.text, !locEnteredText.isEmpty else {
            print("Please enter a location.")
            return
        }
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(locEnteredText) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first, let location = placemark.location {
                let coordinates: CLLocationCoordinate2D = location.coordinate
                let newLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                self.centerMapOnLocation(location: newLocation)
                
                let dropPin = MKPointAnnotation()
                dropPin.coordinate = coordinates
                dropPin.title = placemark.name
                self.myMapView.addAnnotation(dropPin)
                self.myMapView.selectAnnotation(dropPin, animated: true)
                
                self.calculateRoute(to: coordinates)
            }
        }
    }
    
    func calculateRoute(to destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: initialLocation.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.requestsAlternateRoutes = false
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] response, error in
            if let error = error {
                print("Directions error: \(error.localizedDescription)")
                return
            }
            
            guard let routes = response?.routes else { return }
            self.myMapView.removeOverlays(self.myMapView.overlays) // Remove old overlays
            self.routeStep.removeAllObjects() // Clear old route steps
            
            for route in routes {
                self.myMapView.addOverlay(route.polyline, level: .aboveRoads)
                self.myMapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                
                for step in route.steps {
                    self.routeStep.add(step.instructions)
                }
            }
            self.myTableView.reloadData() // Reload the table view with new route steps
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1 // Only one section for route steps
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routeStep.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell()
        tableCell.textLabel?.text = routeStep[indexPath.row] as? String
        return tableCell
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        renderer.lineWidth = 5.0 // Optional: adjust line width for visibility
        return renderer
    }
}
