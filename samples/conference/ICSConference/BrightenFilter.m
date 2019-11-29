/*
 * Copyright © 2017 Intel Corporation. All Rights Reserved.
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

#import "BrightenFilter.h"
#import <CoreImage/CoreImage.h>
#import <WebRTC/WebRTC.h>

@implementation BrightenFilter {
  id<RTCVideoCapturerDelegate> _output;
  CIContext* _context;
  CIFilter* _filter;
  CVPixelBufferRef _buffer;
}

- (instancetype)initWithOutput:(id<RTCVideoCapturerDelegate>)output {
  NSAssert(output != nil, @"output cannot be nil.");
  if (self = [super init]) {
    _enabled = NO;
    _output = output;
    _context = [[CIContext alloc] init];
    _filter = [CIFilter filterWithName:@"CIColorControls"];
    [_filter setDefaults];
    [_filter setValue:[NSNumber numberWithFloat:0.2] forKey:@"inputBrightness"];
  }
  return self;
}

- (void)capturer:(RTCVideoCapturer*)capturer
    didCaptureVideoFrame:(RTCVideoFrame*)frame {
  // If frame does not have a native handle, we need to convert I420 buffer to
  // CIImage. It is a rare case, so we don't handle it here.
  if ([frame.buffer isKindOfClass:[RTCCVPixelBuffer class]] || !_enabled) {
    [_output capturer:capturer didCaptureVideoFrame:frame];
    return;
  }
  [_filter setValue:[CIImage imageWithCVImageBuffer:((RTCCVPixelBuffer*)frame.buffer).pixelBuffer]
             forKey:@"inputImage"];
  CIImage* filteredImage = [_filter outputImage];
  CVPixelBufferRelease(_buffer);
  CVReturn result = CVPixelBufferCreate(
      kCFAllocatorDefault, frame.width, frame.height,
      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, NULL, &_buffer);
  if (result != kCVReturnSuccess) {
    [_output capturer:capturer didCaptureVideoFrame:frame];
    return;
  }
  [_context render:filteredImage toCVPixelBuffer:_buffer];
  RTCVideoFrame* filteredFrame =[[RTCCVPixelBuffer alloc] initWithPixelBuffer:_buffer];
  [_output capturer:capturer didCaptureVideoFrame:filteredFrame];
}

@end
