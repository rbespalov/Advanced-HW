//
//  Pin.swift
//  Advanced HW
//
//  Created by Роман Беспалов on 04.12.2022.
//

import Foundation
import MapKit

final class Annotation: NSObject, MKAnnotation {
    
    var title: String?
    var coordinate: CLLocationCoordinate2D
    var info: String
    
    init(title: String?, coordinate: CLLocationCoordinate2D, info: String) {
        self.title = title
        self.coordinate = coordinate
        self.info = info
        
        super .init()
    }

}

