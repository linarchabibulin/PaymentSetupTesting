//
//  MobilePayPaymentModule.swift
//  MobileTicketCore
//
//  Created by Linar Chabibulin on 11/05/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

import Foundation
import SwiftTryCatch

/**
 MOBILEPAYMODULE DESCRIPTION
 
 MobilePayModule intiates MobilePay app based payments and handles repsonces from MobilePayApp
 To use MobilePay SDK/App you willl need:
 1. Setup 'MobilePayManager.sharedInstance()' in appDelegate - refer to MobilePayConfigurationProtocol for conveniance setting up mobilepay manager.
 2. Call 'handleMobilePayPayment(withUrl url: URL)' from appDelegates 'application(app:, open url:, options:) -> Bool' method to handle MobilePay app call bacs with URL
 3. Call 'makePayment' methhod to initate payments through MobilePay app
 */

class MobilePayModule: NSObject {

    // MARK: public Static variables
    /// - Parameter orderConfirmationStartedHandler: 'Void' type closure
    public static var orderConfirmationStartedHandler: (() -> Void)?
    /// - Parameter successHandler: payment confirmed closure
    public static var successHandler: PaymentConfirmedHandler?
    /// - Parameter errorHandler: payment failed closure
    public static var errorHandler: PaymentErrorHandler?
    /// - Parameter failedToStartHandler: payment did not start closure
    public static var failedToStartHandler: (() -> Void)?
    /// - Parameter addToFavourites: whether the successfull order will be saved to favorites
    public static var addToFavorites = false
    
    public static var orderConfirmationUrlString = ""
    
    // MARK: - Private
    static let kAppErrorDomain = "AppErrorDomain"
    
    // MARK: - Payment methods
    // price is passed in DKK (and is always an integer amount)
/**
     Method for intiating MobilePay payment
     - Parameter orderId: String with order id
     - Parameter price: price of the order
     - Parameter isFavourite: whether you wuold like to add order to Fvourites list on successfull purchase
     - Parameter orderConfirmationStartedHandler: closure for handling starting of order payment (executed before order purchase is confirmed)
     - Parameter successHandler: PaymentConfirmedHandler type closure for handling successfull order payment (executed after order purchase is confirmed)
     - Parameter errorHandler: PaymentErrorHandler type closure for handling any errors that arrise
     - Parameter failedToStartHandler: block perform if api call fails to start. If Api status is unavailable. Optional

     NOTE: MobilePayManager.sharedInstance() must be setup before calling makePayment
*/
    public static func makePayment(forOrderId orderId: String,
                                   withPrice price: Int,
                                   addToFavourites isFavourite: Bool,
                                   orderConfirmationStartedHandler: (() -> Void)?,
                                   successHandler: @escaping PaymentConfirmedHandler,
                                   errorHandler: @escaping PaymentErrorHandler,
                                   failedToStartHandler: (() -> Void)? = nil) {

        
        // Mobile Pay accept price in DKK. So it must be converted
        let payment = MobilePayPayment(orderId: orderId, productPrice: Float(Double(price) / 100.0))
        
        MobilePayModule.orderConfirmationStartedHandler = orderConfirmationStartedHandler
        MobilePayModule.successHandler = successHandler
        MobilePayModule.errorHandler = errorHandler
        MobilePayModule.failedToStartHandler = failedToStartHandler
        MobilePayModule.addToFavorites = isFavourite
        
        SwiftTryCatch.try({
            MobilePayManager.sharedInstance().beginMobilePayment(with: payment!, error: { (error: Error) in
                self.logPayment(shouldPrintClass: true, printMethodName: #function, logString: "Payment failed. Error code: \(error._code), description: \(error.localizedDescription)")
                
                self.errorHandler?(error as NSError)
            })
        }, catch: {(exception: NSException?) in
            let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey : LocalizedStrings.networkErrorMessages.defaultRESTErrorMessage])
            self.errorHandler?(error)
        }, finally: {
        })
    }
    
    /**
     Function for handeling MobilePay app responses.
     Put call to this function in appDelegates 'application(app:, open url:, options:) -> Bool' method (or/and nayothers for appropriate iOS version)
     - Parameter url: URL that might (or might not) contain data from MobilePay app
     */
    
    public static func handleMobilePayPayment(withUrl url: URL) {
        // NOTE: https://trello.com/c/ywvOEJCk/124-app-stuck-on-mobilepay-receipt-screen-for-many-hours
        // We change our MobilePay payment flow such that we ignore the Handler from MobilePay upon return to our app. Instead, when our app regains focus, we always call the confirm endpoint and check whether the confirm/capture succeeded or not. If it did not, the app remains on the basket approve page. If it did, continue as we normally do after payment completion.
        // Left the error handling
        
        MobilePayManager.sharedInstance().handleMobilePayPayment(with: url,
             success: { (paymentResult: MobilePaySuccessfulPayment?) in
                                                                    
                guard let paymentResult = paymentResult else {
                    let error = NSError.errorWithDescription("ERROR: MobilePay payment result is nil", domain: kAppErrorDomain)
                    MobilePayModule.errorHandler?(error)
                    return
                }
                
                let orderId: String = paymentResult.orderId
                let transactionId: String = paymentResult.transactionId
                let amountWithdrawnFromCard: Float = paymentResult.amountWithdrawnFromCard
                
                logPayment(shouldPrintClass: true, printMethodName: #function, logString: "Payment success. order ID: \(orderId), transaction ID: \(transactionId), amount: \(amountWithdrawnFromCard)")
                let orderConfirmation = OrderConfirmationEntity()
                orderConfirmation.orderId = paymentResult.orderId
                orderConfirmation.transactionId = paymentResult.transactionId
                orderConfirmation.addToFavorites = addToFavorites
                
                orderConfirmationStartedHandler?()
                
                PaymentModule.confirmOrder(urlString: MobilePayModule.orderConfirmationUrlString,
                                           orderConfirmation: orderConfirmation,
                                           orderConfirmedHandler: MobilePayModule.successHandler,
                                           orderConfirmationFailureHandler: MobilePayModule.errorHandler,
                                           failedToStartHandler: MobilePayModule.failedToStartHandler)

        },
             error: {(error: Error) in
                self.logPayment(shouldPrintClass: true, printMethodName: #function, logString: "Payment failed. Error code: \(error._code), description: \(error.localizedDescription)")
                
                self.errorHandler?(error as NSError)
        },
             cancel: {(mobilePayCancelledPayment: MobilePayCancelledPayment?) in
                self.logPayment(shouldPrintClass: true, printMethodName: #function, logString: "Payment cancelled by user. Order ID: \(mobilePayCancelledPayment!.orderId)")
                
                let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey : LocalizedStrings.payments.ticketPurchaseCancelledMessage])
                self.errorHandler?(error)
        }
        )
    }
}
