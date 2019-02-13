//
//  PaymentApiClient.swift
//  Mobilbillet
//
//  Copyright © 2017 Kofoed & Co. All rights reserved.
//

import Foundation

/// Api client for 'PaymentModule'
class  PaymentApiClient {
    
    // MARK: - Declarations -
    
    // MARK: - Methods
    
    // MARK: - Payment confirmation API calls
    /**
     Function used to confirm order has been successfully payed by 3rd party service (epay, DIBS, MobielPay)
     - Parameter urlString: urlString to call when
     - Parameter input: OrderConfirmationEntity contiantig all the data needed for purchase vertification
     - Parameter successCallback: success closure that returns successfully confirmed ticket Id
     - Parameter errorCallback: ApiErrorCallback type error handler
     - Parameter failedToStartCallback: block perform if api call fails to start. If Api status is unavailable. Optional
     */
    static func confirm(urlString: String,
                        input: OrderConfirmationEntity,
                        successCallback: @escaping (_ ticketId: Int) -> Void,
                        errorCallback: @escaping ApiErrorCallback,
                        failedToStartCallback: (() -> Void)? = nil) {
        
        let parameters = input.toDictionary()
        
        let apiCallConfiguration = ApiCallConfiguration()
        
        NetworkingModule().performApiCall(urlString: urlString,
                                          parameters: parameters,
                                          configuration: apiCallConfiguration,
                                          token: CoreRepository.accessToken,
                                          successCallback: { (response) in
                                            confirmParsingFunction(response, successCallback, errorCallback)
        },
                                          errorCallback: { (error) in
                                            print("ePayConfirm failed")
                                            errorCallback(error)
        },
                                          failedToStartCallback: failedToStartCallback)
    }
    
    // MARK: - Private - default parsing functions
    /**
     - Parameter apiSuccessResponse: success response returned by api call
     - Parameter successCallback: callback that will be performed if parsing succeeds
     - Parameter errorCallback: callback that will be performed if parsing fails
     */
    private static func defautlConfirmParsingFunction(apiSuccessResponse: CoreApiCallResponseEntity,
                                                      successCallback: @escaping  (_ ticketId: Int) -> Void,
                                                      errorCallback: @escaping ApiErrorCallback) {
        
        if let responseDictionary = apiSuccessResponse.result.value as? [String : Any] {
            successCallback((responseDictionary["productId"] as? Int) ?? 0)
        } else {
            errorCallback(apiSuccessResponse.error)
        }
    }
}
