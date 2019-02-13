//
//  PaymentModuleConfiguration.swift
//
//  Created by Martynas Stanaitis on 03/07/2017.
//  Copyright © 2017 Kofoed & Co. All rights reserved.
//

import Foundation

struct PaymentModuleConfiguration: PaymentModuleConfigurationProtocol {
    
    // MARK: - Declarations -
    ///
    public var confirmOrderUrlString: String!
    ///
    public var epayConfiguration: EpayConfigurationProtocol?
    ///
    public var dibsConfiguration: DIBSConfigurationProtocol?
    
    internal var supportedPaymentProviderTypeList: [CorePaymentProviderType]!
    
    // MARK: - Methods -
    
    static func defaultConfiguration(supportedPaymentProviderTypeList: [CorePaymentProviderType] = [.dibs , .mobilePay],
                                     dibsConfiguration: DIBSConfigurationProtocol? = nil ) -> PaymentModuleConfiguration {
        
        return PaymentModuleConfiguration(confirmOrderUrlString: dibsConfiguration?.orderConfirmationUrlString,
                                          epayConfiguration: nil,
                                          dibsConfiguration: dibsConfiguration,
                                          supportedPaymentProviderTypeList: supportedPaymentProviderTypeList)
    }
    
}
