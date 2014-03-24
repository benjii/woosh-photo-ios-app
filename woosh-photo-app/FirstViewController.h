//
//  FirstViewController.h
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <CoreMotion/CoreMotion.h>
#import <CoreLocation/CoreLocation.h>

#import "AppDelegate.h"


@interface FirstViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate, NSURLConnectionDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

// note that all six bar buttons below must be marked as 'strong' so that they are not auto-dereferenced
// when we remove them from the items array of the main toolbar

// toolbar buttons that are displayed when in 'scan' mode
@property (strong, nonatomic) UIBarButtonItem *scanButton;
@property (strong, nonatomic) UIBarButtonItem *cameraButton;

// toolbar buttons that are displayed when in 'offer' mode
@property (strong, nonatomic) UIBarButtonItem *clearButton;
@property (strong, nonatomic) UIBarButtonItem *offerButton;

// toolbar items that are always displayed
//@property (strong, nonatomic) IBOutlet UIBarButtonItem *flexibleSpace;
//@property (strong, nonatomic) IBOutlet UIBarButtonItem *wooshLabel;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
//@property (weak, nonatomic) IBOutlet UIToolbar *mainToolbar;

@property NSMutableData *receivedData;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CMMotionManager *motionManager;

@property (strong, nonatomic) NSMutableArray *lastDeviceMotions;

-(IBAction) selectPhotographButtonTapped:(id)sender;
-(IBAction) scanForOffers:(id)sender;
-(IBAction) clearPhoto:(id)sender;

-(IBAction) makeOffer:(id)sender;

@end
