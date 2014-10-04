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
//  TODO
//      Move retrieving activities to client

#import "ActivitiesListViewController.h"
#import "ActivityCell.h"
#import "ActivityDetailViewController.h"

@interface ActivitiesListViewController ()
@property (weak, nonatomic) IBOutlet UITableView *activitiesTableView;
@property (strong, nonatomic) NSMutableArray *activities;
@end

NSString *const RIDE = @"Ride";
NSString *const CELL_IDENTIFIER = @"ActivityCell";

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
    cell.activityName.text = self.activities[indexPath.row][@"name"];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.activitiesTableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ActivityDetailViewController *activityDetailViewController = [[ActivityDetailViewController alloc] init];
    [self.navigationController pushViewController:activityDetailViewController animated:YES];
}

- (void) getActivitiesWithType:(NSString *)type {
    NSString *url = @"https://www.strava.com/api/v3/activities?per_page=200&access_token=";
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (connectionError) {
            
        }
        else {
            id allActivities = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            
            // put riding activities in activities array
            for (id activity in allActivities) {
                NSString *activityType = activity[@"type"];
                if ([activityType isEqualToString:RIDE]) {
                    NSLog(@"%@", activity);
                    [self.activities addObject:activity];
                }
            }
            
            [self.activitiesTableView reloadData];
        }
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
