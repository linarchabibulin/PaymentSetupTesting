//
//  MobilePayConfigurationProtocol.swift
//  NetworkingModule
//
//  Created by Martynas Stanaitis on 03/07/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

import Foundation

/**
 MobilePayConfigurationProtocol is made for conveniance as it contains all the data needed to initalize MobilePayManager
 MobilePay SDK manager is a shared instance and should be configured in appDelegate - appDidLoad() method.
 
 ```MobilePayManager.sharedInstance().setup(withMerchantId: String, merchantUrlScheme: String, country: MobilePayCountry)
 MobilePayManager.sharedInstance().returnSeconds = Int32
 MobilePayManager.sharedInstance().captureType = MobilePayCaptureType```
 also please set order confirmation link like:
 MobilePayModule.orderConfirmationUrlString = <MobilePayConfigurationProtocol>.orderConfirmationUrlString
*/

public protocol MobilePayConfigurationProtocol {
    
//    MobilePay SDK configuration
    static var merchantId: String {get set}
    static var merchantUrlScheme: String {get set}
    
    static var country: MobilePayCountry {get set}
    static var captureType: MobilePayCaptureType {get set}
    
    static var orderConfirmationUrlString: String {get set}
    
    // Number of seconds before returning from the receipt screen in MobilePay app back to our app.
    static var returnSeconds: Int32 {get set}
}
