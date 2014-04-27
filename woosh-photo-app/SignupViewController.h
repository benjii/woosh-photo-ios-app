//
//  SignupViewController.h
//  woosh-photo-app
//
//  Created by Ben on 27/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupViewController : UIViewController<UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UINavigationBar *navigationBar;

@property (strong, nonatomic) IBOutlet UITextField *usernameField;
@property (strong, nonatomic) IBOutlet UITextField *passwordField;
@property (strong, nonatomic) IBOutlet UITextField *confirmPasswordField;
@property (strong, nonatomic) IBOutlet UITextField *emailField;
@property (strong, nonatomic) IBOutlet UITextField *invitationKeyField;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *signupButton;

@property (strong, nonatomic) IBOutlet UILabel *remainingSlotsLabel;
@property (strong, nonatomic) IBOutlet UILabel *invitationOnlyWarningLabel;


- (IBAction) cancelTapped:(id)sender;
- (IBAction) signupTapped:(id)sender;
- (IBAction) viewEulaTapped:(id)sender;

- (IBAction) helpUsernameTapped:(id)sender;
- (IBAction) helpPasswordTapped:(id)sender;
- (IBAction) helpOtherTapped:(id)sender;

@property NSMutableData *receivedData;


@end
