//
//  EpayApiClient.swift
//  MobileTicketCore
//
//  Created by Martynas Stanaitis on 08/06/2017.
//  Copyright © 2017 Kofoed. All rights reserved.
//

import Foundation

class EpayApiClient {
    
    // MARK: - Declarations
    
    // used for overriding success response parsing
    /// - Parameter confirmParsingFunction: closure for handeling succesful 'getEpayOrderId()' method's result parsing, for conveniance has default implementation already assigned
    static var getEpayOrderIdSuccessParsingFunction: ((CoreApiCallResponseEntity, @escaping (_ ePayOrderId: String) -> Void, @escaping ApiErrorCallback) -> Void) = defaultGetEpayOrderIdSuccessParsingFunction
    
    // MARK: - Mehtods
    
    // MARK: - Internal
    /**
     Function used create a temporary orderId used in final transaction
     - Parameter urlString: urlString to call when
     - Parameter orderId: string with original tickets OrderId for witch new temporary ePayOrderId will be created
     - Parameter successCallback: success closure which returns successfully created temporary ePayOrderId
     - Parameter errorCallback: ApiErrorCallback type error closure
     - Parameter failedToStartCallback: block perform if api call fails to start. If Api status is unavailable. Optional
     */
    static func getEpayOrderId(urlString: String,
                               orderId: String,
                               successCallback: @escaping (_ ePayOrderId: String) -> Void,
                               errorCallback: @escaping ApiErrorCallback,
                               failedToStartCallback: (() -> Void)? = nil) {
        
        let parameters = ["orderId" : orderId]
        let apiCallConfiguration = ApiCallConfiguration()
        
        NetworkingModule().performApiCall(urlString: urlString,
                                          parameters: parameters,
                                          configuration: apiCallConfiguration,
                                          token: CoreRepository.accessToken,
                                          successCallback: { (response) in
                                            getEpayOrderIdSuccessParsingFunction(response, successCallback, errorCallback)
                                            
        },
                                          errorCallback: { (error) in
                                            errorCallback(error)
        },
                                          failedToStartCallback: failedToStartCallback)
    }
    
    // MARK: - Private

    private static func defaultGetEpayOrderIdSuccessParsingFunction(apiSuccessResponse: CoreApiCallResponseEntity,
                                                     successCallback: @escaping  (_ ePayOrderId: String) -> Void,
                                                     errorCallback: @escaping ApiErrorCallback) {
        
        if let responseDictionary = apiSuccessResponse.result.value as? [String : Any] {
            if let paymentId = responseDictionary["epayPaymentId"] as? Int {
                successCallback("\(paymentId)")
                return
            }
        }
        
        errorCallback(apiSuccessResponse.error)
    }
}
