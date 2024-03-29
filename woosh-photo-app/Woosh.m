//
//  Woosh.m
//  woosh-photo-app
//
//  Created by Ben on 05/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "Woosh.h"
#import "NSData+Base64.h"

@implementation Woosh

@synthesize systemProperties;

@synthesize latitude;
@synthesize longitude;
@synthesize horizontalAccuracy;

@synthesize apnsToken;

static Woosh *instance;

static NSDateFormatter *dateTimeFormatter;

static double DEFAULT_OFFER_DURATION = 300000;      // milliseconds


+ (Woosh *) woosh {
	
	@synchronized(self) {
		if ( !instance ) {
			
			// create the singleton instance
			instance = [[Woosh alloc] init];
            
            dateTimeFormatter = [[NSDateFormatter alloc] init];
			[dateTimeFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSz"];

        }
	}
	
	return instance;
}

+ (NSString *) uuid {
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	
	NSString *uuidString = (__bridge NSString *) CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	
    // convert to lower case to adhere to the Woosh standard to UUIDs (there is no other functional reason)
	return [uuidString lowercaseString];
}

- (NSString *) dateAsDateTimeString:(NSDate *)date {
	return [dateTimeFormatter stringFromDate:date];
}

- (void) createLocalExpityNotificationForOffer:(NSString *)offerId {

    // set up a local notification to let the user know when their offer has expired
    UILocalNotification *expiredOfferNotification = [[UILocalNotification alloc] init];
    expiredOfferNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:DEFAULT_OFFER_DURATION / 1000];     // divide by 1000 to get seconds
    expiredOfferNotification.timeZone = [NSTimeZone defaultTimeZone];
    expiredOfferNotification.alertBody = [NSString stringWithFormat:@"An offer that you made has just expired."];
    expiredOfferNotification.userInfo = [NSDictionary dictionaryWithObject:offerId forKey:@"id"];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:expiredOfferNotification];
    
}

- (void) removeLocalExpityNotificationForOffer:(NSString *)offerId {

    // remove any local notifications for the expiry of this offer
    NSArray *notifications = [[UIApplication sharedApplication] scheduledLocalNotifications];

    for (int i = 0; i < [notifications count]; i++) {
        UILocalNotification* ln = [notifications objectAtIndex:i];
        
        if ( [[ln.userInfo objectForKey:@"id"] isEqualToString:offerId] ) {
            [[UIApplication sharedApplication] cancelLocalNotification:ln];
            break;
        }
    }
    
}

- (BOOL) credentialed {
    return [[[Woosh woosh] systemProperties] objectForKey:@"username"] != nil;
}

- (BOOL) ping {
    
	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *pingEndpoint = [endpoint stringByAppendingPathComponent:@"ping"];
    
    NSMutableURLRequest *pingReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:pingEndpoint]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                            timeoutInterval:5.0];
    
    NSURLResponse *pingResp;
    NSError *pingErr;
    [NSURLConnection sendSynchronousRequest:pingReq returningResponse:&pingResp error:&pingErr];

    // if the error is NIL then we successfully reached the server
    return pingErr == nil;
}

// method for saying hello to the Woosh servers
- (NSURLConnection *) sayClientHello:(id <NSURLConnectionDelegate>)delegate {
    
    NSString *versionString = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    NSString *deviceType = [UIDevice currentDevice].model;
    NSString *operatingSystem = [UIDevice currentDevice].systemVersion;
    
    NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *helloEndpoint = [endpoint stringByAppendingPathComponent:@"hello"];
    
    NSMutableURLRequest *helloReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:helloEndpoint]
                                                            cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                        timeoutInterval:60.0];
    
    [helloReq setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"v=%@&type=%@&os=%@", versionString, deviceType, operatingSystem];
    
    [helloReq setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [[NSURLConnection alloc] initWithRequest:helloReq delegate:delegate startImmediately:NO];
}

- (NSURLConnection *) submitApnsToken:(id <NSURLConnectionDelegate>)delegate {
    
    NSString *rawToken = [[[Woosh woosh] apnsToken] description];
    NSString *deviceToken = [rawToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString:@" " withString:@""];

    NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *aubmitApnsTokenEndpoint = [endpoint stringByAppendingPathComponent:@"apns"];

    NSMutableURLRequest *submitApnsTokenReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:aubmitApnsTokenEndpoint]
                                                                      cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                  timeoutInterval:60.0];
    
    [submitApnsTokenReq setHTTPMethod:@"POST"];
    NSString *postString = [NSString stringWithFormat:@"apnsToken=%@", deviceToken];

    [submitApnsTokenReq setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];

    return [[NSURLConnection alloc] initWithRequest:submitApnsTokenReq delegate:delegate startImmediately:NO];
}

// utility method for making an offer withg a single photograph
- (NSURLConnection *) createCardWithPhoto:(NSString *)name
                             photographId:(NSString *)photographId
                               photograph:(NSData *)photograph
                                 delegate:(id <NSURLConnectionDelegate>)delegate {
    
    // the first thing that we do is create a new Woosh card
	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *newCardEndpoint = [endpoint stringByAppendingPathComponent:@"card"];
    
    NSMutableURLRequest *newCardReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:newCardEndpoint]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:60.0];

    // construct the dictionary to express the new Woosh card - this will be converted to a JSON payload for transport
    
    // note that we do something that looks a little unusual here in that we supply the UUID for the binary object
    // normally we would defer this function to the server (and this is in fact the case for every other object type)
    // but because we need to cache images locally by ID, we must generate the ID here and then pass it to the server
    // (which will then use it as the identifer for the binary, thereby matching with the ID used by the client)
    
    NSDictionary *cardDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"default", @"name",
                                        @"BINARY", @"type",
                                        photographId, @"binaryId",
                                        [photograph base64EncodedString], @"value",
                                        nil];
        
    NSDictionary *cardDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSArray arrayWithObject:cardDataDictionary], @"data",
                                    nil];
    
    // convert the dictionary tp JSON
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:cardDictionary options:NSJSONWritingPrettyPrinted error:nil];
    NSString *payload = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // encode the JSON for transport
    NSData *postData = [payload dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];

    [newCardReq setHTTPMethod:@"POST"];
    [newCardReq setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [newCardReq setHTTPBody:postData];

    return [[NSURLConnection alloc] initWithRequest:newCardReq delegate:delegate startImmediately:YES];
}

- (NSURLConnection *) makeOffer:(NSString *)cardId latitude:(double)latitude longitude:(double)longitude delegate:(id<NSURLConnectionDelegate>)delegate {

    // the first thing that we do is create a new Woosh card
	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *newOfferEndpoint = [endpoint stringByAppendingPathComponent:@"offer"];
    
    NSMutableURLRequest *newOfferReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:newOfferEndpoint]
                                                               cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                           timeoutInterval:60.0];
    
    // construct the dictionary to express the new Woosh card - this will be converted to a JSON payload for transport
    NSDictionary *offerDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                     cardId, @"cardId",
                                     [NSNumber numberWithInt:DEFAULT_OFFER_DURATION], @"duration",          // duration to the server needs to be in milliseconds
                                     [NSNumber numberWithDouble:[[Woosh woosh] latitude]], @"latitude",
                                     [NSNumber numberWithDouble:[[Woosh woosh] longitude]], @"longitude",
                                     @"true", @"autoAccept",
                                     nil];

    // convert the dictionary tp JSON
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:offerDictionary options:NSJSONWritingPrettyPrinted error:nil];
    NSString *payload = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    // encode the JSON for transport
    NSData *postData = [payload dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    [newOfferReq setHTTPMethod:@"POST"];
    [newOfferReq setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [newOfferReq setHTTPBody:postData];
    
    return [[NSURLConnection alloc] initWithRequest:newOfferReq delegate:delegate startImmediately:YES];
}

- (NSURLConnection *) expireOffer:(NSString *)offerId delegate:(id <NSURLConnectionDelegate>)delegate {
 
    // construct the request URL
	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *scanEndpoint = [endpoint stringByAppendingPathComponent:@"offer/expire"];
    NSString *fullUrl = [scanEndpoint stringByAppendingFormat:@"/%@", offerId];
    
    // construct the HTTP request object
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullUrl]
                                                       cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                   timeoutInterval:60.0];
    [req setHTTPMethod:@"POST"];
    
    // kick off the request
    return [[NSURLConnection alloc] initWithRequest:req delegate:delegate startImmediately:YES];

}

- (NSURLConnection *) scan:(id <NSURLConnectionDelegate>)delegate {

    // construct the request URL
	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *scanEndpoint = [endpoint stringByAppendingPathComponent:@"offers"];    
    NSString *fullUrl = [scanEndpoint stringByAppendingFormat:@"?latitude=%.6f&longitude=%.6f&accuracy=%.0f", latitude, longitude, horizontalAccuracy];

    // construct the HTTP request object
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullUrl]
                                                       cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                        timeoutInterval:60.0];
    [req setHTTPMethod:@"GET"];

    // kick off the request
    return [[NSURLConnection alloc] initWithRequest:req delegate:delegate startImmediately:YES];    

}

- (NSURLConnection *) getCards:(id <NSURLConnectionDelegate>)delegate {

    // construct the request URL
	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *cardsEndpoint = [endpoint stringByAppendingPathComponent:@"cards"];
    
    // construct the HTTP request object
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:cardsEndpoint]
                                                       cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                   timeoutInterval:60.0];
    [req setHTTPMethod:@"GET"];
    
    // kick off the request
    return [[NSURLConnection alloc] initWithRequest:req delegate:delegate startImmediately:YES];

}

- (NSURLConnection *) deleteCard:(NSString *)cardId delegate:(id <NSURLConnectionDelegate>)delegate {

    // construct the request URL
	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *scanEndpoint = [endpoint stringByAppendingPathComponent:@"card"];
    NSString *fullUrl = [scanEndpoint stringByAppendingFormat:@"/%@", cardId];
    
    // construct the HTTP request object
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullUrl]
                                                       cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                   timeoutInterval:60.0];
    [req setHTTPMethod:@"DELETE"];
    
    // kick off the request
    return [[NSURLConnection alloc] initWithRequest:req delegate:delegate startImmediately:YES];

}


@end
