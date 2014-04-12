//
//  ViewPhotoViewController.m
//  woosh-photo-app
//
//  Created by Ben on 24/03/2014.
//  Copyright (c) 2014 Luminos. All rights reserved.
//

#import "ViewPhotoViewController.h"
#import "Woosh.h"

@interface ViewPhotoViewController ()

@end

@implementation ViewPhotoViewController

@synthesize photograph;
@synthesize offerId;

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
 
    [self.imageView setImage:self.photograph];
}

- (IBAction) closeButtonTapped:(id)sender {
    [self.imageView setImage:nil];
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

- (IBAction) reportButtonTapped:(id)sender {
    
    // construct the request URL
	NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
    NSString *reportOfferEndpoint = [endpoint stringByAppendingPathComponent:@"offer/report"];
    NSString *fullUrl = [reportOfferEndpoint stringByAppendingFormat:@"/%@", self.offerId];
    
    // construct the HTTP request object
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fullUrl]
                                                       cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                   timeoutInterval:60.0];
    
    [req setHTTPMethod:@"POST"];
    
    // kick off the request
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:req delegate:self startImmediately:YES];
    [conn start];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    [self.imageView setImage:nil];
    [self dismissViewControllerAnimated:YES completion:^{ }];

    UIAlertView *reportAlert = [[UIAlertView alloc] initWithTitle:@"Thank You!"
                                                          message:@"Your report has been logged and the content at this location will be investigated by the Woosh team."
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
    
    [reportAlert show];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    // deal with the authentication challenge
    
    if ([challenge previousFailureCount] > 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Authentication Error"
                                                        message:@"Invalid credentials provided."
                                                       delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        
    } else {
        
        NSDictionary *systemProps = [[Woosh woosh] systemProperties];
        
        // we answer the challenge with the username and password provided by the user at login
        NSString *username = [systemProps objectForKey:@"username"];
        NSString *password = [systemProps objectForKey:@"password"];
        
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
