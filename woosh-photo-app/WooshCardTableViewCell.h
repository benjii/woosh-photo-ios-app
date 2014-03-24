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
@property (nonatomic, strong) NSString *lastOfferId;
@property (nonatomic) BOOL active;


//@property (nonatomic, strong) UITableView *parent;

@property NSMutableData *receivedData;

- (IBAction) expireButtonTapped:(id)sender;
- (IBAction) reofferButtonTapped:(id)sender;

@end
