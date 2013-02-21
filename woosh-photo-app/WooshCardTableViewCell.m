//
//  WooshCardTableViewCell.m
//  woosh-photo-app
//
//  Created by Ben on 18/02/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "WooshCardTableViewCell.h"

@implementation WooshCardTableViewCell

@synthesize thumbnail = _thumbnail;
@synthesize remainingTimeLabel = _remainingTimeLabel;
@synthesize expireReofferButton = _expireReofferButton;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction) expireReofferButtonTapped:(id)sender; {

}

@end
