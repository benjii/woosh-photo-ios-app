//
//  WooshCardTableViewCell.h
//  woosh-photo-app
//
//  Created by Ben on 18/02/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SecondViewController.h"

@interface WooshCardTableViewCell : UITableViewCell<NSURLConnectionDataDelegate>

@property (nonatomic, weak) IBOutlet SecondViewController *parentView;

@property (nonatomic, weak) IBOutlet UIImageView *thumbnail;
@property (nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;

@property (nonatomic, weak) IBOutlet UIButton *expireButton;
@property (nonatomic, weak) IBOutlet UIButton *reofferButton;

@property (nonatomic, weak) IBOutlet UILabel *readOnlyNotificationLabel;

@property (nonatomic, strong) NSString *cardId;
@property (nonatomic) BOOL active;

// set if the user owns this offer - this is the ID for the last offer made
@property (nonatomic, strong) NSString *lastOfferId;

// set if the offer came from another user
@property (nonatomic, strong) NSString *fromOfferId;

@property (nonatomic) double offerEnd;
@property (nonatomic) NSTimer *timer;


//@property (nonatomic, strong) UITableView *parent;

@property NSMutableData *receivedData;

- (IBAction) expireButtonTapped:(id)sender;
- (IBAction) reofferButtonTapped:(id)sender;

@end
