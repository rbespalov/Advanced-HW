//
//  ViewController.swift
//  Advanced HW
//
//  Created by Роман Беспалов on 04.12.2022.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate {
    
    var currentLocation: CLLocation?
    
    private let locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        return locationManager
    }()
    
    // MARK: - Subviews
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.mapType = .hybridFlyover
        mapView.showsUserLocation = true
        mapView.delegate = self
        
        return mapView
    }()
    
    lazy var makeRouteButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemOrange
        button.layer.cornerRadius = 10
        button.setTitle("Create route", for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()
    
    
    // MARK: - Livecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        self.title = "Map demo"
        
        addSubviews()
        setupConstraints()
        findUserLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.requestLocation()
    }

    // MARK: - Private
    
    @objc func buttonTapped() {
        let ac = UIAlertController(title: "Create route", message: "Enter destination coordinates", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        ac.addAction(cancel)
        ac.addTextField { textField in
            textField.placeholder = "  Enter latitude"
        }
        ac.addTextField { textField in
            textField.placeholder = "  Enter longitude"
        }
        let createRouteAction = UIAlertAction(title: "Create", style: .default) { [self] UIAlertAction in
            guard let textFields = ac.textFields else {return}
            
            let latitude = Double(textFields[0].text!)!
            let longitude = Double(textFields[1].text!)!
            
            self.showRouteOnMap(pickupCoordinate: currentLocation!.coordinate, destinationCoordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            
            let destinationPin = Annotation(title: "Destination", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), info: "My destination")
            mapView.addAnnotations([destinationPin])
        }
        ac.addAction(createRouteAction)
        self.navigationController?.present(ac, animated: true)
    }
    
    private func addSubviews() {
        self.view.addSubview(mapView)
        mapView.addSubview(makeRouteButton)
    }

    private func setupConstraints() {
        
        let safeArea = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            mapView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),
            
            makeRouteButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 20),
            makeRouteButton.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -20),
            makeRouteButton.bottomAnchor.constraint(equalTo: mapView.bottomAnchor, constant: -25),
            makeRouteButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func findUserLocation() {
        
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
    }
    
    private func showRouteOnMap(pickupCoordinate: CLLocationCoordinate2D, destinationCoordinate: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickupCoordinate, addressDictionary: nil))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate, addressDictionary: nil))
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            
            if let route = unwrappedResponse.routes.first {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets.init(top: 80.0, left: 20.0, bottom: 100.0, right: 20.0), animated: true)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay)
        render.strokeColor = UIColor.purple
        return render
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            print("Определение локации невозможно")
        case .notDetermined:
            print("Определение локации не запрошено")
        @unknown default:
            fatalError()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location
            mapView.setCenter(location.coordinate, animated: true)
            
            let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
            
            mapView.setRegion(region, animated: true)
            
//            let myPlace = Annotation(title: "I", coordinate: location.coordinate, info: "I am here")
//            mapView.addAnnotations([myPlace])
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
}
