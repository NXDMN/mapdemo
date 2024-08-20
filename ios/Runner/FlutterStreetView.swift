//
//  FlutterStreetView.swift
//  Runner
//
//  Created by COM-(MAC)-2107-0628 on 2/8/24.
//

import Flutter
import UIKit
import GoogleMaps

class FlutterStreetView: NSObject, FlutterPlatformView, GMSPanoramaViewDelegate, UIGestureRecognizerDelegate{
    private var streetViewPanorama: GMSPanoramaView
    private var initOptions: NSDictionary?
    private var methodChannel: FlutterMethodChannel
    private var gestureDetector: UILongPressGestureRecognizer?

    func view() -> UIView {
        return streetViewPanorama
    }

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        streetViewPanorama = GMSPanoramaView(frame: .zero)
        
        methodChannel = FlutterMethodChannel(name: "flutter_street_view_\(viewId)", binaryMessenger: messenger)
        
        super.init()
        methodChannel.setMethodCallHandler(handle)
        initOptions = args as? NSDictionary
        updateInitOptions(args: initOptions)
        setupListener()
    }
    
    private func updateInitOptions(args: NSDictionary?){
        if(args == nil) {
            return;
        }
        
        let param = args! as NSDictionary
        
        if(param["initPosition"] != nil) {
            var pos:CLLocationCoordinate2D? = nil
            
            if(param["initPosition"] is NSArray) {
                let pos_ = param["initPosition"] as! [Double]
                pos = CLLocationCoordinate2D(latitude: pos_[0], longitude: pos_[1])
            }
            
            var source:GMSPanoramaSource? = nil

            if(param["source"] != nil) {
                if(param["source"] is String){
                    let source_ = param["source"] as! String
                    if(source_ == "outdoor") {
                        source = GMSPanoramaSource.outside
                    }
                }
            }
            
            if(pos != nil) {
                if(source != nil){
                    streetViewPanorama.moveNearCoordinate(pos!, source: source!)
                }else{
                    streetViewPanorama.moveNearCoordinate(pos!)
                }
            }
        }
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult){
        
    }
    
    private func setupListener(){
        streetViewPanorama.delegate = self
        gestureDetector = UILongPressGestureRecognizer(target: self, action: #selector(onStreetViewPanoramaLongClick))
        streetViewPanorama.addGestureRecognizer(gestureDetector!)
    }
    
    //-----Events-----
    //https://developers.google.com/maps/documentation/ios-sdk/reference/protocol_g_m_s_panorama_view_delegate-p
    
    func panoramaView(_ view: GMSPanoramaView, willMoveToPanoramaID panoramaID: String){}
    
    func panoramaView(_ view: GMSPanoramaView, didMoveTo panorama: GMSPanorama?){
        onStreetViewPanoramaChange(panorama: panorama)
    }
    
    func panoramaView(_ view: GMSPanoramaView, didMoveTo panorama: GMSPanorama, nearCoordinate coordinate: CLLocationCoordinate2D) {
        onStreetViewPanoramaChange(panorama: panorama)
    }
    
    func panoramaView(_ view: GMSPanoramaView, error: any Error, onMoveNearCoordinate coordinate: CLLocationCoordinate2D) {
        onStreetViewPanoramaChange(panorama: view.panorama, error: error)
    }
    
    func panoramaView(_ view: GMSPanoramaView, error: any Error, onMoveToPanoramaID panoramaID: String) {
        onStreetViewPanoramaChange(panorama: view.panorama, error: error)
    }
    
    func panoramaView(_ panoramaView: GMSPanoramaView, didMove camera: GMSPanoramaCamera) {
        onStreetViewPanoramaCameraChange(camera)
    }
    
    func panoramaView(_ panoramaView: GMSPanoramaView, didTap point: CGPoint) {
        onStreetViewPanoramaClick(point)
    }
    
    func panoramaView(_ panoramaView: GMSPanoramaView, didTap marker: GMSMarker) -> Bool {return true}
    
    func panoramaViewDidStartRendering(_ panoramaView: GMSPanoramaView) {}
    
    func panoramaViewDidFinishRendering(_ panoramaView: GMSPanoramaView) {}
    
    func onStreetViewPanoramaChange(panorama: GMSPanorama?, error: Error? = nil) {
        let args: NSMutableDictionary = [:]
        
        if(panorama != nil) {
            var links: [NSArray] = []
            panorama!.links.forEach { link in
                links.append([link.panoramaID, link.heading])
            }
            args["links"] = links
            args["panoId"] = panorama!.panoramaID
            args["position"] = [panorama!.coordinate.latitude, panorama!.coordinate.longitude]
        }
        
        if(error != nil) {
            args["error"] = "No valid panorama found."
        }
        
        methodChannel.invokeMethod("panorama#onChange", arguments: args)
    }
    
    func onStreetViewPanoramaCameraChange(_ camera: GMSPanoramaCamera) {
        let args: NSDictionary = ["bearing": camera.orientation.heading,
                                  "tilt" : camera.orientation.pitch,
                                  "zoom": camera.zoom,
                                  "fov": camera.fov]
        
        methodChannel.invokeMethod("camera#onChange", arguments: args)
    }
    
    func onStreetViewPanoramaClick(_  point: CGPoint) {
        let orientation = streetViewPanorama.orientation(for: point)
                
        let args : NSDictionary = ["bearing": orientation.heading,
                                   "tilt": orientation.pitch,
                                   "x": Int(point.x),
                                   "y": Int(point.y)]
        
        methodChannel.invokeMethod("panorama#onClick", arguments: args)
    }
    
    @objc func onStreetViewPanoramaLongClick(_ recognizer:UITapGestureRecognizer) {
        if (recognizer.state == .began) {
            let point = recognizer.location(in:streetViewPanorama)
            let orientation = streetViewPanorama.orientation(for: point)
            
            let args : NSDictionary = ["bearing": orientation.heading, 
                                       "tilt": orientation.pitch,
                                       "x": Int(point.x),
                                       "y": Int(point.y)]
            
            methodChannel.invokeMethod("panorama#onLongClick", arguments: args)
        }
    }
}
