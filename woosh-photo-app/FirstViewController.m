//
//  FirstViewController.m
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

#import "FirstViewController.h"
#import "Woosh.h"

@interface FirstViewController ()

@end

// app mode constants
static const int MODE_OFFER = 0;
static const int MODE_ACCEPT = 1;

int mode = MODE_ACCEPT;

// request type constants
static const int REQUEST_TYPE_NONE = -1;

static const int REQUEST_TYPE_SCAN = 0;
static const int REQUEST_TYPE_CREATE_CARD = 1;
static const int REQUEST_TYPE_MAKE_OFFER = 2;

int request_type = REQUEST_TYPE_NONE;

// last user action constants
static const int LAST_ACTION_NONE = 0;
static const int LAST_ACTION_SCAN = 1;
static const int LAST_ACTION_OFFER = 2;

int last_action = LAST_ACTION_NONE;


@implementation FirstViewController

@synthesize receivedData;
@synthesize offerButton;
@synthesize activityView;

@synthesize locationManager;
@synthesize motionManager;

@synthesize lastDeviceMotions;



- (void)viewDidLoad {
    [super viewDidLoad];
    
#if (TARGET_IPHONE_SIMULATOR)
    // if we are running in the simiulator then overlay an 'offer' button on the UIImage view
    [self.offerButton setFrame:CGRectMake(230, 370, 80, 33)];
    [self.offerButton addTarget:self action:@selector(makeOffer:) forControlEvents:UIControlEventTouchUpInside];
    [self.offerButton setHidden:YES];
#endif

    [self.activityView setHidden:YES];
    
    // ensure that the view is initialised correctly
    mode = MODE_ACCEPT;
    self.scanOrClearButton.title = @"Scan";
    
    // start the location manager
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locationManager startUpdatingLocation];
    
    // start the motion manager
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 0.25;  // second
    self.lastDeviceMotions = [NSMutableArray arrayWithCapacity:3];

    // start monitoring for device motion updates
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]                    // this MUST be the main queue
                                            withHandler:^(CMDeviceMotion *motion, NSError *error)
    {
        [self processDeviceMotion:motion error:error];
    }];
    
}

- (void) processDeviceMotion:(CMDeviceMotion *)motion error:(NSError *)error {

    if ([self.lastDeviceMotions count] == 3) {
        
        // we store the last three device motions in order (so shift all existing motions one step closer to the start of the array
        // and insert the new motion at the end)
        [self.lastDeviceMotions replaceObjectAtIndex:0 withObject:[self.lastDeviceMotions objectAtIndex:1]];
        [self.lastDeviceMotions replaceObjectAtIndex:1 withObject:[self.lastDeviceMotions objectAtIndex:2]];
        [self.lastDeviceMotions replaceObjectAtIndex:2 withObject:motion];
        
//                // TODO determine if the pitch has changed enough to performa woosh
//                NSLog(@"%@", [[self.lastDeviceMotions objectAtIndex:0] attitude]);
//                NSLog(@"%@", [[self.lastDeviceMotions objectAtIndex:1] attitude]);
//                NSLog(@"%@", [[self.lastDeviceMotions objectAtIndex:2] attitude]);
        
        double leastRecentPitch = [[self.lastDeviceMotions objectAtIndex:0] attitude].pitch;
        double mostRecentPitch = [[self.lastDeviceMotions objectAtIndex:2] attitude].pitch;
        
//                NSLog(@"least: %f", leastRecentPitch);
//                NSLog(@"most: %f", mostRecentPitch);
//                NSLog(@"%f", leastRecentPitch - mostRecentPitch);
        
        if ( (leastRecentPitch - mostRecentPitch < -1) && last_action == LAST_ACTION_NONE) {
            
            // kick off a scan request
            [self.activityView setHidden:NO];
            [self.activityView startAnimating];

            last_action = LAST_ACTION_SCAN;
            request_type = REQUEST_TYPE_SCAN;
            
            // reset the response data
            self.receivedData = [NSMutableData data];
            
            [[Woosh woosh] scan:self];
            
            NSLog(@"scan");
            
        } else if ( (leastRecentPitch - mostRecentPitch > 1) && last_action == LAST_ACTION_NONE) {
            
            if (self.imgView.image != nil) {

                last_action = LAST_ACTION_OFFER;
                
                // pop up an activity view
                [self.activityView setHidden:NO];
                [self.activityView startAnimating];
                
                // convert the raw image data into a PNG (use JPEG instead?)
                NSData *jpeg = UIImageJPEGRepresentation(self.imgView.image, 0.0);
                
                // we do two things here - create the card and then offer it
                // the card creation is started here and the offer is made then the new card ID is received in the response (within the delegate)
                request_type = REQUEST_TYPE_CREATE_CARD;
                
                self.receivedData = [NSMutableData data];
                
                [[Woosh woosh] createCardWithPhoto:@"default" photograph:jpeg delegate:self];
                
                NSLog(@"offer");
            }
            
        } else {
            
            last_action = LAST_ACTION_NONE;
            NSLog(@"none");
            
        }
//                NSLog(@"--------");
        
    } else {
        
        [self.lastDeviceMotions addObject:motion];
        
    }

}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *mostRecentLocation = [locations objectAtIndex:[locations count] - 1];
    
    // store the location in the Woosh service singleton
    [[Woosh woosh] setLatitude:mostRecentLocation.coordinate.latitude];
    [[Woosh woosh] setLatitude:mostRecentLocation.coordinate.longitude];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];

    self.imgView.image = chosenImage;
    
    // display the offer button
#if (TARGET_IPHONE_SIMULATOR)
    [self.offerButton setHidden:NO];
#endif
    
    // make sure that the UIImageView is displaying correctly
    [self.imgView bringSubviewToFront:self.offerButton];
    
    // set the mode to 'offer' - the user has a photo selected and can make an offer
    mode = MODE_OFFER;
    self.scanOrClearButton.title = @"Clear";
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) makeOffer:(id)sender {

    if (self.imgView.image != nil) {

        [self.activityView setHidden:NO];
        [self.activityView startAnimating];

        // convert the raw image data into a PNG (use JPEG instead?)
        NSData *jpeg = UIImageJPEGRepresentation(self.imgView.image, 0.0);
        
        // we do two things here - create the card and then offer it
        // the card creation is started here and the offer is made then the new card ID is received in the response (within the delegate)
        request_type = REQUEST_TYPE_CREATE_CARD;
        
        self.receivedData = [NSMutableData data];
        
        [[Woosh woosh] createCardWithPhoto:@"default" photograph:jpeg delegate:self];

    }
    
}

-(IBAction) selectPhotographButtonTapped:(id)sender {
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    
        // the user can select from either the gallery of existing images, or take a new photo with the camera
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera or Gallery?"
                                                        message:@"Would you like to choose from your gallery or take a new photo with the camera?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Camera", @"Gallery", nil];

        [alert show];
    
    } else {

        // the only option that the user has is to select from the gallery
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [picker setDelegate:self];
        
        [self presentViewController:picker animated:YES completion:nil];
        
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex == 1) {
        
        // the user chose camera
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [picker setDelegate:self];
        
        [self presentViewController:picker animated:YES completion:nil];
        
    } else if (buttonIndex == 2) {
        
        // the user chose gallery
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [picker setDelegate:self];
        
        [self presentViewController:picker animated:YES completion:nil];

    } else {
        
        // user cancelled the action
        
    }
    
}

-(IBAction) scanOrClearPhoto:(id)sender {
    
    if (mode == MODE_OFFER) {
    
        self.imgView.image = nil;
        
        // the user cleared the offer - move to 'accept' mode
        mode = MODE_ACCEPT;
        self.scanOrClearButton.title = @"Scan";
        [self.offerButton setHidden:YES];

    } else {

        [self.activityView setHidden:NO];
        [self.activityView startAnimating];
        
        // scan for offers at the current location
        request_type = REQUEST_TYPE_SCAN;

        // reset the response data
        self.receivedData = [NSMutableData data];
        
        [[Woosh woosh] scan:self];
                        
    }
    
}

//
// everything below here is asynchronous HTTP request processing, including handling authentication challenges
//

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    if (request_type == REQUEST_TYPE_NONE) {
     
        // do nothing

    } else if (request_type == REQUEST_TYPE_SCAN) {
        
//        NSString* newStr = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
//        NSLog(@"%@", newStr);

        // render the response into an array for processing and pass back to the caller
        NSError *jsonErr = nil;
        NSArray *availableOffers = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&jsonErr];
       
        if ([availableOffers count] == 0) {
            
            [self.activityView stopAnimating];
            [self.activityView setHidden:YES];

            UIAlertView *noAvailableOffersAlert = [[UIAlertView alloc] initWithTitle:@"Sorry!"
                                                                             message:@"There are no offers available at your location at the present time. Please try again later."
                                                                            delegate:nil
                                                                   cancelButtonTitle:@"Bummer!"
                                                                   otherButtonTitles: nil];
            [noAvailableOffersAlert show];
            
        } else {
            
            NSError *error = nil;
            NSArray *offers = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                              options:NSJSONReadingMutableContainers
                                                                error:&error];

            // procoess each offer
            for (int count = 0; count < [offers count]; count++) {
                NSDictionary *offer = [offers objectAtIndex:count];
        
                NSString *url = [[[[offer objectForKey:@"offeredCard"] objectForKey:@"data"] objectAtIndex:0] objectForKey:@"value"];
                NSURLRequest *photoDownloadReq = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                              timeoutInterval:60.0];

                // download the photo
                NSURLResponse *resp = nil;
                NSError *error = nil;
                NSData *photographData = [NSURLConnection sendSynchronousRequest:photoDownloadReq
                                                           returningResponse:&resp
                                                                       error:&error];                
                // save it to the camera roll
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                [library writeImageDataToSavedPhotosAlbum:photographData
                                                 metadata:nil
                                          completionBlock:nil];
            }
            
            [self.activityView stopAnimating];
            [self.activityView setHidden:YES];

            // tell the user what we just did
            UIAlertView *savedPhotosAlert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                       message:[NSString stringWithFormat:@"%d were found in your proximity and have been saved to your photo library.", [offers count]]
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK!"
                                                             otherButtonTitles: nil];
            [savedPhotosAlert show];
            
        }

    } else if (request_type == REQUEST_TYPE_CREATE_CARD) {
        
        NSError *error = nil;
        NSDictionary *respDict = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&error];
        
//        NSString* newStr = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
//        NSLog(@"%@", newStr);
        
        // grab the new card ID from the response
        NSString *newCardId = [respDict objectForKey:@"id"];

        // now make an offer on the card (in this app it's automatic to make an offer immediately after creating a card)
        request_type = REQUEST_TYPE_MAKE_OFFER;
        self.receivedData = [NSMutableData data];
        [[Woosh woosh] makeOffer:newCardId latitude:[[Woosh woosh] latitude] longitude:[[Woosh woosh] longitude] delegate:self];
        
    } else if (request_type == REQUEST_TYPE_MAKE_OFFER) {
        
        NSError *error = nil;
        NSDictionary *respDict = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&error];

        
        NSString *newOfferId = [respDict objectForKey:@"id"];

        
        if (newOfferId != nil) {

            // stop the activity view
            [self.activityView stopAnimating];
            [self.activityView setHidden:YES];

            UIAlertView *confirmationAlert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                        message:@"Your offer is now available to others within your proximity."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Sweet!"
                                                              otherButtonTitles:nil];
            [confirmationAlert show];
            
            // now that the offer has been made, reset the UI to be in accept mode
            self.imgView.image = nil;
            
            // the user cleared the offer - move to 'accept' mode
            mode = MODE_ACCEPT;
            self.scanOrClearButton.title = @"Scan";
            
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

@end
