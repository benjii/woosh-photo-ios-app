//
//  SecondViewController.m
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "SecondViewController.h"

#import "Woosh.h"
#import "WooshCardTableViewCell.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

@synthesize wooshCardTableView;
@synthesize loadActivityView;

@synthesize receivedData;
@synthesize wooshCardsModel;


// request type constants
static const int REQUEST_TYPE_NONE = -1;

static const int REQUEST_TYPE_LIST_CARDS = 0;
static const int REQUEST_TYPE_DELETE_CARD = 1;

int req_type = REQUEST_TYPE_NONE;


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // make sure that the loading activity view is on the top
    [self.view bringSubviewToFront:self.loadActivityView];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];
    
    // initialise the buffer to hold server response data
    self.receivedData = [NSMutableData data];
    
    // retrieve the full set of user cards from the Woosh servers
    req_type = REQUEST_TYPE_LIST_CARDS;

    NSURLConnection * conn = [[Woosh woosh] getCards:self];
    [conn start];
}

- (void) threadStartAnimating:(id)data {
    [self.loadActivityView startAnimating];
}

- (void) threadStopAnimating:(id)data {
    [self.loadActivityView stopAnimating];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void) refreshCards {

    [NSThread detachNewThreadSelector:@selector(threadStartAnimating:) toTarget:self withObject:nil];
    
    // initialise the buffer to hold server response data
    self.receivedData = [NSMutableData data];
    
    // retrieve the full set of user cards from the Woosh servers
    req_type = REQUEST_TYPE_LIST_CARDS;
    
    NSURLConnection * conn = [[Woosh woosh] getCards:self];
    [conn start];

}

- (IBAction) refreshButtonTapped:(id)sender {
    [self refreshCards];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.wooshCardsModel count];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSString *cardId = [[self.wooshCardsModel objectAtIndex:indexPath.row] objectForKey:@"id"];

        // make the call to the server to delete the card
        req_type = REQUEST_TYPE_DELETE_CARD;
        [[Woosh woosh] deleteCard:cardId delegate:self];
        
    }
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSDictionary *cardDict = [self.wooshCardsModel objectAtIndex:indexPath.row];
    NSDictionary *dataDict = [[cardDict objectForKey:@"data"] objectAtIndex:0];
    NSString *binaryId = [dataDict objectForKey:@"binaryId"];
    
    NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *imagePath = [[documentPath URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:binaryId];

    if ( [[NSFileManager defaultManager] fileExistsAtPath:[imagePath path]] ) {
        
        // load the image from the local image cache
        NSLog(@"Locally cached image found - displaying...");
        
        // segue out to the read-only version of the message composer
        [self performSegueWithIdentifier:@"ViewPhotograph" sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    ViewPhotoViewController *vc = [segue destinationViewController];
    if ([[segue identifier] isEqualToString:@"ViewPhotograph"]) {
        
        NSIndexPath *path = [self.wooshCardTableView indexPathForSelectedRow];
        WooshCardTableViewCell *cell = (WooshCardTableViewCell *)[self.wooshCardTableView cellForRowAtIndexPath:path];
        
        vc.photograph = cell.thumbnail.image;
        vc.offerId = cell.fromOfferId;
    }

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *wooshCardTableIdentifier = @"WooshCardTableItem";
    
    WooshCardTableViewCell *cell = (WooshCardTableViewCell *) [tableView dequeueReusableCellWithIdentifier:wooshCardTableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"WooshCardTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    cell.parentView = self;
    cell.timer = [NSTimer timerWithTimeInterval:1.0
                                         target:cell
                                       selector:@selector(remainingTimeDidTick:)
                                       userInfo:nil
                                        repeats:YES];
    
    // to populate the cell we;
    //  1. determine if this card orginated from this user
    //  2. if so, they may manipulate it (i.e.: re-offer / expire it)
    //  3. if not then the offer can not be manipulated (but the user can view it)
    
    NSDictionary *cardDict = [self.wooshCardsModel objectAtIndex:indexPath.row];
    id dataArry = [cardDict objectForKey:@"data"];

//    NSDictionary *fromOffer = [cardDict objectForKey:@"fromOffer"];
    
    if ( [[cardDict objectForKey:@"fromOffer"] isKindOfClass:[NSDictionary class]] ) {
        // a 'from offer' is present which means that the card did not originate from here
        // make the cell read-only
        
        cell.remainingTimeLabel.hidden = YES;
        cell.expireButton.hidden = YES;
        cell.reofferButton.hidden = YES;
        cell.readOnlyNotificationLabel.hidden = NO;
        cell.fromOfferId = [[cardDict objectForKey:@"fromOffer"] objectForKey:@"id"];
        cell.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
        
        // load data
        if ([dataArry isKindOfClass:[NSArray class]]) {
            
            NSDictionary *dataDict = [[cardDict objectForKey:@"data"] objectAtIndex:0];
            NSString *binaryId = [dataDict objectForKey:@"binaryId"];
            
            NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            NSURL *imagePath = [[documentPath URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:binaryId];
            
            if ( [[NSFileManager defaultManager] fileExistsAtPath:[imagePath path]] ) {
                
                // load the image from the local image cache
                NSLog(@"Locally cached image found - loading...");
                cell.thumbnail.image = [UIImage imageWithContentsOfFile:[imagePath path]];
                
            } else {
                NSURL *remoteUrl = [NSURL URLWithString:[dataDict objectForKey:@"value"]];
                
                // download the image to the local cache
                NSLog(@"No locally cached image found - downloading...");
                NSData *imageData = [NSData dataWithContentsOfURL:remoteUrl];
                
                if (imageData == nil) {
                    
                    NSLog(@"Warning! Could not download image from S3. Tagging image as unavailable.");
                    
                    // write an empty image to the cache - it's missing
                    [[NSFileManager defaultManager] createFileAtPath:[imagePath path] contents:[NSData data] attributes:nil];
                    
                    cell.remainingTimeLabel.text = @"Card Missing!";
                    
                } else {
                    
                    NSLog(@"Downloaded image from S3 - storing in local cache.");
                    [imageData writeToURL:imagePath atomically:YES];
                    
                }
                
                cell.thumbnail.image = [UIImage imageWithContentsOfFile:[imagePath path]];
            }
        }
        
    } else {
        
        // there was no 'from offer' present so this offer must have originated with this user
        // therefore they are allowed to manipulate it

        cell.remainingTimeLabel.hidden = NO;
        cell.expireButton.hidden = NO;
        cell.reofferButton.hidden = NO;
        cell.readOnlyNotificationLabel.hidden = YES;

        double offerEnd = [[[cardDict objectForKey:@"lastOffer"] objectForKey:@"offerEnd"] doubleValue];
        NSDate *offerEndDate = [NSDate dateWithTimeIntervalSince1970:offerEnd / 1000];
        BOOL active = [offerEndDate compare:[NSDate date]] == NSOrderedDescending;
        
        cell.cardId = [cardDict objectForKey:@"id"];
        cell.lastOfferId = [[cardDict objectForKey:@"lastOffer"] objectForKey:@"id"];
        cell.active = active;

        // load data
        if ([dataArry isKindOfClass:[NSArray class]]) {
            
            NSDictionary *dataDict = [[cardDict objectForKey:@"data"] objectAtIndex:0];
            NSString *binaryId = [dataDict objectForKey:@"binaryId"];
            
            NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            NSURL *imagePath = [[documentPath URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:binaryId];
            
            if ( [[NSFileManager defaultManager] fileExistsAtPath:[imagePath path]] ) {
                
                // load the image from the local image cache
                NSLog(@"Locally cached image found - loading...");
                cell.thumbnail.image = [UIImage imageWithContentsOfFile:[imagePath path]];
                
                if (active) {
                    
                    NSLog(@"Offer is active (ends at %@) - setting UI to allow user to expire it.", [[Woosh woosh] dateAsDateTimeString:offerEndDate]);

                    cell.expireButton.hidden = NO;
                    cell.reofferButton.hidden = YES;
                    cell.backgroundColor = [UIColor colorWithRed:0 green:255 blue:0 alpha:0.05];

                    cell.offerEnd = offerEnd;
                    [[NSRunLoop mainRunLoop] addTimer:cell.timer forMode:NSRunLoopCommonModes];

                } else {
                    
                    NSLog(@"Offer is expired (ended at %@) - setting UI to allow user to re-offer it.", [[Woosh woosh] dateAsDateTimeString:offerEndDate]);
                    
                    cell.expireButton.hidden = YES;
                    cell.reofferButton.hidden = NO;
                    cell.backgroundColor = [UIColor colorWithRed:255 green:0 blue:0 alpha:0.05];

                    cell.remainingTimeLabel.text = @"No time remaining";
                    
                }
                
            } else {
                NSURL *remoteUrl = [NSURL URLWithString:[dataDict objectForKey:@"value"]];
                
                // download the image to the local cache
                NSLog(@"No locally cached image found - downloading...");
                NSData *imageData = [NSData dataWithContentsOfURL:remoteUrl];
                
                if (imageData == nil) {
                    
                    NSLog(@"Warning! Could not download image from S3. Tagging image as unavailable.");
                    
                    // write an empty image to the cache - it's missing
                    [[NSFileManager defaultManager] createFileAtPath:[imagePath path] contents:[NSData data] attributes:nil];
                    
                    cell.remainingTimeLabel.text = @"Card Missing!";
                    
                    cell.expireButton.hidden = YES;
                    cell.reofferButton.hidden = YES;
                    
                } else {
                    
                    NSLog(@"Downloaded image from S3 - storing in local cache.");
                    [imageData writeToURL:imagePath atomically:YES];
                    
                    if (active) {
                        
                        NSLog(@"Offer is active (ends at %@) - setting UI to allow user to expire it.", [[Woosh woosh] dateAsDateTimeString:offerEndDate]);
  
                        cell.expireButton.hidden = NO;
                        cell.reofferButton.hidden = YES;
                        cell.backgroundColor = [UIColor colorWithRed:0 green:255 blue:0 alpha:0.05];

                        cell.offerEnd = offerEnd;
                        [[NSRunLoop mainRunLoop] addTimer:cell.timer forMode:NSRunLoopCommonModes];

                    } else {
                        
                        NSLog(@"Offer is expired (ended at %@) - setting UI to allow user to re-offer it.", [[Woosh woosh] dateAsDateTimeString:offerEndDate]);

                        cell.expireButton.hidden = YES;
                        cell.reofferButton.hidden = NO;
                        cell.backgroundColor = [UIColor colorWithRed:255 green:0 blue:0 alpha:0.05];
                        
                        cell.remainingTimeLabel.text = @"No time remaining";
                        
                    }
                }
                
                cell.thumbnail.image = [UIImage imageWithContentsOfFile:[imagePath path]];
            }
        
        } else {
            
            cell.remainingTimeLabel.text = @"Card Missing!";

            cell.expireButton.hidden = YES;
            cell.reofferButton.hidden = YES;
            
        }
    }
    
    // if this is the last cell to make then stop animating the activity view
    if ( indexPath.row == [self.wooshCardsModel count] - 1 ) {
        [NSThread detachNewThreadSelector:@selector(threadStopAnimating:) toTarget:self withObject:nil];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    if (req_type == REQUEST_TYPE_NONE) {
        
        // do nothing
        
    } else if (req_type == REQUEST_TYPE_LIST_CARDS) {

        NSError *jsonErr = nil;
        self.wooshCardsModel = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                               options:NSJSONReadingMutableContainers
                                                                 error:&jsonErr];
        
        NSLog(@"%@", [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding]);
        
        if ([self.wooshCardsModel count] == 0) {
            [NSThread detachNewThreadSelector:@selector(threadStopAnimating:) toTarget:self withObject:nil];            
        }
        
        [self.wooshCardTableView reloadData];

    } else if (req_type == REQUEST_TYPE_DELETE_CARD) {
        
        // refresh the list of card from the servers
        req_type = REQUEST_TYPE_LIST_CARDS;
        [[Woosh woosh] getCards:self];

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
    
    UIAlertView *connectionAlert = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                              message:@"We hit a glitch! But we are sure that it is temporary, so please try again soon."
                                                             delegate:nil
                                                    cancelButtonTitle:@"Bummer"
                                                    otherButtonTitles:nil];
    [connectionAlert show];    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
