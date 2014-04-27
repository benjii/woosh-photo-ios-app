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

@synthesize receivedData;

static const int MINIMUM_USERNAME_LENGTH = 4;
static const int MINIMUM_PASSWORD_LENGTH = 6;


- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationBar setBackgroundImage:[UIImage new]
                             forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.shadowImage = [UIImage new];
    self.navigationBar.translucent = YES;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

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
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction) helpUsernameTapped:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"Username"
                                message:[NSString stringWithFormat:@"You can choose any username that is more than %d characters long.", MINIMUM_USERNAME_LENGTH]
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (IBAction) helpPasswordTapped:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"Password"
                                message:[NSString stringWithFormat:@"Your password must have a minimum length of %d characters.", MINIMUM_PASSWORD_LENGTH]
                               delegate:nil
                      cancelButtonTitle:@"Got it!"
                      otherButtonTitles:nil] show];
}

- (IBAction) helpOtherTapped:(id)sender {
    [[[UIAlertView alloc] initWithTitle:@"Other"
                                message:@"Please provide your email address and your key (Woosh in invite-only at the moment)!"
                               delegate:nil
                      cancelButtonTitle:@"Fair Enough!"
                      otherButtonTitles:nil] show];
}

- (IBAction) viewEulaTapped:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://woosh.io/eula"]];
}

- (IBAction) signupTapped:(id)sender {
 
    NSString *username = self.usernameField.text;
    NSString *password = self.passwordField.text;
    NSString *confirmPassword = self.confirmPasswordField.text;
    NSString *email = self.emailField.text;
    NSString *invitationKey = self.invitationKeyField.text;

    // check that the username is OK
    if (username == nil || [username compare:@""] == NSOrderedSame || [username length] < 8) {
        [[[UIAlertView alloc] initWithTitle:@"Invalid Username"
                                    message:[NSString stringWithFormat:@"You must choose a username that is at least %d characters long.", MINIMUM_USERNAME_LENGTH]
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    
    // check that the password is OK
    if (password == nil || [password compare:@""] == NSOrderedSame || [password length] < 6) {
        [[[UIAlertView alloc] initWithTitle:@"Invalid Password"
                                    message:[NSString stringWithFormat:@"You must choose a password that is at least %d characters long.", MINIMUM_PASSWORD_LENGTH]
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

    // check that an invitation key was provided
    if (invitationKey == nil || [invitationKey compare:@""] == NSOrderedSame) {
        [[[UIAlertView alloc] initWithTitle:@"Invitation Key Required"
                                    message:@"During the Woosh ramp-up period you must provide an Invitation Key to be able to sign up."
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }

    // if all input is valid then perform the sign-up
    NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *signupEndpoint = [endpoint stringByAppendingPathComponent:@"signup"];
    NSString *fullRequest = [NSString stringWithFormat:@"%@?username=%@&password=%@&email=%@&invitationKey=%@", signupEndpoint, username, password, email, invitationKey];
    
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

    } else if ([status compare:@"INVALID_INVITATION_KEY"] == NSOrderedSame) {

        [[[UIAlertView alloc] initWithTitle:@"Invalid Invitation Key"
                                    message:@"You did not provide a valid Invitation Key. Please try again."
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
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    NSError *jsonErr = nil;
    NSDictionary *pingResponse = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                            options:NSJSONReadingMutableContainers
                                                              error:&jsonErr];

    int remainingSlots = [[pingResponse objectForKey:@"remainingUserSlots"] intValue];
    int totalSlots = [[pingResponse objectForKey:@"totalSlotsAvailable"] intValue];
    
    // if totalSlots == -1 then Woosh is not in invitation-only mode anymore
    if ( totalSlots == -1 ) {
     
        self.remainingSlotsLabel.hidden = YES;
        self.invitationOnlyWarningLabel.hidden = YES;
        
    } else {

        if (remainingSlots <= 0) {
            self.remainingSlotsLabel.text = [NSString stringWithFormat:@"Sorry! There are no more sign-up slots available."];
            self.signupButton.enabled = NO;
        } else {
            self.remainingSlotsLabel.text = [NSString stringWithFormat:@"There are %d sign-up slots remaining", remainingSlots];
            self.signupButton.enabled = YES;
        }

    }
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
