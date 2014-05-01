//
//  AppDelegate.m
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "AppDelegate.h"

#import "Woosh.h"
#import "LoginViewController.h"


@implementation AppDelegate

@synthesize receivedData;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *systemPropertiesPath = [documentPath URLByAppendingPathComponent:@"woosh.plist"];
    
    // log some interesting output
    NSLog(@"Application directory: %@", [documentPath path]);

    // create the images cache directory
    NSURL *imagesCachePath = [documentPath URLByAppendingPathComponent:@"images"];
    [[NSFileManager defaultManager] createDirectoryAtURL:imagesCachePath withIntermediateDirectories:YES attributes:nil error:nil];
    
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

    }
        
    // if all input is valid then attempt an authenticated action
    NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *pingEndpoint = [endpoint stringByAppendingPathComponent:@"ping"];
    
    NSMutableURLRequest *pingReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:pingEndpoint]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];
    
    // reset the response data
    self.receivedData = [NSMutableData data];
    
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:pingReq delegate:self startImmediately:NO];
    [conn start];

    // register for remote Push notifications
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)];

    // Override point for customization after application launch.
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    UIAlertView *notificationAlert = [[UIAlertView alloc] initWithTitle:@"Notification"
                                                                message:notification.alertBody
                                                               delegate:self cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
    [notificationAlert show];
}

// Delegation methods
- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    
    // save the most recent token in the global Blue instance
    [[Woosh woosh] setApnsToken:devToken];
    
    NSLog(@"APNS token: %@", devToken);
    
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    NSLog(@"Error when registering for remote Push notifications. Error: %@", err);
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

    // flush system properties to disk
    NSString *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *systemPropertiesPath = [documentPath stringByAppendingPathComponent:@"woosh.plist"];
    
    [[[Woosh woosh] systemProperties] writeToFile:systemPropertiesPath atomically:YES];
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError *jsonErr = nil;
    NSDictionary *pingResponse = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&jsonErr];
        
    NSString *motd = [pingResponse objectForKey:@"motd"];
        
    if ( ! [motd isEqual:[NSNull null]]) {
        if (motd != nil && [motd compare:@""] != NSOrderedSame) {
            [[[UIAlertView alloc] initWithTitle:@"Message Of The Day"
                                        message:[NSString stringWithFormat:@"%@", motd]
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

@end
