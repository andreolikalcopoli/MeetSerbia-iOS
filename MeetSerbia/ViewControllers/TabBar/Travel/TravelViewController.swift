//
//  TravelViewController.swift
//  MeetSerbia
//
//  Created by Nemanja Ducic on 9.3.23..
//

import UIKit
import MapboxMaps
import MapboxCoreMaps
import CoreLocation
import Firebase
import MapboxCommon
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation

class TravelViewController: UIViewController, CLLocationManagerDelegate,UISearchBarDelegate,UITableViewDelegate,UITableViewDataSource {
    private let storageRef = Storage.storage().reference()
    
    
    //LOCAL HOLDERS
    private var coordinatePointsArray = [CoordinateModel]() // SLUZI U SLUCAJU DA SACUVAMO RUTU
    private var coordinatesForPointsFromAdd = [CoordinateModel]()
    var waypointsArray = [Waypoint]() // WAYPOINTI ZA NAVIGACIJU
    var wayPointsAditionalyAded = [Waypoint]() // WAYPOINTI IZ ADD BUTTONA
    var pointAnnotationManager : PointAnnotationManager?
    var selectedAnnotation: PointAnnotation? //SELEKTOVANA ANOTACIJA
    private var selectedLocationStart:LocationModel?
    private var selectedLocationEnd:LocationModel?
    var currentLatitude: CLLocationDegrees?
    var currentLongitude: CLLocationDegrees?
    private var filteredData = [String]()
    var locationManager = CLLocationManager()
    var didSelectSearchForStartingPoint = false
    
    // OUTLETS
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var mhHolderView: UIView!
    @IBOutlet weak var holderImage: UIImageView!
    @IBOutlet weak var addbtn: UIButton!
    @IBOutlet weak var holderLabel: UILabel!
    @IBOutlet weak var holderView: UIStackView!
    @IBOutlet weak var saveRoutesButton: UIButton!
    @IBOutlet weak var showLocalitiesButton: UIButton!
    @IBOutlet weak var startNavButton: UIButton!
    @IBOutlet weak var searchTableBiew: UITableView!
    @IBOutlet weak var searchEnd: UISearchBar!
    @IBOutlet weak var seachStart: UISearchBar!
    internal var mapView: MapView!
    @IBOutlet weak var stackView: UIStackView!
    
 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initSetup()
       
        self.mhHolderView.addSubview(mapView)
        self.mhHolderView.bringSubviewToFront(searchEnd)
        self.mhHolderView.bringSubviewToFront(seachStart)
        self.mhHolderView.bringSubviewToFront(searchTableBiew)
        self.mhHolderView.bringSubviewToFront(startNavButton)
        self.mhHolderView.bringSubviewToFront(showLocalitiesButton)
        self.mhHolderView.bringSubviewToFront(saveRoutesButton)
        self.mhHolderView.bringSubviewToFront(stackView)
        self.mhHolderView.bringSubviewToFront(holderView)
        self.mhHolderView.bringSubviewToFront(holderLabel)
    
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = filteredData[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredData.count
    }
    private  func initSetup(){
        holderView.isHidden = true
        stackView.isHidden = true
        saveRoutesButton.isHidden = true
        addbtn.layer.cornerRadius = 15
        searchEnd.delegate = self
        seachStart.delegate = self
        searchTableBiew.dataSource = self
        searchTableBiew.delegate = self
        
        searchTableBiew.isHidden = true
        holderView.layoutMargins = UIEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
        holderView.isLayoutMarginsRelativeArrangement = true
        // Create Button
               let button = UIButton(type: .custom)
               button.setTitle("", for: .normal)
               button.setTitleColor(.white, for: .normal)
               button.backgroundColor = .clear
               button.translatesAutoresizingMaskIntoConstraints = false
            button.setImage(UIImage(named: "x"), for: .normal) // Set image for the button

               button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
                holderView.addSubview(button)
                NSLayoutConstraint.activate([
                  button.topAnchor.constraint(equalTo: holderView.topAnchor, constant: 16),
                  button.trailingAnchor.constraint(equalTo: holderView.trailingAnchor, constant: -16),
                  button.widthAnchor.constraint(equalToConstant: 40),
                  button.heightAnchor.constraint(equalToConstant: 40)
              ])
       
        // Delegates
        locationManager.delegate = self
        self.tabBarController!.selectedIndex = 2
        mapinit()

    }
    @objc func closeButtonTapped() {
        holderView.isHidden = true
       }
    private func mapinit(){
        let myResourceOptions = ResourceOptions(accessToken: Constants.token)
        let myMapInitOptions = MapInitOptions(resourceOptions: myResourceOptions)
        mapView = MapView(frame: mhHolderView.bounds   , mapInitOptions: myMapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isUserInteractionEnabled = true
        pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        pointAnnotationManager!.delegate = self
        let width = Constants.serbiaNorthEast.longitude - Constants.serbiaSouthWest.longitude
        let height = Constants.serbiaNorthEast.latitude - Constants.serbiaSouthWest.latitude
        let expansionWidth = width * 0.15
        let expansionHeight = height * 0.15
        let expandedSouthWest = CLLocationCoordinate2D(latitude: Constants.serbiaSouthWest.latitude - expansionHeight, longitude: Constants.serbiaSouthWest.longitude - expansionWidth)
        let expandedNorthEast = CLLocationCoordinate2D(latitude: Constants.serbiaNorthEast.latitude + expansionHeight, longitude: Constants.serbiaNorthEast.longitude + expansionWidth)
        let bounds = CoordinateBounds(southwest: expandedSouthWest,
        northeast: expandedNorthEast)
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(currentDestinationTextFieldTapped)))
        try? mapView.mapboxMap.setCameraBounds(with: CameraBoundsOptions(bounds: bounds))
        let camera = mapView.mapboxMap.camera(for: bounds, padding: .zero, bearing:0, pitch: 0)
        mapView.mapboxMap.setCamera(to: camera)
    }

    @objc func currentDestinationTextFieldTapped(){
        searchTableBiew.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        selectedLocationStart = nil
        searchTableBiew.isHidden = true
        selectedLocationEnd = nil
        searchEnd.text = ""
        seachStart.text = ""
        saveRoutesButton.isHidden = true
        stackView.isHidden = true
        holderView.isHidden = true
        if Constants().userDefLangugaeKey == "eng"{
            searchEnd.placeholder = "Enter Destination"
            seachStart.placeholder = "Enter starting point"
        } else if Constants().userDefLangugaeKey == "lat" {
            searchEnd.placeholder = "Unesite željenu destinaciju"
            seachStart.placeholder = "Unesite početnu lokaciju"

        } else {
            searchEnd.placeholder = "Унесите жељену дестинацију"
            seachStart.placeholder = "Унесите почетну локацију"
        }
        addbtn.setTitle(Constants().getAddToRoute(), for: .normal)
        showLocalitiesButton.setTitle(Constants().getShowLocalities(), for: .normal)
        saveRoutesButton.setTitle(Constants().getSaveRoute(), for: .normal)
        startNavButton.setTitle(Constants().getMyPath(), for: .normal)

    }
  
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            break
        }
     

        
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates()
        default:
            break
        }
    }
    
   
    
    func startLocationUpdates() {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard indexPath.row < filteredData.count else {
                   return
               }
        let selectedLocation = filteredData[indexPath.row]
        if didSelectSearchForStartingPoint{
            seachStart.searchTextField.text = selectedLocation
            seachStart.endEditing(true)
            selectedLocationStart = LocalManager.shared.allLocations.first{$0.nameLat.lowercased() == selectedLocation.lowercased()}
           
            searchTableBiew.reloadData()
        } else {
            searchEnd.endEditing(true)
            searchEnd.searchTextField.text = selectedLocation
            selectedLocationEnd = LocalManager.shared.allLocations.first{$0.nameLat.lowercased() == selectedLocation.lowercased()}
            searchTableBiew.reloadData()
         
        }
        searchTableBiew.isHidden = true
        
        if selectedLocationEnd != nil && selectedLocationStart != nil  {
            searchTableBiew.isHidden = true
            saveRoutesButton.isHidden = false
            stackView.isHidden = false
        }

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.mapView.mapboxMap.setCamera(to: CameraOptions(center: location.coordinate, zoom:14))
        }
        print(location,"lokacija")
        currentLatitude = location.coordinate.latitude
        currentLongitude = location.coordinate.longitude
        let yourCoordinate = CLLocationCoordinate2D(latitude: self.currentLatitude!, longitude: self.currentLongitude! )
        
        var pointAnnotation = PointAnnotation(coordinate: yourCoordinate)
        pointAnnotation.image = .init(image: UIImage(named: "pin")!, name: "Ви")
        pointAnnotation.iconAnchor = .bottom
        let pointAnnotationManager = mapView.annotations.makePointAnnotationManager()
        pointAnnotationManager.delegate = self
        pointAnnotationManager.annotations = [pointAnnotation]
        
        locationManager.stopUpdatingLocation()
    }
    func mapView(_ mapView: MapView, tapOnCalloutFor annotation: Annotation) {
        if annotation is PointAnnotation {
            print("Tapped on marker with title: ")
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates()
        case .denied, .restricted:
            let alert = UIAlertController(title: "Location Access Denied", message: "Please grant location access in the Settings app to use this feature.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        default:
            break
        }
    }
    
    
    @IBAction func saveRouteClick(_ sender: Any) {
        saveRoutesButton.isHidden = true
        coordinatePointsArray.append(CoordinateModel(lat: currentLatitude ?? 0.0, lon: currentLongitude ?? 0.0))
        coordinatePointsArray.append(CoordinateModel(lat: selectedLocationStart?.lat ?? 00.0,lon: selectedLocationStart?.lon ?? 0.0))
        coordinatePointsArray.append(contentsOf: coordinatesForPointsFromAdd)
        coordinatePointsArray.append(CoordinateModel(lat: selectedLocationEnd?.lat ?? 0.0,lon: selectedLocationEnd?.lon ?? 0.0))
      
        FirebaseWizard().addToFavouriteRoutes(customRoute: CustomRoute(name: seachStart.text! + " - " + searchEnd.text!,points: coordinatePointsArray), completion: {
            added in
            if added {
                self.showToast(message: Constants().getSaved(), font: UIFont(name: "Arial", size: 17.0)!)
            } else {
                self.showToast(message: Constants().getSaveFailed(), font: UIFont(name: "Arial", size: 17.0)!)

            }
        })
    }
    
    @IBAction func showLocalityClicked(_ sender: Any) {
        
        var destionation = CLLocationCoordinate2D(latitude: selectedLocationEnd!.lat, longitude: selectedLocationEnd!.lon)
        var currentLocation = CLLocationCoordinate2D(latitude: selectedLocationStart!.lat, longitude: selectedLocationStart!.lon)
        var myLocation = CLLocationCoordinate2D(latitude: currentLatitude!, longitude: currentLongitude!)
        
        addAnnotations(getProximityAnnotations(start: Point(currentLocation), end: Point(destionation), oneMore: Point(myLocation)).0,getProximityAnnotations(start: Point(currentLocation), end: Point(destionation), oneMore: Point(myLocation)).1)
       
    }
    func getProximityAnnotations(start: Point, end: Point, oneMore: Point) -> ([LocationModel], [TollModel]) {
        let padding = 0.020000
        let west = min(start.coordinates.longitude, end.coordinates.longitude, oneMore.coordinates.longitude) - padding
        let east = max(start.coordinates.longitude, end.coordinates.longitude, oneMore.coordinates.longitude) + padding
        let south = min(start.coordinates.latitude, end.coordinates.latitude, oneMore.coordinates.latitude) - padding
        let north = max(start.coordinates.latitude, end.coordinates.latitude, oneMore.coordinates.latitude) + padding
        
        var proximityAnnotations: [LocationModel] = []
        var proximityTolls: [TollModel] = []
        
        for annotation in LocalManager.shared.allLocations {
            let annotationCoordinate = CLLocationCoordinate2D(latitude: annotation.lat, longitude: annotation.lon)
            if (annotationCoordinate.longitude > west && annotationCoordinate.longitude < east &&
                annotationCoordinate.latitude > south && annotationCoordinate.latitude < north) {
                proximityAnnotations.append(annotation)
            }
        }
        for tol in LocalManager.shared.allTolls {
            let tollCoordinate = CLLocationCoordinate2D(latitude: tol.lat, longitude: tol.lon)
            if (tollCoordinate.longitude > west && tollCoordinate.longitude < east &&
                tollCoordinate.latitude > south && tollCoordinate.latitude < north) {
                proximityTolls.append(tol)
            }
        }
        
        return (proximityAnnotations, proximityTolls)
    }

    @IBAction func startNavClicked(_ sender: Any) {
        stackView.isHidden = true
        saveRoutesButton.isHidden = true
            startNavigation()
    }
    
    func startNavigation(){
        
        waypointsArray.append(Waypoint(coordinate:  LocationCoordinate2D(latitude: currentLatitude!, longitude: currentLongitude!)))
        waypointsArray.append(Waypoint(coordinate: LocationCoordinate2D(latitude: selectedLocationStart!.lat, longitude: selectedLocationStart!.lon)))
        waypointsArray.append(contentsOf: wayPointsAditionalyAded)
        waypointsArray.append(Waypoint(coordinate: LocationCoordinate2D(latitude: selectedLocationEnd!.lat, longitude: selectedLocationEnd!.lon)))
        let options = NavigationRouteOptions(waypoints: waypointsArray)
        Directions.shared.calculate(options) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let strongSelf = self else {
                    return
                }
                let indexedRouteResponse = IndexedRouteResponse(routeResponse: response, routeIndex: 0)
                let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                                customRoutingProvider: NavigationSettings.shared.directions,
                                                                credentials: NavigationSettings.shared.directions.credentials,
                                                                simulating: SimulationMode.never)
                
                let navigationOptions = NavigationOptions(navigationService: navigationService)
                let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                        navigationOptions: navigationOptions)
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.routeLineTracksTraversal = true
                strongSelf.present(navigationViewController, animated: true, completion: nil)
            }
        }
        
        waypointsArray.removeAll()
        coordinatePointsArray.removeAll()
        coordinatesForPointsFromAdd.removeAll()
        wayPointsAditionalyAded.removeAll()
       
    }

    func addAnnotations(_ locations: [LocationModel],_ tolls:[TollModel]) {
        var annotationsToAdd: [PointAnnotation] = []
        
        for item in locations {
            
            let coordinate = CLLocationCoordinate2D(latitude: item.lat, longitude: item.lon)
            var pointAnnotation = PointAnnotation(coordinate: coordinate)
            if item.subcat.contains("mobilna"){
                pointAnnotation.image = .init(image: UIImage(named: "mts_pin")!, name: item.id)
            } else if item.nameLat == Constants.VRNJACKA_BANJA {
                pointAnnotation.image = .init(image: UIImage(named: "pin_vrnjacka_banja")!, name: item.id)
            }
            else if item.nameLat == Constants.RUMA {
                pointAnnotation.image = .init(image: UIImage(named: "pin_ruma")!, name: item.id)
            }else {
                pointAnnotation.image = UIImage(named: Utils().getPinForCategory(category: item.category)).map { .init(image: $0, name: item.id) }
            }
            
            pointAnnotation.iconAnchor = .bottom
            pointAnnotation.iconSize = .maximum(0.5, 0.5)
            if Constants().userDefLangugaeKey == "eng"{
                
                if item.images.isEmpty{
                    pointAnnotation.userInfo = ["name":item.nameEng]
                } else {
                    pointAnnotation.userInfo = ["name":item.nameEng,
                                                "image":item.images[0]]
                }
                
                
            } else if Constants().userDefLangugaeKey == "lat" {
                if item.images.isEmpty{
                    pointAnnotation.userInfo = ["name":item.nameLat]
                } else {
                    pointAnnotation.userInfo = ["name":item.nameLat,
                                                "image":item.images[0]]
                }
                
            } else {
                if item.images.isEmpty{
                    pointAnnotation.userInfo = ["name":item.nameCir]
                } else {
                    pointAnnotation.userInfo = ["name":item.nameCir,
                                                "image":item.images[0]]
                }
                
            }
            
            annotationsToAdd.append(pointAnnotation)
        }
        for tl in tolls {
            let coordinate = CLLocationCoordinate2D(latitude: tl.lat, longitude: tl.lon)
            var pointAnnotation = PointAnnotation(coordinate: coordinate)
            pointAnnotation.image = .init(image: UIImage(named: "toll")!, name: tl.nameLat)
            if Constants().userDefLangugaeKey == "eng"{
                
                    pointAnnotation.userInfo = ["name":tl.nameEng]
                
            } else if Constants().userDefLangugaeKey == "lat" {
                    pointAnnotation.userInfo = ["name":tl.nameLat]
                                               
            } else {
                    pointAnnotation.userInfo = ["name":tl.nameCir]
            }
            pointAnnotation.iconAnchor = .bottom
            pointAnnotation.iconSize = .maximum(0.5, 0.5)
            annotationsToAdd.append(pointAnnotation)
        }
        self.pointAnnotationManager?.annotations.removeAll()
        
        self.pointAnnotationManager?.annotations.append(contentsOf: annotationsToAdd)
        
    }
    func annotationManager(_ manager: AnnotationManager, didDetectTappedAnnotations annotations: [Annotation]) {
        
        if let anot = annotations.first as? PointAnnotation{
            
            if anot.image?.image == UIImage(named: "pin"){
                print("stojan")
            } else {
                selectedAnnotation = anot
               updateHolderView(anot: anot)
            }
            
         
        }
    }
    private func updateHolderView(anot:PointAnnotation){
        
        holderView.isHidden = false
        holderLabel.text = anot.userInfo?["name"] as! String
        
        if anot.userInfo?["image"] != nil {
            storageRef.child(anot.userInfo?["image"] as! String).getData(maxSize: 5 * 1024 * 1024) { data, error in
                if let error = error {
                    print("Error downloading image: \(error.localizedDescription)")
                } else {
                    if let imageData = data, let image = UIImage(data: imageData) {
                        self.holderImage.image = image
                        
                    } else {
                        print("Error loading image data")
                    }
                }
            }
        }
        
        
    }
    @IBAction func adBtnClick(_ sender: Any) {
      
        wayPointsAditionalyAded.append(Waypoint(coordinate: (selectedAnnotation?.point.coordinates)!))
        coordinatesForPointsFromAdd.append(CoordinateModel(lat: selectedAnnotation?.point.coordinates.latitude ?? 0.0, lon: selectedAnnotation?.point.coordinates.longitude ?? 0.0))
        holderView.isHidden = true
    }
   
}

extension TravelViewController: AnnotationInteractionDelegate {

    
 
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if Constants().userDefLangugaeKey == "eng" {
            let filteredData = LocalManager.shared.allLocations.filter { item in
                return item.nameEng.lowercased().contains(searchText.lowercased())
            }
            self.filteredData = filteredData.map { $0.nameLat.uppercased() }
        } else if Constants().userDefLangugaeKey == "lat" {
            let filteredData = LocalManager.shared.allLocations.filter { item in
                
                return item.nameLat.lowercased().contains(searchText.lowercased())
            }
            self.filteredData = filteredData.map { $0.nameLat.uppercased() }
        } else {
            let filteredData = LocalManager.shared.allLocations.filter { item in
                return item.nameCir.lowercased().contains(searchText.lowercased())
            }
            self.filteredData = filteredData.map { $0.nameLat.uppercased() }
        }
        
        searchTableBiew.isHidden = filteredData.isEmpty
        searchTableBiew.reloadData()
    }
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        if searchBar == searchEnd {
            didSelectSearchForStartingPoint = false
            tableViewTopConstraint.constant = CGFloat(60)

        } else {
            didSelectSearchForStartingPoint = true
            tableViewTopConstraint.constant = CGFloat(0)

        }
        
        searchTableBiew.isHidden = false
        
          return true
      }
    
    
    
}





