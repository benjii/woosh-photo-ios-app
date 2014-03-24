//
//  ViewPhotoViewController.h
//  woosh-photo-app
//
//  Created by Ben on 24/03/2014.
//  Copyright (c) 2014 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewPhotoViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic) UIImage *photograph;

- (IBAction) closeButtonTapped:(id)sender;

@end
