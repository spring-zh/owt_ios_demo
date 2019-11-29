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
#import <AFNetworking/AFNetworking.h>
#import <OWT/OWT.h>
#import "ConferenceSFUStreamViewController.h"
#import "HorizontalSegue.h"
#import "BrightenFilter.h"

@interface ConferenceSFUStreamViewController () <SFUStreamViewDelegate, OWTRemoteMixedStreamDelegate>

@property(strong, nonatomic) OWTRemoteStream* remoteStream;
@property(strong, nonatomic) OWTRemoteStream* screenStream;
@property(strong, nonatomic) OWTConferenceClient* conferenceClient;
@property(strong, nonatomic) OWTConferencePublication* publication;
@property(strong, nonatomic) OWTConferenceSubscription* subscription;

- (void)handleLocalPreviewOrientation;
- (void)handleSwipeGuesture:(UIScreenEdgePanGestureRecognizer*)sender;


@end

@implementation ConferenceSFUStreamViewController{
  NSTimer* _getStatsTimer;
  RTCVideoSource* _source;
  RTCCameraVideoCapturer* _capturer;
  BOOL _subscribedMix;
  BrightenFilter* _filter;
  NSString* _url;
}

- (void)showMsg: (NSString *)msg
{
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:msg preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
  [alertController addAction:okAction];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor clearColor];
  appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
  _conferenceClient=[appDelegate conferenceClient];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStreamAddedNotification:) name:@"OnStreamAdded" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStreamRemovedNotification:) name:@"OnStreamRemoved" object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChangedNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
  UIScreenEdgePanGestureRecognizer *edgeGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGuesture:)];
  edgeGestureRecognizer.delegate=self;
  edgeGestureRecognizer.edges=UIRectEdgeLeft;
  [self.view addGestureRecognizer:edgeGestureRecognizer];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [self doPublish];
  });
  if (@available(iOS 11.0, *)) {
    [self setNeedsUpdateOfHomeIndicatorAutoHidden];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [self handleLocalPreviewOrientation];
}


-(void)loadView {
  [super loadView];
  _streamView=[[SFUStreamView alloc]initWithFrame:[UIScreen mainScreen].bounds];
  _streamView.delegate=self;
  self.view=_streamView;
}

-(void)viewDidLayoutSubviews{
  [super viewDidLayoutSubviews];
//  _streamView.contentSize = _streamView.remoteVideoGroup.frame.size;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)handleSwipeGuesture:(UIScreenEdgePanGestureRecognizer*)sender{
  if(sender.state==UIGestureRecognizerStateEnded){
    [_conferenceClient leaveWithOnSuccess:^{
      [self quitConference];
    } onFailure:^(NSError* err){
      [self quitConference];
      NSLog(@"Failed to leave. %@",err);
    }];
  }
}

- (void)handleLocalPreviewOrientation{
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  switch(orientation){
    case UIInterfaceOrientationLandscapeLeft:
      [self.streamView.localVideoView setTransform:CGAffineTransformMakeRotation(M_PI_2)];
      break;
    case UIInterfaceOrientationLandscapeRight:
      [self.streamView.localVideoView setTransform:CGAffineTransformMakeRotation(M_PI+M_PI_2)];
      break;
    default:
      NSLog(@"Unsupported orientation.");
      break;
  }
}

- (void)quitConference{
  dispatch_async(dispatch_get_main_queue(), ^{
    _localStream = nil;
    [_getStatsTimer invalidate];
    if(_capturer){
      [_capturer stopCapture];
    }
    _conferenceClient=nil;
    [self performSegueWithIdentifier:@"Back" sender:self];
  });
}

- (void) quitBtnDidTouchedDown:(SFUStreamView *)view {
  [_conferenceClient leaveWithOnSuccess:^{
    [self quitConference];
  } onFailure:^(NSError* err){
    [self quitConference];
    NSLog(@"Failed to leave. %@",err);
  }];
}

- (void)onStreamRemovedNotification:(NSNotification*)notification {
  NSDictionary* userInfo = notification.userInfo;
  OWTRemoteStream* stream = userInfo[@"stream"];
  NSLog(@"A stream was removed from %@", stream.origin);
  [self onRemoteStreamRemoved:stream];
}

- (void)onStreamAddedNotification:(NSNotification*)notification {
  NSDictionary* userInfo = notification.userInfo;
  OWTRemoteStream* stream = userInfo[@"stream"];
  NSLog(@"New stream add from %@", stream.origin);
  [self onRemoteStreamAdded:stream];
}

- (void)onStreamEndNotification:(NSNotification*)notification {
  NSDictionary* userInfo = notification.userInfo;
  OWTRemoteStream* stream = userInfo[@"stream"];
  NSLog(@"New stream add from %@", stream.origin);
  [self onRemoteStreamAdded:stream];
}

-(void)onOrientationChangedNotification:(NSNotification*)notification{
  [self handleLocalPreviewOrientation];
}

- (void)onRemoteStreamRemoved:(OWTRemoteStream*)remoteStream {
  if (remoteStream.source.video==OWTVideoSourceInfoScreenCast) {
    _screenStream = nil;
  }
  if(![remoteStream isKindOfClass:[OWTRemoteMixedStream class]])
    [_streamView removeRemoteStreamRenderer:remoteStream];
}

- (void)onRemoteStreamAdded:(OWTRemoteStream*)remoteStream {
  NSLog(@"[ZSPDEBUG Function:%s Line:%d] remoteStream:%@ streamid:%@", __FUNCTION__,__LINE__,remoteStream,[remoteStream streamId]);
  if (remoteStream.source.video==OWTVideoSourceInfoScreenCast) {
    _screenStream = remoteStream;
//    [self subscribe];
  }
  
  if (![remoteStream isKindOfClass:[OWTRemoteMixedStream class]] && (![remoteStream.streamId isEqualToString:_publication.publicationId])) {
    [self subscribeForwardStream:remoteStream];
  }
}

// Try to subscribe screen sharing stream is available, otherwise, subscribe
// mixed stream.
- (void)subscribe {
  for (id s in appDelegate.remoteStreams) {
    if(![s isKindOfClass:[OWTRemoteMixedStream class]])
    {
      [self subscribeForwardStream:s];
    }
  }
  
  
#if 0
  if (_screenStream) {
    [_conferenceClient subscribe:_screenStream withOptions: nil
        onSuccess:^(OWTConferenceSubscription* _Nonnull subscription) {
          subscription.delegate=self;
          dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"Subscribe screen stream success.");
            //[_screenStream attach:((StreamView*)self.view).remoteVideoView];
            [_streamView.act stopAnimating];
          });
        }
        onFailure:^(NSError* _Nonnull err) {
          NSLog(@"Subscribe screen stream failed. Error: %@",
                [err localizedDescription]);
        }];
  } else {
    OWTConferenceSubscribeOptions* subOption =
        [[OWTConferenceSubscribeOptions alloc] init];
    subOption.video=[[OWTConferenceVideoSubscriptionConstraints alloc]init];
    OWTVideoCodecParameters* h264Codec = [[OWTVideoCodecParameters alloc] init];
    h264Codec.name = OWTVideoCodecH264;
    h264Codec.profile = @"M";
    subOption.video.codecs = [NSArray arrayWithObjects:h264Codec, nil];
    subOption.audio = [[OWTConferenceAudioSubscriptionConstraints alloc]init];
//    OWTAudioCodecParameters* pcmCodec = [[OWTAudioCodecParameters alloc] init];
//    pcmCodec.name = OWTAudioCodecPcma;
//    subOption.audio.codecs = [NSArray arrayWithObjects:pcmCodec, nil];
//    subOption.video.bitrateMultiplier = 2.0f;
    int width = INT_MAX;
    int height = INT_MAX;
    for (NSValue* value in appDelegate.mixedStream.capabilities.video.resolutions) {
      CGSize resolution=[value CGSizeValue];
      if (resolution.width == 640 && resolution.height == 480) {
        width = resolution.width;
        height = resolution.height;
        break;
      }
      if (resolution.width < width && resolution.height != 0) {
        width = resolution.width;
        height = resolution.height;
      }
    }
    [[AVAudioSession sharedInstance]
        overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                          error:nil];
    [_conferenceClient subscribe:appDelegate.mixedStream
        withOptions:subOption
        onSuccess:^(OWTConferenceSubscription* subscription) {
          _subscription=subscription;
          _subscription.delegate=self;
          _getStatsTimer = [NSTimer timerWithTimeInterval:1.0
                                                  target:self
                                                selector:@selector(printStats)
                                                userInfo:nil
                                                 repeats:YES];
          [[NSRunLoop mainRunLoop] addTimer:_getStatsTimer
                                    forMode:NSDefaultRunLoopMode];
          dispatch_async(dispatch_get_main_queue(), ^{
            _remoteStream = appDelegate.mixedStream;
            NSLog(@"Subscribe stream success.");
            [_remoteStream attach:((SFUStreamView*)self.view).remoteVideoView];
            [_streamView.act stopAnimating];
            _subscribedMix = YES;
          });
        }
        onFailure:^(NSError* err) {
          NSLog(@"Subscribe stream failed. %@", [err localizedDescription]);
        }];
  }
#endif
}

-(void)doPublish{
  if (_localStream == nil) {
#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Camera is not supported on simulator");
    OWTStreamConstraints* constraints=[[OWTStreamConstraints alloc]init];
    constraints.audio=YES;
    constraints.video=nil;
#else
    /* Create LocalStream with constraints */
    OWTStreamConstraints* constraints=[[OWTStreamConstraints alloc] init];
    constraints.audio=YES;
    constraints.video=[[OWTVideoTrackConstraints alloc] init];
    constraints.video.frameRate=24;
    constraints.video.resolution=CGSizeMake(640,480);
    constraints.video.devicePosition=AVCaptureDevicePositionFront;
#endif
    RTCMediaStream *localRTCStream = [self createLocalSenderStream:constraints];
    OWTStreamSourceInfo *sourceinfo = [[OWTStreamSourceInfo alloc] init];
    sourceinfo.audio = OWTAudioSourceInfoMic;
    sourceinfo.video = OWTVideoSourceInfoCamera;
    _localStream=[[OWTLocalStream alloc] initWithMediaStream:localRTCStream source:sourceinfo];

#if TARGET_IPHONE_SIMULATOR
    NSLog(@"Stream does not have video track.");
#else
    dispatch_async(dispatch_get_main_queue(), ^{
      [((SFUStreamView *)self.view).localVideoView setCaptureSession:[_capturer captureSession] ];
    });
#endif
    OWTPublishOptions* options=[[OWTPublishOptions alloc] init];
    OWTAudioCodecParameters* opusParameters=[[OWTAudioCodecParameters alloc] init];
    opusParameters.name=OWTAudioCodecOpus;
    OWTAudioEncodingParameters *audioParameters=[[OWTAudioEncodingParameters alloc] init];
    audioParameters.codec=opusParameters;
    options.audio=[NSArray arrayWithObjects:audioParameters, nil];
    OWTVideoCodecParameters *h264Parameters=[[OWTVideoCodecParameters alloc] init];
    h264Parameters.name=OWTVideoCodecH264;
    OWTVideoEncodingParameters *videoParameters=[[OWTVideoEncodingParameters alloc]init];
    videoParameters.codec=h264Parameters;
    options.video=[NSArray arrayWithObjects:videoParameters, nil];
    [_conferenceClient publish:_localStream withOptions:options onSuccess:^(OWTConferencePublication* p) {
      NSLog(@"[ZSPDEBUG Function:%s Line:%d] publish success! OWTConferencePublication:%@ id:%@", __FUNCTION__,__LINE__,p,p.publicationId);
      _publication=p;
      _publication.delegate=self;
      [self mixToCommonView:p];

    } onFailure:^(NSError* err) {
      NSLog(@"publish failure!");
      [self showMsg:[err localizedFailureReason]];
    }];
    _screenStream=appDelegate.screenStream;
    _remoteStream=appDelegate.mixedStream;
    [self subscribe];
  }
}

-(void)printStats{
  [_publication statsWithOnSuccess:^(NSArray<RTCLegacyStatsReport *> * _Nonnull stats) {
    NSLog(@"%@", stats);
  } onFailure:^(NSError * _Nonnull e) {
    NSLog(@"%@",e);
  }];
}

-(void)mixToCommonView:(OWTConferencePublication* )publication{
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  manager.requestSerializer = [AFJSONRequestSerializer serializer];
  [manager.requestSerializer setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  manager.responseSerializer = [AFHTTPResponseSerializer serializer];
  manager.securityPolicy.allowInvalidCertificates=NO;
  manager.securityPolicy.validatesDomainName=YES;
  NSDictionary *params = [[NSDictionary alloc]initWithObjectsAndKeys:@"add", @"op", @"/info/inViews", @"path", @"common", @"value", nil];
  NSArray* paramsArray=[NSArray arrayWithObjects:params, nil];
  [manager PATCH:[NSString stringWithFormat:@"http://112.74.73.206:3001/rooms/%@/streams/%@", appDelegate.conferenceId, publication.publicationId ] parameters:paramsArray success:nil failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
  }];
}

-(void)subscribeForwardStream:(OWTRemoteStream *)remoteStream{
  OWTConferenceSubscribeOptions* subOption =
      [[OWTConferenceSubscribeOptions alloc] init];
  subOption.video=[[OWTConferenceVideoSubscriptionConstraints alloc]init];
  OWTVideoCodecParameters* h264Codec = [[OWTVideoCodecParameters alloc] init];
  h264Codec.name = OWTVideoCodecH264;
  h264Codec.profile = @"M";
  subOption.video.codecs = [NSArray arrayWithObjects:h264Codec, nil];
  subOption.audio = [[OWTConferenceAudioSubscriptionConstraints alloc]init];
  //    OWTAudioCodecParameters* pcmCodec = [[OWTAudioCodecParameters alloc] init];
  //    pcmCodec.name = OWTAudioCodecPcma;
  //    subOption.audio.codecs = [NSArray arrayWithObjects:pcmCodec, nil];
  //    subOption.video.bitrateMultiplier = 2.0f;

  [[AVAudioSession sharedInstance]
      overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                        error:nil];
  
  //show loading icon
  dispatch_async(dispatch_get_main_queue(), ^(){
    [_streamView.act startAnimating];
  });
  
  [_conferenceClient subscribe:remoteStream
  withOptions:subOption
  onSuccess:^(OWTConferenceSubscription* subscription) {
    _subscription=subscription;
    _subscription.delegate=self;
    _getStatsTimer = [NSTimer timerWithTimeInterval:1.0
                                            target:self
                                          selector:@selector(printStats)
                                          userInfo:nil
                                           repeats:YES];
//    [[NSRunLoop mainRunLoop] addTimer:_getStatsTimer
//                              forMode:NSDefaultRunLoopMode];
    dispatch_async(dispatch_get_main_queue(), ^{
      NSLog(@"Subscribe stream success.");
      UIView<RTCVideoRenderer> *videoView = [_streamView addRemoteRenderer:remoteStream];
      [remoteStream attach:videoView];
      //hide loading icon
      [_streamView.act stopAnimating];
    });
  }
  onFailure:^(NSError* err) {
    NSLog(@"Subscribe stream failed. %@", [err localizedDescription]);
  }];
}

static NSString * const kARDAudioTrackId = @"ARDAMSa0";
static NSString * const kARDVideoTrackId = @"ARDAMSv0";

- (NSString *)createRandomUuid
{
  // Create universally unique identifier (object)
  CFUUIDRef uuidObject = CFUUIDCreate(kCFAllocatorDefault);
  // Get the string representation of CFUUID object.
  NSString *uuidStr = (NSString *)CFBridgingRelease(CFUUIDCreateString(kCFAllocatorDefault, uuidObject));
  CFRelease(uuidObject);
  return uuidStr;
}

- (RTCMediaStream*)createLocalSenderStream:(OWTStreamConstraints*)constraints{
  //init media senders
  RTCPeerConnectionFactory* factory = [RTCPeerConnectionFactory sharedInstance];
  RTCMediaStream* stream = [factory mediaStreamWithStreamId:[self createRandomUuid]];
  
  //add audio track
  RTCAudioSource* audio_source = [factory audioSourceWithConstraints:nil];
  RTCAudioTrack* audio_track =
      [factory audioTrackWithSource:audio_source trackId:[self createRandomUuid]];
  [stream addAudioTrack:audio_track];
  
  //add video track
  // Reference: ARDCaptureController.m.
  RTCVideoSource* video_source = [factory videoSource];
  RTCCameraVideoCapturer* capturer =
      [[RTCCameraVideoCapturer alloc] initWithDelegate:video_source];
  // Configure capturer position.
  NSArray<AVCaptureDevice*>* captureDevices =
      [RTCCameraVideoCapturer captureDevices];
  if (captureDevices == 0) {
    return nil;
  }
  AVCaptureDevice* device = captureDevices[0];
  if (constraints.video.devicePosition) {
    for (AVCaptureDevice* d in captureDevices) {
      if (d.position == constraints.video.devicePosition) {
        device = d;
        break;
      }
    }
  }
  // Configure FPS.
  NSUInteger fps =
      constraints.video.frameRate ? constraints.video.frameRate : 24;
  // Configure resolution.
  NSArray<AVCaptureDeviceFormat*>* formats =
      [RTCCameraVideoCapturer supportedFormatsForDevice:device];
  AVCaptureDeviceFormat* selectedFormat = nil;
  if (constraints.video.resolution.width == 0 &&
      constraints.video.resolution.height == 0) {
    selectedFormat = formats[0];
  } else {
    for (AVCaptureDeviceFormat* format in formats) {
      CMVideoDimensions dimension =
          CMVideoFormatDescriptionGetDimensions(format.formatDescription);
      if (dimension.width == constraints.video.resolution.width &&
          dimension.height == constraints.video.resolution.height) {
        for (AVFrameRateRange* frameRateRange in
             [format videoSupportedFrameRateRanges]) {
          if (frameRateRange.minFrameRate <= fps &&
              fps <= frameRateRange.maxFrameRate) {
            selectedFormat = format;
            break;
          }
        }
      }
      if(selectedFormat){
        break;
      }
    }
  }
  if (selectedFormat == nil) {
    return nil;
  }
  [capturer startCaptureWithDevice:device format:selectedFormat fps:fps];
  RTCVideoTrack* video_track =
      [factory videoTrackWithSource:video_source trackId:[self createRandomUuid]];
  [stream addVideoTrack:video_track];
  _capturer = capturer;
  
  return stream;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  HorizontalSegue *s = (HorizontalSegue *)segue;
  s.isDismiss = YES;
}

-(void)onVideoLayoutChanged{
  NSLog(@"OnVideoLayoutChanged.");
}

-(void)subscriptionDidMute:(OWTConferenceSubscription *)subscription trackKind:(OWTTrackKind)kind{
  NSLog(@"Subscription is muted.");
}

-(void)subscriptionDidUnmute:(OWTConferenceSubscription *)subscription trackKind:(OWTTrackKind)kind{
  NSLog(@"Subscription is unmuted.");
}

-(void)subscriptionDidEnd:(OWTConferenceSubscription *)subscription{
  NSLog(@"Subscription is ended.");
}

-(void)publicationDidMute:(OWTConferencePublication *)publication trackKind:(OWTTrackKind)kind{
  NSLog(@"Publication is muted.");
}

-(void)publicationDidUnmute:(OWTConferencePublication *)publication trackKind:(OWTTrackKind)kind{
  NSLog(@"Publication is unmuted.");
}

-(void)publicationDidEnd:(OWTConferencePublication *)publication{
  NSLog(@"Publication is ended.");
}

@end
