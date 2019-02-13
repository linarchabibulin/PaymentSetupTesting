/*!
 @header
 The DIBS payment server service is used by the DIBS payment window to acquire the address of a payment server, which is
 currently online. The user of the library is responsible for invoking the updateActivePaymentServer method, which
 determines which server to use. If this has not been done, the payment window will attempt to use the default server.
 The intention is that the client should invoke updateActivePaymentServer when the app starts up, and possibly when
 network connection is restored (eg. when using Apple's Reachability class).
 @copyright Copyright 2011 DIBS. All rights reserved.
 */

#import <Foundation/Foundation.h>

#define DIBS_PAYMENT_SERVER_UPDATED @"DIBS_ServerUpdatedNotification"
#define DIBS_PAYMENT_SERVER_UPDATE_FAILED @"DIBS_ServerUpdateFailedNotification"

/*!
 @abstract Service that provides address of payment server to the payment window.
 
 @discussion This class is not supposed to be instantiated.
 */
@interface DIBSPaymentServerService : NSObject {

}

/*!
 @abstract Explicitly set the server URLs of the payment library.

 @discussion This method allows for control on which URLs the payment window will use and which servers to use
             for payment operations. You will need to contact DIBS to get the possible values that suits your payment window.

 @param defaultServerBaseURL    the default payment base URL to use, when ping hasn't been run or no pinged server answered
 @param paymentServersURLPath   the last part (path) of the URL, that identifies which payment window type to show
 @param failoverPaymentServers  any other payment servers you want to be able to fallback to, if ping determines some are unreachable (array of NSURL instances)
 */
+ (void)setDefaultPaymentServer:(NSURL *)defaultServerBaseURL withURLPath:(NSString *)paymentServersURLPath andFailoverPaymentServers:(NSArray *)failoverPaymentServers;



/*!
 @abstract Set the ping timeout - standard: 2.
 
 @discussion this method will set the timeout on the  
 @param timeout    the time the lib will wait before timeout

 */
+ (void)setTimeout:(NSUInteger) timeout;


/*!
 @internal
 @return the URL of the last payment server, that was pinged successfully including URL path of payment window.
 If no server has been pinged, the default server is returned.
 */
+ (NSURL *)activePaymentURL;

/*!
 Initiates an asynchronous task which determines which payment server should be used by future instances of the payment window.
 When a server has been pinged successfully, a notification named "ServerUpdatedNotification" will be posted. If no working 
 servers could be found a notification named "ServerUpdateFailedNotification" will be posted. 
 */
+ (void)updateActivePaymentServer;

@end
