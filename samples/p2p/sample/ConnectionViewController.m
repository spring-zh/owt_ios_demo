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

#import <OWT/OWT.h>
#import "ConnectionViewController.h"
#import "SocketSignalingChannel.h"

@interface ConnectionViewController ()

@property(nonatomic) OWTP2PClient* peerClient;

@end

@implementation ConnectionViewController

- (void)showMsg: (NSString *)msg
{
  UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:msg preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
  [alertController addAction:okAction];
  [self presentViewController:alertController animated:YES completion:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];

  // register
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNotification:) name:nil object:nil];

  _peerClient=[appDelegate peerClient];
  NSString *tmpStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"userDefaultURL"];
  if (tmpStr && tmpStr.length != 0) {
    [_urlTb setText: tmpStr];
  }
  tmpStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"userDefaultToken"];
  if (tmpStr && tmpStr.length != 0) {
    [_tokenTb setText: tmpStr];
  }

  // Socket.IO library uese low level network APIs. In some iOS 10 devices, OS does not ask user for network permission. As a result, Socket.IO connection fails because app does not have network access. Following code uese Objective-C API to trigger a network request, so user will have the chance to allow network permission for this app.
  NSMutableURLRequest *request=[[NSMutableURLRequest alloc]init];
  [request setURL:[NSURL URLWithString:@"https://www.apple.com"]];
  NSOperationQueue *queue = [[NSOperationQueue alloc] init];
  [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
    // Nothing here.
  }];
}

- (void) loadView {
  [super loadView];

}
- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (IBAction)TextField_DidEndOnExit:(id)sender {    // hide the keyboard.
  [sender resignFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  HorizontalSegue *s = (HorizontalSegue *)segue;
  s.isDismiss = NO;
  s.isLandscapeOrientation = NO;
}

- (IBAction)connectBtnTouchDown:(id)sender {

  NSMutableDictionary *tokenDict=[[NSMutableDictionary alloc]init];
  [tokenDict setValue:_urlTb.text forKey:@"host"];
  [tokenDict setValue:_tokenTb.text forKey:@"token"];
  [[NSUserDefaults standardUserDefaults] setValue:_urlTb.text forKey:@"userDefaultURL"];
  [[NSUserDefaults standardUserDefaults] setValue:_tokenTb.text forKey:@"userDefaultToken"];
  NSError* error;
  NSData* tokenData=[NSJSONSerialization dataWithJSONObject:tokenDict options:NSJSONWritingPrettyPrinted error:&error];
  NSString *tokenString=[[NSString alloc]initWithData:tokenData encoding:NSUTF8StringEncoding];
  if(error){
    NSLog(@"Failed to get token.");
    return;
  }
  // TODO: Please avoid to execute connect immediatly after a previous session is closed. When WebSocket old run loop ends, it may clean all event listeners binded, also includes listenrs for the new session.
  [_peerClient connect:tokenString onSuccess:^(NSString *msg){
    NSLog(@"Login success.");
    dispatch_async(dispatch_get_main_queue(), ^{
      [self performSegueWithIdentifier:@"MySegue" sender:self];
    });
  } onFailure:^(NSError * _Nonnull err){
    NSLog(@"Login fail.");
  }];
}



-(void)onNotification:(NSNotification *)notification{

}


@end
