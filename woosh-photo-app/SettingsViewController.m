//
//  SettingsViewController.m
//  woosh-photo-app
//
//  Created by Ben on 30/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "SettingsViewController.h"
#import "Woosh.h"


@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // display the user's invitation key (so that they can share it with others)
    self.invitationKeyLabel.text = [[[Woosh woosh] systemProperties] objectForKey:@"invitationKey"];

    // set up the 'sign out' button
    [self.signOutButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"]
                                            stretchableImageWithLeftCapWidth:8.0f
                                            topCapHeight:0.0f]
                                  forState:UIControlStateNormal];
    
    [self.signOutButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.signOutButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];
    self.signOutButton.titleLabel.shadowColor = [UIColor lightGrayColor];
    self.signOutButton.titleLabel.shadowOffset = CGSizeMake(0, -1);
    
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

-(IBAction) signOutButtonTapped:(id)sender {
    UIAlertView *confirmSignOutAlert = [[UIAlertView alloc] initWithTitle:@"Are You Sure?"
                                                                  message:@"You are about to sign out. If you sign out then you will be prompted for your login credentials again the next time that you use Woosh."
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                         otherButtonTitles:@"Sign Out", nil];
    
    [confirmSignOutAlert show];
}

-(IBAction) viewEulaButtonTapped:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://woosh.io/eula"]];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex == 1) {

        // when the user signs out two things happen;
        //    1. the device persistent authentication details are deleted
        //    2. the user is pushed back to the login screen
        
        NSURL *documentPath = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        NSURL *systemPropertiesPath = [documentPath URLByAppendingPathComponent:@"woosh.plist"];
        
        [[NSFileManager defaultManager] removeItemAtURL:systemPropertiesPath error:nil];
        [[Woosh woosh] setSystemProperties:[NSMutableDictionary dictionary]];
        
        [self.tabBarController setSelectedIndex:0];

    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
