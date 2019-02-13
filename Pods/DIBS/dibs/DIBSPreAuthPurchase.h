/*!
 @header
 
 Payment AND pre-authorization of credit card for later ticket pay.
 
 @copyright Copyright 2011 DIBS. All rights reserved.
 */
#import "DIBSPaymentBase.h"

/*!
 @abstract Represents the form parameters needed for the "pre-authorize and credit card payment" flow.
 
 @discussion Use an instance of this class as the return value from 
 @link //apple_ref/occ/intfm/DIBSPaymentSource/getPaymentData getPaymentData @/link
 */
@interface DIBSPreAuthPurchase : DIBSPaymentBase {
@private
	NSUInteger _amount;
	NSString *_orderID;
	NSString *_payTypes;
    
    BOOL _calcfee;
    
}

/*! the amount of money to be paid */
@property(nonatomic, readonly) NSUInteger amount;

/*! a merchant-specific ID, identifying the order */
@property(nonatomic, readonly) NSString *orderID;

/*! which types of payment that are allowed to be used */
@property(nonatomic, readonly) NSString *payTypes;

/*! Set to YES, if you want payment window to calculate fee in the payment window */
@property(nonatomic, assign) BOOL calcfee;

/*!
 @abstract Construct payment window data for a "credit card payment" flow.
 
 @param merchantID    the id of the merchant
 @param orderID       a merchant-specific ID, identifying the order
 @param amount        the amount of money to be paid
 @param currencyCode  the currency to show in payment window
 @param payTypes      which types of payment that are allowed to be used

 
 @see //apple_ref/occ/clm/DIBSPaymentBase/getPaymentTypes getPaymentTypes
 */
- (id)initWithMerchantID:(NSString *)merchantID orderID:(NSString *)orderID amount:(NSUInteger)amount currencyCode:(NSString *)currencyCode payTypes:(NSArray *)payTypes;
@end
