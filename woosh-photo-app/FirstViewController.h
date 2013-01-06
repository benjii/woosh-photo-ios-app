//
//  FirstViewController.h
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FirstViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scanOrClearButton;

-(IBAction) selectPhotographButtonTapped:(id)sender;
-(IBAction) scanOrClearPhoto:(id)sender;

-(void) makeOffer:(id)sender;

@end
