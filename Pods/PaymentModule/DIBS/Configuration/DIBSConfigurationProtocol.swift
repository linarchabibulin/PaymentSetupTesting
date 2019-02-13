//
//  DIBSConfigurationProtocol.swift
//  PaymentsModule
//
//  Copyright © 2019 Kofoed. All rights reserved.
//

import Foundation

public protocol DIBSConfigurationProtocol {

    /// DIBS library specific propertie
    var merchantId: String {get}
    /// DIBS library specific propertie
    var hMacKey: String {get}
    ///
    var currencyCode: String {get}
    var payTypes: [AnyObject] {get}
    var language: String {get}
    var dibsOrderId: String {get set}
    var orderConfirmationUrlString: String {get}

    var paymentAcceptedCallback: (() -> Void)? {get set}
    
    var appearenceConfiguration: DIBSAppearanceConfiguration! {get}
}
