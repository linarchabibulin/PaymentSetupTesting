//
//  EpayEditViewController.swift
//  MobileTicketCore
//
//  Created by Martynas Stanaitis on 05/06/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

import UIKit

/**
 EpayEditViewController is ment for editing epay payment data
 */

public class EpayEditViewController: EpayBaseViewController {
    
    // MARK: - Declarations
    
    // MARK: - Private
    private var editSuccessHandler: PaymentEditSuccessHandler?
    private var editFailHandler: PaymentEditFailHandler?
    
    // MARK: - Methods
    
    // MARK: - Initalization
    /**
     Default initiator
     - Parameter epayConfiguration: see 'EpayConfigurationProtocol' for detailed description.
     - Parameter editSuccessHandler: closure executed once edit transaction succeeds
     - Parameter editFailHandler: closure executed once edit transaction fails
     */
    convenience init(configuration:EpayConfigurationProtocol,
                     editSuccessHandler: PaymentEditSuccessHandler?,
                     editFailHandler: PaymentEditFailHandler?) {
        self.init(configuration: configuration)
        
        self.editSuccessHandler = editSuccessHandler
        self.editFailHandler = editFailHandler
    }
    
    // MARK: - View management
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        addBackBarButton()
        
        if epayConfiguration.purchaseCardSubscriptionId == nil {
            enableSubscriptionCreationMode()
        } else {
            enableSubscriptionEditMode(subscriptionId: epayConfiguration.purchaseCardSubscriptionId!)
        }
        
        view.backgroundColor = .white
        activityIndicator.show(view)
    }
    
    // MARK: - Overrides
    
    override func paymentAccepted(_ notification: Notification) {
        super.paymentAccepted(notification)
        
        let ePayParameterList: [ePayParameter] = (notification.object as? [ePayParameter])!
        
        // if subscription was successful - subscriptionId is returned
        var subscriptionId: Int64?
        var cardNo = ""
        for ePayParameter in ePayParameterList {
            if ePayParameter.key == "cardno" {
                cardNo = ePayParameter.value
            }
            if ePayParameter.key == "subscriptionid" {
              subscriptionId = Int64(ePayParameter.value)
            }
        }
        
        if let subscriptionId = subscriptionId {
            editSuccessHandler?(subscriptionId, cardNo, self)
        } else {
            editFailHandler?(self)
        }
    }
    
    @objc override func paymentWindowCancelled(_ notification: Notification) {
        super.paymentWindowCancelled(notification)
        _ = self.navigationController?.popViewController(animated: true)
    }
}
