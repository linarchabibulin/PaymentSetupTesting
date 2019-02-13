//
//  EpayPaymentInfoProtocol.swift
//  Pods
//
//  Created by Martynas Stanaitis on 05/06/2017.
//
//

import Foundation

/**
 EPAY CONFIGURATION PROTOCOL
 Configuration protocol for ePay payment module
 Register properties with Epay:
 - Parameter merchantId: merchant id - identiefies the merchant
 - Parameter hMacKey: encryption key
 ePay sdk Options
 - Parameter currencyCode: currency in witch transactions will be executed
 - Parameter payTypes: list of supported payment cards
 - Parameter language: language in which payment screen will be displayed
 
 Extra parameters
 - Parameter customerMobileNumber: customer mobile number
 - Parameter customerName: customer name
 - Parameter ePayOrderId: used in edit info flow - NOTE: Edit Mode disabled for now
 - Parameter purchaseCardSubscriptionId: used in purchase flow. epay configuratation id, stored as 'paymentToken' property in CoreCutomerEntity
 - Parameter getEpayOrderUrlString: url string for 'EpayApiClient.getEpayOrderId' function that gets ePayOrderId
 - Parameter viewDidLoadAdditionalExecutionCallback: callback which gets executed at the end of epayViewControllers 'viewDidLoad:' method
 - Parameter viewWillAppearAdditionalExecutionCallback: callback which gets executed at the end of epayViewControllers 'viewWillAppear:'  method
 */

public protocol EpayConfigurationProtocol {
    
    // MARK: - ePay lib specific properties
    var merchantId: String {get set}
    var hMacKey: String {get set}
    
    // Payment currency
    var currencyCode: String {get set}
    
    // Types of cards allowed for payment
    var payTypes: [AnyObject] {get set}
    
    // Language for payment dialog
    var language: String {get set}
    
    // MARK: - Extra configuration
    var customerMobileNumber: String? {get set}
    var customerName: String? {get set}
    
    var ePayOrderId: String? {get set} // used in edit info flow - NOTE: Edit Mode disabled for now
    var purchaseCardSubscriptionId: Int64? {get set} // used in purchase flow. epay configuratation id, stored as 'paymentToken' property in CoreCutomerEntity
    
    // MARK: ePayApiClient url links
    var getEpayOrderUrlString: String {get set}
    var orderConfirmationUrlString: String {get set}

    // MARK: Closures
    var viewDidLoadAdditionalExecutionCallback: ((_ controller: EpayBaseViewController?) -> Void)? {get set}
    var viewWillAppearAdditionalExecutionCallback: ((_ controller: EpayBaseViewController?, _ animated: Bool?) -> Void)? {get set}
}
