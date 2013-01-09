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

static Woosh *instance;

static int RANDOM_CARD_NAME_LENGTH = 8;
static int DEFAULT_OFFER_DURATION = 300000;      // milliseconds


+ (Woosh *) woosh {
	
	@synchronized(self) {
		if ( !instance ) {
			
			// create the singleton instance
			instance = [[Woosh alloc] init];
            
        }
	}
	
	return instance;
}

- (NSString *) randomAlphaString {
    char data[RANDOM_CARD_NAME_LENGTH];
    for (int x=0; x < RANDOM_CARD_NAME_LENGTH; data[x++] = (char)('A' + (arc4random_uniform(26))));
    return [[NSString alloc] initWithBytes:data length:RANDOM_CARD_NAME_LENGTH encoding:NSUTF8StringEncoding];    
}

+ (NSString *) uuid {
	CFUUIDRef uuidObj = CFUUIDCreate(nil);
	
	NSString *uuidString = (__bridge NSString *) CFUUIDCreateString(nil, uuidObj);
	CFRelease(uuidObj);
	
	return uuidString;
}

// utility method for making an offer withg a single photograph
- (NSURLConnection *) createCardWithPhoto:(NSString *)name photograph:(NSData *)photograph delegate:(id <NSURLConnectionDelegate>)delegate {
    
    // the first thing that we do is create a new Woosh card
	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *newCardEndpoint = [endpoint stringByAppendingPathComponent:@"card"];
    
    NSMutableURLRequest *newCardReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:newCardEndpoint]
                                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                          timeoutInterval:60.0];

    // construct the dictionary to express the new Woosh card - this will be converted to a JSON payload for transport
    NSDictionary *cardDataDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                        @"default", @"name",
                                        @"BINARY", @"type",
                                        [photograph base64EncodedString], @"value",
                                        nil];
        
    NSDictionary *cardDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [self randomAlphaString], @"name",
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

@end
