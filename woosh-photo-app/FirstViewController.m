//
//  FirstViewController.m
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "FirstViewController.h"
#import "Woosh.h"

@interface FirstViewController ()

@end

static const int MODE_OFFER = 0;
static const int MODE_ACCEPT = 1;

int mode = MODE_ACCEPT;


@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if (TARGET_IPHONE_SIMULATOR)
    // if we are running in the simiulator then overlay an 'offer' button on the UIImage view
    UIButton *offerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [offerButton setTitle:@"Offer" forState:UIControlStateNormal];
    [offerButton setFrame:CGRectMake(230, 410, 80, 33)];
    [offerButton addTarget:self action:@selector(makeOffer:) forControlEvents:UIControlEventTouchUpInside];

    [self.imgView addSubview:offerButton];
#endif
    
    // ensure that the view is initialised correctly
    mode = MODE_ACCEPT;
    self.scanOrClearButton.title = @"Scan";
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];

    self.imgView.contentMode = UIViewContentModeScaleAspectFit;
    self.imgView.image = chosenImage;
    
    // set the mode to 'offer' - the user has a photo selected and can make an offer
    mode = MODE_OFFER;
    self.scanOrClearButton.title = @"Clear";
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) makeOffer:(id)sender {
    
    // convert the raw image data into a PNG (use JPEG instead?)
    NSData *jpeg = UIImagePNGRepresentation(self.imgView.image);
    
    // call the Woosh API to make the offer
    BOOL result = [[Woosh woosh] offerWithPhoto:@"default" photograph:jpeg];

    if (result == YES) {
        UIAlertView *confirmationAlert = [[UIAlertView alloc] initWithTitle:@"Offer Made"
                                                                     message:@"Your offer is now available."
                                                                    delegate:nil
                                                           cancelButtonTitle:@"OK"
                                                           otherButtonTitles:nil];
        [confirmationAlert show];

        // now that the offer has been made, reset the UI to be in accept mode
        self.imgView.image = nil;
        
        // the user cleared the offer - move to 'accept' mode
        mode = MODE_ACCEPT;
        self.scanOrClearButton.title = @"Scan";

    }
}

-(IBAction) selectPhotographButtonTapped:(id)sender {
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
    
        // the user can select from either the gallery of existing images, or take a new photo with the camera
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera or Gallery?"
                                                        message:@"Would you like to choose from your gallery or take a new photo with the camera?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Camera", @"Gallery", nil];

        [alert show];
    
    } else {

        // the only option that the user has is to select from the gallery
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [picker setDelegate:self];
        
        [self presentViewController:picker animated:YES completion:nil];
        
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (buttonIndex == 1) {
        
        // the user chose camera
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
        [picker setDelegate:self];
        
        [self presentViewController:picker animated:YES completion:nil];
        
    } else if (buttonIndex == 2) {
        
        // the user chose gallery
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        [picker setDelegate:self];
        
        [self presentViewController:picker animated:YES completion:nil];

    } else {
        
        // user cancelled the action
        
    }
    
}

-(IBAction) scanOrClearPhoto:(id)sender {
    
    if (mode == MODE_OFFER) {
    
        self.imgView.image = nil;
        
        // the user cleared the offer - move to 'accept' mode
        mode = MODE_ACCEPT;
        self.scanOrClearButton.title = @"Scan";

    } else {
        
        // TODO scan for offers in the local geographic region
        NSArray *availableOffers = [[Woosh woosh] scan];
        
        NSLog(@"%@", availableOffers);
        
    }
    
}

@end
