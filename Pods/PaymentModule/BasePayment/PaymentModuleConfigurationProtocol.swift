//
//  PaymentModuleConfigurationProtocol.swift
//  Mobilbillet
//
//  Created by Martynas Stanaitis on 03/07/2017.
//  Copyright © 2017 Kofoed & Co. All rights reserved.
//

import Foundation

/// PaymentModuleConfigurationProtocol is used to configure Payment module
protocol PaymentModuleConfigurationProtocol {
    /// - Parameter confirmOrderUrlString: url string for confirmOrder merthod that checks if payment through 3rd party service was successfully logged in server.
    var confirmOrderUrlString: String! {get set}
    
    /// - Parameter epayConfiguration: object conforming to EpayConfigurationProtocol used for ePay moduel configuration. Not needed if ePay module is not used
    var epayConfiguration: EpayConfigurationProtocol? {get set}
    /// - Parameter dibsConfiguration: object conforming to EpayConfigurationProtocol used for DIBS moduel configuration. Not needed if DIBS module is not used
    var dibsConfiguration: DIBSConfigurationProtocol? {get set}
    
    /// - Parameter supportedPaymentProviderTypeList: list containg all the payments provider types that the app supports.
    var supportedPaymentProviderTypeList: [CorePaymentProviderType]! {get set}
}
