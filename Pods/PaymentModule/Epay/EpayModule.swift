//
//  EpayPaymentModule.swift
//  MobileTicketCore
//
//  Created by Linar Chabibulin on 11/05/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

import Foundation

/**
 EPAY MODULE
 EpayModule wraps ePay lib.
 This module will be displayed in its own ViewController.
 Refer to 'EpayConfigurationProtocol' for configuration options.
 */

class EpayModule {
    /// - Parameter epayConfiguration: configuration for ePay
    public var epayConfiguration: EpayConfigurationProtocol!
    /// - Parameter orderConfirmationStartedHandler: 'Void' type closure
    public var orderConfirmationStartedHandler: (() -> Void)!
    /// - Parameter orderConfirmedHandler: 'PaymentConfirmedHandler' type success closure
    public var orderConfirmedHandler: PaymentConfirmedHandler!
    /// - Parameter orderConfirmationFailureHandler: 'PaymentErrorHandler' type failure closure
    public var orderFailureHandler: PaymentErrorHandler!
    /// - Parameter failedToStartHandler: payment did not start closure
    public var failedToStartHandler: (() -> Void)?

    weak private var navigationController: UINavigationController?
    private var orderId: String?  // used only for making payments
    private var price: Int?
    private var addToFavorites = false
    
    /**
     Default initiator
     - Parameter navigationController: navigation Controller into which epay view controller will be pushed
     - Parameter epayConfiguration: see 'EpayConfigurationProtocol' for detailed description.
     */
    init(navigationController: UINavigationController,
         epayConfiguration: EpayConfigurationProtocol ) {
        
        self.navigationController = navigationController
        self.epayConfiguration = epayConfiguration
    }
    
    /**
     Method for intiating MobilePay payment
     - Parameter orderId: String with order id
     - Parameter price: price of the order
     - Parameter isFavourite: whether you wuold like to add order to Fvourites list on successfull purchase
     - Parameter successHandler: PaymentConfirmedHandler type closure for handleing successfull order payment (executed after order purchase is confirmed)
     - Parameter errorHandler: PaymentErrorHandler type closure for handling any errors that arrise
     - Parameter failedToStartHandler: block perform if api call fails to start. If Api status is unavailable. Optional
     */
    public func makePayment(orderId: String,
                             price: Int,
                             addToFavorites: Bool,
                             orderConfirmationStartedHandler: @escaping () -> Void,
                             orderConfirmedHandler: @escaping PaymentConfirmedHandler,
                             orderFailureHandler: @escaping PaymentErrorHandler,
                             failedToStartHandler: (() -> Void)? = nil) {
        
        self.orderId = orderId
        self.price = price
        self.addToFavorites = addToFavorites
        self.orderConfirmationStartedHandler = orderConfirmationStartedHandler
        self.orderConfirmedHandler = orderConfirmedHandler
        self.orderFailureHandler = orderFailureHandler
        self.failedToStartHandler = failedToStartHandler
        
        EpayApiClient.getEpayOrderId(urlString: epayConfiguration.getEpayOrderUrlString, orderId: orderId, successCallback: { ePayOrderId in
            
            dispatch_main_async_safe {
                let epayPaymentController = EpayPaymentViewController(configuration: self.epayConfiguration,
                                                                      orderId: self.orderId!,
                                                                      epayOrderId: ePayOrderId,
                                                                      price: self.price!,
                                                                      addToFavorites: self.addToFavorites,
                                                                      paymentStartedCallback: self.orderConfirmationStartedHandler,
                                                                      paymentSuccessCallback: self.orderConfirmedHandler,
                                                                      paymentErrorCallback: self.orderFailureHandler,
                                                                      failedToStartCallback: self.failedToStartHandler)
            
            
                self.navigationController?.pushViewController(epayPaymentController, animated: true)
            }
            
        }, errorCallback: { error in
            self.orderFailureHandler(error)
        }, failedToStartCallback: failedToStartHandler)
    }
    
    /**
     Method for editing epay payment data.
     - Parameter editSuccessHandler: PaymentEditSuccessHandler type closure for handling editing success.
     - Parameter editFailHandler: PaymentEditFailHandler type closure for handling editing fails.
     */
    
    public func editPaymentData(editSuccessHandler: PaymentEditSuccessHandler?, editFailHandler: PaymentEditFailHandler?) {
        let epayEditController = EpayEditViewController(configuration: epayConfiguration,
                                                        editSuccessHandler: editSuccessHandler,
                                                        editFailHandler: editFailHandler)
        navigationController?.pushViewController(epayEditController, animated: true)
    }
}


