//
//  DIBSApiClient.swift
//  MobileTicketCore
//
//  Created by Linar Chabibulin on 28/08/2017.
//  Copyright © 2017 Kofoed & Co. All rights reserved.
//

import Foundation

class DIBSApiClient {
    
    // MARK: - Declaration
    
    // used for overriding success response parsing
    /// - Parameter confirmParsingFunction: closure for handeling successful 'getDIBSOrderId()' method's result parsing, for convenience has default implementation already assigned
    static var getDIBSOrderIdSuccessParsingFunction: ((CoreApiCallResponseEntity, @escaping (_ orderId: String) -> Void, @escaping ApiErrorCallback) -> Void) = defautlGetDIBSOrderIdSuccessParsingFunction
    
    // MARK: - Mehtods
    
    // MARK: - Internal
    /**
     Function used create a temporary orderId used in final transaction
     - Parameter urlString: urlString to call when
     - Parameter successCallback: success closure that returns successfully created temporary dibsOrderId
     - Parameter errorCallback: ApiErrorCallback type error handler
     */
    func getDIBSOrderId(urlString: String, successCallback: @escaping (_ orderId: String) -> Void, errorCallback: @escaping ApiErrorCallback) {
        
        let apiCallConfiguration = ApiCallConfiguration(method: "GET", encoding: .urlEncoding)
        
        NetworkingModule().performApiCall(urlString: urlString,
                                          configuration: apiCallConfiguration,
                                          successCallback: { (response) in
                                            DIBSApiClient.getDIBSOrderIdSuccessParsingFunction(response, successCallback, errorCallback)
        },
                                          errorCallback: { (error) in
                                            errorCallback(error)
        })
    }
    
    // MARK: - Private
    
    private static func defautlGetDIBSOrderIdSuccessParsingFunction(apiSuccessResponse: CoreApiCallResponseEntity,
                                                                    successCallback: @escaping  (_ orderId: String) -> Void,
                                                                    errorCallback: @escaping ApiErrorCallback) {
        
        if let orderId: String = apiSuccessResponse.result.value as? String {
            successCallback(orderId)
        } else {
            errorCallback(apiSuccessResponse.error)
        }
    }
}
