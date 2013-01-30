//
//  SignupViewController.m
//  woosh-photo-app
//
//  Created by Ben on 27/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "SignupViewController.h"
#import "Woosh.h"

@interface SignupViewController ()

@end

@implementation SignupViewController

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

- (IBAction) signupTapped:(id)sender {
 
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    NSString *confirmPassword = self.confirmPasswordField.text;
    NSString *email = self.emailField.text;

    // check that the username is OK
    if (username == nil || [username compare:@""] == NSOrderedSame || [username length] < 4) {
        [[[UIAlertView alloc] initWithTitle:@"Invalid Username"
                                    message:@"You must choose a username that is greater than 4 characters in length."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    
    // check that the password is OK
    if (password == nil || [password compare:@""] == NSOrderedSame || [password length] < 6) {
        [[[UIAlertView alloc] initWithTitle:@"Invalid Password"
                                    message:@"You must choose a username that is greater than 6 characters in length."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    
    // check that the password and the confirmation password match
    if ([password compare:confirmPassword] != NSOrderedSame) {
        [[[UIAlertView alloc] initWithTitle:@"Mismatch!"
                                    message:@"The passwords that you entered do not match. Please try again."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;        
    }

    // check that the provided email is OK
    // TODO apply a regular expression to check this
    if (email == nil || [email compare:@""] == NSOrderedSame) {
        [[[UIAlertView alloc] initWithTitle:@"Invalid Email"
                                    message:@"You must provide a valid email address."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }

    // if all input is valid then perform the sign-up
    NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *signupEndpoint = [endpoint stringByAppendingPathComponent:@"signup"];
    NSString *fullRequest = [NSString stringWithFormat:@"%@?username=%@&password=%@&email=%@", signupEndpoint, username, password, email];
    
    NSMutableURLRequest *signupReq = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullRequest]
                                                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                         timeoutInterval:60.0];
    
    NSURLResponse *signupResp;
    NSError *signupErr;
    NSData *signupResponseData = [NSURLConnection sendSynchronousRequest:signupReq returningResponse:&signupResp error:&signupErr];
    
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:signupResponseData
                                                             options:NSJSONReadingMutableContainers
                                                               error:nil];
    
    NSString *status = [jsonDict objectForKey:@"status"];
    
    if ([status compare:@"USERNAME_UNAVAILABLE"] == NSOrderedSame) {
        
        [[[UIAlertView alloc] initWithTitle:@"Username Unavailable"
                                    message:@"We're sorry but that username is already in use. Please try a different one."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;

    } else if ([status compare:@"FAILED"] == NSOrderedSame) {

        [[[UIAlertView alloc] initWithTitle:@"Server Error"
                                    message:@"We're sorry but the Woosh servers are misbehaving. We have been notified and we'll track it down..."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;

    } else if ([status compare:@"OK"] == NSOrderedSame) {

        NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *systemPropertiesPath = [documentPath URLByAppendingPathComponent:@"woosh.plist"];

        NSString *invitationKey = [jsonDict objectForKey:@"invitationKey"];

        NSMutableDictionary *props = [[Woosh woosh] systemProperties];
        
        // set the username and password on the system properties dictionary
        [props setObject:username forKey:@"username"];
        [props setObject:password forKey:@"password"];
        [props setObject:invitationKey forKey:@"invitationKey"];
        
        // flush the system properties file to disk
        [props writeToURL:systemPropertiesPath atomically:NO];
        
        // dismiss the login view - the user is free to being using the app
        [self.presentingViewController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            [[[UIAlertView alloc] initWithTitle:@"Success!"
                                        message:@"You are now signed up to Woosh! Have fun!"
                                       delegate:nil
                              cancelButtonTitle:@"Awesome!"
                              otherButtonTitles:nil] show];            
        }];
    }

}

- (IBAction) cancelTapped:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
