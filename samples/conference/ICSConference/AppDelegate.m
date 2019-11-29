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
#import <WebRTC/WebRTC.h>

#import "AppDelegate.h"

//#import "FileAudioFrameGenerator.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
  _mixedStream = [[OWTRemoteMixedStream alloc] init];
    [self.window setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.jpg"]]];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (OWTConferenceClient*)conferenceClient{
  if (_conferenceClient==nil){
    //NSString* path=[[NSBundle mainBundle]pathForResource:@"audio_long16" ofType:@"pcm"];
    //FileAudioFrameGenerator* generator=[[FileAudioFrameGenerator alloc]initWithPath:path sampleRate:16000 channelNumber:1];
    //[RTCGlobalConfiguration setCustomizedAudioInputEnabled:YES audioFrameGenerator:generator];
    OWTConferenceClientConfiguration* config=[[OWTConferenceClientConfiguration alloc]init];
    NSArray *ice=[[NSArray alloc]initWithObjects:[[RTCIceServer alloc]initWithURLStrings:[[NSArray alloc]initWithObjects:@"stun:61.152.239.47:3478", nil]], nil];
    config.rtcConfiguration=[[RTCConfiguration alloc] init];
//    config.rtcConfiguration.iceServers=ice;
    _conferenceClient=[[OWTConferenceClient alloc]initWithConfiguration:config];
    _conferenceClient.delegate=self;
  }
  return _conferenceClient;
}

-(void)onVideoLayoutChanged{
  NSLog(@"OnVideoLayoutChanged.");
}

-(void)conferenceClient:(OWTConferenceClient *)client didAddStream:(OWTRemoteStream *)stream{
  NSLog(@"AppDelegate on stream added");
  stream.delegate=self;
  if ([stream isKindOfClass:[OWTRemoteMixedStream class]]) {
    _mixedStream = (OWTRemoteMixedStream *)stream;
    _mixedStream.delegate=self;
  }
  if(stream.source.video==OWTVideoSourceInfoScreenCast){
    _screenStream=stream;
  }
  [self.remoteStreams addObject:stream];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnStreamAdded" object:self userInfo:[NSDictionary dictionaryWithObject:stream forKey:@"stream"]];
}

-(void)conferenceClientDidDisconnect:(OWTConferenceClient *)client{
  NSLog(@"Server disconnected");
  _mixedStream = nil;
}

-(void)conferenceClient:(OWTConferenceClient *)client didReceiveMessage:(NSString *)message from:(NSString *)senderId{
  NSLog(@"AppDelegate received message: %@, from %@", message, senderId);
}

- (void)conferenceClient:(OWTConferenceClient *)client didAddParticipant:(OWTConferenceParticipant *)user{
  user.delegate=self;
  NSLog(@"A new participant joined the meeting.");
}

-(void)streamDidEnd:(OWTRemoteStream *)stream{
  NSLog(@"Stream did end");
  [self.remoteStreams removeObject:stream];
  [[NSNotificationCenter defaultCenter] postNotificationName:@"OnStreamRemoved" object:self userInfo:[NSDictionary dictionaryWithObject:stream forKey:@"stream"]];
}

-(void)participantDidLeave:(OWTConferenceParticipant *)participant{
  NSLog(@"Participant left conference.");
}

@end
