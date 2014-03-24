//
//  ViewPhotoViewController.m
//  woosh-photo-app
//
//  Created by Ben on 24/03/2014.
//  Copyright (c) 2014 Luminos. All rights reserved.
//

#import "ViewPhotoViewController.h"

@interface ViewPhotoViewController ()

@end

@implementation ViewPhotoViewController

@synthesize photograph;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
 
    [self.imageView setImage:self.photograph];
}

- (IBAction) closeButtonTapped:(id)sender {
    [self.imageView setImage:nil];
    [self dismissViewControllerAnimated:YES completion:^{ }];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
