//
//  VideoCallViewController.m
//  VideoChatApp
//
//  Created by Deepak on 13/10/13.
//  Copyright (c) 2013 Deepak. All rights reserved.
//

#import "VideoCallViewController.h"
#import "User.h"

@interface VideoCallViewController ()

@property (nonatomic, weak) IBOutlet UIButton *callButton;
@property (nonatomic, weak) IBOutlet UILabel *ringigngLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *callingActivityIndicator;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *startingCallActivityIndicator;
@property (nonatomic, weak) IBOutlet UIImageView *opponentVideoView;
@property (nonatomic, weak) IBOutlet UIImageView *myVideoView;
@property (nonatomic, weak) IBOutlet UINavigationBar *navBar;
@property (nonatomic, strong) AVAudioPlayer *ringingPlayer;

@property (nonatomic, weak) QBVideoChat *videoChat;
@property (nonatomic, strong) UIAlertView *callAlert;

- (IBAction)call:(id)sender;
- (void)reject;
- (void)accept;


@end

@implementation VideoCallViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.opponentVideoView.layer.borderWidth = 1;
    self.opponentVideoView.layer.borderColor = [[UIColor grayColor] CGColor];
    self.opponentVideoView.layer.cornerRadius = 5;

    self.navigationItem.title = [User sharedInstance].currentQBUser.login;
    [self.callButton setTitle:[NSString stringWithFormat:@"Call to %@", self.receiver.login] forState:UIControlStateNormal];

    // Setup video chat
    //
    self.videoChat = [[QBChat instance] createAndRegisterVideoChatInstance];
    self.videoChat.viewToRenderOpponentVideoStream = self.opponentVideoView;
    self.videoChat.viewToRenderOwnVideoStream = self.myVideoView;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButtonPressed:(id)sender {
    
    [self.videoChat finishCall];
    [[QBChat instance] unregisterVideoChatInstance: self.videoChat];

    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)call:(id)sender{
    // Call
    if(self.callButton.tag == 101){
        self.callButton.tag = 102;
        
        // Call user by ID
        //
        [self.videoChat callUser:[[NSNumber numberWithInt:self.receiver.ID] integerValue] conferenceType:QBVideoChatConferenceTypeAudioAndVideo];
        
        self.callButton.hidden = YES;
        self.ringigngLabel.hidden = NO;
        self.ringigngLabel.text = @"Calling...";
       // self.ringigngLabel.frame = CGRectMake(128, 375, 90, 37);
        self.callingActivityIndicator.hidden = NO;
        
        // Finish
    }else{
        self.callButton.tag = 101;
        
        // Finish call
        //
        [self.videoChat finishCall];
        
        self.myVideoView.hidden = YES;
        self.opponentVideoView.layer.contents = (id)[[UIImage imageNamed:@"person.png"] CGImage];
        self.opponentVideoView.image = [UIImage imageNamed:@"person.png"];
        //AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        //[self.callButton setTitle:appDelegate.currentUser == 1 ? @"Call User2" : @"Call User1" forState:UIControlStateNormal];
        [self.callButton setTitle:self.receiver.login forState:UIControlStateNormal];
        self.opponentVideoView.layer.borderWidth = 1;
        
        [self.startingCallActivityIndicator stopAnimating];
    }
}

- (void)reject{
    // Reject call
    //
    [self.videoChat rejectCall];
    
    self.callButton.hidden = NO;
    
    
    self.ringigngLabel.hidden = YES;
    
    self.ringingPlayer = nil;
}

- (void)accept{
    // Accept call
    //
    [self.videoChat acceptCall];
    
    self.ringigngLabel.hidden = YES;
    self.callButton.hidden = NO;
    [self.callButton setTitle:@"Hang up" forState:UIControlStateNormal];
    self.callButton.tag = 102;
    
    self.opponentVideoView.layer.borderWidth = 0;
    
    [self.startingCallActivityIndicator startAnimating];
    
    self.myVideoView.hidden = NO;
    
    self.ringingPlayer = nil;
}

- (void)hideCallAlert{
    [self.callAlert dismissWithClickedButtonIndex:-1 animated:YES];
    self.callAlert = nil;
}

#pragma mark -
#pragma mark AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    self.ringingPlayer = nil;
}


#pragma mark -
#pragma mark QBChatDelegate
//
// VideoChat delegate

// Called in case when opponent is calling to you
-(void) chatDidReceiveCallRequestFromUser:(NSUInteger)userID conferenceType:(enum QBVideoChatConferenceType)conferenceType{
    NSLog(@"chatDidReceiveCallRequestFromUser %d", userID);
    
    self.callButton.hidden = YES;
    
    // show call alert
    //
    if (self.callAlert == nil) {
//        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//        NSString *message = [NSString stringWithFormat:@"%@ is calling. Would you like to answer?", appDelegate.currentUser == 1 ? @"User 2" : @"User 1"];
        
        NSString *message = [NSString stringWithFormat:@"%@ is calling. Would you like to answer?", [User sharedInstance
                                                                                                     ].currentQBUser.login];
        self.callAlert = [[UIAlertView alloc] initWithTitle:@"Call" message:message delegate:self cancelButtonTitle:@"Decline" otherButtonTitles:@"Accept", nil];
        [self.callAlert show];
    }
    
    // hide call alert if opponent has canceled call
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCallAlert) object:nil];
    [self performSelector:@selector(hideCallAlert) withObject:nil afterDelay:3];
    
    // play call music
    //
    if(self.ringingPlayer == nil){
        NSString *path =[[NSBundle mainBundle] pathForResource:@"ringing" ofType:@"wav"];
        NSURL *url = [NSURL fileURLWithPath:path];
        self.ringingPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:NULL];
        self.ringingPlayer.delegate = self;
        [self.ringingPlayer setVolume:1.0];
        [self.ringingPlayer play];
    }
}

// Called in case when you are calling to user, but he hasn't answered

-(void) chatCallUserDidNotAnswer:(NSUInteger)userID{
    NSLog(@"chatCallUserDidNotAnswer %d", userID);
    
    self.callButton.hidden = NO;
    self.ringigngLabel.hidden = YES;
    self.callingActivityIndicator.hidden = YES;
    self.callButton.tag = 101;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"VideoChat" message:@"User isn't answering. Please try again." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void) chatCallDidRejectByUser:(NSUInteger)userID {
    NSLog(@"chatCallDidRejectByUser %d", userID);
    
    self.callButton.hidden = NO;
    self.ringigngLabel.hidden = YES;
    self.callingActivityIndicator.hidden = YES;
    
    self.callButton.tag = 101;
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"QuickBlox VideoChat" message:@"User has rejected your call." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

-(void) chatCallDidAcceptByUser:(NSUInteger)userID{
    NSLog(@"chatCallDidAcceptByUser %d", userID);
    
    self.ringigngLabel.hidden = YES;
    self.callingActivityIndicator.hidden = YES;
    
    self.opponentVideoView.layer.borderWidth = 0;
    
    self.callButton.hidden = NO;
    [self.callButton setTitle:@"Hang up" forState:UIControlStateNormal];
    self.callButton.tag = 102;
    
    self.myVideoView.hidden = NO;
    
    [self.startingCallActivityIndicator startAnimating];
}

-(void) chatCallDidStopByUser:(NSUInteger)userID status:(NSString *)status{
    NSLog(@"chatCallDidStopByUser %d purpose %@", userID, status);
    
    if([status isEqualToString:kStopVideoChatCallStatus_OpponentDidNotAnswer]){
        self.callButton.hidden = NO;
        
        self.callAlert.delegate = nil;
        [self.callAlert dismissWithClickedButtonIndex:0 animated:YES];
        self.callAlert = nil;
        
        self.ringigngLabel.hidden = YES;
        
        self.ringingPlayer = nil;
        
    }else{
        self.myVideoView.hidden = YES;
        self.opponentVideoView.layer.contents = (id)[[UIImage imageNamed:@"person.png"] CGImage];
        self.opponentVideoView.layer.borderWidth = 1;
//        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//        [self.callButton setTitle:appDelegate.currentUser == 1 ? @"Call User2" : @"Call User1" forState:UIControlStateNormal];
        
        [self.callButton setTitle:self.receiver.login forState:UIControlStateNormal];
        self.callButton.tag = 101;
    }
}

- (void)chatCallDidStartWithUser:(NSUInteger)userID{
    [self.startingCallActivityIndicator stopAnimating];
}

- (void)didStartUseTURNForVideoChat{
    NSLog(@"_____TURN_____TURN_____");
}


#pragma mark -
#pragma mark UIAlertView

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (buttonIndex) {
            // Reject
        case 0:
            [self reject];
            break;
            // Accept
        case 1:
            [self accept];
            break;
            
        default:
            break;
    }
    
    self.callAlert = nil;
}
@end

// ============Methods that may be requered in Future===========

/**
 Called in case changing online users
 
 @param onlineUsers Array of online users
 @param roomName Name of room in which have changed online users
 */
//- (void)chatRoomDidChangeOnlineUsers:(NSArray *)onlineUsers room:(NSString *)roomName;

//#pragma mark -
//#pragma mark Contact list

/**
 Called in case receiving contact request
 
 @param userID User ID from which received contact request
 */
//- (void)chatDidReceiveContactAddRequestFromUser:(NSUInteger)userID;

/**
 Called in case changing contact list
 */
//- (void)chatContactListDidChange:(QBContactList *)contactList;

/**
 Called in case changing contact's online status
 
 @param userID User which online status has changed
 @param isOnline New user status (online or offline)
 @param status Custom user status
 */
//- (void)chatDidReceiveContactItemActivity:(NSUInteger)userID isOnline:(BOOL)isOnline status:(NSString *)status;



/**
 Fired when room was successfully created
 */
//- (void)chatRoomDidCreate:(NSString*)roomName;


/**
 Check if current user logged into Chat
 
 @return YES if user is logged in, NO otherwise
 */
//- (BOOL)isLoggedIn;



/**
 Get current chat user
 
 @return An instance of QBUUser
 */
//- (QBUUser *)currentUser;


/**
Add user to contact list request

@param userID ID of user which you would like to add to contact list
@return YES if the request was sent successfully. If not - see log.
*/
//- (BOOL)addUserToContactListRequest:(NSUInteger)userID;


//- (BOOL)createOrJoinRoomWithName:(NSString *)name membersOnly:(BOOL)isMembersOnly persistent:(BOOL)isPersistent;


