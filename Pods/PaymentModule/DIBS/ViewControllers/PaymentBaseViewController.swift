//
//  PaymentBaseViewController.swift
//  Mobilbillet
//
//  Created by Linar Chabibulin on 11/05/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

class PaymentBaseViewController: UIViewController, DIBSPaymentSource, DIBSPaymentResultDelegate {
    
    // MARK: - Declarations
    
    // MARK: - Public
    var configuration: DIBSConfigurationProtocol!
    var paymentView: DIBSPaymentView!
    
    // MARK: - Private
    private var activityIndicator = ActivityIndicator()
    
    // MARK: - Methods
    
    // MARK: - View management
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = configuration.appearenceConfiguration.paymentBackgroundColor
        
        localize()
        activityIndicator.show(view)

        // construct the payment view, and set the source for payment data
        paymentView = DIBSPaymentView(frame: UIScreen.main.bounds, source: self)
        // set self as the implementation of DIBSPaymentResultDelegate to get callbacks from payment window
        paymentView.delegate = self
    }
    
    // Workaround to fix
    // https://fabric.io/kofoed2/ios/apps/dk.midttrafik.mobilbillet/issues/573ccf08ffcdc042500b61cb
    // http://stackoverflow.com/questions/5738589/uiwebview-crash-when-dismissing-modal-view-controller-while-request-is-in-prog
    override func viewWillDisappear(_ animated: Bool) {
        
        if let webView = getWebView() {
            webView.delegate = nil
            webView.stopLoading()
        }
        
        super.viewWillDisappear(animated)
    }
    
    // MARK: -

    // Returns DIBS underlying UIWebView using KVC
    // http://jerrymarino.com/2014/01/31/objective-c-private-instance-variable-access.html
    private func getWebView() -> UIWebView? {
        
        return DIBSPaymentView.accessInstanceVariablesDirectly
            ? paymentView?.value(forKey: "_paymentView") as? UIWebView
            : nil
    }
    
    func configurePayment(_ payment: DIBSPaymentBase) {
#if DEBUG
        // Allow using test cards in Debug & Staging builds only
        payment.test = true
#endif
        
        payment.language = configuration.language
        payment.theme = Theme_Custom
        
        let appBgColor = configuration.appearenceConfiguration.appBackgroundColor.toHexString()
        let payButtonBgColor = configuration.appearenceConfiguration.playButtonBackgroundColor.toHexString()
        let payButtonFontColor = configuration.appearenceConfiguration.payButtonFontColor.toHexString()
        
        payment.customThemeCSS = "{\"appBgColor\":\"\(appBgColor)\",\"paybuttonBgColor\":\"\(payButtonBgColor)\",\"paybuttonFontColor\":\"\(payButtonFontColor)\"}"
        
        let postData = payment.generatePostData()
        payment.calculatedMAC = calculateMac(postData!)
    }
    
    // MARK: - DIBSPaymentSource members
    
    func getPaymentData() -> DIBSPaymentBase? {
        // Set up a pre-authorization to make tiket purchases later
        let preAuthorization = DIBSPreAuthorization(
            merchantID: configuration.merchantId,
            orderID: configuration.dibsOrderId,
            currencyCode: configuration.currencyCode,
            payTypes: configuration.payTypes
        )
        
        preAuthorization?.uniqueOrderID = false
        configurePayment(preAuthorization!)
        
        return preAuthorization
    }

    // MARK: - DIBSPaymentResultDelegate members
    
    // Called when the payment window has been fully loaded and is ready for user input.
    func didLoadPaymentWindow() {
        // Possible fix for crash in [UIThreadSafeNode createPeripheral]:
        // https://fabric.io/kofoed2/ios/apps/dk.midttrafik.mobilbillet/issues/573c3fd8ffcdc04250050be4/sessions/732abf2cb5784b92b2d06ad3de5b3d02
        // http://stackoverflow.com/questions/16584556/uithreadsafenode-createperipheral-unrecognized-selector-sent-to-instance
        getWebView()?.keyboardDisplayRequiresUserAction = false
        
        activityIndicator.hide()
        
        if paymentView != nil {
            view?.addSubview(paymentView!)
        }
    }
    
    // Called when the payment window fails to load.
    func failedLoadingPaymentWindow() {
        
        activityIndicator.hide()
        
        if (self.navigationController?.viewControllers.last is CoreApproveTicketViewController) == false {
            // it can be called multiply times
            // if top controller in navigation stack is of class ApproveTicketBaseViewController - the navigation back already have been performed - ignore navigation back
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    // DIBSPaymentView delegates to this method when a cancel URL has been loaded as a result of cancel processing
    func didLoadCancelURL() {
        print("[PaymentBaseViewController.didLoadCancelURL]")
        
        // When the payment was cancelled, paymentCancelled should be called, too
        // - thus we are not doing anyhing special inside this method
    }
    
    // Callback from DIBSPaymentView, after a call to cancelPayment, when the payment window is done with its cancel processing.
    func paymentCancelled(_ params: [AnyHashable: Any]) {
        print("[PaymentBaseViewController.paymentCancelled]")
        
        activityIndicator.hide()
        _ = navigationController?.popViewController(animated: true)
    }
    
    // DIBSPaymentView delegates to this method when a payment has been accepted.
    func paymentAccepted(_ params: [AnyHashable: Any]) {
        print("[PaymentBaseViewController.paymentAccepted]")
        
        // NOTE: 'payment accepted' gets called by DIBS when you edit credit card data. That means when you create
        // an account and fill in credit card data you get a payment success callback that screws up push
        // notification pop-up appearance logic. 
        // This checks from what controller we came to PaymentBaseViewController
        if ((previousViewController() as? CoreEditProfileViewController) != nil) {
            // not a payment
            return
        }
        
        configuration.paymentAcceptedCallback?()
        
#if DEBUG
        for param in params {
            print(param.0, param.1)
        }
#endif
    }
    
    // DIBSPaymentView delegates to this method when some error occurred in payment processing.
    // You should use this to taker proper action in showing or logging errors and maybe closing the payment window.
    func errorDidOccur(_ params: [AnyHashable: Any]) {
        activityIndicator.hide()

        let errorNumber: Int = params[DIBSPaymentLibraryErrorNumberKey] as! Int
        
        // Return localized error message if available, otherwise use DIBS provided error message.
        let errorMessage: String = LocalizedStrings.payments.DIBS.errorMessages[errorNumber]
            ?? params[DIBSPaymentLibraryErrorMessageKey] as! String
        
        print("[PaymentBaseViewController.errorDidOccur] Code [\(errorNumber)], Message [\(errorMessage)]")
        
        // NOTE: You SHOULD check errorCode against the DIBSPaymentLibraryCriticalErrorMax constant,
        // and if critical, your app SHOULD fully cancel/dismiss the payment window and ensure
        // that the current payment processing stops
        if errorNumber <= DIBSPaymentLibraryCriticalErrorMax {
            // indicates severe error that should make us abort payment
            _ = navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - HMAC calculation
    
    // http://tech.dibspayment.com/batch/d2integratedpwapihmac
    private func calculateMac(_ postData: String) -> String {
        // Create the message for MAC calculation sorted by the key
        let parameters: [String : String] = getPostDataPatameters(postData)
        let sortedInitialParameters = parameters.sorted { $0.0 < $1.0 }
        
        // initiating OrderedDictionary with Element list is causing crash when "Swif Compiler - Code Generation" Optimization level is not none (set in build settings)
        // instead we are creating empty OrderedDictionary and adding parameters one by one
        // Trello task - https://trello.com/c/jYj2oInN/377-live-ver-1-6-6-app-crashes-after-user-taps-on-approve-purchase-button
        var sortedParameters = OrderedDictionary<String, String>()
        var i = 0
        for parameter in sortedInitialParameters {
            _ = sortedParameters.insertElement((parameter.0, parameter.1), atIndex: i)
            i += 1
        }
        
        _ = sortedParameters.removeValueForKey("custom_theme")
        _ = sortedParameters.removeValueForKey("version")

        let macString = sortedParameters.queryStringWithEncoding()
    
        // Calculate MAC key
        let data = SHA256.dataFromHexString(configuration.hMacKey)
        let hash = macString.sha256(data)
        let mac = SHA256.hexStringFromData(hash)
        
        return mac
    }
    
    // https://gist.github.com/jackreichert/81a7ce9d0cefd5d1780f
    private func getPostDataPatameters(_ query: String) -> [String : String] {
        
        var results = [String : String]()
        let keyValueList = query.components(separatedBy: "&")
        
        if !keyValueList.isEmpty {
            for pair in keyValueList {
                let pairKeyValueList = pair.components(separatedBy: "=")
                if pairKeyValueList.count > 1 {
                    // Alex: URL decode POSTDATA parameters, to satisfy the HMAC calculation
                    results.updateValue(pairKeyValueList[1].removingPercentEncoding ?? "", forKey: pairKeyValueList[0])
                }
            }
            
        }
        return results
    }
    
    // MARK: - BaseViewController overrides
        // @Linar - check this logic is from midttrafik
//    override func handleAPIUnavailableNotification() {
//        activityIndicator.hide()
//    }
    
    // MARK: - Helpers
    
    private func localize() {
        
        title = LocalizedStrings.payments.sceneTitle_changePayment
        addBackBarButton(title: title ?? "",
                         font: configuration.appearenceConfiguration.navigationBarFont,
                         itemColor: configuration.appearenceConfiguration.navigationBarItemColor)
    }
}
