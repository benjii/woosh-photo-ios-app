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

// utility method for making an offer withg a single photograph
- (BOOL) offerWithPhoto:(NSString *)name photograph:(NSData *)photograph;

// perform a scan (an 'up woosh')
- (NSArray *) scan;

@end
