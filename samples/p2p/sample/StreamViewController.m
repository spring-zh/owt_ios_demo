/*
 * Copyright © 2016 Intel Corporation. All Rights Reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <AVFoundation/AVFoundation.h>
#import <WebRTC/WebRTC.h>
#import <OWT/OWT.h>
#import "StreamViewController.h"
#import "StreamView.h"

@interface StreamViewController () <StreamViewDelegate>

@property(nonatomic, retain) OWTLocalStream* localStream;
@property(nonatomic, retain) OWTP2PClient* peerClient;
@property(nonatomic, retain) NSTimer* getStatsTimer;

@end

@implementation StreamViewController{
  BOOL _isChatting;
  OWTP2PPublication* _publication;
}

- (void)showMsg: (NSString *)msg
{
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:msg delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
  [alert show];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotification:) name:nil object:nil];

  while ([appDelegate.infos count] > 0) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OnStreamAdded" object:appDelegate userInfo:appDelegate.infos[[appDelegate.infos count] - 1]];
    [appDelegate.infos removeLastObject];
  }

  NSLog(@"Stream view did load.");
  _peerClient=[appDelegate peerClient];
  _isChatting = NO;

#if TARGET_IPHONE_SIMULATOR
  NSLog(@"Camera is not supported on simulator.");
  OWTStreamConstraints* constraints=[[OWTStreamConstraints alloc] init];
  constraints.audio=YES;
  constraints.video=nil;
  _localStream=[[OWTLocalStream alloc] initWithConstratins:constraints error:nil];
#else
  [self attachLocal];
#endif

  NSNotificationCenter* nc=[NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(routeChange:) name:AVAudioSessionRouteChangeNotification object:nil];

  //[self publish];
}

-(void)routeChange:(NSNotification*)notification{
  [[AVAudioSession sharedInstance]overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
}

- (void) viewDidDisappear:(BOOL)animated {
  NSLog(@"disappearing");
  [super viewDidDisappear:animated];
  _localStream = nil;
}

-(void)viewDidAppear:(BOOL)animated{
  [super viewDidAppear:animated];
  _status.textAlignment = NSTextAlignmentCenter;
  _status.textColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

-(void)loadView{
  [super loadView];

  appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
  _streamView=[[StreamView alloc]init];
  _streamView.delegate=self;
  _status = [[UILabel alloc]init];
  _status.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height / 30.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height / 30.0);
  [_streamView addSubview:_status];
  self.view=_streamView;
}


-(void)publishBtnDidTouchedDown:(StreamView *)view{
  [self publish];
}

- (void)stopBtnDidTouchedDown:(StreamView *)view {
  [_publication stop];
}

-(void)publish{
  dispatch_async(dispatch_get_main_queue(), ^{
    [_peerClient publish:_localStream to:appDelegate.remoteUserId onSuccess:^(OWTP2PPublication* publication){
      _publication=publication;
      if(_getStatsTimer){
        [_getStatsTimer invalidate];
      }
      _getStatsTimer=[NSTimer timerWithTimeInterval:5.0 target:self selector:@selector(printStats) userInfo:nil repeats:YES];
      [[NSRunLoop mainRunLoop] addTimer:_getStatsTimer forMode:NSDefaultRunLoopMode];
    }onFailure:^(NSError *err) {
      NSLog(@"%@", [err localizedFailureReason]);
    }];
    _status.text = @"Chatting...";
  });
}

-(void)printStats{
}

- (void)attachLocal {
  if(_localStream==nil){
    OWTStreamConstraints* constraints=[[OWTStreamConstraints alloc] init];
    constraints.audio=YES;
    constraints.video=[[OWTVideoTrackConstraints alloc] init];
    constraints.video.frameRate=24;
    constraints.video.resolution=CGSizeMake(640,480);
    constraints.video.devicePosition=AVCaptureDevicePositionFront;
    dispatch_async(dispatch_get_main_queue(), ^{
      _localStream=[[OWTLocalStream alloc] initWithConstratins:constraints error:nil];
      if(_localStream){
        [_localStream attach:_streamView.localVideoView];
      }
    });
  }
}

-(void)onNotification:(NSNotification *)notification{
  if([notification.name isEqualToString:@"OnStreamAdded"]){
    NSDictionary* userInfo = notification.userInfo;
    OWTRemoteStream* stream = userInfo[@"stream"];
    [self onRemoteStreamAdded:stream];
  }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  HorizontalSegue *s = (HorizontalSegue *)segue;
  s.isDismiss = YES;
  s.isLandscapeOrientation = NO;
}

-(void)onRemoteStreamAdded:(OWTRemoteStream*)remoteStream{
  if(remoteStream.source.video==OWTVideoSourceInfoScreenCast){
    NSLog(@"Screen stream added.");
  }
  else if (remoteStream.source.video==OWTVideoSourceInfoCamera){
    NSLog(@"Camera stream added.");
  }
  [remoteStream attach:_streamView.remoteVideoView];
}

-(void)onRemoteStreamRemoved:(OWTRemoteStream*)remoteStream{
}

-(void)publicationDidEnd:(OWTP2PPublication *)publication{
  NSLog(@"Publication did end.");
}

@end
