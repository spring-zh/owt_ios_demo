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


#ifndef sample_StreamView_h
#define sample_StreamView_h

#import <OWT/OWT.h>
#import <WebRTC/WebRTC.h>

#define MAX_CONNECTERS 4
#define GetColorFromHex(hexColor) \
[UIColor colorWithRed:((hexColor >> 16) & 0xFF) / 255.0 \
green:((hexColor >>  8) & 0xFF) / 255.0 \
blue:((hexColor >>  0) & 0xFF) / 255.0 \
alpha:((hexColor >> 24) & 0xFF) / 255.0]

@class StreamView;
@protocol StreamViewDelegate <NSObject>
/// Called when publish button is touched
- (void) quitBtnDidTouchedDown:(StreamView*)view;

@end

@interface StreamView:UIView {
  // Auto-adjust to the screen size
  CGRect screenSize;
}

@property(nonatomic,readonly) RTCCameraPreviewView *localVideoView;
@property(nonatomic,readonly) UIView<RTCVideoRenderer> *remoteVideoView;
@property(strong, nonatomic) UIActivityIndicatorView *act;
@property(nonatomic, strong) NSString* stats;
@property(nonatomic,weak) id<StreamViewDelegate> delegate;

@end

#endif
