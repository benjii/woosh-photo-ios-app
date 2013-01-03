//
//  FirstViewController.m
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import "FirstViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    self.imgView.image = chosenImage;
    
    [self dismissViewControllerAnimated:YES completion:nil];

    NSLog(@"");
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


//-(IBAction) takeWithCameraButtonClicked:(id)sender {
//    
//    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//
//        // set up the image picker
//        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//        [picker setSourceType:UIImagePickerControllerSourceTypeCamera];
//        [picker setDelegate:self];
//        
//        [self presentViewController:picker animated:YES completion:nil];
//        
//    } else {
//    
//        // slert the user that their device does not have photographic capability
//        [[[UIAlertView alloc] initWithTitle:@"No Camera" message:@"Your device does not have photographic capability." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
//
//    }
//    
//}

-(IBAction) clearPhoto:(id)sender {
    self.imgView.image = nil;
}

@end
