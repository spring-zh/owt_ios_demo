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

#import "HorizontalSegue.h"

@implementation HorizontalSegue

- (void) perform
{
  UIViewController *desViewController = (UIViewController *)self.destinationViewController;
  
  UIView *srcView = [(UIViewController *)self.sourceViewController view];
  UIView *desView = [desViewController view];
  
  desView.transform = srcView.transform;
  desView.bounds = srcView.bounds;
  
  if(_isLandscapeOrientation)
  {
    if(_isDismiss)
    {
      desView.center = CGPointMake(srcView.center.x, srcView.center.y  - srcView.frame.size.height);
    }
    else
    {
      desView.center = CGPointMake(srcView.center.x, srcView.center.y  + srcView.frame.size.height);
    }
  }
  else
  {
    if(_isDismiss)
    {
      desView.center = CGPointMake(srcView.center.x - srcView.frame.size.width, srcView.center.y);
    }
    else
    {
      desView.center = CGPointMake(srcView.center.x + srcView.frame.size.width, srcView.center.y);
    }
  }
  
  
  UIWindow *mainWindow = [[UIApplication sharedApplication].windows objectAtIndex:0];
  [mainWindow addSubview:desView];
  
  // slide newView over oldView, then remove oldView
  [UIView animateWithDuration:0.5
                   animations:^{
                     desView.center = CGPointMake(srcView.center.x, srcView.center.y);
                     
                     if(_isLandscapeOrientation)
                     {
                       if(_isDismiss)
                       {
                         srcView.center = CGPointMake(srcView.center.x, srcView.center.y + srcView.frame.size.height);
                       }
                       else
                       {
                         srcView.center = CGPointMake(srcView.center.x, srcView.center.y - srcView.frame.size.height);
                       }
                     }
                     else
                     {
                       if(_isDismiss)
                       {
                         srcView.center = CGPointMake(srcView.center.x + srcView.frame.size.width, srcView.center.y);
                       }
                       else
                       {
                         srcView.center = CGPointMake(srcView.center.x - srcView.frame.size.width, srcView.center.y);
                       }
                     }
                   }
                   completion:^(BOOL finished){
                     if (finished) {
                       [srcView removeFromSuperview];
                       mainWindow.rootViewController = desViewController;
                     }
                   }];
}

@end
