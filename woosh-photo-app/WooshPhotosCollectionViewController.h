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


@interface WooshPhotosCollectionViewController : UICollectionViewController<NSURLConnectionDelegate, CLLocationManagerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *loadingCardsActivityView;

@property NSMutableData *receivedData;
@property (strong, nonatomic) CLLocationManager *locationManager;

@property NSArray *cards;

- (void) refreshCards;
- (void) scanForOffers:(id)sender;

-(IBAction) selectPhotographButtonTapped:(id)sender;

@end
