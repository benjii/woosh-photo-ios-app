//
//  SettingsViewController.h
//  woosh-photo-app
//
//  Created by Ben on 30/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController<UIAlertViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *invitationKeyLabel;
@property (strong, nonatomic) IBOutlet UIButton *signOutButton;

-(IBAction) signOutButtonTapped:(id)sender;
-(IBAction) viewEulaButtonTapped:(id)sender;

@end
