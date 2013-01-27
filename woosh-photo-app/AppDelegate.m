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

        // popping up the login view controller is now down elsewhere
        
//        // if the properties file does not exist then neither will authentication credentials
//        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Secure Service" message:@"You must login to use Woosh." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Login", nil];
//        
//        alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
//        
//        [alert show];
    }
        
    // Override point for customization after application launch.
    return YES;
}

//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
//    
//    if (buttonIndex == 0) {
//        NSString *username = [[alertView textFieldAtIndex:0] text];
//        NSString *password = [[alertView textFieldAtIndex:1] text];
//        
//        NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//        NSURL *systemPropertiesPath = [documentPath URLByAppendingPathComponent:@"woosh.plist"];
//        
//        NSMutableDictionary *props = [[Woosh woosh] systemProperties];
//        
//        // set the username and password on the system properties dictionary
//        [props setObject:username forKey:@"username"];
//        [props setObject:password forKey:@"password"];
//        
//        // flush the system properties file to disk
//        [props writeToURL:systemPropertiesPath atomically:NO];
//        
//        // TODO now that we are authenitcated, check to see that we have all of the users published cards
//    }
//}

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

@end
