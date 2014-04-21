//
//  FirstViewController.m
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>

#import "FirstViewController.h"
#import "LoginViewController.h"

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
static const int REQUEST_TYPE_ACCEPT_OFFER = 3;

int request_type = REQUEST_TYPE_NONE;

// last user action constants
static const int LAST_ACTION_NONE = 0;
static const int LAST_ACTION_SCAN = 1;
static const int LAST_ACTION_OFFER = 2;

int last_action = LAST_ACTION_NONE;


@implementation FirstViewController

@synthesize receivedData;

@synthesize navigationItem;
@synthesize activityView;
@synthesize locationAccuracyLabel;

@synthesize locationManager;
@synthesize motionManager;

@synthesize lastDeviceMotions;



- (void)viewDidLoad {
    [super viewDidLoad];
        
    [self.activityView setHidden:YES];
    
    // ensure that the view is initialised correctly
    mode = MODE_ACCEPT;
    
    // create all of the required buttons
    self.scanButton = [[UIBarButtonItem alloc] initWithTitle:@"Scan"
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(scanForOffers:)];
    
    self.cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                      target:self
                                                                      action:@selector(selectPhotographButtonTapped:)];
    
    self.clearButton = [[UIBarButtonItem alloc] initWithTitle:@"Clear"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(clearPhoto:)];
    
    self.offerButton = [[UIBarButtonItem alloc] initWithTitle:@"Offer"
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(makeOffer:)];
 
    // configure the main toolbar
    self.navigationItem.leftBarButtonItem = self.cameraButton;
    self.navigationItem.rightBarButtonItem = self.scanButton;
    
    // start the location manager
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    // start the motion manager
    self.motionManager = [[CMMotionManager alloc] init];
    self.motionManager.deviceMotionUpdateInterval = 0.15;  // second
    self.lastDeviceMotions = [NSMutableArray arrayWithCapacity:3];

    // start monitoring for device motion updates
    [self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue mainQueue]                    // this MUST be the main queue
                                            withHandler:^(CMDeviceMotion *motion, NSError *error)
    {
        [self processDeviceMotion:motion error:error];
    }];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // if the system properties array is empty at this point then pop up the login view to capture user authentication credentials
    if ([[[Woosh woosh] systemProperties] count] == 0) {
        LoginViewController *loginView = [[LoginViewController alloc] init];
        
        [self presentViewController:loginView animated:YES completion:^{ }];
    }
 
    self.locationAccuracyLabel.text = @"";
    self.locationAccuracyLabel.hidden = YES;
    self.imgView.backgroundColor = [UIColor lightGrayColor];

    [self.locationManager startUpdatingLocation];

    if ( ! [CLLocationManager locationServicesEnabled] ) {
        self.locationAccuracyLabel.text = @"Location Services are disabled. Loction Services are required to Woosh photos.";
        self.locationAccuracyLabel.hidden = NO;
        self.imgView.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.025];
    }
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // stop location services to conserve power
    [self.locationManager stopUpdatingLocation];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) processDeviceMotion:(CMDeviceMotion *)motion error:(NSError *)error {

    if ([self.lastDeviceMotions count] == 3) {
        
        // we store the last three device motions in order so shift all existing motions one step closer to the start of the array
        // and insert the new motion at the end)
        [self.lastDeviceMotions replaceObjectAtIndex:0 withObject:[self.lastDeviceMotions objectAtIndex:1]];
        [self.lastDeviceMotions replaceObjectAtIndex:1 withObject:[self.lastDeviceMotions objectAtIndex:2]];
        [self.lastDeviceMotions replaceObjectAtIndex:2 withObject:motion];
        
        double leastRecentPitch = [[self.lastDeviceMotions objectAtIndex:0] attitude].pitch;
        double mostRecentPitch = [[self.lastDeviceMotions objectAtIndex:2] attitude].pitch;
                
        if ( (leastRecentPitch - mostRecentPitch < -1) && last_action == LAST_ACTION_NONE) {
            
            // kick off a scan request
            [self.activityView setHidden:NO];
            [self.activityView startAnimating];

            last_action = LAST_ACTION_SCAN;
            request_type = REQUEST_TYPE_SCAN;
            
            // reset the response data
            self.receivedData = [NSMutableData data];
            
            if ( [[Woosh woosh] ping]) {
            
                [[Woosh woosh] scan:self];

            } else {

                [self.activityView stopAnimating];
                [self.activityView setHidden:YES];
                
                UIAlertView *connectionAlert = [[UIAlertView alloc] initWithTitle:@"Connection Error!"
                                                                          message:@"The Woosh app was not able to connect to the Woosh servers at this time. Sorry 'bout that, but please try again soon."
                                                                         delegate:nil
                                                                cancelButtonTitle:@"OK"
                                                                otherButtonTitles:nil];
                [connectionAlert show];

            }
        
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
                
                if ( [[Woosh woosh] ping] ) {

                    // write the JPEG to the local image cache
                    NSString *photographId = [Woosh uuid];
                    
                    NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
                    NSURL *imagePath = [[documentPath URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:photographId];
                    
                    [[NSFileManager defaultManager] createFileAtPath:[imagePath path] contents:jpeg attributes:nil];

                    // create the new Woosh card
                    [[Woosh woosh] createCardWithPhoto:@"default"
                                          photographId:photographId
                                            photograph:jpeg
                                              delegate:self];

                } else {
                    
                    [self.activityView stopAnimating];
                    [self.activityView setHidden:YES];

                    UIAlertView *connectionAlert = [[UIAlertView alloc] initWithTitle:@"Connection Error!"
                                                                              message:@"The Woosh app was not able to connect to the Woosh servers at this time. Sorry 'bout that, but please try again soon."
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
                    [connectionAlert show];
                    
                }
                
            }
            
        } else {

            // log the last action as NONE, which clears the way for a new action
            last_action = LAST_ACTION_NONE;
            
        }
    
    } else {
        
        [self.lastDeviceMotions addObject:motion];
        
    }

}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *mostRecentLocation = [locations objectAtIndex:[locations count] - 1];
    
    // store the location in the Woosh service singleton
    [[Woosh woosh] setLatitude:mostRecentLocation.coordinate.latitude];
    [[Woosh woosh] setLongitude:mostRecentLocation.coordinate.longitude];
    [[Woosh woosh] setHorizontalAccuracy:mostRecentLocation.horizontalAccuracy];

    NSLog(@"Horizontal accuracy is %f metres", mostRecentLocation.horizontalAccuracy);
    
    if ( ! [CLLocationManager locationServicesEnabled] ) {

        self.locationAccuracyLabel.text = @"Location Services are disabled. Loction Services are required to Woosh photos.";
        self.locationAccuracyLabel.hidden = NO;
        self.imgView.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.025];
    
    } else if ( mostRecentLocation.horizontalAccuracy > 10.0f ) {
    
        self.locationAccuracyLabel.text = @"Your location accuracy may not be sufficient to allow Woosh to work optimally.";
        self.locationAccuracyLabel.hidden = NO;
        self.imgView.backgroundColor = [UIColor colorWithRed:1.0 green:0.8 blue:0.0 alpha:0.025];
    
    } else /* location accuracy is <= 10 metres */ {
    
        self.locationAccuracyLabel.text = @"";
        self.locationAccuracyLabel.hidden = YES;
        self.imgView.backgroundColor = [UIColor lightGrayColor];
        
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if ( ! [CLLocationManager locationServicesEnabled] ) {
        
        self.locationAccuracyLabel.text = @"Location Services are disabled. Loction Services are required to Woosh photos.";
        self.locationAccuracyLabel.hidden = NO;
        self.imgView.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.025];

    } else {
        
        self.locationAccuracyLabel.text = @"";
        self.locationAccuracyLabel.hidden = YES;
        self.imgView.backgroundColor = [UIColor lightGrayColor];        
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];

    self.imgView.image = chosenImage;
    
    // set the mode to 'offer' - the user has a photo selected and can make an offer
    mode = MODE_OFFER;
    
    // configure the main toolbar
    self.navigationItem.rightBarButtonItem = self.offerButton;
    self.navigationItem.leftBarButtonItem = self.clearButton;

    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) makeOffer:(id)sender {
    
    // check that location services is working (if not warn the user that Woosh won't work well)
    if ( ! [CLLocationManager locationServicesEnabled] ) {
        UIAlertView *locServicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled"
                                                                           message:@"Woosh would like to make your photo available but it needs Location Services enabled to be able to to so. Please enable Location Services in Settings and try again."
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
        [locServicesDisabledAlert show];
        return;
    }
    
    if ([[Woosh woosh] ping]) {

        // disable the offer button so that the user can't tap it again
        [self.offerButton setEnabled:NO];
        
        // if the network is reachable then continue
        if (self.imgView.image != nil) {
            
            [self.activityView setHidden:NO];
            [self.activityView startAnimating];
            
            // convert the raw image data into a PNG (use JPEG instead?)
            NSData *jpeg = UIImageJPEGRepresentation(self.imgView.image, 0.0);
            
            // we do two things here - create the card and then offer it
            // the card creation is started here and the offer is made then the new card ID is received in the response (within the delegate)
            request_type = REQUEST_TYPE_CREATE_CARD;
            
            self.receivedData = [NSMutableData data];
            
            // write the JPEG to the local image cache
            NSString *photographId = [Woosh uuid];
            
            NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            NSURL *imagePath = [[documentPath URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:photographId];
            
            [[NSFileManager defaultManager] createFileAtPath:[imagePath path] contents:jpeg attributes:nil];

            // create the new Woosh card
            [[Woosh woosh] createCardWithPhoto:@"default"
                                  photographId:photographId
                                    photograph:jpeg
                                      delegate:self];
            
        }

    } else {
        
        [self.activityView stopAnimating];
        [self.activityView setHidden:YES];

        UIAlertView *connectionAlert = [[UIAlertView alloc] initWithTitle:@"Connection Error!"
                                                                  message:@"The Woosh app was not able to connect to the Woosh servers at this time. Sorry 'bout that, but please try again soon."
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
        [connectionAlert show];
        
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

-(IBAction) scanForOffers:(id)sender {
    
    // check that location services is working (if not warn the user that Woosh won't work well)
    if ( ! [CLLocationManager locationServicesEnabled] ) {
    
        UIAlertView *locServicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled"
                                                                           message:@"Woosh would like to scan for photos but it needs Location Services enabled to be able to to so. Please enable Location Services in Settings and try again."
                                                                          delegate:nil
                                                                 cancelButtonTitle:@"OK"
                                                                 otherButtonTitles:nil];
        [locServicesDisabledAlert show];
        return;

    }
    
    [self.activityView setHidden:NO];
    [self.activityView startAnimating];
        
    // scan for offers at the current location
    request_type = REQUEST_TYPE_SCAN;

    // reset the response data
    self.receivedData = [NSMutableData data];
        
    if ([[Woosh woosh] ping]) {
        
        [[Woosh woosh] scan:self];
        
    } else {
            
        [self.activityView stopAnimating];
        [self.activityView setHidden:YES];

        UIAlertView *connectionAlert = [[UIAlertView alloc] initWithTitle:@"Connection Error!"
                                                                  message:@"The Woosh app was not able to connect to the Woosh servers at this time. Sorry 'bout that, but please try again soon."
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
        [connectionAlert show];
       
    }
    
}

-(IBAction) clearPhoto:(id)sender {
    
    self.imgView.image = nil;
    
    // the user cleared the offer - move to 'accept' mode
    mode = MODE_ACCEPT;
    
    // configure the main toolbar
    self.navigationItem.leftBarButtonItem = self.cameraButton;
    self.navigationItem.rightBarButtonItem = self.scanButton;
    
}


//
// everything below here is asynchronous HTTP request processing, including handling authentication challenges
//

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    if (request_type == REQUEST_TYPE_NONE) {
     
        // do nothing

    } else if (request_type == REQUEST_TYPE_SCAN) {
        
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

                // figure out if the offer is auto-accept
                int isAutoAccept = [[[[offer objectForKey:@"offeredCard"] objectForKey:@"lastOffer"] objectForKey:@"autoAccept"] intValue];

                if ( isAutoAccept == YES ) {
                    
                    // if the offer is auto-accept then make the required server calls (and download the photo)
                    NSString *offerId = [offer objectForKey:@"offerId"];

                    // send a message to the Woosh servers to accept the offer
                    NSString *endpoint = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"ServerEndpoint"];
                    NSString *acceptOfferEndpoint = [endpoint stringByAppendingPathComponent:[NSString stringWithFormat:@"offer/accept/%@", offerId]];

                    NSURLResponse *resp = nil;
                    NSError *error = nil;
                    [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:acceptOfferEndpoint]]
                                          returningResponse:&resp
                                                      error:&error];
                    
                    // download the photo (card) that is associated with the offer
                    NSString *url = [[[[offer objectForKey:@"offeredCard"] objectForKey:@"data"] objectAtIndex:0] objectForKey:@"value"];
                    NSURLRequest *photoDownloadReq = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                                                      cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                                  timeoutInterval:60.0];
                    
                    // download the photo
                    NSData *photographData = [NSURLConnection sendSynchronousRequest:photoDownloadReq
                                                                   returningResponse:&resp
                                                                               error:&error];
                    
                    // save it to the camera roll
                    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                    [library writeImageDataToSavedPhotosAlbum:photographData
                                                     metadata:nil
                                              completionBlock:nil];
                }
                
            }
            
            [self.activityView stopAnimating];
            [self.activityView setHidden:YES];

            // tell the user what we just did
            UIAlertView *savedPhotosAlert = [[UIAlertView alloc] initWithTitle:@"Photos Added To Gallery"
                                                                       message:[NSString stringWithFormat:@"%ld photo(s) were found in your proximity and have been saved to your Photo Gallery.", (unsigned long)[offers count]]
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK!"
                                                             otherButtonTitles: nil];
            [savedPhotosAlert show];

            // push to the offer history view
            [self.tabBarController setSelectedIndex:1];
        }

    } else if (request_type == REQUEST_TYPE_CREATE_CARD) {
        
        NSError *error = nil;
        NSDictionary *respDict = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&error];
                
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
                                                                        message:@"Your photo is now available to others within your proximity."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Sweet!"
                                                              otherButtonTitles:nil];
            [confirmationAlert show];
            
            // now that the offer has been made, reset the UI to be in accept mode
            self.imgView.image = nil;
            
            // the user cleared the offer - move to 'accept' mode
            mode = MODE_ACCEPT;
            
            // configure the main toolbar
            self.navigationItem.leftBarButtonItem = self.cameraButton;
            self.navigationItem.rightBarButtonItem = self.scanButton;
            
            // the offer has been made - re-enable the offer button
            [self.offerButton setEnabled:YES];

        } else if (request_type == REQUEST_TYPE_ACCEPT_OFFER) {
            
            // do nothing - we simply tell the Woosh servers that the user accepted the offer, nothing more
            NSLog(@"Offer acceptance sent to the Woosh servers.");
            
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
    
    [self.activityView stopAnimating];
    [self.activityView setHidden:YES];
    
    UIAlertView *connectionAlert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                              message:@"We tried to post your photo to the Woosh servers but we were unable to at this time. But we are sure that this is a temporary glitch, so please try again soon."
                                                             delegate:nil
                                                    cancelButtonTitle:@"Bummer"
                                                    otherButtonTitles:nil];
    [connectionAlert show];
    
    // just in case we disabled it
    [self.offerButton setEnabled:YES];

}

@end
