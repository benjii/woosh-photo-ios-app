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

@synthesize receivedData;
@synthesize wooshCardsModel;


// request type constants
static const int REQUEST_TYPE_NONE = -1;

static const int REQUEST_TYPE_LIST_CARDS = 0;
static const int REQUEST_TYPE_DELETE_CARD = 1;

int req_type = REQUEST_TYPE_NONE;


- (void)viewDidLoad {
    [super viewDidLoad];
    
	// Do any additional setup after loading the view, typically from a nib.
    
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // initialise the buffer to hold server response data
    self.receivedData = [NSMutableData data];
    
    // retrieve the full set of user cards from the Woosh servers
    req_type = REQUEST_TYPE_LIST_CARDS;

    NSURLConnection * conn = [[Woosh woosh] getCards:self];
    [conn start];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (IBAction) refreshButtonTapped:(id)sender {

    // initialise the buffer to hold server response data
    self.receivedData = [NSMutableData data];

    // retrieve the full set of user cards from the Woosh servers
    req_type = REQUEST_TYPE_LIST_CARDS;
    
    NSURLConnection * conn = [[Woosh woosh] getCards:self];
    [conn start];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *wooshCardTableIdentifier = @"WooshCardTableItem";
    
    WooshCardTableViewCell *cell = (WooshCardTableViewCell *) [tableView dequeueReusableCellWithIdentifier:wooshCardTableIdentifier];
    
    if (cell == nil) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"WooshCardTableViewCell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    
    // reset the cell
    cell.expireReofferButton.titleLabel.text = @"";

    // to populate the cell we;
    //    1. look in persistent storage for the image (if not found then download it)
    //    2. determine if the card is on offer (by looking at the offer end time)
    //    3. if the offer is expired then show the 're-offer' button
    //    4. if the offer is not expired then show the 'expire' button, which will immediately invalidate the offer
    
    NSDictionary *cardDict = [self.wooshCardsModel objectAtIndex:indexPath.row];
    id dataArry = [cardDict objectForKey:@"data"];
    
    // determine if the card is currently under offer
    NSDate *offerEnd = [NSDate dateWithTimeIntervalSince1970:[[cardDict objectForKey:@"lastOfferEnd"] doubleValue] / 1000];
    BOOL active = [offerEnd compare:[NSDate date]] == NSOrderedDescending;

    cell.cardId = [cardDict objectForKey:@"id"];
    cell.lastOfferId = [cardDict objectForKey:@"lastOfferId"];
    cell.active = active;

    if ([dataArry isKindOfClass:[NSArray class]]) {

        NSDictionary *dataDict = [[cardDict objectForKey:@"data"] objectAtIndex:0];
        NSString *binaryId = [dataDict objectForKey:@"binaryId"];
   
        NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *imagePath = [[documentPath URLByAppendingPathComponent:@"images"] URLByAppendingPathComponent:binaryId];
        
        if ( [[NSFileManager defaultManager] fileExistsAtPath:[imagePath path]] ) {
            
            // load the image from the local image cache
            NSLog(@"Locally cached image found - loading...");
            cell.thumbnail.image = [UIImage imageWithContentsOfFile:[imagePath path]];
            
            cell.expireReofferButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            if (active) {
                
                NSLog(@"Offer is active (ends at %@) - setting UI to allow user to expire it.", [[Woosh woosh] dateAsDateTimeString:offerEnd]);
                cell.expireReofferButton.titleLabel.text = @"Expire";
            
                NSTimeInterval interval = [offerEnd timeIntervalSinceNow];
                NSInteger time = interval;
                cell.remainingTimeLabel.text = [NSString stringWithFormat:@"%d:%02d remaining for offer", time / 60, time % 60];
                
            } else {
                
                NSLog(@"Offer is expired (ended at %@) - setting UI to allow user to re-offer it.", [[Woosh woosh] dateAsDateTimeString:offerEnd]);
                cell.expireReofferButton.titleLabel.text = @"Re-offer";
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
                
                cell.expireReofferButton.enabled = NO;
                cell.expireReofferButton.titleLabel.textAlignment = NSTextAlignmentCenter;
                cell.expireReofferButton.titleLabel.text = @"Unavailable";
                
            } else {
                
                NSLog(@"Downloaded image from S3 - storing in local cache.");
                [imageData writeToURL:imagePath atomically:YES];
                
                cell.expireReofferButton.titleLabel.textAlignment = NSTextAlignmentCenter;
                if (active) {
                    
                    NSLog(@"Offer is active (ends at %@) - setting UI to allow user to expire it.", [[Woosh woosh] dateAsDateTimeString:offerEnd]);
                    cell.expireReofferButton.titleLabel.text = @"Expire";
                
                    NSTimeInterval interval = [offerEnd timeIntervalSinceNow];
                    NSInteger time = interval;
                    cell.remainingTimeLabel.text = [NSString stringWithFormat:@"%d:%d remaining for offer", time / 60, time % 60];

                } else {
                    
                    NSLog(@"Offer is expired (ended at %@) - setting UI to allow user to re-offer it.", [[Woosh woosh] dateAsDateTimeString:offerEnd]);
                    cell.expireReofferButton.titleLabel.text = @"Re-offer";
                    cell.remainingTimeLabel.text = @"No time remaining";

                }
                
            }
            
            cell.thumbnail.image = [UIImage imageWithContentsOfFile:[imagePath path]];
        }

    } else {

        cell.remainingTimeLabel.text = @"Card Missing!";
        
        cell.expireReofferButton.enabled = NO;
        cell.expireReofferButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        cell.expireReofferButton.titleLabel.text = @"Unavailable";

    }
        
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
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
