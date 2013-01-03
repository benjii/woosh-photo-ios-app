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

-(IBAction) selectPhotographButtonTapped:(id)sender;
//-(IBAction) takeWithCameraButtonClicked:(id)sender;

-(IBAction) clearPhoto:(id)sender;

@end
