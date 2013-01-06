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

static Woosh *instance;
static int RANDOM_CARD_NAME_LENGTH = 8;


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
- (BOOL) offerWithPhoto:(NSString *)name photograph:(NSData *)photograph {
    
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
                                        [photograph base64EncodedString], @"base64BinaryValue",
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

    // convert the response to a string and then a dictionary (the response is a JSON packet)
    NSString *jsonResponse = [[NSString alloc] initWithData:newCardResponseData encoding:NSASCIIStringEncoding];
    NSLog(@"%@", jsonResponse);
    
    return YES;
}

- (NSArray *) scan {
    // TODO perform a call to the 'scan' method on the RESTful API
    NSLog(@"This is where we would perform a scan.");
    
    return [NSArray array];
}

@end
