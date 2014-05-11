//
//  WooshPhotoCollectionViewCell.h
//  woosh-photo-app
//
//  Created by Ben on 03/05/2014.
//  Copyright (c) 2014 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WooshPhotoCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *thumbnail;
@property (nonatomic, weak) IBOutlet UILabel *offerCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *remainingTimeLabel;

@end
