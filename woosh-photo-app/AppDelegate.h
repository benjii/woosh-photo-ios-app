//
//  AppDelegate.h
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Reachability.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLConnectionDelegate>

@property (strong, nonatomic) UIWindow *window;

@property NSMutableData *receivedData;

@end
