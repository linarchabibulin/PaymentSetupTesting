//
//  DibsModule.swift
//  MobileTicketCore
//
//  Created by Linar Chabibulin on 11/05/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

import Foundation

/**
 DIBS MODULE
 DibsPaymentModule wraps DIBS lib.
 This module will be displayed in its own ViewController.
 Refer to 'DIBSConfigurationProtocol' for configuration options.
 */

public class DibsModule {
    /// - Parameter dibsConfiguration: configuration for DIBS
    public var dibsConfiguration: DIBSConfigurationProtocol!
    /// - Parameter orderConfirmationStartedHandler: 'Void' type closure
    public var orderConfirmationStartedHandler: (() -> Void)!
    /// - Parameter orderConfirmedHandler: 'PaymentConfirmedHandler' type success closure
    public var orderConfirmedHandler: PaymentConfirmedHandler!
    /// - Parameter orderConfirmationFailureHandler: 'PaymentErrorHandler' type failure closure
    public var orderFailureHandler: PaymentErrorHandler!
    /// - Parameter failedToStartHandler: payment did not start closure
    public var failedToStartHandler: (() -> Void)?
    
    weak private var navigationController: UINavigationController?
    private var orderId: String?
    private var price: Int?
    private var addToFavorites = false
    
    /**
     Default initiator
     - Parameter navigationController: navigation Controller into which DIBS view controller will be pushed
     - Parameter epayConfiguration: see 'EpayConfigurationProtocol' for detailed description.
     */
    init(navigationController: UINavigationController,
         dibsConfiguration: DIBSConfigurationProtocol) {
        
        self.navigationController = navigationController
        self.dibsConfiguration = dibsConfiguration
    }
    
    /**
     Method for intiating MobilePay payment
     - Parameter orderId: String with order id
     - Parameter price: price of the order
     - Parameter isFavourite: whether you would like to add order to Fvourites list on successfull purchase
     - Parameter orderConfirmationStartedHandler: closure for handling starting of order payment (executed before order purchase is confirmed)
     - Parameter successHandler: PaymentConfirmedHandler type closure for handleing successfull order payment (executed after order purchase is confirmed)
     - Parameter errorHandler: PaymentErrorHandler type closure for handling any errors that arrise
     - Parameter failedToStartCallback: block perform if api call fails to start. If Api status is unavailable. Optional
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
        
        
        if CustomerRepository.customer?.paymentToken == nil {
            let error = NSError.errorWithDescription(
                "Attempting a DIBS payment while paymentToken == nil",
                localizedDescription: LocalizedStrings.payments.ticketPurchaseFailureMessage
            )
            orderFailureHandler(error)
            return
        }
        
        let dibsPaymentViewController = DIBSPaymentViewController()
        dibsPaymentViewController.configuration = dibsConfiguration
        dibsPaymentViewController.orderId = orderId
        dibsPaymentViewController.price = price
        dibsPaymentViewController.addToFavorites = addToFavorites
        dibsPaymentViewController.orderConfirmationStartedHandler = orderConfirmationStartedHandler
        dibsPaymentViewController.paymentSuccessCallback = orderConfirmedHandler
        dibsPaymentViewController.paymentErrorCallback = orderFailureHandler
        dibsPaymentViewController.failedToStartCallback = failedToStartHandler
        
        navigationController?.pushViewController(dibsPaymentViewController, animated: true)
    }
    
    /**
     Method for editing DIBS payment data.
     - Parameter editSuccessHandler: PaymentEditSuccessHandler type closure for handling editing success.
     */
    
    public func editPaymentData(editSuccessHandler: PaymentEditSuccessHandler?, editFailHandler: PaymentEditFailHandler?) {
        
        let editPaymentInfoViewController = EditPaymentInfoViewController()
        editPaymentInfoViewController.configuration = dibsConfiguration
        editPaymentInfoViewController.editSuccessHandler = editSuccessHandler
        editPaymentInfoViewController.editFailHandler = editFailHandler
        
        navigationController?.pushViewController(editPaymentInfoViewController, animated: true)
    }
}
