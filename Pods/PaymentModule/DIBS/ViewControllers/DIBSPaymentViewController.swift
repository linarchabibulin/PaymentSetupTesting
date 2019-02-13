//
//  DIBSPaymentViewController.swift
//  Mobilbillet
//
//  Created by Linar Chabibulin on 11/05/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

class DIBSPaymentViewController: PaymentBaseViewController {

    // MARK: - Declarations
    
    // MARK: - Public
    var orderId: String!
    var price: Int!         // Ticket price in Danish Ore
    var addToFavorites = false
    var orderConfirmationStartedHandler: (() -> Void)!
    var paymentSuccessCallback: PaymentConfirmedHandler!
    var paymentErrorCallback: PaymentErrorHandler!
    var failedToStartCallback: (() -> Void)?
    
    // MARK: - Methods
    
    // MARK: - View management
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = LocalizedStrings.payments.DIBS.sceneTitle
        
        // Set Back button title to the view before previous, since pressing the Back button
        // goes 2 view back to workaround "duplicate order ID" issue with DIBS
        if let backViewController = previousViewController(),
            let navigationController = navigationController {
            if navigationController.viewControllers.count > 2 {
                let viewControllerBeforePrevious = navigationController.viewControllers[navigationController.viewControllers.count - 3]
                backViewController.navigationItem.backBarButtonItem?.title = viewControllerBeforePrevious.title
            }
        }
        
        // Construct the payment view, and set the source for payment data
        paymentView = DIBSPaymentView(frame: UIScreen.main.bounds, source: self)
        // Set self as the implementation of DIBSPaymentResultDelegate to get callbacks from payment window
        paymentView!.delegate = self
    }
    
    // MARK: - DIBSPaymentSource
    
    override func getPaymentData() -> DIBSPaymentBase? {
        guard let paymentToken = CustomerRepository.customer?.paymentToken else {
            return nil
        }
        
        // Set up a pre-authorization to make tiket purchases later
        let dibsTicketPurchase = DIBSTicketPurchase(
            merchantID: configuration.merchantId,
            orderID: orderId,
            amount: UInt(price),  // The amount to be paid, given in "least possible unit" (aka: "oerer")
            currencyCode: configuration.currencyCode,
            ticketID: "\(paymentToken)"
        )
        
        dibsTicketPurchase?.uniqueOrderID = true
        configurePayment(dibsTicketPurchase!)
        
        return dibsTicketPurchase
    }
    
    // MARK: - DIBSPaymentResultDelegate
    
    // Called when the payment window has been fully loaded and is ready for user input.
    override func didLoadPaymentWindow() {
        super.didLoadPaymentWindow()
        
        if !DibsRepository.hasEnterCVCPromptShown {
            DibsRepository.hasEnterCVCPromptShown = true
            showAlert(LocalizedStrings.payments.enterCVCPrompt)
        }
    }
    
    override func failedLoadingPaymentWindow() {
        super.failedLoadingPaymentWindow()

        let error = NSError.errorWithDescription(
            "Failed to load the DIBS payment window.",
            localizedDescription: LocalizedStrings.payments.DIBS.failedLoadingPaymentWindowMessage
        )
        paymentErrorCallback(error)
    }
    
    // Callback from DIBSPaymentView, after a call to cancelPayment, when the payment window is done with its cancel processing.
    override func paymentCancelled(_ params: [AnyHashable: Any]) {
        super.paymentCancelled(params)

        let error = NSError.errorWithDescription(
            "Payment was cancelled by the user.",
            localizedDescription: LocalizedStrings.payments.ticketPurchaseCancelledMessage
        )
        paymentErrorCallback(error)
    }
    
    // DIBSPaymentView delegates to this method when a payment has been accepted.
    override func paymentAccepted(_ params: [AnyHashable: Any]) {
        super.paymentAccepted(params)
        
        _ = navigationController?.popViewController(animated: true)
        
        if let transactionId = params["transact"] as? String {
            let confirmation = OrderConfirmationEntity()
            confirmation.orderId = orderId
            confirmation.transactionId = transactionId
            confirmation.addToFavorites = addToFavorites
            
            orderConfirmationStartedHandler()
            
            PaymentModule.confirmOrder(urlString: configuration.orderConfirmationUrlString,
                                       orderConfirmation: confirmation,
                                       orderConfirmedHandler: paymentSuccessCallback,
                                       orderConfirmationFailureHandler: paymentErrorCallback,
                                       failedToStartHandler: failedToStartCallback)
        } else {
            let error = NSError.errorWithDescription(
                "DIBS payment didn't return a transaction ID.",
                localizedDescription: LocalizedStrings.payments.ticketPurchaseFailureMessage
            )
            self.paymentErrorCallback(error)
        }
    }

    override func errorDidOccur(_ params: [AnyHashable: Any]) {
        super.errorDidOccur(params)

        let errorNumber = params[DIBSPaymentLibraryErrorNumberKey] as? Int
        
        let error = NSError.errorWithDescription(
            params[DIBSPaymentLibraryErrorMessageKey] as! String,
            localizedDescription: LocalizedStrings.payments.DIBS.errorMessages[errorNumber ?? -1]
                ?? LocalizedStrings.payments.ticketPurchaseFailureMessage
        )
        paymentErrorCallback(error)
    }
}
