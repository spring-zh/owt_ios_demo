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
#import "SFUStreamView.h"
#import "VideoViewCell.h"

@interface SFUStreamView () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation SFUStreamView{
  UILabel* statsLabel;
  BOOL isStatsLabelVisiable;
  NSArray<NSString*> *_videoGroupString;
}

-(instancetype)initWithFrame:(CGRect)frame{
  if(self=[super initWithFrame:frame]){
    self.backgroundColor=[UIColor whiteColor];

    _videoGroupString = [[NSArray alloc] initWithObjects:@"Local Video Preview" ,@"Remote Video Preview" ,nil];
    
    _videoViewGroup = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    _videoViewGroup.bounces = YES;
    _videoViewGroup.editing = FALSE;
    _videoViewGroup.allowsSelection = NO;
    _videoViewGroup.allowsSelectionDuringEditing = NO;
    _videoViewGroup.dataSource = self;
    _videoViewGroup.delegate = self;
//    _videoViewGroup.separatorInset = UIEdgeInsetsMake(5, 5, 5, 5);
//    _videoViewGroup.style = UITableViewStyleGrouped;
    
    [_videoViewGroup registerClass:[VideoViewCell class] forCellReuseIdentifier:@"videoViewCell"];

#if defined(RTC_SUPPORTS_METAL)
//    _remoteVideoView = [[RTCEAGLVideoView alloc]init];
//    _remoteVideoView = [[RTCMTLVideoView alloc]initWithFrame:CGRectZero];
#else
//    _remoteVideoView = [[RTCEAGLVideoView alloc]init];
#endif
      CGRect localVideoViewFrame=CGRectZero;
      localVideoViewFrame.origin.x = 0;
      localVideoViewFrame.origin.y = 0;
      localVideoViewFrame.size.width = 640;
      localVideoViewFrame.size.height = 480;
    _localVideoView=[[RTCCameraPreviewView alloc] initWithFrame:localVideoViewFrame];
    _act=[[UIActivityIndicatorView  alloc] init];
    statsLabel=[[UILabel alloc]init];
    isStatsLabelVisiable=NO;

    [self addSubview:_videoViewGroup];
    [self addSubview:_act];
    self.remoteRenderer = [[NSMutableDictionary alloc] init];
    
    [_videoViewGroup reloadData];
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

-(UIView<RTCVideoRenderer> *)addRemoteRenderer:(OWTRemoteStream*)remoteStream{
  int width = INT_MAX;
  int height = INT_MAX;
  
  for (NSValue* value in remoteStream.capabilities.video.resolutions) {
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
  
  UIView<RTCVideoRenderer> * videoView = [[RTCEAGLVideoView alloc]init];
  videoView.translatesAutoresizingMaskIntoConstraints=NO;
  // remote view
  CGRect remoteVideoViewFrame=CGRectZero;
  remoteVideoViewFrame.origin.x = 0;
  remoteVideoViewFrame.origin.y = 0;
  remoteVideoViewFrame.size.width = width;
  remoteVideoViewFrame.size.height = height;
  videoView.frame=remoteVideoViewFrame;
  
//  videoView.contentMode = UIViewContentModeScaleAspectFill; // <— Doesn’t seem to work?
  NSLog(@"[ZSPDEBUG Function:%s Line:%d] remoteStream:%@ streamid:%@ width:%d height:%d", __FUNCTION__,__LINE__,remoteStream,[remoteStream streamId],width,height);
  
  [self.remoteRenderer setObject:videoView forKey:remoteStream.streamId];
  if ([NSThread isMainThread]) {
    [_videoViewGroup reloadData];
  }else {
    dispatch_sync(dispatch_get_main_queue(),^(){
      [_videoViewGroup reloadData];
    });
  }
  return videoView;
}

-(void)removeRemoteStreamRenderer:(OWTRemoteStream*)remoteStream{
  NSLog(@"[ZSPDEBUG Function:%s Line:%d] remoteStream:%@ streamid:%@", __FUNCTION__,__LINE__,remoteStream,[remoteStream streamId]);
  __block UIView<RTCVideoRenderer> * videoView = [self.remoteRenderer objectForKey:remoteStream.streamId];
  if(videoView != nil){
    [self.remoteRenderer removeObjectForKey:remoteStream.streamId];

    if ([NSThread isMainThread]) {
      [videoView removeFromSuperview];
      [_videoViewGroup reloadData];
    }else {
      dispatch_sync(dispatch_get_main_queue(),^(){
        [videoView removeFromSuperview];
        [_videoViewGroup reloadData];
      });
    }
  }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
  if (section == 0) {
    return 1;
  }else{
    return [_remoteRenderer count];
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 480;
//  int height = 0;
//  if (indexPath.section == 0) {
//    height = 480;
//  }else if(indexPath.section == 1){
//    if(indexPath.row < [_remoteRenderer count]){
//      UIView<RTCVideoRenderer> * videoView = [[_remoteRenderer allValues] objectAtIndex:indexPath.row];
//      if (videoView != nil) {
//        height = videoView.bounds.size.height;
//      }
//    }
//  }
//  return height;
}



- (VideoViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
  static NSString *cell_id = @"videoViewCell";
  VideoViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cell_id forIndexPath:indexPath];
  if (cell == nil) {
    cell = [[VideoViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cell_id];
  }
  if (indexPath.section == 0) {
    cell.videoView = _localVideoView;
  }else if(indexPath.section == 1){
    if(indexPath.row < [_remoteRenderer count]){
      UIView<RTCVideoRenderer> * videoView = [[_remoteRenderer allValues] objectAtIndex:indexPath.row];
      if (videoView != nil) {
        cell.videoView = videoView;
      }
    }else{
      cell.videoView = nil;
    }
    
  }
  
  return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
  return 2;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
  return [_videoGroupString objectAtIndex:section];
}

//display section index scroll
//- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView{
//  return _videoGroupString;
//}

@end
