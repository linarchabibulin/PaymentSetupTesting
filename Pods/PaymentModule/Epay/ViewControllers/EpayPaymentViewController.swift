//
//  EpayPaymentViewController.swift
//  MobileTicketCore
//
//  Created by Martynas Stanaitis on 05/06/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

import Foundation

/// EpayPaymentViewController is ment for making payments
class EpayPaymentViewController: EpayBaseViewController {
    
    // MARK: - Declarations
    
    // MARK: - Private
    private var paymentStartedCallback: (() -> Void)!
    private var paymentSuccessCallback: PaymentConfirmedHandler!
    private var paymentErrorCallback: PaymentErrorHandler!
    private var failedToStartHandler: (() -> Void)?
    
    private var orderId: String! // oroginal orderId
    private var epayOrderId: String!  // used in purchase flow
    private var price: Int!       // Ticket price in DKK
    private var addToFavorites = false
    
    // MARK: - Methods
    
    // MARK: initalization
    /**
     Method for intiating MobilePay payment
     - Parameter configuration: see 'EpayConfigurationProtocol' for detailed description.
     - Parameter orderId: String with order id
     - Parameter price: price of the order
     - Parameter isFavourite: whether you wuold like to add order to Fvourites list on successfull purchase
     - Parameter successHandler: PaymentConfirmedHandler type closure for handleing successfull order payment (executed after order purchase is confirmed)
     - Parameter errorHandler: PaymentErrorHandler type closure for handling any errors that arrise
     - Parameter failedToStartCallback: block perform if api call fails to start. If Api status is unavailable. Optional
     */
    convenience init(configuration:EpayConfigurationProtocol,
                     orderId: String,
                     epayOrderId: String,
                     price: Int,
                     addToFavorites: Bool = false,
                     paymentStartedCallback: @escaping () -> Void,
                     paymentSuccessCallback: @escaping PaymentConfirmedHandler,
                     paymentErrorCallback: @escaping PaymentErrorHandler,
                     failedToStartCallback: (() -> Void)? = nil) {
        
        self.init(configuration: configuration)
        
        self.orderId = orderId
        self.epayOrderId = epayOrderId
        self.price = price
        self.addToFavorites = addToFavorites
        
        self.paymentStartedCallback = paymentStartedCallback
        self.paymentSuccessCallback = paymentSuccessCallback
        self.paymentErrorCallback = paymentErrorCallback
        self.failedToStartHandler = failedToStartCallback
    }
    
    // MARK: - View management
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        if epayConfiguration.purchaseCardSubscriptionId != nil {
            enablePurchaseMode(subscriptionId: epayConfiguration.purchaseCardSubscriptionId!)
            addOrderParameters(price: price, epayOrderId: epayOrderId)
        } else {
            print("\(#function) Error!: Trying to make payment when epayConfiguration.purchaseCardSubscriptionId == nil")
        }
        activityIndicator.show(view)
        
        // FIXME: Send Screen track notification
    }
    
    // MARK: - Overrides
    
    @objc override func paymentWindowLoaded(_ notification: Notification) {
        super.paymentWindowLoaded(notification)
        
        activityIndicator.hide()
        
        if !CoreRepository.hasEnterCVCPromptShown {
            CoreRepository.hasEnterCVCPromptShown = true
            showAlert(LocalizedStrings.payments.enterCVCPrompt)
        }
    }
    
    @objc override func paymentAccepted(_ notification: Notification) {
        super.paymentAccepted(notification)
        
        _ = navigationController?.popViewController(animated: true)
        
        let ePayParameters: [ePayParameter] = notification.object as! [ePayParameter]
        
        if let transactionId = ePayParameters[0].value {
            let confirmation = OrderConfirmationEntity()
            confirmation.orderId = orderId
            confirmation.transactionId = transactionId
            confirmation.addToFavorites = addToFavorites
            
            paymentStartedCallback()
            PaymentModule.confirmOrder(urlString: epayConfiguration.orderConfirmationUrlString,
                                       orderConfirmation: confirmation,
                                       orderConfirmedHandler: paymentSuccessCallback,
                                       orderConfirmationFailureHandler: paymentErrorCallback,
                                       failedToStartHandler: failedToStartHandler)
        } else {
            let error = NSError.errorWithDescription(
                "ePay payment didn't return a transaction ID.",
                localizedDescription: LocalizedStrings.payments.ticketPurchaseFailureMessage
            )
            
            paymentErrorCallback(error)
        }
    }
    
    @objc override func paymentWindowCancelled(_ notification: Notification) {
        super.paymentWindowCancelled(notification)
        
        if let controllerList = navigationController?.viewControllers {
            _ = navigationController?.popToViewController(controllerList[controllerList.count - 3], animated: true) // navigate 2 controlers back to screen before approve screen
        }
    }
}
