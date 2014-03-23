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


- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.usernameField.delegate = self;
    self.passwordField.delegate = self;
    
    [self.navigationBar setBackgroundImage:[UIImage new]
                             forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.shadowImage = [UIImage new];
    self.navigationBar.translucent = YES;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (IBAction) loginTapped:(id)sender {
 
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    // perform checks on user input
    if (username == nil || [username compare:@""] == NSOrderedSame) {
        [[[UIAlertView alloc] initWithTitle:@"Invalid Username"
                                    message:@"To log in you must provide a username."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }

    if (password == nil || [password compare:@""] == NSOrderedSame) {
        [[[UIAlertView alloc] initWithTitle:@"Invalid Password"
                                    message:@"To log in you must provide a password."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }

    // if all input is valid then attempt an authenticated action
    NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *authEndpoint = [endpoint stringByAppendingPathComponent:@"authenticate"];
    
    NSMutableURLRequest *authReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:authEndpoint]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:60.0];

    // reset the response data
    self.receivedData = [NSMutableData data];
    
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:authReq delegate:self startImmediately:NO];
    [conn start];
}

- (IBAction) signupTapped:(id)sender {
    SignupViewController *signupView = [[SignupViewController alloc] init];
    [signupView setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    
    [self presentViewController:signupView animated:YES completion:^{ }];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    // if all is OK then save the users authentication credentials
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    
    NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *systemPropertiesPath = [documentPath URLByAppendingPathComponent:@"woosh.plist"];
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
    NSString *invitationKey = [jsonDict objectForKey:@"invitationKey"];
    
    NSMutableDictionary *props = [[Woosh woosh] systemProperties];
    
    // set the username and password on the system properties dictionary
    [props setObject:username forKey:@"username"];
    [props setObject:password forKey:@"password"];
    [props setObject:invitationKey forKey:@"invitationKey"];
    
    // flush the system properties file to disk
    [props writeToURL:systemPropertiesPath atomically:NO];
    
    // dismiss the login view - the user is free to being using the app
    [self dismissViewControllerAnimated:YES completion:^{ }];

}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    // deal with the authentication challenge
    
    if ([challenge previousFailureCount] > 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authentication Error"
                                                        message:@"Invalid credentials provided."
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    } else {
        
        // we answer the challenge with the username and password provided by the user at login
        NSString *username = self.usernameField.text;
        NSString *password = self.passwordField.text;
        
        NSURLCredential *cred = [[NSURLCredential alloc] initWithUser:username password:password                                                                            persistence:NSURLCredentialPersistenceForSession];
        
        [[challenge sender] useCredential:cred forAuthenticationChallenge:challenge];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
