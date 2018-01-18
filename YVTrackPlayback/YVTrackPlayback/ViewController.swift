//
//  ViewController.swift
//  YVTrackPlayback
//
//  Created by 周逸文 on 2018/1/18.
//  Copyright © 2018年 YV. All rights reserved.
//

import UIKit

class ViewController: UIViewController,MAMapViewDelegate  {
    
    var myLocation: MAAnimatedAnnotation?
    //最小刷新时间 (帧)
    let minframeInterval = 2
    
    var mapView: MAMapView!

    var  dpLink: CADisplayLink?
    
    var uptateIndex: Int = 0
    //角度值
    var yvAngle: Double = 0
    
    var polyline: MAPolyline?
    
    var traceCoordinates: Array<CLLocationCoordinate2D> = []
    //临时数组 暂存坐标
    var temporarytraceCoordinates: Array<CLLocationCoordinate2D> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initMapView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        start()
    }
    func initMapView() {
        mapView = MAMapView(frame: self.view.bounds)
        mapView.delegate = self
        mapView.showsCompass = false
        mapView.showsScale = false

        let data: Data? = try! Data.init(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "running_record", ofType: "json")!))
        if(data != nil) {
            let jsonObj = try? JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [[String:Any]]
            traceCoordinates = jsonObj!.map({ (element) -> CLLocationCoordinate2D in
                let lat = element["latitude"] as! NSString
                let lon = element["longtitude"] as! NSString
                return  CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue)
            })
            if let lat = traceCoordinates.first?.latitude, let lon = traceCoordinates.first?.longitude{
                mapView.centerCoordinate = CLLocationCoordinate2DMake(lat, lon)
            }
        }
        mapView.setZoomLevel(18, animated: true)
        self.view.addSubview(mapView)
    }
    
    
    func start()  {
        uptateIndex = 0
        yvAngle = 0
        temporarytraceCoordinates = []
        mapView.setZoomLevel(18, animated: true)
        dpLink = CADisplayLink(target: self, selector: #selector(ViewController.update))
        dpLink?.frameInterval = minframeInterval
        dpLink?.isPaused = false
        dpLink?.add(to: RunLoop.current, forMode: RunLoopMode.commonModes)
    }
    
    @objc func update(){
        if uptateIndex >= traceCoordinates.count - 2 {
            UIView.animate(withDuration: 2, animations: {
                if let line = self.polyline {
                    self.mapView.showOverlays([line], edgePadding: UIEdgeInsetsMake(120, 20, 240, 20), animated: true)
                    self.mapView.remove(line)
                }
                self.dpLink?.isPaused = true
                self.dpLink?.remove(from: RunLoop.current, forMode: RunLoopMode.commonModes)
                self.dpLink?.invalidate()
                self.dpLink = nil
            })
            return
        }
        if  let line = self.polyline  {
            self.mapView.remove(line)
        }
        temporarytraceCoordinates.append(traceCoordinates[uptateIndex])
        polyline = MAPolyline(coordinates: &temporarytraceCoordinates, count: UInt(temporarytraceCoordinates.count))
        if myLocation == nil {
            myLocation = MAAnimatedAnnotation()
            myLocation!.title = "AMap"
            myLocation!.coordinate = temporarytraceCoordinates.last!
            mapView!.addAnnotation(myLocation)
        }
        myLocation!.coordinate = temporarytraceCoordinates.last!
        self.mapView.add(polyline)
        self.mapView.setCenter(traceCoordinates[uptateIndex+1], animated: false)
        self.mapView.setRotationDegree(CGFloat(yvAngle) , animated: false, duration: 1)
        self.mapView.setCameraDegree( CGFloat(yvAngle), animated: false, duration: 1)
        yvAngle += 1
        uptateIndex += 1
        
    }
    
    func mapView(_ mapView: MAMapView!, rendererFor overlay: MAOverlay!) -> MAOverlayRenderer! {
        if overlay.isKind(of: MAPolyline.self) {
            let renderer: MAPolylineRenderer = MAPolylineRenderer.init(polyline: overlay as! MAPolyline!)
            renderer.lineWidth = 8.0
            renderer.strokeColor = UIColor(red: 0, green: 230, blue: 239, alpha: 1)
            return renderer
        }
        return nil
    }
    
    func mapView(_ mapView: MAMapView, viewFor annotation: MAAnnotation) -> MAAnnotationView? {
        
        if annotation.isEqual(myLocation) {
            let annotationIdentifier = "myLcoationIdentifier"
            var poiAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
            if poiAnnotationView == nil {
                poiAnnotationView = MAAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            }
            poiAnnotationView?.image = UIImage(named: "userHeadimage")
            poiAnnotationView?.imageView.layer.cornerRadius = 20
            poiAnnotationView?.imageView.layer.masksToBounds = true
            poiAnnotationView?.imageView.backgroundColor = UIColor.white
            poiAnnotationView?.imageView.layer.borderColor = UIColor.white.cgColor
            poiAnnotationView?.imageView.layer.borderWidth = 2
            poiAnnotationView!.canShowCallout = false
            return poiAnnotationView
        }
        return nil
    }
}

