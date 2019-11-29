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

@implementation StreamView{
  UILabel* statsLabel;
  BOOL isStatsLabelVisiable;
}

-(instancetype)initWithFrame:(CGRect)frame{
  if(self=[super initWithFrame:frame]){
    self.backgroundColor=[UIColor whiteColor];

#if defined(RTC_SUPPORTS_METAL)
    _remoteVideoView = [[RTCEAGLVideoView alloc]init];
//    _remoteVideoView = [[RTCMTLVideoView alloc]initWithFrame:CGRectZero];
#else
    _remoteVideoView = [[RTCEAGLVideoView alloc]init];
#endif
    _localVideoView=[[RTCCameraPreviewView alloc] init];
    _act=[[UIActivityIndicatorView  alloc] init];
    [_act startAnimating];
    statsLabel=[[UILabel alloc]init];
    isStatsLabelVisiable=NO;

    [self addSubview:_remoteVideoView];
    [self addSubview:_localVideoView];
    [self addSubview:_act];
  }
  return self;
}

-(void)layoutSubviews{
  screenSize =  [UIScreen mainScreen].bounds;
  CGFloat right=0;
  CGFloat bottom=0;
  if (@available(iOS 11.0, *)) {
    right=self.safeAreaInsets.right;
    bottom=self.safeAreaInsets.bottom;
  }
  
  // local view
  _localVideoView.translatesAutoresizingMaskIntoConstraints=NO;
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_localVideoView
                                                   attribute:NSLayoutAttributeRight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self
                                                   attribute:NSLayoutAttributeRight
                                                  multiplier:1.0
                                                  constant:-right]];
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_localVideoView
                                                   attribute:NSLayoutAttributeBottom
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self
                                                   attribute:NSLayoutAttributeBottom
                                                  multiplier:1.0
                                                    constant:-bottom]];
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_localVideoView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeWidth multiplier:0.25 constant:0]];
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_localVideoView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeHeight multiplier:0.25 constant:0]];

  // remote view
  CGRect remoteVideoViewFrame=CGRectZero;
  remoteVideoViewFrame.origin.x = 0;
  remoteVideoViewFrame.origin.y = 0;
  remoteVideoViewFrame.size.width = screenSize.size.width;
  remoteVideoViewFrame.size.height = screenSize.size.height;
  _remoteVideoView.frame=remoteVideoViewFrame;
  
  _remoteVideoView.contentMode = UIViewContentModeScaleAspectFill; // <— Doesn’t seem to work?

  // indicater
  float actSize = screenSize.size.width / 10.0;
  _act.frame = CGRectMake(screenSize.size.width /2.0 - actSize, screenSize.size.height / 2.0 - actSize, 2 * actSize, 2 * actSize);
  _act.activityIndicatorViewStyle=UIActivityIndicatorViewStyleWhiteLarge;
  //  self.act.color = [UIColor redColor];
  _act.hidesWhenStopped = YES;

  // Stats label
  CGRect statsLabelFrame=CGRectMake(screenSize.size.width-140, 0, 140, 100);
  statsLabel.frame=statsLabelFrame;
  statsLabel.backgroundColor=[[UIColor whiteColor] colorWithAlphaComponent:0.2f];
  statsLabel.textColor=[UIColor blackColor];
  statsLabel.font=[statsLabel.font fontWithSize:12];
  statsLabel.lineBreakMode=NSLineBreakByWordWrapping;
  statsLabel.numberOfLines=0;
  
  for(UIView *view in self.subviews){
    view.transform = self.transform;
  }
}

-(void)setStats:(NSString *)stats{
  if([stats length]==0&&isStatsLabelVisiable){
    [statsLabel removeFromSuperview];
  } else if([stats length]!=0&&!isStatsLabelVisiable){
    [self addSubview:statsLabel];
  }
  statsLabel.text=stats;
}


@end
