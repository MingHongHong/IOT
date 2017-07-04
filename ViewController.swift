
//
//  ViewController.swift
//  RoadBumping
//
//  Created by IIS-NRL on 2017/5/17.
//  Copyright © 2017年 IIS-NRL. All rights reserved.
//

import UIKit
import MapKit
import CoreBluetooth
import CoreLocation



class ViewController:UIViewController,CBCentralManagerDelegate,CBPeripheralDelegate,CLLocationManagerDelegate{
    
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label4: UILabel!
    @IBOutlet weak var label5: UILabel!
    
    let managerLocation = CLLocationManager()
    var locationManager: CLLocationManager = CLLocationManager();
    var startLocation: CLLocation!
    
    var manager:CBCentralManager!
    @IBOutlet weak var longitude: UILabel!
    @IBOutlet weak var latitude: UILabel!
    var peripheral:CBPeripheral!
    
    let BEAN_NAME = "PM25"
    let BEAN_SERVICE_UUID =
        CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
    let BEAN_SCRATCH_UUID =
        CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214")
    
   
    
    // convert Date to TimeInterval (typealias for Double)
    var timeInterval = 0
    var lat = "lat"
    var long = "long"
    

    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CBCentralManager(delegate: self, queue: nil)
        label.text = "view did load"
        managerLocation.delegate = self
        managerLocation.desiredAccuracy =  kCLLocationAccuracyBest
        managerLocation.requestWhenInUseAuthorization()
        managerLocation.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager,didFailWithError error:Error) {
    print ("LOL")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == CBManagerState.poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
            label.text = "Scannig for peripherals"
        } else {
            label.text = "Bluetooth not available."
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber) {
        label.text = "peripheral discovered"
        let device = (advertisementData as NSDictionary)
            .object(forKey: CBAdvertisementDataLocalNameKey)
            as? NSString
        if device?.contains(BEAN_NAME) == true {
            label.text = "connecting arduino ..."
            self.manager.stopScan()
            
            self.peripheral = peripheral
            self.peripheral.delegate = self
            
            manager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral) {
        label2.text = BEAN_NAME
        label.text = "discovering servicce"
        peripheral.discoverServices(nil)
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            label.text = "service found"
            let thisService = service as CBService
            
            if service.uuid == BEAN_SERVICE_UUID {
                label3.text = "OK"
                peripheral.discoverCharacteristics(
                    nil,
                    for: thisService
                )
            }
        }
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?) {
        
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if thisCharacteristic.uuid == BEAN_SCRATCH_UUID {
                label.text = "wating for data ..."
                label4.text = "OK"
                self.peripheral.setNotifyValue(
                    true,
                    for: thisCharacteristic
                )
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        //var count:UInt32 = 0;
  
        if characteristic.uuid == BEAN_SCRATCH_UUID {
            // characteristic.value!.getBytes(&count, length: sizeof(UInt32))
            //label.text = NSString(format: "%llu", count) as String
            
            let data = characteristic.value!
            var byte:UInt8 = 0
            data.copyBytes(to: &byte,count: 1)
            let value = Int(byte)
            print(value)
            let pm25 = String(describing: value)
            let someDate3 = Date()
            
            // convert Date to TimeInterval (typealias for Double)
            let timeInterval3 = Int(someDate3.timeIntervalSince1970)

            
            label.text = "receiving data ..."
            label5.text = pm25
            
            
            if((timeInterval3 > timeInterval+60)){
                print(timeInterval3," ",timeInterval)
                timeInterval = timeInterval3
            var request = URLRequest(url: URL(string: "https://api.thingspeak.com/update?api_key=CPYDJ8OIOTNZFNP8&field1="+pm25+"&field2="+lat+"&field3="+long)!)
            request.httpMethod = "POST"
            let session = URLSession.shared
            
            session.dataTask(with: request) {data, response, err in
                
                }.resume()
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[0]
        let myLocation:CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        print(myLocation.latitude)
        print(myLocation.longitude)
        latitude.text = (String(format: "%.4f",myLocation.latitude))
        longitude.text = (String(format: "%.4f",myLocation.longitude))
        
        long = String(describing: myLocation.longitude)
        lat = String(describing: myLocation.latitude)
        
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?) {
        label.text = "scaning ..."
        label2.text = "--"
        label3.text = "--"
        label4.text = "--"
        label5.text = "--"
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}
