//
//  AppDelegate.h
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CMMotionManager *motionManager;

@property (strong, nonatomic) NSMutableArray *lastDeviceMotions;

@end
