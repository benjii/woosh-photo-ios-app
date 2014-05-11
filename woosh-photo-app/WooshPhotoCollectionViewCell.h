//
//  WooshPhotoCollectionViewCell.h
//  woosh-photo-app
//
//  Created by Ben on 03/05/2014.
//  Copyright (c) 2014 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WooshPhotosCollectionViewController.h"

@interface WooshPhotoCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet id parentView;

@property (nonatomic, weak) IBOutlet UIImageView *thumbnail;
@property (nonatomic, weak) IBOutlet UILabel *offerCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;

// the ID of the card that is bwing shown
@property (nonatomic, strong) NSString *cardId;

// indicates whether the card is active (offered) or not
@property (nonatomic) BOOL active;

// if active, when the offer is due to end
@property (nonatomic) double offerEnd;

// set if the user owns this offer - this is the ID for the last offer made
@property (nonatomic, strong) NSString *lastOfferId;

// set if the offer came from another user
@property (nonatomic, strong) NSString *fromOfferId;

// a timer to show the offer time ticking down
@property (nonatomic) NSTimer *timer;

@end
