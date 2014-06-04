//
//  WooshPhotosCollectionViewController.h
//  woosh-photo-app
//
//  Created by Ben on 03/05/2014.
//  Copyright (c) 2014 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "WooshPhotoCollectionViewCell.h"


@interface WooshPhotosCollectionViewController : UICollectionViewController<NSURLConnectionDelegate, CLLocationManagerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingCardsActivityView;

@property NSMutableData *receivedData;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property NSArray *cards;
@property NSCache *imageCache;
@property NSIndexPath *selectedPath;

@property NSInteger expireButtonIndex;
@property NSInteger deleteButtonIndex;
@property NSInteger reofferButtonIndex;

- (void) refreshCards;
//- (void) scanForOffers:(id)sender;

-(IBAction) helpButtonTapped:(id)sender;
-(IBAction) selectPhotographButtonTapped:(id)sender;

@end
