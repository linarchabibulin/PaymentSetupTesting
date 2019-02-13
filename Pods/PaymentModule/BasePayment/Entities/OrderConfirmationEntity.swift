//
//  OrderConfirmModel.swift
//
//  Copyright © 2017 Kofoed & Co. All rights reserved.
//

/// Entity that is used as a prototype for json in PaymentApiClient.confirm() function.
/// `TranactionId` property is not needed for MobielPay payment confirmations. ePay and DIBS requires it.

class OrderConfirmationEntity {
    
    // MARK: - Declarations
    
    // MARK: - Public
    var transactionId = ""
    var orderId = ""
    var addToFavorites = false
    
    // MARK: - Methods
    
    // MARK: - Helpers
    
    func toDictionary() -> [String : Any] {
        
        return ["transactionId" : transactionId,
                "orderId" : orderId,
                "addToFavorites" : addToFavorites]
    }
}
