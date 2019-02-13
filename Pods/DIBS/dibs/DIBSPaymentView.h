/*!
 @header
 The DIBS payment window provides the means for merchants or developers to add online payment functionality to their app.
 @copyright Copyright 2011 DIBS. All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "DIBSPaymentBase.h"

/*!
 @abstract Error codes in @link //apple_ref/occ/intfm/DIBSPaymentResultDelegate/errorDidOccur errorDidOccur@/link
           less than or equal to this constant, should be considered critical and payment processing must be stopped.
 */
FOUNDATION_EXPORT NSInteger const DIBSPaymentLibraryCriticalErrorMax;

/*! @abstract Key into errorInfo to get the error number */
FOUNDATION_EXPORT NSString *const DIBSPaymentLibraryErrorNumberKey;

/*! @abstract Key into errorInfo to get the error message */
FOUNDATION_EXPORT NSString *const DIBSPaymentLibraryErrorMessageKey;

/*!
 @abstract Implementations of this acts as the source for actual payment data, that the payment window needs.
 
 @namespace DIBS
 */
@protocol DIBSPaymentSource

/*!
 @abstract Construct the actual payment data, that the payment window needs to present a payment form.
 
 @discussion Apps must implement this to produce the proper payment data for the payment window to present. 
 What constitutes "proper payment data" differs from the "payment flow" the app wants to present. Generally, the
 app is expected to use one of the DIBSPaymentBase sub-classes, as the result of the getPaymentData call.
 */
- (DIBSPaymentBase *)getPaymentData;

@end

/*!
 @abstract Delegate to @link //apple_ref/occ/cl/DIBSPaymentView DIBSPaymentView@/link 
 */
@protocol DIBSPaymentResultDelegate

/*!
 Called when the payment window has been fully loaded and is ready for user input.
 */
- (void)didLoadPaymentWindow;

/*!
 Called when the payment window fails to load.
 */
- (void)failedLoadingPaymentWindow;

/*!
 @link //apple_ref/occ/cl/DIBSPaymentView DIBSPaymentView@/link delegates to this method when a cancel URL has been
 loaded as a result of cancel processing. 
 */
- (void)didLoadCancelURL;

/*!
 Callback from @link //apple_ref/occ/cl/DIBSPaymentView DIBSPaymentView@/link, after a call to 
 @link //apple_ref/occ/instm/DIBSPaymentView/cancelPayment cancelPayment@/link, when the payment window 
 is done with its cancel processing.
 
 If a cancel URL is loaded as part of cancel processing, both 
 @link //apple_ref/occ/intfm/DIBSPaymentResultDelegate/didLoadCancelURL didLoadCancelURL@/link 
 <em>and</em> this method is called.
 */
- (void)paymentCancelled:(NSDictionary *)params;

/*!
 @link //apple_ref/occ/cl/DIBSPaymentView DIBSPaymentView@/link delegates to this method when a payment
 has been accepted.
 */
- (void)paymentAccepted:(NSDictionary *)params;

/*!
 @link //apple_ref/occ/cl/DIBSPaymentView DIBSPaymentView@/link delegates to this method when some error occurred
 in payment processing. You should use this to taker proper action in showing or logging errors and maybe closing
 the payment window.

 Use the constants "DIBSPaymentLibraryErrorNumberKey" and "DIBSPaymentLibraryErrorMessageKey"
 to obtain error number and message.

 IMPORTANT NOTE: Error codes &lt;= "DIBSPaymentLibraryCriticalErrorMax" indicate critical errors.
                 Your app SHOULD close the payment window in these cases and ensure that the payment does not continue.
 */
- (void)errorDidOccur:(NSDictionary *)params;

@end

/*!
 @abstract View to present payment window in.
 
 @discussion To present a payment window, you instantiate this class, set its source and adds it to your view where you want it.
 To be able to follow the flow of an ongoing payment, you implement @link //apple_ref/occ/intf/DIBSPaymentResultDelegate DIBSPaymentResultDelegate@/link
 and set it on the view.
 */
@interface DIBSPaymentView : UIView {
@private
	id<DIBSPaymentResultDelegate> _delegate;
	id<DIBSPaymentSource> _paymentSource;
	DIBSPaymentBase *_paymentData;
	UIWebView *_paymentView;
    BOOL _paymentWindowLoaded;
}

/*! The payment window delegates to this to tell about the flow of the payment. */
@property(nonatomic, assign) IBOutlet id<DIBSPaymentResultDelegate> delegate;

/*! The payment window use this to get the actual data for the payment form */
@property(nonatomic, assign) IBOutlet id<DIBSPaymentSource> paymentSource;

/*!
 Initiates a cancellation of an ongoing payment.
 
 If the payment window has been fully loaded (a call to 
 @link //apple_ref/occ/intfm/DIBSPaymentResultDelegate/didLoadPaymentWindow didLoadPaymentWindow@/link has been made)
 and a cancel URL has been set, the cancel URL will be loaded, and the delegate is notified via 
 @link //apple_ref/occ/intfm/DIBSPaymentResultDelegate/didLoadCancelURL didLoadCancelURL@/link when done loading cancel URL.
 If no cancel URL has been set, or after cancel URL has been loaded, delegate is notified about the cancel being completed,
 via a call to @link //apple_ref/occ/intfm/DIBSPaymentResultDelegate/paymentCancelled paymentCancelled@/link. 
 */
- (IBAction)cancelPayment;

- (id)initWithFrame:(CGRect)frame source:(id<DIBSPaymentSource>)paymentSource;

@end
