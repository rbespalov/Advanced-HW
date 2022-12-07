//
//  ViewController.swift
//  Advanced HW
//
//  Created by Роман Беспалов on 04.12.2022.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
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
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        mapView.addGestureRecognizer(lpgr)
        
        return mapView
    }()
    
    
    lazy var makeRouteButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemOrange
        button.layer.cornerRadius = 10
        button.setTitle(NSLocalizedString("button-loc", comment: ""), for: .normal)
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        return button
    }()
    
    
    // MARK: - Livecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        self.title = NSLocalizedString("title-VC", comment: "")
        let infoButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(showInfo))
        self.navigationItem.rightBarButtonItem = infoButton
        
        addSubviews()
        setupConstraints()
        findUserLocation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.requestLocation()
    }

    // MARK: - Private
    
    @objc func showInfo() {
        let alert = UIAlertController(title: NSLocalizedString("info", comment: ""), message: NSLocalizedString("info-text", comment: ""), preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .cancel)
        alert.addAction(action)
        self.navigationController?.present(alert, animated: true)
    }
    
    @objc func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizer.State.ended {
            let touchLocation = gestureRecognizer.location(in: mapView)
            let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            let overlays = mapView.overlays
            mapView.removeOverlays(overlays)
            self.showRouteOnMap(pickupCoordinate: currentLocation!.coordinate, destinationCoordinate: locationCoordinate)
            print (locationCoordinate.longitude, locationCoordinate.latitude)
            return
        }
    }
    
    @objc func buttonTapped() {
        let ac = UIAlertController(title: NSLocalizedString("button-loc", comment: ""), message: NSLocalizedString("route-allert-loc", comment: ""), preferredStyle: .alert)
        let cancel = UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel)
        ac.addAction(cancel)
        ac.addTextField { textField in
            textField.placeholder = NSLocalizedString("latitude-loc", comment: "")
        }
        ac.addTextField { textField in
            textField.placeholder = NSLocalizedString("longitude-loc", comment: "")
        }
        let createRouteAction = UIAlertAction(title: NSLocalizedString("create", comment: ""), style: .default) { [self] UIAlertAction in
            guard let textFields = ac.textFields else {return}
            
            let latitude = Double(textFields[0].text!)!
            let longitude = Double(textFields[1].text!)!
            
            self.showRouteOnMap(pickupCoordinate: currentLocation!.coordinate, destinationCoordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            
            let destinationPin = Annotation(title: NSLocalizedString("destination", comment: ""), coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), info: NSLocalizedString("my-destination", comment: ""))
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
            print(NSLocalizedString("error-impossible", comment: ""))
        case .notDetermined:
            print(NSLocalizedString("error-not_requested", comment: ""))
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
