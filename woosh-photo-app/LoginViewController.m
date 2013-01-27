//
//  LoginViewController.m
//  woosh-photo-app
//
//  Created by Ben on 27/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "LoginViewController.h"

#import "SignupViewController.h"
#import "Woosh.h"


@interface LoginViewController ()

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (IBAction) loginTapped:(id)sender {
 
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    // perform checks on user input
    if (username == nil || [username compare:@""] == NSOrderedSame || [username length] < 4) {
        [[[UIAlertView alloc] initWithTitle:@"Invalid Username"
                                    message:@"You must choose a username that is greater than 4 characters in length."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }

    if (password == nil || [password compare:@""] == NSOrderedSame || [password length] < 6) {
        [[[UIAlertView alloc] initWithTitle:@"Invalid Password"
                                    message:@"You must choose a username that is greater than 6 characters in length."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }

    // if all input is valid then continue

    NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *systemPropertiesPath = [documentPath URLByAppendingPathComponent:@"woosh.plist"];
        
    NSMutableDictionary *props = [[Woosh woosh] systemProperties];
        
    // set the username and password on the system properties dictionary
    [props setObject:username forKey:@"username"];
    [props setObject:password forKey:@"password"];
        
    // flush the system properties file to disk
    [props writeToURL:systemPropertiesPath atomically:NO];

    // dismiss the login view - the user is free to being using the app
    [self dismissModalViewControllerAnimated:YES];

}

- (IBAction) signupTapped:(id)sender {
    SignupViewController *signupView = [[SignupViewController alloc] init];
    [signupView setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    
    [self presentViewController:signupView animated:YES completion:^{ }];
}

//	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
//    NSString *signupEndpoint = [endpoint stringByAppendingPathComponent:@"signup"];
//
//    NSMutableURLRequest *signupReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:signupEndpoint]
//                                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
//                                                         timeoutInterval:60.0];
//
//    NSURLResponse *signupResp;
//    NSError *signupErr;
//    NSData *signupResponseData = [NSURLConnection sendSynchronousRequest:signupReq returningResponse:&signupResp error:&signupErr];
//
//    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:signupResponseData
//                                                             options:NSJSONReadingMutableContainers
//                                                               error:nil];
//
//    NSString *status = [jsonDict objectForKey:@"status"];

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
