//
//  WooshCardTableViewCell.m
//  woosh-photo-app
//
//  Created by Ben on 18/02/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "WooshCardTableViewCell.h"
#import "Woosh.h"

@implementation WooshCardTableViewCell

@synthesize thumbnail = _thumbnail;
@synthesize remainingTimeLabel = _remainingTimeLabel;
@synthesize expireButton = _expireButton;
@synthesize reofferButton = _reofferButton;
@synthesize parentView = _parentView;
@synthesize timer = _timer;

@synthesize cardId;
@synthesize lastOfferId;
@synthesize active;

@synthesize receivedData;

static const int REQUEST_TYPE_NONE = -1;

static const int REQUEST_TYPE_MAKE_OFFER = 0;
static const int REQUEST_TYPE_EXPIRE_OFFER = 1;

int cell_request_type = REQUEST_TYPE_NONE;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
//        self.receivedData = [NSData data];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction) expireButtonTapped:(id)sender {
    self.receivedData = [NSMutableData data];
    
    // expire the current offer on the card
    cell_request_type = REQUEST_TYPE_EXPIRE_OFFER;
    [[Woosh woosh] expireOffer:self.lastOfferId delegate:self];
}

- (IBAction) reofferButtonTapped:(id)sender {
    self.receivedData = [NSMutableData data];
    
    // re-offer the card
    cell_request_type = REQUEST_TYPE_MAKE_OFFER;
    [[Woosh woosh] makeOffer:cardId latitude:[[Woosh woosh] latitude] longitude:[[Woosh woosh] longitude] delegate:self];
}

// everything below here is for handling the connection
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {

    // the offer is now expired, so update this cell to reflect that
    if (cell_request_type == REQUEST_TYPE_EXPIRE_OFFER) {
        
        [self.timer invalidate];
        self.remainingTimeLabel.text = @"Offer Is Expired";

    } else if (cell_request_type == REQUEST_TYPE_MAKE_OFFER) {
        
        NSError *error = nil;
        NSDictionary *respDict = [NSJSONSerialization JSONObjectWithData:self.receivedData
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&error];
        
        
        NSString *newOfferId = [respDict objectForKey:@"id"];
        
        if (newOfferId != nil) {
            UIAlertView *confirmationAlert = [[UIAlertView alloc] initWithTitle:@"Success!"
                                                                        message:@"Your card has been re-offered."
                                                                       delegate:nil
                                                              cancelButtonTitle:@"Sweet!"
                                                              otherButtonTitles:nil];
            [confirmationAlert show];
        }
    }

    [self.parentView refreshCards];
    
}

- (void) remainingTimeDidTick:(NSTimer*) theTimer {
    NSDate *offerEndDate = [NSDate dateWithTimeIntervalSince1970:self.offerEnd / 1000];
    NSTimeInterval interval = [offerEndDate timeIntervalSinceNow];
    NSInteger time = interval;
    
    if (time <= 0) {
        
        // stop the timer
        [self.timer invalidate];
        [self.parentView refreshCards];
        
    } else {
        self.remainingTimeLabel.text = [NSString stringWithFormat:@"%d:%02d remaining for offer", (int)time / 60, (int)time % 60];
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
                                                              message:@"We tried to expire your offer on the Woosh servers but we were unable to at this time. But we are sure that this is a temporary glitch, so please try again soon."
                                                             delegate:nil
                                                    cancelButtonTitle:@"Bummer"
                                                    otherButtonTitles:nil];
    [connectionAlert show];
    
}

@end
