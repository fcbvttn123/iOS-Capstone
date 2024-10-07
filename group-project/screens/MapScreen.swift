/*
Group Name: Byte_Buddies
Group Members:
- Tran Thanh Ngan Vu 991663076
- Chahat Jain 991668960
- Fizza Imran 991670304
- Chakshita Gupta 991653663
Description: This class manages the functionality related to searching for and selecting the home campus location on the map.
*/

import UIKit
import CoreLocation
import MapKit

class MapScreen: BaseViewController, UITextFieldDelegate, MKMapViewDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let locationManager = CLLocationManager()
    let regionRadius: CLLocationDistance = 1000
    var locations: [CLLocation] = [] // Array to store locations
    var homeCampusLocation: CLLocation? // Variable to store the home campus location
    var selectedLocation: CLLocation? // Variable to store the selected location
    var selectedMapItem: MKMapItem? // Variable to store the selected map item
    
    var searchResults: [MKMapItem] = []
    
    @IBOutlet var myMapView: MKMapView!
    @IBOutlet var tbLocEntered: UITextField!
    @IBOutlet var myTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myMapView.delegate = self
        tbLocEntered.delegate = self
        myTableView.dataSource = self
        myTableView.delegate = self
        
        tbLocEntered.placeholder = "Search for your campus"
        // Initialize locations array with some sample locations (you can replace these with your desired locations)
        let homeCampusLatitude = 43.7315
        let homeCampusLongitude = -79.7624
        homeCampusLocation = CLLocation(latitude: homeCampusLatitude, longitude: homeCampusLongitude)
        locations.append(homeCampusLocation!) // Add home campus to locations array
        locations.append(CLLocation(latitude: 43.7315, longitude: -79.7624)) // Brampton coordinates
        locations.append(CLLocation(latitude: 43.5890, longitude: -79.6441)) // Mississauga coordinates
        
        centerMapOnLocation(location: locations[0]) // Center map on the first location
        addAnnotationsForLocations(locations: locations) // Add annotations for all locations
    }
    
    // This function is used to make the keyboard disappear when we tap the "return" key
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }
    
    // MARK: - Helper Methods
    
    // This function centers the map on a given location
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        myMapView.setRegion(coordinateRegion, animated: true)
    }
    
    // MARK: - Search Functionality
    
    // This function searches for a new location based on the text entered in the text field
    @IBAction func findNewLocation(sender: Any) {
        myMapView.removeAnnotations(myMapView.annotations) // Clear existing annotations
        
        guard let locEnteredText = tbLocEntered.text else { return }
        let localSearchRequest = MKLocalSearch.Request()
        localSearchRequest.naturalLanguageQuery = locEnteredText
        let localSearch = MKLocalSearch(request: localSearchRequest)
        
        localSearch.start { [weak self] (response, error) in
            guard let self = self else { return }
            guard error == nil else {
                print("Error searching for your College: \(error!)")
                return
            }
            
            if let mapItems = response?.mapItems {
                self.searchResults = mapItems
                self.myTableView.reloadData()
                
                for item in mapItems {
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = item.placemark.coordinate
                    dropPin.title = item.name
                    self.myMapView.addAnnotation(dropPin)
                    self.myMapView.selectAnnotation(dropPin, animated: true)
                }
                
                if let firstItem = mapItems.first {
                    self.centerMapOnLocation(location: firstItem.placemark.location!)
                }
            }
        }
    }
    
    // This function adds annotations for the provided locations on the map
    func addAnnotationsForLocations(locations: [CLLocation]) {
        for location in locations {
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = location.coordinate
            myMapView.addAnnotation(dropPin)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 150
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)
        let mapItem = searchResults[indexPath.row]
        
        var addressDetails = ""
        
        if let street = mapItem.placemark.thoroughfare {
            addressDetails += "\nStreet: \(street)"
        }
        if let city = mapItem.placemark.locality {
            addressDetails += "\nCity: \(city)"
        }
        if let state = mapItem.placemark.administrativeArea {
            addressDetails += "\nState: \(state)"
        }
        if let postalCode = mapItem.placemark.postalCode {
            addressDetails += "\nPostal Code: \(postalCode)"
        }
        
        // Create attributed string for the cell's text label
        let attributedString = NSMutableAttributedString()
        let name = NSAttributedString(string: mapItem.name ?? "", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)])
        let details = NSAttributedString(string: addressDetails, attributes: nil)
        attributedString.append(name)
        attributedString.append(details)
        
        // Display attributed string in cell
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.attributedText = attributedString
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedMapItem = searchResults[indexPath.row]
        if let selectedLocation = selectedMapItem.placemark.location {
            self.selectedLocation = selectedLocation
            myMapView.removeAnnotations(myMapView.annotations) // Clear existing annotations
            
            let dropPin = MKPointAnnotation()
            dropPin.coordinate = selectedLocation.coordinate
            dropPin.title = selectedMapItem.name
            myMapView.addAnnotation(dropPin)
            myMapView.selectAnnotation(dropPin, animated: true)
            
            centerMapOnLocation(location: selectedLocation)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapScreen2" {
            if let destinationVC = segue.destination as? MapScreenCampus {
                // Prepare for navigation to the next screen if needed
            }
        }
    }
}
