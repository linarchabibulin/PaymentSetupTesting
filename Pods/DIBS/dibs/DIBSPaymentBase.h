/*!
 @header
 
 @abstract Creation of payment window data.
 
 @discussion When the payment window loads, it needs data from the app, to know what to present.
 To help construct this data, the DIBS mobile payment library provides a class hierarchy, with 
 @link //apple_ref/occ/cl/DIBSPaymentBase DIBSPaymentBase@/link as the base class.
 
 Normally, the app will not instantiate or inherit the base, but instead use the concrete sub-classes, which
 fit specific, supported, payment flows.
 
 <dl>
   <dt>Normal, "pay with credit card", flow</dt>
   <dd>@link //apple_ref/occ/cl/DIBSPurchase DIBSPurchase@/link</dd>

   <dt>Pre-authorize a credit card for ticket payment</dt>
   <dd>@link //apple_ref/occ/cl/DIBSPreAuthorization DIBSPreAuthorization@/link</dd>

   <dt>Purchase made with ticket from a pre-authorized credit card</dt>
   <dd>@link //apple_ref/occ/cl/DIBSTicketPurchase DIBSTicketPurchase@/link</dd>
 </dl>
 
 @copyright Copyright 2011 DIBS. All rights reserved. 
 */

#import <UIKit/UIKit.h>

//#define DIBS_PAYMENT_LIBRARY_VERSION  @"1.0.0-SNAPSHOT"
#define DIBS_PAYMENT_LIBRARY_VERSION  @"1.2.3"

/*!
 Defines the possible layouts of the payment window.
 */
typedef enum {
    Theme_Default,
	Theme_iPhoneDIBS,
	Theme_iPhoneNative,
	Theme_AndroidDIBS,
	Theme_AndroidNative,
	Theme_Custom,
} DIBSTheme;

/*!
 @abstract Base class for generating payment window POST data.
 
 @discussion You should <em>not</em> instantiate this class directly in your app. Instead, use the concrete subclass 
 that conforms to the payment flow you need.
 */
@interface DIBSPaymentBase : NSObject {
@private
	NSString *_merchantID;
	NSString *_currencyCode;

	DIBSTheme _theme;
    NSString *_customThemeCSS;
	NSUInteger _timeout;
	NSString *_language;
	NSString *_callbackURL;
	NSString *_cancelURL;
	BOOL _test;
	NSString *_calculatedMAC;
    
    NSDictionary *_customOptions;
}

/*! id of the merchant */
@property(nonatomic, readonly) NSString *merchantID;

/*! currency to show in payment window */
@property(nonatomic, readonly) NSString *currencyCode;

/*! theme to control presentation of payment window */
@property(nonatomic, assign) DIBSTheme theme;

/*! If "theme" is set to custom, this property is used to determine custom theme values.
 *
 * This needs to be JSON formatted.
 * example: {"appBgColor":"#BABA21","paybuttonBgColor":"#000000","paybuttonFontColor":"#FFFFFF"}
 */
@property(nonatomic, retain) NSString *customThemeCSS;

/*! timeout (in seconds), before payment window "times out" and shows a message about it */
@property(nonatomic, assign) NSUInteger timeout;

/*! language to present payment window in */
@property(nonatomic, retain) NSString *language;

/*! server-to-server callback URL to be called, when payment is processed */
@property(nonatomic, retain) NSString *callbackURL;

/*!
 URL to be loaded by payment window if payment was cancelled.
 
 It is optional to give a cancelURL, but if it has been set, the payment window will try to load it, in the case
 where a payment is cancelled. In the case of cancelled payment, if a cancel URL has been set, <em>both</em>
 @link //apple_ref/occ/intfm/DIBSPaymentResultDelegate/didLoadCancelURL didLoadCancelURL@/link <em>and</em>
 @link //apple_ref/occ/intfm/DIBSPaymentResultDelegate/paymentCancelled paymentCancelled@/link are called. 
 */
@property(nonatomic, retain) NSString *cancelURL;

/*! Set to YES for test transactions. */
@property(nonatomic, assign) BOOL test;

/*! A, pre-calculated, MAC value. See DIBS library documentation for discussion of MAC support. */
@property(nonatomic, retain) NSString *calculatedMAC;

/*! Can be used to transfer app custom options to payment window */
@property(nonatomic, retain) NSDictionary *customOptions;

/*!
 @return the allowed types of payment.
 */
+ (NSArray *)getPaymentTypes;

+ (NSArray *)getDefaultLanguages;

// ----------- Internal, API private methods -------------

// @internal
- (id)initWithMerchantID:(NSString *)merchantID currencyCode:(NSString *)currencyCode;

// Generates the post form data specific to a flow.
// Base implementation raises an exception, as sub-classes are supposed to override and provide their own implementation.
// @internal
- (NSDictionary *)generateFlowSpecificPostData;

// Generates the post form data, as the payment window expects it to
// @internal
- (NSString *)generatePostData;

@end
