//
//  EpayPaymentBaseViewController.swift
//  MobileTicketCore
//
//  Created by Martynas Stanaitis on 05/06/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

import Foundation

/**
 EPAY BASE VIEW CONTROLLER
 EpayBaseViewController provides base implementation for displaying ePay View and handleing ePay sdk transactions
 */

open class EpayBaseViewController: UIViewController {
    
    // MARK: - Declarations
    
    // MARK: - Public
    /// - Parameter epayConfiguration: configuration for ePay
    public var epayConfiguration: EpayConfigurationProtocol!

    // MARK: Private declarations
    private var epaylib: ePayLib = ePayLib()
    
    // ePay webview spinner - we have no control of it
    // shows when error is received (we only interested in no internet error)
    // it does not get hidden when internet connection re-appears
    private var isErrorSpinnerVisible = false
    
    // MARK: Internal declarations
    internal var activityIndicator = ActivityIndicator()
    
    // MARK: initalization
    /**
     Default initiator
     - Parameter epayConfiguration: see 'EpayConfigurationProtocol' for detailed description.
     */
    convenience init(configuration:EpayConfigurationProtocol) {
        self.init()
        self.epayConfiguration = configuration
    }
    
    // MARK: - LifeCycle
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        guard epayConfiguration != nil else {
            print("ERROR!: epayConfiguration was not set properly!")
            return
        }
        
        startMonitoringInternetConnection()
        
        NotificationCenter.default.addObserver(self, selector: #selector(paymentAccepted), name: Notification.Name.PaymentAccepted, object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paymentLoadingAcceptPage), name: Notification.Name.PaymentLoadingAcceptPage, object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paymentWindowCancelled), name: Notification.Name.PaymentWindowCancelled, object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paymentWindowLoaded), name: Notification.Name.PaymentWindowLoaded, object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(paymentWindowLoading), name: Notification.Name.PaymentWindowLoading, object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(errorOccurred), name: Notification.Name.ErrorOccurred, object:nil)
        
        // Init the ePay Lib with parameters and the view to add it to.
        self.epaylib = ePayLib(view: view)
        setupEpayParameters()
        
        epayConfiguration.viewDidLoadAdditionalExecutionCallback?(self)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startPayment()
        epayConfiguration.viewWillAppearAdditionalExecutionCallback?(self, animated)
    }
    
    // MARK: - Payment setup
    
    func setupEpayParameters() {
        // set default parameters
        epaylib.parameters.add(ePayParameter.key("merchantnumber", value: epayConfiguration.merchantId)) // http://tech.epay.dk/en/specification#258
        epaylib.parameters.add(ePayParameter.key("currency", value: epayConfiguration.currencyCode))     // http://tech.epay.dk/en/specification#259
        
        // RASK - is it needed when adding card?
        // if commented - orderId is generated and still displayed. Does it have any effect?
        //        epaylib.parameters.add(ePayParameter.key("orderid", value: ePayOrderId))              // http://tech.epay.dk/en/specification#261
        epaylib.parameters.add(ePayParameter.key("mobile", value: "2"))                                // ???
        epaylib.parameters.add(ePayParameter.key("paymentcollection", value: "1"))                     // http://tech.epay.dk/en/specification#263
        epaylib.parameters.add(ePayParameter.key("lockpaymentcollection", value: "1"))                 // http://tech.epay.dk/en/specification#264
        epaylib.parameters.add(ePayParameter.key("paymenttype", value: "1, 3, 4, 6, 7, 9"))            // http://tech.epay.dk/en/specification#265
        // RASK - check if autodetect works
        epaylib.parameters.add(ePayParameter.key("language", value: "0"))                              // http://tech.epay.dk/en/specification#266
        epaylib.parameters.add(ePayParameter.key("encoding", value: "UTF-8"))                          // http://tech.epay.dk/en/specification#267
        // RASK - if custom css will be needed
        epaylib.parameters.add(ePayParameter.key("mobilecssurl", value: "http://www.filedropper.com/epaytheme"))   // http://tech.epay.dk/en/specification#269
        epaylib.parameters.add(ePayParameter.key("instantcapture", value: "0"))                        // http://tech.epay.dk/en/specification#270
        //[parameters addObject:[KeyValue initKey:@"callbackurl" value:@""]];                          // http://tech.epay.dk/en/specification#275
        epaylib.parameters.add(ePayParameter.key("instantcallback", value: "1"))                       // http://tech.epay.dk/en/specification#276
        
        //[parameters addObject:[KeyValue initKey:@"group" value:@"group"]];                           // http://tech.epay.dk/en/specification#279
        
        // is visible in ePay administration
        // http://tech.epay.dk/en/specification#280
        if let customerMobileNumber = epayConfiguration.customerMobileNumber, let customerName = epayConfiguration.customerName {
            epaylib.parameters.add(ePayParameter.key("description", value: "\(customerMobileNumber) \(customerName)"))
        } else {
            epaylib.parameters.add(ePayParameter.key("description", value: ""))
        }
        
        //[parameters addObject:[KeyValue initKey:@"hash" value:@""]];                                  //http://tech.epay.dk/en/specification#281
        //[parameters addObject:[KeyValue initKey:@"subscriptionname" value:@"0"]];                     //http://tech.epay.dk/en/specification#283
        //[parameters addObject:[KeyValue initKey:@"mailreceipt" value:@""]];                           //http://tech.epay.dk/en/specification#284
        //[parameters addObject:[KeyValue initKey:@"googletracker" value:@"0"]];                        //http://tech.epay.dk/en/specification#286
        //[parameters addObject:[KeyValue initKey:@"backgroundcolor" value:@""]];                       //http://tech.epay.dk/en/specification#287
        //[parameters addObject:[KeyValue initKey:@"opacity" value:@""]];                               //http://tech.epay.dk/en/specification#288
        epaylib.parameters.add(ePayParameter.key("declinetext", value: "Decline Text"))                 //http://tech.epay.dk/en/specification#289
    }
    
    func startPayment() {
        epaylib.displayCancelButton = true
        epaylib.loadPaymentWindow()
    }
    
    func addOrderParameters(price: Int, epayOrderId: String) {
        epaylib.parameters.add(ePayParameter.key("orderid", value: epayOrderId))   // http://tech.epay.dk/en/specification#261
        epaylib.parameters.add(ePayParameter.key("amount", value: "\(price)")) // http://tech.epay.dk/en/specification#260
    }
    
    func enablePurchaseMode(subscriptionId: Int64) {
        // IMPORTANT - Default value is 0
        // In documentation it is not mentioned that there is option 4 - as mentioned by Max on 2017.01.06 in https://trello.com/c/pCONj8C1/1-epay-developer-kit
        epaylib.parameters.add(ePayParameter.key("subscription", value: "4"))
        epaylib.parameters.add(ePayParameter.key("subscriptionId", value: "\(subscriptionId)"))
    }
    
    func enableSubscriptionCreationMode() {
        // updates view to subscription mode - for credit card edition
        // if enabled - on successfull edit will return card information and new 'subscriptionId'
        epaylib.parameters.add(ePayParameter.key("subscription", value: "1"))                         //http://tech.epay.dk/en/specification#282
    }
    
    // NOTE: EDIT MODE NOT USED ATM
    func enableSubscriptionEditMode(subscriptionId: Int64) {
        // updates view to subscription mode - for credit card edition
        // not used since 2017-06-02
        // if enabled - on successfull edit will return card information and same 'subscriptionId'
        epaylib.parameters.add(ePayParameter.key("subscription", value: "2"))                          //http://tech.epay.dk/en/specification#282
        epaylib.parameters.add(ePayParameter.key("subscriptionId", value: "\(subscriptionId)"))        //http://tech.epay.dk/en/specification#283
    }
    
    // MARK: - Notifications
    
    @objc func paymentAccepted(_ notification: Notification) {
        print("\(notification)")
        activityIndicator.hide()
    }
    
    @objc func paymentLoadingAcceptPage(_ notification: Notification) {
        print("\(notification)")
        activityIndicator.hide()
    }
    
    @objc func paymentWindowCancelled(_ notification: Notification) {
        print("\(notification)")
        activityIndicator.hide()
    }
    
    @objc func paymentWindowLoaded(_ notification: Notification) {
        print("\(notification)")
        activityIndicator.hide()
        let subviewList = view.subviews
        
        guard subviewList.count > 0 else {
            print("Warning: subviewList is empty in `EpayBaseViewController` \(#function)")
            return
        }
        
        // there is ePay webView that we do not have direct access to
        // there might be a validation view on top of it
        // we need to loop through subviews  in order to get the webview
        for index in 0...(subviewList.count - 1) {
            if subviewList[index] is UIWebView {
                print("\("\(String(describing: (subviewList[index] as! UIWebView).stringByEvaluatingJavaScript(from: "document.body.innerHTML")))")")
                break
            }
        }
    }
    
    @objc func paymentWindowLoading(_ notification: Notification) {
        print("\(notification)")
    }
    
    @objc func errorOccurred(_ notification: Notification) {
        print("\(notification)")
        activityIndicator.hide()
        
        // check for not internet connection error
        let error: NSError = notification.object as! NSError
        if error.code == NetworkingConstants.noInternetCode {
            isErrorSpinnerVisible = true
        }
    }
    
    // MARK: reachability module - UIViewControllers extension override
    
    override open func updateScreenWithReachabilityStatus(isReachable: Bool) {
        
        if isReachable && isErrorSpinnerVisible {
            // reload screen only if Epay error spinner is visible
            isErrorSpinnerVisible = false
            startPayment()
        }
    }

}
