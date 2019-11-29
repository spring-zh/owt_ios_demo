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

#import <Foundation/Foundation.h>
#import "StreamView.h"

@implementation StreamView

-(instancetype)initWithFrame:(CGRect)frame{

  if(self=[super initWithFrame:frame]){
    self.backgroundColor=[UIColor blackColor];
    _remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
    _remoteVideoView.delegate = self;
    _localVideoView=[[RTCEAGLVideoView alloc] initWithFrame:CGRectZero];
    _publishBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    _stopBtn=[UIButton buttonWithType:UIButtonTypeCustom];
    _localStreamBtn = [[UIButton alloc] init];
    [_publishBtn addTarget:self action:@selector(onAcceptBtnDown:) forControlEvents:UIControlEventTouchDown];
    [_stopBtn addTarget:self action:@selector(onDenyBtnDown:) forControlEvents:UIControlEventTouchDown];
    [_localStreamBtn addTarget:self action:@selector(onLocalStreamBtnDown:) forControlEvents:UIControlEventTouchDown];
    
    [self addSubview:_remoteVideoView];
    [self addSubview:_localVideoView];
    [self addSubview:_publishBtn];
    [self addSubview:_stopBtn];
  }
  return self;
}

-(void)layoutSubviews{

  screenSize =  [UIScreen mainScreen].bounds;

  // localVideo
  CGRect localVideoViewFrame=CGRectZero;
  localVideoViewFrame.origin.x = screenSize.size.width / 12.0;
  localVideoViewFrame.origin.y = screenSize.size.height * 2.0 / 3.0;
  localVideoViewFrame.size.width = screenSize.size.width / 3.0;
  localVideoViewFrame.size.height = screenSize.size.height / 4.0;
  _localVideoView.frame=localVideoViewFrame;

  _localVideoView.layer.borderColor = [UIColor yellowColor].CGColor;
  _localVideoView.layer.borderWidth = 0.0;

  // remoteVideo
  CGRect remoteVideoViewFrame=CGRectZero;
  remoteVideoViewFrame.origin.x = 0;
  remoteVideoViewFrame.origin.y = 0;
  remoteVideoViewFrame.size.width = screenSize.size.width;
  remoteVideoViewFrame.size.height = screenSize.size.height;
  _remoteVideoView.frame=remoteVideoViewFrame;
  _remoteVideoView.layer.borderColor = [UIColor blackColor].CGColor;
  _remoteVideoView.layer.borderWidth = 2.0;


  // acceptBtn
  [_publishBtn setTitle:@"📹" forState:UIControlStateNormal];
  [_publishBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  _publishBtn.titleLabel.font = [UIFont systemFontOfSize:30];
  CGRect acceptBtnFrame=CGRectZero;
  acceptBtnFrame.origin.x = screenSize.size.width / 2.0;
  acceptBtnFrame.origin.y = screenSize.size.height * 11.0 / 12.0 - screenSize.size.width / 5;
  acceptBtnFrame.size.width = screenSize.size.width / 5;
  acceptBtnFrame.size.height = screenSize.size.width / 5;
  _publishBtn.frame = acceptBtnFrame;
  _publishBtn.layer.cornerRadius = screenSize.size.width / 10;
  [_publishBtn setBackgroundColor:[UIColor greenColor]];

  // denyBtn
  [_stopBtn setTitle:@"❌" forState:UIControlStateNormal];
  [_stopBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  _stopBtn.titleLabel.font = [UIFont systemFontOfSize:30];
  CGRect denyBtnFrame=CGRectZero;
  denyBtnFrame.origin.x = screenSize.size.width * 11.0 / 12.0 - screenSize.size.width / 5;
  denyBtnFrame.origin.y = screenSize.size.height * 11.0 / 12.0 - screenSize.size.width / 5;
  denyBtnFrame.size.width = screenSize.size.width / 5;
  denyBtnFrame.size.height = screenSize.size.width / 5;
  _stopBtn.frame=denyBtnFrame;
  _stopBtn.layer.cornerRadius = screenSize.size.width / 10;
  [_stopBtn setBackgroundColor:[UIColor redColor]];


  // localStreamBtn
  [_localStreamBtn setTitle:@"lStream" forState:UIControlStateNormal];
  [_localStreamBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  CGRect localStreamBtnFrame=CGRectZero;
  localStreamBtnFrame.origin.x = 0;
  localStreamBtnFrame.origin.y = screenSize.size.height / 2.0;
  localStreamBtnFrame.size.width = 100;
  localStreamBtnFrame.size.height = screenSize.size.height / 8.0 ;
  _localStreamBtn.frame=localStreamBtnFrame;

}

-(void)onAcceptBtnDown:(id)sender{
  [_delegate publishBtnDidTouchedDown:self];
}

-(void)onDenyBtnDown:(id)sender{
  [_delegate stopBtnDidTouchedDown:self];
}

- (void) onLocalStreamBtnDown:(id) sender {
  [_delegate localStreamBtnDidTouchedDown:self];
}

- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
  if (videoView != self.remoteVideoView) {
    return;
  }
  if (size.width > 0 && size.height > 0) {
    CGRect remoteVideoFrame =
        AVMakeRectWithAspectRatioInsideRect(size, self.bounds);
    _remoteVideoView.frame = remoteVideoFrame;
    _remoteVideoView.center =
        CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
  }
}

@end
