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
#import "FileAudioFrameGenerator.h"

@implementation FileAudioFrameGenerator{
  FILE *_fd;
  NSInteger _sampleRate;
  NSInteger _channelNumber;
  NSInteger _bufferSize;
}

-(instancetype)initWithPath:(NSString *)path sampleRate:(NSInteger)sampleRate channelNumber:(NSInteger)channelNumber{
  self = [super init];
  _sampleRate=sampleRate;
  _channelNumber=channelNumber;
  NSInteger sampleSize=16;
  NSInteger framesIn10Ms=sampleRate/100;
  _bufferSize=framesIn10Ms*channelNumber*sampleSize/8;
  _fd=fopen([path UTF8String], "rb");
  return self;
}

-(NSUInteger)channelNumber{
  return _channelNumber;
}

-(NSUInteger)sampleRate{
  return _sampleRate;
}

-(NSUInteger)framesForNext10Ms:(uint8_t*) buffer capacity:(const NSUInteger)capacity{
  if(capacity<_bufferSize){
    NSAssert(false,@"No enough memory to store frames for next 10 ms");
    return 0;
  }
  if(fread(buffer, 1, _bufferSize, _fd)!=_bufferSize){
    fseek(_fd,0,SEEK_SET);
    fread(buffer, 1, _bufferSize, _fd);
  }
  return _bufferSize;
}

@end
