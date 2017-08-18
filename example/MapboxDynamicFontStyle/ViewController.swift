//
//  ViewController.swift
//  MapboxDynamicFontStyle
//
//  Created by Felix Lamouroux on 18.08.17.
//  Copyright © 2017 iosphere GmbH. All rights reserved.
//

import UIKit
import Mapbox

class ViewController: UIViewController {
    // IMPORTANT: keep a strong reference to a font observer
    var fontObserver: ISHMapboxDynamicFontObserver?

    override func viewDidLoad() {
        super.viewDidLoad()
        // IMPORTANT: Provide your own Mapbox access token here
        MGLAccountManager.setAccessToken("<#access_token#>")

        // Standard Mapbox setup
        let mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.setCenter(CLLocationCoordinate2D(latitude: 59.31, longitude: 18.06), zoomLevel: 9, animated: false)

        // IMPORTANT: set the delegate
        mapView.delegate = self
        view.addSubview(mapView)
    }
}

extension ViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        // IMPORTANT: initialize the font observer once the style is loaded
        fontObserver = ISHMapboxDynamicFontObserver(style: style)
    }
}
