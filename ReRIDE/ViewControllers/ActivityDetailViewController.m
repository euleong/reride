//
//  ActivityDetailViewController.m
//  ReRIDE
//
//  Created by Eugenia Leong on 10/3/14.
//  Copyright (c) 2014 Eugenia Leong. All rights reserved.
//

#import "ActivityDetailViewController.h"
#import "StravaClient.h"
#import "StravaActivity.h"
#import "MBProgressHUD.h"

@interface ActivityDetailViewController ()
@property (weak, nonatomic) IBOutlet UILabel *rpm;
@property (weak, nonatomic) IBOutlet UILabel *mph;
@property (weak, nonatomic) NSString *activityId;
@property (strong, nonatomic) NSArray * cadenceData;
@property (strong, nonatomic) NSArray * velocityData;
@property (weak, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UIView *circle;
@property (strong, nonatomic) StravaClient *client;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGestureRecognizer;

// animation stuff
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UIDynamicItemBehavior *roadBehavior;

- (IBAction)onTap:(UITapGestureRecognizer *)sender;

@end

NSString *const CADENCE = @"cadence";
NSString *const VELOCITY = @"velocity_smooth";
int const CIRCLE_DIAMETER = 100;
// width and height of screen
int width;
int height;
MBProgressHUD *statusHud;

// to keep track of which index in cadenceData and velocityData we're at
int dataIndex = 0;

@implementation ActivityDetailViewController

- (id)initWithActivityId:(NSString *)activityId activityName:(NSString*)activityName {
    self = [super init];
    if (self) {
        self.activityId = activityId;
        
        self.title = activityName;
        self.client = [StravaClient instance];
        
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        height = screenRect.size.height;
        width = screenRect.size.width;
        //NSLog(@"height %d, width %d", height, width);
    }
    return self;
    
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // create drawing
    [self createScene];
    
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    self.roadBehavior = [[UIDynamicItemBehavior alloc] init];
    [self.animator addBehavior:self.roadBehavior];
    
    self.tapGestureRecognizer.enabled = NO;
    
    // show loading status hud
    statusHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    statusHud.mode = MBProgressHUDModeIndeterminate;
    statusHud.labelText = @"Loading...";
    
    // should only start animating when we get data
    [self getActivityDataWithCompletion:^(BOOL finished) {
        if (finished) {
            // hide status hud and start playing animation
            [statusHud hide:YES];
            [self startAnimating];
        }
    }];
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
                                             height/2,
                                             width, 10)];
    road.backgroundColor = [UIColor blackColor];
    [self.view addSubview:road];
    
    // create primitive crankset/pedals
    CGRect rect = CGRectMake(width/2 - CIRCLE_DIAMETER*0.5,
                             height/3 - CIRCLE_DIAMETER*0.5 ,CIRCLE_DIAMETER,CIRCLE_DIAMETER);
    
    
    
    CGRect crankArmRect = CGRectMake(CIRCLE_DIAMETER*0.5-10,
                                     CIRCLE_DIAMETER*0.5-10,
                                     CIRCLE_DIAMETER*0.9,20);
    // crank
    self.circle = [[UIView alloc]
                   initWithFrame:rect];
    self.circle.layer.cornerRadius = 50;
    self.circle.backgroundColor = [UIColor yellowColor];
    [self.view addSubview:self.circle];
    
    // left crank arm
    UIView *crankArmL = [[UIView alloc]
                         initWithFrame:crankArmRect];
    
    
    crankArmL.transform = CGAffineTransformTranslate(crankArmL.transform, -crankArmL.center.x*0.5 + 10, 0);
    crankArmL.transform = CGAffineTransformRotate(crankArmL.transform, M_PI + M_PI*0.25);
    crankArmL.transform = CGAffineTransformTranslate(crankArmL.transform, crankArmL.center.x*0.5 - 10, 0);
    
    crankArmL.layer.cornerRadius = 10;
    crankArmL.backgroundColor = [UIColor blueColor];
    [self.circle addSubview:crankArmL];
    
    // add another circle on top to hide the left crankarm that shouldn't be seen
    UIView *secondCircle = [[UIView alloc]
                   initWithFrame:CGRectMake(0, 0, CIRCLE_DIAMETER, CIRCLE_DIAMETER)];
    secondCircle.layer.cornerRadius = 50;
    secondCircle.backgroundColor = [UIColor yellowColor];
    [self.circle addSubview:secondCircle];
    
    // right crank arm
    UIView *crankArmR = [[UIView alloc]
                    initWithFrame:crankArmRect];
    

    crankArmR.transform = CGAffineTransformTranslate(crankArmR.transform, -crankArmR.center.x*0.5 + 10, 0);
    crankArmR.transform = CGAffineTransformRotate(crankArmR.transform, M_PI*0.25);
    crankArmR.transform = CGAffineTransformTranslate(crankArmR.transform, crankArmR.center.x*0.5 - 10, 0);

    crankArmR.layer.cornerRadius = 10;
    crankArmR.backgroundColor = [UIColor blueColor];
    [self.circle addSubview:crankArmR];
    
}

- (void)updateView {
    // finish animating
    if (dataIndex >= [self.velocityData count]) {
        self.mph.text = @"0.00";
        [self.timer invalidate];
        return;
    }
    
    // make view representing the road segments
    UIView *roadSegment = [[UIView alloc]
                           initWithFrame:CGRectMake(width,
                                                    height/2,
                                                    CIRCLE_DIAMETER*M_PI, 10)];
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
    [self.roadBehavior addLinearVelocity:CGPointMake(velocity*-100.f, 0) forItem:roadSegment];
    // end make view representing the road segments
    // TODO make background scenery... trees?
    
    // update mph text
    self.mph.text = [StravaActivity msToMphStr:velocity];
    
    // update rpm text
    if (!self.cadenceData) {
        // no rpm data
        self.rpm.text = @"--";
    }
    else {
        float cadence = [self.cadenceData[dataIndex] floatValue];
        
        UIViewAnimationOptions option = UIViewAnimationOptionCurveLinear;
        // last revolution
        if (dataIndex == [self.velocityData count]-1) {
            option = UIViewAnimationOptionCurveEaseOut;
        }
        // pass in duration for half a revolution
        [self pedalWithRadians:[self calculateRadiansWithCadence:cadence] options:option];
        
        self.rpm.text = [NSString stringWithFormat:@"%d", (int)cadence];
    }
    
    dataIndex++;
}

- (void) pedalWithRadians:(CGFloat)radians options:(UIViewAnimationOptions)options {
    // this spin completes {radians} every 0.5 second
    
    CGFloat halfRadians = radians*0.5f;
    // prevent taking shortest route
    if (halfRadians > M_PI) {
        halfRadians *= -1.f;
    }
    
    [UIView animateWithDuration:0.25
            delay:0.0
            options:options
            animations:^{
                self.circle.transform = CGAffineTransformRotate(self.circle.transform, halfRadians);
            }
            completion:^(BOOL finished)
            {
                [UIView animateWithDuration:0.25
                                delay:0.0
                                options:options
                                animations:^{
                                     self.circle.transform = CGAffineTransformRotate(self.circle.transform, halfRadians);
                                }
                                completion:nil];
                 
    }];
    
}

- (CGFloat) calculateRadiansWithCadence:(float)cadence {
    // convert rpm -> revolutions per second
    float rps = cadence/60.f;
    // result is now # revolutions per second, how far can we go in half a second?
    rps *= M_PI;

    return (CGFloat)rps;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)startAnimating {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateView) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)getActivityDataWithCompletion:(void (^)(BOOL finished))completion {

    // get velocity data
    [self.client getStreamDataById:self.activityId type:VELOCITY success:^(AFHTTPRequestOperation *operation, id response) {
        
        for (id object in response) {
            NSString *dataType = object[@"type"];
            if ([dataType isEqualToString:VELOCITY]) {
                //NSLog(@"%@", object[@"data"]);
                self.velocityData = object[@"data"];
                break;
            }
        }
        
        // get cadence data
        [self.client getStreamDataById:self.activityId type:CADENCE success:^(AFHTTPRequestOperation *operation, id response) {
            
            for (id object in response) {
                NSString *dataType = object[@"type"];
                if ([dataType isEqualToString:CADENCE]) {
                    //NSLog(@"%@", object[@"data"]);
                    self.cadenceData = object[@"data"];
                    break;
                }
            }
            
            // got data needed to animate
            completion(YES);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"error: %@", [error description]);
            [self showErrorWithDataType:CADENCE];
            self.tapGestureRecognizer.enabled = YES;
        }];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", [error description]);
        [self showErrorWithDataType:@"velocity"];
        self.tapGestureRecognizer.enabled = YES;

    }];

}

// shows error in status hud when we can't retrieve velocity or cadence data
- (void) showErrorWithDataType:(NSString *)type {
    // hide loading hud
    [statusHud hide:YES];
    statusHud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    statusHud.mode = MBProgressHUDModeText;
    statusHud.labelText = [NSString stringWithFormat:@"Unable to retrieve %@.", type];
    statusHud.detailsLabelText = @"Tap anywhere to try again.";
}

/*
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
        
        //[self startAnimating];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", [error description]);
    }];
}


- (void) getActivityGrade {
    [self.client getStreamDataById:self.activityId type:@"grade_smooth" success:^(AFHTTPRequestOperation *operation, id response) {
        
        for (id object in response) {
            NSString *dataType = object[@"type"];
            if ([dataType isEqualToString:@"grade_smooth"]) {
                NSLog(@"%@", object[@"data"]);
                //self.cadenceData = object[@"data"];
                break;
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", [error description]);
    }];
}
 */
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onTap:(UITapGestureRecognizer *)sender {
    
    [statusHud hide:YES];
    self.tapGestureRecognizer.enabled = NO;
    [self getActivityDataWithCompletion:^(BOOL finished) {
        if (finished) {
            [self startAnimating];
        }
    }];
}
@end
