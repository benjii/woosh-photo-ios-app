//
//  Woosh.h
//  woosh-photo-app
//
//  Created by Ben on 05/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Woosh : NSObject

@property NSMutableDictionary *systemProperties;

// the singleton Woosh services instance
+ (Woosh *) woosh;

// the user's most recent location
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double horizontalAccuracy;

@property (nonatomic) NSData *apnsToken;

- (NSString *) dateAsDateTimeString:(NSDate *)date;

- (void) createLocalExpityNotificationForOffer:(NSString *)offerId;
- (void) removeLocalExpityNotificationForOffer:(NSString *)offerId;

+ (NSString *) uuid;

// perform a Woosh server ping
- (BOOL) ping;
- (BOOL) credentialed;

// method for a client to say hello to the server and provide device data
- (NSURLConnection *) sayClientHello:(id <NSURLConnectionDelegate>)delegate;
- (NSURLConnection *) submitApnsToken:(id <NSURLConnectionDelegate>)delegate;

// utility method for making an offer withg a single photograph
- (NSURLConnection *) createCardWithPhoto:(NSString *)name
                             photographId:(NSString *)photographId
                               photograph:(NSData *)photograph
                                 delegate:(id <NSURLConnectionDelegate>)delegate;

- (NSURLConnection *) makeOffer:(NSString *)cardId latitude:(double)latitude longitude:(double)longitude delegate:(id <NSURLConnectionDelegate>)delegate;
- (NSURLConnection *) expireOffer:(NSString *)offerId delegate:(id <NSURLConnectionDelegate>)delegate;

// perform a scan (an 'up woosh')
- (NSURLConnection *) scan:(id <NSURLConnectionDelegate>)delegate;

// gets the full list of cards owned by the currently authenticated user
- (NSURLConnection *) getCards:(id <NSURLConnectionDelegate>)delegate;

// removes a card from the Woosh servers
- (NSURLConnection *) deleteCard:(NSString *)cardId delegate:(id <NSURLConnectionDelegate>)delegate;

@end
