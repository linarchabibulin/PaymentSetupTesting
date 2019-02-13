//
//  EditPaymentInfoViewController.swift
//  Mobilbillet
//
//  Created by Linar Chabibulin on 11/05/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

class EditPaymentInfoViewController: PaymentBaseViewController {
    
    // MARK: - Declarations -
    
    var editSuccessHandler: PaymentEditSuccessHandler?
    var editFailHandler: PaymentEditFailHandler?
    
    // MARK: - Methods -
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        addBackBarButton(title: title ?? "",
                         font: configuration.appearenceConfiguration.navigationBarFont,
                         itemColor: configuration.appearenceConfiguration.navigationBarItemColor)
    }
    
    // MARK: - DIBSPaymentResultDelegate
    
    // DIBSPaymentView delegates to this method when a payment has been accepted.
    override func paymentAccepted(_ params: [AnyHashable: Any]) {
        super.paymentAccepted(params)
        
        if let subscritpionIdString = params["transact"] as? String,
            let subscritpionId = Int64(subscritpionIdString) {
            // cardNo can be ignored - not used
            editSuccessHandler?(subscritpionId, "", self)
            return
        }
        
        editFailHandler?(self)
    }
}
