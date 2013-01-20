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


@interface FirstViewController : UIViewController<UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate, NSURLConnectionDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UIToolbar *mainToolbar;

//@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraItem;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *wooshLabel;
//@property (weak, nonatomic) IBOutlet UIBarButtonItem *clearItem;

@property (weak, nonatomic) IBOutlet UIButton *offerButton;

@property NSMutableData *receivedData;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CMMotionManager *motionManager;

@property (strong, nonatomic) NSMutableArray *lastDeviceMotions;

-(IBAction) selectPhotographButtonTapped:(id)sender;
-(IBAction) scanOrClearPhoto:(id)sender;

-(void) makeOffer:(id)sender;

@end
