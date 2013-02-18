//
//  WooshCardTableViewCell.h
//  woosh-photo-app
//
//  Created by Ben on 18/02/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WooshCardTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *thumbnail;
@property (nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;

- (IBAction) reofferButtonTapped:(id)sender;
- (IBAction) expireOfferButtonTapped:(id)sender;

@end
