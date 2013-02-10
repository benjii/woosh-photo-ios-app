//
//  SignupViewController.h
//  woosh-photo-app
//
//  Created by Ben on 27/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupViewController : UIViewController

@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UITextField *confirmPasswordField;
@property (strong, nonatomic) IBOutlet UITextField *emailField;
@property (strong, nonatomic) IBOutlet UITextField *invitationKeyField;


- (IBAction) cancelTapped:(id)sender;
- (IBAction) signupTapped:(id)sender;

@end
