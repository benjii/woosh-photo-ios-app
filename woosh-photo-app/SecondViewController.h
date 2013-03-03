//
//  SecondViewController.h
//  woosh-photo-app
//
//  Created by Ben on 01/01/2013.
//  Copyright (c) 2013 Luminos. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SecondViewController : UIViewController<UITableViewDataSource, UITabBarDelegate, NSURLConnectionDataDelegate>

@property (strong, nonatomic) IBOutlet UITableView *wooshCardTableView;

@property NSMutableData *receivedData;
@property NSArray *wooshCardsModel;

- (IBAction) refreshButtonTapped:(id)sender;

@end
