//
//  ActivitiesListViewController.m
//  ReRIDE
//
//  Created by Eugenia Leong on 10/3/14.
//  Copyright (c) 2014 Eugenia Leong. All rights reserved.
//
//  10/3/14 1 hour:
//      Set up ActivitiesListViewController
//      Got cycling activities
//      Display cycling activities in tableView
//      Push detail view controller when cell selected
//  10/4/14 5 hours:
//      Retrieve cycling stream (velocity and cadence)
//      Create primitive graphics and animation
//      Move API calls to client
//      Add autolayout constraints in DetailView
//  10/5/14 3 hours?
//      Start animation after retrieving both velocity and cadence data
//      Fix rotation
//      Added more ride data to cell
//      Created StravaActivity model
//  10/6/14 1 hour
//      Double check speed and cadence animation
//      Added some error messages
// 10/8/14 2 hours
//      Fix rotation
// 10/9/14
//      Played around with speed animation. Tried using animateWithDuration, so roadSegments don't bump into each other.
//      Fix bug in status messages
//  TODO
//      Authorization
//      Improve speed animation

#import "ActivitiesListViewController.h"
#import "ActivityCell.h"
#import "ActivityDetailViewController.h"
#import "StravaClient.h"
#import "StravaActivity.h"
#import "MBProgressHUD.h"

@interface ActivitiesListViewController ()
@property (weak, nonatomic) IBOutlet UITableView *activitiesTableView;
@property (strong, nonatomic) NSMutableArray *activities;
@property (strong, nonatomic) StravaClient *client;

@end

NSString *const RIDE = @"Ride";
NSString *const CELL_IDENTIFIER = @"ActivityCell";
MBProgressHUD *statusHud;

@implementation ActivitiesListViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.activities = [[NSMutableArray alloc] init];
        self.title = @"My Cycling Activities";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.activitiesTableView.dataSource = self;
    self.activitiesTableView.delegate = self;
    
    UINib *customNib = [UINib nibWithNibName:CELL_IDENTIFIER bundle:nil];
    [self.activitiesTableView registerNib:customNib forCellReuseIdentifier:CELL_IDENTIFIER];
    
    [self getActivitiesWithType:RIDE];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.activities count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];
    id activity = self.activities[indexPath.row];
    cell.activityName.text = activity[@"name"];
    NSString *averageSpeed = [NSString stringWithFormat:@"%@", activity[@"average_speed"]];
    cell.averageSpeed.text = [StravaActivity msToMphStr:[averageSpeed floatValue]];
    if (activity[@"average_cadence"]) {
        NSString *averageCadence = [NSString stringWithFormat:@"%@", activity[@"average_cadence"]];
        cell.averageCadence.text = [NSString stringWithFormat:@"%d", [averageCadence intValue]];
    }
    else {
        cell.averageCadence.text = @"--";
    }

    return cell;
}

- (float)msToMph:(float)number {
    return number*2.23694;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 90;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.activitiesTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *activityId = self.activities[indexPath.row][@"id"];
    NSString *activityName = self.activities[indexPath.row][@"name"];
    //NSLog(@"%@", activityId);
    ActivityDetailViewController *activityDetailViewController = [[ActivityDetailViewController alloc] initWithActivityId:activityId activityName:activityName];
    [self.navigationController pushViewController:activityDetailViewController animated:YES];
}

- (void) getActivitiesWithType:(NSString *)type {
    
    statusHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    statusHud.mode = MBProgressHUDModeIndeterminate;
    statusHud.labelText = @"Retrieving activities";
    
    self.client = [StravaClient instance];//[[StravaClient alloc] init];
    
    [self.client getAllActivitiesByType:type success:^(AFHTTPRequestOperation *operation, id response) {
        
        [statusHud hide:YES];
        // put riding activities in activities array
        for (id activity in response) {
            NSString *activityType = activity[@"type"];
            if ([activityType isEqualToString:RIDE]) {
                //NSLog(@"%@", activity);
                [self.activities addObject:activity];
            }
        }
        
        [self.activitiesTableView reloadData];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", [error description]);
    }];
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
