//
//  WooshPhotoCollectionViewCell.m
//  woosh-photo-app
//
//  Created by Ben on 03/05/2014.
//  Copyright (c) 2014 Luminos. All rights reserved.
//

#import "WooshPhotoCollectionViewCell.h"

@implementation WooshPhotoCollectionViewCell

@synthesize thumbnail;
@synthesize offerCountLabel;
@synthesize remainingTimeLabel;


- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) remainingTimeDidTick:(NSTimer*) theTimer {
    NSDate *offerEndDate = [NSDate dateWithTimeIntervalSince1970:self.offerEnd / 1000];
    NSTimeInterval interval = [offerEndDate timeIntervalSinceNow];
    NSInteger time = interval;
    
    if (time <= 0) {
        
        // stop the timer
        [self.timer invalidate];
        [theTimer invalidate];
        
        [self.parentView refreshCards];
        
    } else {
        self.remainingTimeLabel.text = [NSString stringWithFormat:@"%d:%02d", (int)time / 60, (int)time % 60];
    }
    
}

-(BOOL) isOffered {
    NSDate *offerEndDate = [NSDate dateWithTimeIntervalSince1970:self.offerEnd / 1000];
    NSTimeInterval interval = [offerEndDate timeIntervalSinceNow];
    NSInteger time = interval;
    
    return time > 0;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
