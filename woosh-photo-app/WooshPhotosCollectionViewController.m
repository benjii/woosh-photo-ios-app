//
//  WooshPhotosCollectionViewController.m
//  woosh-photo-app
//
//  Created by Ben on 03/05/2014.
//  Copyright (c) 2014 Luminos. All rights reserved.
//

#import "WooshPhotosCollectionViewController.h"

#import "Woosh.h"
#import "LoginViewController.h"

@interface WooshPhotosCollectionViewController ()

@end

// request type constants
static const int REQUEST_TYPE_NONE = -1;

static const int REQUEST_TYPE_SAY_HELLO = 0;
static const int REQUEST_TYPE_APNS_TOKEN = 1;
static const int REQUEST_TYPE_LIST_CARDS = 2;
static const int REQUEST_TYPE_CREATE_CARD = 3;
static const int REQUEST_TYPE_MAKE_OFFER = 4;
static const int REQUEST_TYPE_EXPIRE_OFFER = 5;
static const int REQUEST_TYPE_DELETE_CARD = 6;
static const int REQUEST_TYPE_SCAN = 7;

//static const int REQUEST_TYPE_ACCEPT_OFFER = 6;

int w_request_type = REQUEST_TYPE_NONE;

@implementation WooshPhotosCollectionViewController

@synthesize receivedData;
@synthesize cards;
@synthesize imageCache;
@synthesize selectedPath;

@synthesize expireButtonIndex;
@synthesize deleteButtonIndex;
@synthesize reofferButtonIndex;

@synthesize fileManager;

static NSString* LOCATION_SERVICES_REQUIRED = @"Location Services are disabled";
static NSString* SUB_OPTIMAL_ACCURACY = @"%.0f metre location accuracy";
static NSString* READY_TO_WOOSH = @"Ready to Woosh!";



- (void)viewDidLoad {
    [super viewDidLoad];

    // initialise the request type
    w_request_type = REQUEST_TYPE_NONE;
    
    // grab the default file manager
    self.fileManager = [NSFileManager defaultManager];
    
    // if the system properties array is empty at this point then pop up the login view to capture user authentication credentials
    if ( [[[Woosh woosh] systemProperties] count] == 0 ) {
        
        LoginViewController *loginView = [[LoginViewController alloc] init];
        [self presentViewController:loginView animated:YES completion:^{
            // do nothing
        }];
        
    }

    // initialise the image cache
    self.imageCache = [[NSCache alloc] init];
    
    // start the location manager
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    
    // add a swipe gesture to the view so that users can swipe down to scan
    UISwipeGestureRecognizer *downSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleDownSwipe:)];
    downSwipeGesture.numberOfTouchesRequired = 1;
    downSwipeGesture.direction = UISwipeGestureRecognizerDirectionDown;
    
    [self.collectionView addGestureRecognizer:downSwipeGesture];

    // add a swipe gesture to the view so that users can swipe up to re-offer
    UISwipeGestureRecognizer *upSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleUpSwipe:)];
    upSwipeGesture.numberOfTouchesRequired = 1;
    upSwipeGesture.direction = UISwipeGestureRecognizerDirectionUp;
    
    [self.collectionView addGestureRecognizer:upSwipeGesture];

    // add a long-press gesture to the view so that users can manipulate image cells
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = .5;    // seconds

    [self.collectionView addGestureRecognizer:longPress];
}

- (void) refreshCards {
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Refreshing...";
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // do nothing
    });
    
    // initialise the buffer to hold server response data
    self.receivedData = [NSMutableData data];
    
    // retrieve the full set of user cards from the Woosh servers
    w_request_type = REQUEST_TYPE_LIST_CARDS;
    
    NSURLConnection * conn = [[Woosh woosh] getCards:self];
    [conn start];

}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ( [[[Woosh woosh] systemProperties] count] == 0 ) {
        
        LoginViewController *loginView = [[LoginViewController alloc] init];
        [self presentViewController:loginView animated:YES completion:^{
            // do nothing
        }];
        
    }
    
    self.navigationItem.prompt = READY_TO_WOOSH;
    
    // start updating location
    [self.locationManager startUpdatingLocation];
    
    if ( ! [CLLocationManager locationServicesEnabled] ) {
        self.navigationItem.prompt = LOCATION_SERVICES_REQUIRED;
    }

    // if no other request is going on at the moment then we can refresh the cards list
    if ( w_request_type == REQUEST_TYPE_NONE && [[Woosh woosh] credentialed] ) {
        w_request_type = REQUEST_TYPE_SAY_HELLO;
        self.receivedData = [NSMutableData data];
        [[[Woosh woosh] sayClientHello:self] start];
    }
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // stop location services to conserve power
    [self.locationManager stopUpdatingLocation];
}

-(void) handleDownSwipe:(UISwipeGestureRecognizer *)gestureRecognizer {
    
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
    
    // scan for offers at the current location
    w_request_type = REQUEST_TYPE_SCAN;
    self.receivedData = [NSMutableData data];
    [[Woosh woosh] scan:self];
    
}

-(void) handleUpSwipe:(UISwipeGestureRecognizer *)gestureRecognizer {
    NSLog(@"Up swipe gesture detected.");
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {

    // if the gesture has not ended yet then ignore it
    if (gestureRecognizer.state != UIGestureRecognizerStateEnded) {
        return;
    }
    
    // find the point at which the user is pressing
    CGPoint p = [gestureRecognizer locationInView:self.collectionView];
    
    self.selectedPath = [self.collectionView indexPathForItemAtPoint:p];
    
    if (self.selectedPath == nil){
       
        NSLog(@"User was not pressing over a cell. Ignoring...");
    
    } else {
        
        WooshPhotoCollectionViewCell* cell = (WooshPhotoCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:self.selectedPath];
        
        NSLog(@"User long-pressed on cell: %@", cell);
        
        if ( [cell isOffered] ) {

            UIActionSheet *cellActions = [[UIActionSheet alloc] initWithTitle:nil
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:@"Expire", nil];
            
            self.expireButtonIndex = 0;
            self.deleteButtonIndex = -1;
            self.reofferButtonIndex = -1;
            
            [cellActions showFromTabBar:self.tabBarController.tabBar];

        } else {
            
            UIActionSheet *cellActions = [[UIActionSheet alloc] initWithTitle:nil
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                       destructiveButtonTitle:@"Delete"
                                                            otherButtonTitles:@"Woosh Again", nil];

            self.expireButtonIndex = -1;
            self.deleteButtonIndex = 0;
            self.reofferButtonIndex = 1;

            [cellActions showFromTabBar:self.tabBarController.tabBar];
            
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {

    // grab the relevant cell
    WooshPhotoCollectionViewCell* cell = (WooshPhotoCollectionViewCell *) [self.collectionView cellForItemAtIndexPath:self.selectedPath];
    
    if ( buttonIndex == self.deleteButtonIndex ) {
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Deleting...";
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            // do nothing
        });

        // evaculate the local cache
        NSURL *documentPath = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *imagePath = [[documentPath URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:cell.imageId];
        
        // locally cached image found - store the image in the in-memory cache for later
        [self.imageCache removeObjectForKey:cell.imageId];
        [fileManager removeItemAtURL:imagePath error:nil];
        
        // make the call to the server to delete the card
        self.receivedData = [NSMutableData data];
        w_request_type = REQUEST_TYPE_DELETE_CARD;
        [[Woosh woosh] deleteCard:cell.cardId delegate:self];

        [MBProgressHUD hideHUDForView:self.view animated:YES];
        
    } else if ( buttonIndex == self.expireButtonIndex ) {

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Expiring...";
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            // do nothing
        });

        // expire the current offer on the card
        self.receivedData = [NSMutableData data];
        w_request_type = REQUEST_TYPE_EXPIRE_OFFER;
        
        [[Woosh woosh] expireOffer:cell.lastOfferId delegate:self];

        [MBProgressHUD hideHUDForView:self.view animated:YES];

    } else if ( buttonIndex == self.reofferButtonIndex ) {

        // this is the re-offer button

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Wooshing...";
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            // do nothing
        });

        // re-offer the card
        self.receivedData = [NSMutableData data];
        w_request_type = REQUEST_TYPE_MAKE_OFFER;
        
        [[Woosh woosh] makeOffer:cell.cardId latitude:[[Woosh woosh] latitude] longitude:[[Woosh woosh] longitude] delegate:self];

        [MBProgressHUD hideHUDForView:self.view animated:YES];

    }
    
    NSLog(@"User clicked button: %ld", (long)buttonIndex);
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *mostRecentLocation = [locations objectAtIndex:[locations count] - 1];
    
    // store the location in the Woosh service singleton
    [[Woosh woosh] setLatitude:mostRecentLocation.coordinate.latitude];
    [[Woosh woosh] setLongitude:mostRecentLocation.coordinate.longitude];
    [[Woosh woosh] setHorizontalAccuracy:mostRecentLocation.horizontalAccuracy];
    
//    NSLog(@"Horizontal accuracy is %f metres", mostRecentLocation.horizontalAccuracy);

    if ( ! [CLLocationManager locationServicesEnabled] ) {
        self.navigationItem.prompt = LOCATION_SERVICES_REQUIRED;
    } else if ( mostRecentLocation.horizontalAccuracy > 20.0f ) {
        self.navigationItem.prompt = [NSString stringWithFormat:SUB_OPTIMAL_ACCURACY, [[Woosh woosh] horizontalAccuracy]];
    } else /* location accuracy is <= 10 metres */ {
        self.navigationItem.prompt = READY_TO_WOOSH;
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSLog(@"Location services authorization status changed.");
}

//
// action buttons
//

-(IBAction) helpButtonTapped:(id)sender {
    
    UIAlertView *helpAlert = [[UIAlertView alloc] initWithTitle:@"How To Share Photos With Your Friends"
                                                        message:@"\nTap the Share icon to drop a photo into the world\n\nSwipe down to grab shared photos\n\nHold on a photo for more options"
                                                       delegate:nil
                                              cancelButtonTitle:@"I Got It"
                                              otherButtonTitles:nil];
    [helpAlert show];
    
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
        
        // no camera - the only option that the user has is to select from the gallery
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];

    // convert the raw image data into a PNG (use JPEG instead?)
    NSData *jpeg = UIImageJPEGRepresentation(chosenImage, 0.0);
    
    // we do two things here - create the card and then offer it
    // the card creation is started here and the offer is made then the new card ID is received in the response (within the delegate)
    w_request_type = REQUEST_TYPE_CREATE_CARD;
    self.receivedData = [NSMutableData data];

    // generate a new unique ID for the photograph
    NSString *photographId = [Woosh uuid];

    // place the JPEG into the in-memory cache
    [self.imageCache setObject:jpeg forKey:photographId];
    
    // write the JPEG to the local image cache
    NSURL *documentPath = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *imagePath = [[documentPath URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:photographId];
    
    [fileManager createFileAtPath:[imagePath path] contents:jpeg attributes:nil];
    
    // create the new Woosh card
    [[Woosh woosh] createCardWithPhoto:@"default"
                          photographId:photographId
                            photograph:jpeg
                              delegate:self];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

//
// collection view delegate and datasource methods
//

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    // TODO check each card to make sure that it has at least a "fromOffer" or a "lastOffer"

    return ( self.cards == nil ) ? 0 : [self.cards count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    WooshPhotoCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"WooshPhotoCell" forIndexPath:indexPath];
    
    // grab the card and it's data from the JSON
    NSDictionary *card = [self.cards objectAtIndex:indexPath.row];
    id data = [card objectForKey:@"data"];
    
    cell.cardId = [card objectForKey:@"id"];
 
//    // output the card JSON
//    NSLog(@"%@", card);
    
    // set properties that are common to all cells
    cell.parentView = self;
    cell.timer = [NSTimer timerWithTimeInterval:1.0
                                         target:cell
                                       selector:@selector(remainingTimeDidTick:)
                                       userInfo:nil
                                        repeats:YES];

    // load the photo (either from local storage if it exists, or from S3 if it doesn't)
    if ([data isKindOfClass:[NSArray class]]) {
        
        NSDictionary *dataDict = [data objectAtIndex:0];
        NSString *binaryId = [dataDict objectForKey:@"binaryId"];
        
        // look for the photograph in the in-memory cache
        if ([self.imageCache objectForKey:binaryId] != nil) {
            
            NSLog(@"Found image in the in-memory cache - rendering...");
            cell.thumbnail.image = [UIImage imageWithData:[self.imageCache objectForKey:binaryId]];
            cell.imageId = binaryId;
            
        } else {
            
            // the photograph was not found in the image cache so look for it on disk
            // if not found on disk then we download from S3
            
            NSURL *documentPath = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            NSURL *imagePath = [[documentPath URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:binaryId];
            
            if ( [fileManager fileExistsAtPath:[imagePath path]] ) {

                NSLog(@"Locally cached image found - loading...");

                // locally cached image found - store the image in the in-memory cache for later
                [self.imageCache setObject:[NSData dataWithContentsOfFile:[imagePath path]] forKey:binaryId];
                cell.thumbnail.image = [UIImage imageWithData:[self.imageCache objectForKey:binaryId]];
                cell.imageId = binaryId;
                
            } else {
                NSURL *remoteUrl = [NSURL URLWithString:[dataDict objectForKey:@"value"]];
                
                // download the image to the local cache
                NSLog(@"No locally cached image found - downloading...");
                NSData *imageData = [NSData dataWithContentsOfURL:remoteUrl];
                
                if (imageData == nil) {
                    
                    NSLog(@"Warning! Could not download image from S3. Tagging image as unavailable.");
                    
                    // write an empty image to the cache - it's missing
                    [fileManager createFileAtPath:[imagePath path] contents:[NSData data] attributes:nil];
                    
                    cell.remainingTimeLabel.text = @"Card Missing!";
                    
                } else {
                    
                    NSLog(@"Downloaded image from S3 - storing in local cache.");

                    [imageData writeToURL:imagePath atomically:YES];
                    [self.imageCache setObject:imageData forKey:binaryId];
                    
                    cell.thumbnail.image = [UIImage imageWithData:imageData];
                    cell.imageId = binaryId;
                }
                
            }

        }
    }
    
    // the rendering of cells depends somewhat on whether the card is owned by this user or not
    // we can tell if a user owns a card if there is a 'lastOffer' property set
    
    if ( [[card objectForKey:@"fromOffer"] isKindOfClass:[NSDictionary class]] ) {
        // there is a "fromOffer" property set so this offer did not originate from here - it's read only

        cell.fromOfferId = [[card objectForKey:@"fromOffer"] objectForKey:@"id"];
        cell.remainingTimeLabel.hidden = YES;
        cell.offerCountLabel.hidden = YES;
        
    } else if ( [[card objectForKey:@"lastOffer"] isKindOfClass:[NSDictionary class]] ){
        // there is a "lastOffer" property set so this offer did originate here
        
        // figure out how long the offer is open for
        double offerEnd = [[[card objectForKey:@"lastOffer"] objectForKey:@"offerEnd"] doubleValue];
        NSDate *offerEndDate = [NSDate dateWithTimeIntervalSince1970:offerEnd / 1000];
        BOOL active = [offerEndDate compare:[NSDate date]] == NSOrderedDescending;
        
        cell.lastOfferId = [[card objectForKey:@"lastOffer"] objectForKey:@"id"];
        cell.active = active;
        cell.offerCountLabel.hidden = NO;
        cell.offerCountLabel.text = [NSString stringWithFormat:@"%@ / %@", [card objectForKey:@"totalAcceptances"], [card objectForKey:@"totalOffers"]];

        if ( cell.active ) {
            
            cell.offerEnd = offerEnd;
            cell.remainingTimeLabel.hidden = NO;

            [[NSRunLoop mainRunLoop] addTimer:cell.timer forMode:NSRunLoopCommonModes];
        } else {
            cell.remainingTimeLabel.hidden = YES;
        }
        
    } else {
        
        NSLog(@"No 'from offer' or 'last offer' set on the card. Something is very wrong!");
        return nil;
        
    }
    
    return cell;
}

//
// everything below here is asynchronous HTTP request processing, including handling authentication challenges
//

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    if (w_request_type == REQUEST_TYPE_NONE) {
        
        // do nothing
        
    } else if (w_request_type == REQUEST_TYPE_SAY_HELLO) {
        
        NSLog(@"Server accepted client devices 'hello'.");
        
        w_request_type = REQUEST_TYPE_APNS_TOKEN;
        self.receivedData = [NSMutableData data];
        [[[Woosh woosh] submitApnsToken:self] start];
        
    } else if (w_request_type == REQUEST_TYPE_APNS_TOKEN ) {
        
        NSLog(@"Server accepted client device APNS token.");
        [self refreshCards];

    } else if (w_request_type == REQUEST_TYPE_LIST_CARDS) {
        
        NSError *jsonErr = nil;
        self.cards = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                     options:NSJSONReadingMutableContainers
                                                       error:&jsonErr];
        
//        NSLog(@"%@", [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding]);

        [self.collectionView reloadData];

        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        });

    } else if (w_request_type == REQUEST_TYPE_CREATE_CARD) {
        
        NSError *error = nil;
        NSDictionary *respDict = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&error];
        
        // grab the new card ID from the response
        NSString *newCardId = [respDict objectForKey:@"id"];
        
        // now make an offer on the card (in this app it's automatic to make an offer immediately after creating a card)
        w_request_type = REQUEST_TYPE_MAKE_OFFER;
        self.receivedData = [NSMutableData data];
        
        NSLog(@"Card %@ successfully created.", newCardId);
 
        [[Woosh woosh] makeOffer:newCardId latitude:[[Woosh woosh] latitude] longitude:[[Woosh woosh] longitude] delegate:self];
        
    } else if (w_request_type == REQUEST_TYPE_MAKE_OFFER) {
        
        NSError *error = nil;
        NSDictionary *respDict = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&error];
        
        NSString *newOfferId = [respDict objectForKey:@"id"];
        
        if (newOfferId != nil) {
            
            UIAlertView *confirmationAlert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                        message:@"Your photo is now available to others within your proximity."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Sweet!"
                                                              otherButtonTitles:nil];
            [confirmationAlert show];
            
            NSLog(@"Card successfully offered (%@).", newOfferId);
            
            // create a local notification for the offer expiry (so that the user knows when their offer expired)
            [[Woosh woosh] createLocalExpityNotificationForOffer:newOfferId];
            
            // now that we've created the new card and offered it, refresh all cards
            [self refreshCards];
        }

    } else if (w_request_type == REQUEST_TYPE_EXPIRE_OFFER) {

        // grab the relevant cell
        WooshPhotoCollectionViewCell* cell = (WooshPhotoCollectionViewCell *) [self.collectionView cellForItemAtIndexPath:self.selectedPath];

        [cell.timer invalidate];
        cell.remainingTimeLabel.hidden = YES;
        cell.remainingTimeLabel.text = @"";
        
        // create a local notification for the offer expiry (so that the user knows when their offer expired)
        [[Woosh woosh] removeLocalExpityNotificationForOffer:cell.lastOfferId];
        
    } else if (w_request_type == REQUEST_TYPE_DELETE_CARD) {
        
        // refresh the list of card from the servers
        w_request_type = REQUEST_TYPE_LIST_CARDS;
        [self refreshCards];
        
    } else if (w_request_type == REQUEST_TYPE_SCAN) {

        // render the response into an array for processing and pass back to the caller
        NSError *jsonErr = nil;
        NSArray *availableOffers = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                                   options:NSJSONReadingMutableContainers
                                                                     error:&jsonErr];
        
        if ([availableOffers count] == 0) {
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
            
            // process each offer
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

            // tell the user what we just did
            UIAlertView *savedPhotosAlert = [[UIAlertView alloc] initWithTitle:@"Photos Added To Gallery"
                                                                       message:[NSString stringWithFormat:@"%ld photo(s) were found in your proximity and have been saved to your Photo Gallery.", (unsigned long)[offers count]]
                                                                      delegate:nil
                                                             cancelButtonTitle:@"OK!"
                                                             otherButtonTitles: nil];
            [savedPhotosAlert show];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
