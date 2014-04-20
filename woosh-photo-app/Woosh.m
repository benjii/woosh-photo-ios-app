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
@synthesize networkIsReachable;

static Woosh *instance;

static NSDateFormatter *dateTimeFormatter;

//static int RANDOM_CARD_NAME_LENGTH = 8;
static int DEFAULT_OFFER_DURATION = 300000;      // milliseconds


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

//- (NSString *) randomAlphaString {
//    char data[RANDOM_CARD_NAME_LENGTH];
//    for (int x=0; x < RANDOM_CARD_NAME_LENGTH; data[x++] = (char)('A' + (arc4random_uniform(26))));
//    return [[NSString alloc] initWithBytes:data length:RANDOM_CARD_NAME_LENGTH encoding:NSUTF8StringEncoding];    
//}

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
//                                    [self randomAlphaString], @"name",
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
                                     [NSNumber numberWithInt:DEFAULT_OFFER_DURATION], @"duration",
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
    NSString *fullUrl = [scanEndpoint stringByAppendingFormat:@"?latitude=%.6f&longitude=%.6f", latitude, longitude];

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
