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

#import "PrepareViewController.h"
#import "StreamViewController.h"

@interface PrepareViewController () {
  AppDelegate* appDelegate;
}

@property BOOL isCaller;
@property (nonatomic) OWTP2PClient *peerClient;

@end

@implementation PrepareViewController

- (void)viewDidLoad {
    [super viewDidLoad];
  _isCaller = NO;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onInvited:) name:@"OnInvited" object:nil];
  appDelegate = (id)[[UIApplication sharedApplication]delegate];
  _peerClient = appDelegate.peerClient;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)TextField_DidEndOnExit:(id)sender {    // hide the keyboard
  [sender resignFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (void) onInvited:(NSNotification *)notification{
  NSDictionary* userInfo = notification.userInfo;
  if([notification.name isEqualToString:@"OnInvited"]) {
    _isCaller = NO;
    appDelegate.remoteUserId = userInfo[@"remoteUserId"];
    dispatch_async(dispatch_get_main_queue(), ^{
      [self performSegueWithIdentifier: @"Dial" sender: self];
    });
  }
}

- (IBAction)call:(id)sender {
  _isCaller = YES;
  appDelegate.remoteUserId = _remoteUserId.text;
  _peerClient.allowedRemoteIds=@[appDelegate.remoteUserId];
  dispatch_async(dispatch_get_main_queue(), ^{
    [self performSegueWithIdentifier: @"Dial" sender: self];
  });
}

- (IBAction)logout:(id)sender {
  [_peerClient disconnectWithOnSuccess:^{
    dispatch_async(dispatch_get_main_queue(),^{
      [self performSegueWithIdentifier: @"Logout" sender: self];
    });
  } onFailure:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  HorizontalSegue *s = (HorizontalSegue *)segue;
  if ([segue.identifier isEqualToString:@"Logout"]) {
    s.isDismiss = YES;
  } else {
    s.isDismiss = NO;
    StreamViewController *svc = (StreamViewController*)[segue destinationViewController];
    svc.isCaller = _isCaller;
  }
  s.isLandscapeOrientation = NO;
  
}
@end
