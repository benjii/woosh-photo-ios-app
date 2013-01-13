//
//  AppDelegate.m
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "AppDelegate.h"

#import "Woosh.h"

@implementation AppDelegate

@synthesize lastDeviceMotions;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *systemPropertiesPath = [documentPath URLByAppendingPathComponent:@"woosh.plist"];
    
    // log some interesting output
    NSLog(@"Application directory: %@", [documentPath path]);
    
    NSMutableDictionary *props = nil;
    
    if ( [[NSFileManager defaultManager] fileExistsAtPath:[systemPropertiesPath path]] ) {
        
        // properties file does exist - read it.
        props = [NSMutableDictionary dictionaryWithContentsOfFile:[systemPropertiesPath path]];
        
        // this both instantiates the Woosh services and sets it's system properties
        [[Woosh woosh] setSystemProperties:props];
        
    } else {
        
        // properties file does not exist - create it
        NSMutableDictionary *props = [NSMutableDictionary dictionary];
        
        // flush the system properties file to disk
        [props writeToURL:systemPropertiesPath atomically:NO];
        
        // this both instantiates the Woosh services and sets it's system properties
        [[Woosh woosh] setSystemProperties:props];
        
        // if the properties file does not exist then neither will authentication credentials
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Secure Service" message:@"You must login to use Woosh." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Login", nil];
        
        alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
        
        [alert show];
    }
    
    // start the location manager
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
    
    // start the motion manager
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 0.5;  // second
    self.lastDeviceMotions = [NSMutableArray arrayWithCapacity:3];
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [self.motionManager startDeviceMotionUpdatesToQueue:queue
                                            withHandler:^(CMDeviceMotion *motion, NSError *error)
        {
            
            // TODO we are interested in the pitch of the device
            //      if within 1 second the pitch has changed more than 70 degrees then we have an up or down woosh

            if ([self.lastDeviceMotions count] == 3) {

                // we store the last three device motions in order (so shift all existing motions one step closer to the start of the array
                // and insert the new motion at the end)
                [self.lastDeviceMotions replaceObjectAtIndex:0 withObject:[self.lastDeviceMotions objectAtIndex:1]];
                [self.lastDeviceMotions replaceObjectAtIndex:1 withObject:[self.lastDeviceMotions objectAtIndex:2]];
                [self.lastDeviceMotions replaceObjectAtIndex:2 withObject:motion];

                // TODO determine if the pitch has changed enough to performa woosh
                NSLog(@"%@", [[self.lastDeviceMotions objectAtIndex:0] attitude]);
                NSLog(@"%@", [[self.lastDeviceMotions objectAtIndex:1] attitude]);
                NSLog(@"%@", [[self.lastDeviceMotions objectAtIndex:2] attitude]);

                double leastRecentPitch = [[self.lastDeviceMotions objectAtIndex:0] attitude].pitch;
                double mostRecentPitch = [[self.lastDeviceMotions objectAtIndex:2] attitude].pitch;
                
                NSLog(@"least: %f", leastRecentPitch);
                NSLog(@"most: %f", mostRecentPitch);
                NSLog(@"%f", leastRecentPitch - mostRecentPitch);
                
                if (leastRecentPitch - mostRecentPitch < -1) {
                    NSLog(@"scan");
                } else if (leastRecentPitch - mostRecentPitch > 1) {
                    NSLog(@"offer");
                }
                NSLog(@"--------");
                
            } else {
                
                [self.lastDeviceMotions addObject:motion];
                
            }
            
        }];
    
    // Override point for customization after application launch.
    return YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *mostRecentLocation = [locations objectAtIndex:[locations count] - 1];
    
    // store the location in the Woosh service singleton
    [[Woosh woosh] setLatitude:mostRecentLocation.coordinate.latitude];
    [[Woosh woosh] setLatitude:mostRecentLocation.coordinate.longitude];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        NSString *username = [[alertView textFieldAtIndex:0] text];
        NSString *password = [[alertView textFieldAtIndex:1] text];
        
        NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *systemPropertiesPath = [documentPath URLByAppendingPathComponent:@"woosh.plist"];
        
        NSMutableDictionary *props = [[Woosh woosh] systemProperties];
        
        // set the username and password on the system properties dictionary
        [props setObject:username forKey:@"username"];
        [props setObject:password forKey:@"password"];
        
        // flush the system properties file to disk
        [props writeToURL:systemPropertiesPath atomically:NO];
        
        // TODO now that we are authenitcated, check to see that we have all of the users published cards
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {

    // stop all of the location and motion monitoring
    [self.motionManager stopDeviceMotionUpdates];
    [self.locationManager stopUpdatingLocation];

    // flush system properties to disk
    NSString *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *systemPropertiesPath = [documentPath stringByAppendingPathComponent:@"woosh.plist"];
    
    [[[Woosh woosh] systemProperties] writeToFile:systemPropertiesPath atomically:YES];
    
}

@end
