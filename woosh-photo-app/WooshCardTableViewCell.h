//
//  WooshCardTableViewCell.h
//  woosh-photo-app
//
//  Created by Ben on 18/02/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WooshCardTableViewCell : UITableViewCell<NSURLConnectionDataDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *thumbnail;
@property (nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;
@property (nonatomic, weak) IBOutlet UIButton *expireReofferButton;

@property (nonatomic, strong) NSString *cardId;
@property (nonatomic, strong) NSString *lastOfferId;
@property (nonatomic) BOOL active;


//@property (nonatomic, strong) UITableView *parent;

@property NSMutableData *receivedData;

- (IBAction) expireReofferButtonTapped:(id)sender;

@end
