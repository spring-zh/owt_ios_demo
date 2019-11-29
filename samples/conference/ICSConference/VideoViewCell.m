//
//  ZSPTableViewCell.m
//  ICSConference
//
//  Created by spring on 2019/10/28.
//  Copyright © 2019 Intel Corporation. All rights reserved.
//

#import "VideoViewCell.h"

@implementation VideoViewCell

-(instancetype)initWithFrame:(CGRect)frame{
  if(self=[super initWithFrame:frame]){
    self.contentMode = UIViewContentModeCenter;
  }
  return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setVideoView:(UIView *)videoView{
  if(_videoView == videoView)
    return;
  
  if (_videoView) {
    [_videoView removeFromSuperview];
  }
  if(videoView != nil){
    [self addSubview:videoView];
  }
  
  _videoView = videoView;
}

-(void)layoutSubviews{
  CGRect rt = self.frame;
//  rt.size = CGSizeMake(rt.size.width-20, rt.size.height-20);
//  rt.origin = CGPointMake(rt.origin.x+20, rt.origin.y+20);
//  _videoView.frame = rt;
}

@end
