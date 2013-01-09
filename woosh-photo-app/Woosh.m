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
static int DEFAULT_OFFER_DURATION = 60000;      // milliseconds


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

//- (BOOL) startAsyncHttpRequest:(NSURLRequest *)request {
//    self.connection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
//    
//    if (self.connection != nil) {
//        self.receivedData = [NSMutableData data];
//    }
//    
//    [self.connection start];
//    
//    return YES;
//}

// utility method for making an offer withg a single photograph
- (NSString *) createCardWithPhoto:(NSString *)name photograph:(NSData *)photograph {
    
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
    
//    NSLog(@"%@", payload);
    
    // encode the JSON for transport
    NSData *postData = [payload dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];

    [newCardReq setHTTPMethod:@"POST"];
    [newCardReq setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [newCardReq setHTTPBody:postData];

//    NSString *request = [[NSString alloc] initWithData:postData encoding:NSASCIIStringEncoding];
//    NSLog(@"%@", request);

    // send the request to create the Woosh card and wait for the response
    NSURLResponse *newCardResp = [[NSURLResponse alloc] init];
    NSError *newCardError = [[NSError alloc] init];
    NSData *newCardResponseData = [NSURLConnection sendSynchronousRequest:newCardReq
                                                        returningResponse:&newCardResp
                                                                    error:&newCardError];

    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:newCardResponseData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    
    // return the ID of the new card to the caller
    return [json objectForKey:@"id"];
}

- (NSString*) makeOffer:(NSString *)cardId latitude:(double)latitude longitude:(double)longitude {

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
        
    // send the request to create the Woosh card and wait for the response
    NSURLResponse *newOfferResp = [[NSURLResponse alloc] init];
    NSError *newOfferError = [[NSError alloc] init];
    NSData *newOfferResponseData = [NSURLConnection sendSynchronousRequest:newOfferReq
                                                         returningResponse:&newOfferResp
                                                                     error:&newOfferError];
    
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:newOfferResponseData
                                                         options:NSJSONReadingMutableContainers
                                                           error:&error];
    
    // return the ID of the new card to the caller
    return [json objectForKey:@"id"];

}

- (NSArray *) scan {

    // construct the request URL
	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *scanEndpoint = [endpoint stringByAppendingPathComponent:@"offers"];    
    NSString *fullUrl = [scanEndpoint stringByAppendingFormat:@"?latitude=%.6f&longitude=%.6f", latitude, longitude];

    // construct the HTTP request object
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullUrl]
                                                       cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                        timeoutInterval:60.0];
    [req setHTTPMethod:@"GET"];

    // send the request to create the Woosh card and wait for the response
    NSURLResponse *resp = [[NSURLResponse alloc] init];
    NSError *respErr = [[NSError alloc] init];
    NSData *respData = [NSURLConnection sendSynchronousRequest:req
                                                         returningResponse:&resp
                                                                     error:&respErr];
    
    // render the response into an array for processing and pass back to the caller
    NSError *jsonErr = nil;
    NSArray *json = [NSJSONSerialization JSONObjectWithData:respData
                                                    options:NSJSONReadingMutableContainers
                                                      error:&jsonErr];
    
    return json;
}

@end
