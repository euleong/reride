//
//  ActivityDetailViewController.m
//  ReRIDE
//
//  Created by Eugenia Leong on 10/3/14.
//  Copyright (c) 2014 Eugenia Leong. All rights reserved.
//

#import "ActivityDetailViewController.h"
#import "StravaClient.h"

@interface ActivityDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *rpm;
@property (weak, nonatomic) IBOutlet UILabel *mph;
@property (weak, nonatomic) NSString *activityId;
@property (strong, nonatomic) NSArray * cadenceData;
@property (strong, nonatomic) NSArray * velocityData;
@property (weak, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UIView *circle;
@property (strong, nonatomic) StravaClient *client;

// animation stuff
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIDynamicItemBehavior *roadBehavior;
@property (strong, nonatomic) UIDynamicItemBehavior *pedalBehavior;
@end

NSString *const CADENCE = @"cadence";
NSString *const VELOCITY = @"velocity_smooth";
int const CIRCLE_DIAMETER = 100;
int const INNER_CIRCLE_DIAMETER = 40;

// to keep track of which index in cadenceData and velocityData we're at
int dataIndex = 0;

@implementation ActivityDetailViewController

- (id)initWithActivityId:(NSString *)activityId activityName:(NSString*)activityName {
    self = [super init];
    if (self) {
        self.activityId = activityId;
        
        self.title = activityName;
        self.client = [[StravaClient alloc] init];
    }
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self createScene];
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.roadBehavior = [[UIDynamicItemBehavior alloc] init];
    [self.animator addBehavior:self.roadBehavior];
    
    // should only start animating when we get both of these results
    [self getActivityCadence];
    [self getActivityVelocity];

}

- (void)viewWillDisappear:(BOOL)animated {
    [self.timer invalidate];
    // so views don't appear over activities list
    [self.view.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
}

- (void)createScene {
    // create road
    UIView *road = [[UIView alloc]
                    initWithFrame:CGRectMake(0,
                                             self.view.frame.size.height/2,
                                             self.view.frame.size.width, 10)];
    road.backgroundColor = [UIColor blackColor];
    [self.view addSubview:road];
    
    // create primitive crankset/pedals
    CGRect rect = CGRectMake(self.view.frame.size.width/2 - (CIRCLE_DIAMETER*0.5),
                             self.view.frame.size.height/4,CIRCLE_DIAMETER,CIRCLE_DIAMETER);
    self.circle = [[UIView alloc]
                   initWithFrame:rect];
    self.circle.layer.cornerRadius = 50;
    self.circle.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.circle];
    
    UIView *spot = [[UIView alloc]
                    initWithFrame:CGRectMake(self.circle.frame.size.width/2,
                                             self.circle.frame.size.height/2,
                                             INNER_CIRCLE_DIAMETER,INNER_CIRCLE_DIAMETER)];
    spot.layer.cornerRadius = 50;
    spot.backgroundColor = [UIColor blueColor];
    [self.circle addSubview:spot];
}

- (void)updateView {
    // finish animating
    if (dataIndex >= [self.velocityData count]) {
        [self.timer invalidate];
        return;
    }
    
    // make view representing the road segments
    
    UIView *roadSegment = [[UIView alloc]
                           initWithFrame:CGRectMake(self.view.frame.size.width,
                                                    self.view.frame.size.height/2,
                                                    self.view.frame.size.width, 10)];
    if (dataIndex%2 == 0) {
        roadSegment.backgroundColor = [UIColor grayColor];
    }
    else {
        roadSegment.backgroundColor = [UIColor blackColor];
    }
    roadSegment.clipsToBounds = YES;
    [self.view addSubview:roadSegment];
    
    [self.roadBehavior addItem:roadSegment];
    
    float velocity = [self.velocityData[dataIndex] floatValue];
    //NSLog(@"velocity: %f", velocity);
    [self.roadBehavior addLinearVelocity:CGPointMake(velocity*-100, 0) forItem:roadSegment];
    // end make view representing the road segments
    // TODO make background scenery... trees?
    
    // update mph text
    self.mph.text = [NSString stringWithFormat:@"%.02f", [self msToMph:velocity]];
    
    // update rpm text
    if (!self.cadenceData) {
        // no rpm data
        self.rpm.text = @"--";
    }
    else {
        float cadence = [self.cadenceData[dataIndex] floatValue];
        // pass in duration for half a revolution
        [self pedalWithDuration:[self calculateDurationWithCadence:cadence]];
        self.rpm.text = [NSString stringWithFormat:@"%d", (int)cadence];
    }
    
    dataIndex++;
}

- (void) pedalWithDuration: (NSTimeInterval) duration {
    // this spin completes 360 degrees every 1 second
    [UIView animateWithDuration: duration
            delay: 0
            options: UIViewAnimationOptionCurveLinear
            animations: ^{
                self.circle.transform = CGAffineTransformRotate(self.circle.transform, M_PI);
            }
            completion:nil];
    
}

- (float) calculateDurationWithCadence:(float)cadence {
    // convert rpm -> revolutions per second
    float rps = cadence/60.f;
    // result is now # revolutions per second, how long does it take to rotate half a revolution?
    return 0.5f/rps;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startAnimating {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateView) userInfo:nil repeats:YES];
    [self.timer fire];
}

// converts m/s to mph
- (float)msToMph:(float)number {
    return number*2.23694;
}

- (void) getActivityCadence {
    
    [self.client getStreamDataById:self.activityId type:CADENCE success:^(AFHTTPRequestOperation *operation, id response) {
        
        for (id object in response) {
            NSString *dataType = object[@"type"];
            if ([dataType isEqualToString:CADENCE]) {
                //NSLog(@"%@", object[@"data"]);
                self.cadenceData = object[@"data"];
                break;
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", [error description]);
    }];
    
}

- (void) getActivityVelocity {
    
    [self.client getStreamDataById:self.activityId type:VELOCITY success:^(AFHTTPRequestOperation *operation, id response) {
        
        for (id object in response) {
            NSString *dataType = object[@"type"];
            if ([dataType isEqualToString:VELOCITY]) {
                //NSLog(@"%@", object[@"data"]);
                self.velocityData = object[@"data"];
                break;
            }
        }
        
        [self startAnimating];
        
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
