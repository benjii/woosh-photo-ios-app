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

// utility method for making an offer withg a single photograph
- (NSURLConnection *) createCardWithPhoto:(NSString *)name photograph:(NSData *)photograph delegate:(id <NSURLConnectionDelegate>)delegate;
- (NSURLConnection *) makeOffer:(NSString *)cardId latitude:(double)latitude longitude:(double)longitude delegate:(id <NSURLConnectionDelegate>)delegate;

// perform a scan (an 'up woosh')
- (NSURLConnection *) scan:(id <NSURLConnectionDelegate>)delegate;

@end
