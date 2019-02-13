//
//  PaymentModule.swift
//  MobileTicketCore
//
//  Created by Linar Chabibulin on 11/05/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

import UIKit

public typealias PaymentConfirmedHandler = (_ ticketId: Int) -> Void
public typealias PaymentErrorHandler = (_ error: NSError) -> Void

public typealias PaymentEditSuccessHandler = (_ subscritpionId: Int64, _ cardNo: String, _ editController: UIViewController?) -> Void
public typealias PaymentEditFailHandler = (_ editController: UIViewController?) -> Void

/**
 PAYMENTMODULE
 Payment module is a one stop solution to for handleing payments.
 MobilePay SDK works in conjunction with 3rd party MobilePay app - refer to 'MobilePayModule' for information on how to
 ePay and DIBS modules create, present and close their own view controllers - we assume that this view controlelr is pushed into standart navigationControler.
 */

class PaymentModule {
    
    // MARK: - Declarations
    
    // MARK: - Public
    /// url string for `PaymentApiClient.confirm()` function
    static public var defaultConfirmPaymentUrlString: String!
    /// `PaymentModuleConfigurationProtocol` conforming object that storres all the configurations for root payment object and specific payment modules
    public var configuration: PaymentModuleConfigurationProtocol
    /// `PaymentConfirmedHandler` type success closure
    public var orderConfirmedHandler: PaymentConfirmedHandler?
    /// `PaymentErrorHandler` type failure closure
    public var orderConfirmationFailureHandler: PaymentErrorHandler?
    /// payment did not start closure
    public var orderConfirmationDidNotStartHandler: (() -> Void)?

    // MARK: - Private
    private var paymentProviderType: CorePaymentProviderType
    weak private var navigationController: UINavigationController!
    
    
    // MARK: - Methods
    
    // MARK: - Initialization
    /**
     Default initiator
     - Parameter configuration: see 'PaymentModuleConfigurationProtocol' for detailed description.
     - Parameter paymentProviderType: 'CorePaymentProviderType' payment type you want to make
     - Parameter navigationController: navigationController into which payment view controller will be pushed (if payment module uses its own view controllers)
     */
    init(configuration: PaymentModuleConfigurationProtocol,
         paymentProviderType: CorePaymentProviderType,
         navigationController: UINavigationController) {
        
        self.configuration = configuration
        PaymentModule.defaultConfirmPaymentUrlString = self.configuration.confirmOrderUrlString
        
        self.paymentProviderType = paymentProviderType
        self.navigationController = navigationController
    }
    
    // MARK: - Public
    
    /**
     Default payment confirmation function. All payment Modules should call this before executing their 'orderConfirmedHandler's
     Use this function to confirm that 3rd party service successfully completed transaction.
     - Parameter orderConfirmation: OrderConfirmationEntity containing all the data needed to confirm order
     - Parameter orderConfirmedHandler: 'PaymentConfirmedHandler' type success closure. Optional
     - Parameter orderConfirmationFailureHandler: 'PaymentErrorHandler' type failure closure. Optional
     - Parameter failedToStartHandler: block perform if api call fails to start. If Api status is unavailable. Optional

     */
    static public func confirmOrder(urlString: String,
                                    orderConfirmation: OrderConfirmationEntity,
                                    orderConfirmedHandler: PaymentConfirmedHandler?,
                                    orderConfirmationFailureHandler: PaymentErrorHandler?,
                                    failedToStartHandler: (() -> Void)? = nil) {
        
        var orderConfirmTask: (_ success: @escaping (Int) -> Void, _ failure: @escaping (NSError) -> Void) -> Void
        orderConfirmTask = { (success, failure) in
            PaymentApiClient.confirm(urlString: urlString,
                                     input: orderConfirmation,
                                     successCallback: success,
                                     errorCallback: failure,
                                     failedToStartCallback: failedToStartHandler)
        }
        
        let successHandler: ((Any?)->Void) = { (value) in
            if let ticketId = value as? Int {
                orderConfirmedHandler?(ticketId)
            } else {
                print("ERROR: ticketId not parssed correctly - defaulting to -1")
                orderConfirmedHandler?(-1)
            }
        }
        
        if let orderConfirmationFailureHandler = orderConfirmationFailureHandler {
            // Call order\confirm method, retrying if failed
            NetworkRetryHelper().retry(
                task: orderConfirmTask,
                success: successHandler,
                failure: orderConfirmationFailureHandler
            )
        }
    }
    
    /**
     Method for initiating payment procedure - payment type, and payment configurations are set in init() method - see init().
     
     - Parameter orderId: String with order id
     - Parameter price: price of the order
     - Parameter isFavourite: whether you wuold like to add order to Fvourites list on successfull purchase
     - Parameter orderConfirmationStartedHandler: PaymentConfirmedHandler type closure for handleing successfull order payment (executed after order purchase is confirmed)
     - Parameter orderConfirmationFailureHandler: PaymentErrorHandler type closure for handling any errors that arrise
     - Parameter orderConfirmationDidNotStartHandler: block perform if api call fails to start. If Api status is unavailable. Optional

     */
    public func makePayment(forOrderId orderId: String,
                            withPrice price: Int,
                            addToFavourites isFavourite: Bool,
                            orderConfirmationStartedHandler: @escaping () -> Void,
                            orderConfirmedHandler: @escaping PaymentConfirmedHandler,
                            orderConfirmationFailureHandler: @escaping PaymentErrorHandler,
                            orderConfirmationDidNotStartHandler: (() -> Void)? = nil) {
        
        self.orderConfirmedHandler = orderConfirmedHandler
        self.orderConfirmationFailureHandler = orderConfirmationFailureHandler
        self.orderConfirmationDidNotStartHandler = orderConfirmationDidNotStartHandler

        guard isPaymentProviderSupported(paymentProviderType) else {
            orderConfirmationFailureHandler(NSError.errorWithDescription("ERROR: payment method \(paymentProviderType) is not supported"))
            return
        }
        
        switch paymentProviderType {
            
        case .ePay:
            break
            
        case .mobilePay:
            
            MobilePayModule.makePayment(forOrderId: orderId,
                                        withPrice: price,
                                        addToFavourites: isFavourite,
                                        orderConfirmationStartedHandler: orderConfirmationStartedHandler,
                                        successHandler: orderConfirmedHandler,
                                        errorHandler: orderConfirmationFailureHandler)
            
            
        case .dibs:
            
            guard let configuration = configuration.dibsConfiguration else {
                orderConfirmationFailureHandler(NSError.errorWithDescription("ERROR - DIBS configuration is missing!"))
                return
            }

            let dibsModule = DibsModule(navigationController: self.navigationController!,
                                        dibsConfiguration: configuration)
            
            dibsModule.makePayment(orderId: orderId,
                                   price: price,
                                   addToFavorites: isFavourite,
                                   orderConfirmationStartedHandler: orderConfirmationStartedHandler,
                                   orderConfirmedHandler: orderConfirmedHandler,
                                   orderFailureHandler: orderConfirmationFailureHandler)
        }
    }
    
    /**
     Method for editing payment data - payment type, and payment configurations are set in init() method - see init().
     - Parameter editSuccessHandler: PaymentEditSuccessHandler type closure for handleing editing success - NOTE: add navigation on completion logic here.
     */
    
    public func editPaymentData(editSuccessHandler: @escaping PaymentEditSuccessHandler, editFailHandler: @escaping PaymentEditFailHandler) {
        switch paymentProviderType {
        case .ePay:
            break
            
        case .mobilePay:
            print("Warning! - MobilePay edits handled by MobilePay app")
            
        case .dibs:
            guard let configuration = configuration.dibsConfiguration else {
                orderConfirmationFailureHandler?(NSError.errorWithDescription("ERROR - DIBS configuration is missing!"))
                return
            }
            
            let dibsModule = DibsModule(navigationController: navigationController!,
                                        dibsConfiguration: configuration)
            
            dibsModule.editPaymentData(editSuccessHandler: editSuccessHandler, editFailHandler: editFailHandler)
        }
    }
    
    /// Method for checking if payment type is supported
    /// - Parameter paymentProviderType: CorePaymentProviderType to check.
    public func isPaymentProviderSupported(_ paymentProviderType: CorePaymentProviderType) -> Bool {
        return configuration.supportedPaymentProviderTypeList.contains(paymentProviderType)
    }
}
