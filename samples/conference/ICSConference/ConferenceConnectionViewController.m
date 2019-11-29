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

#import <AFNetworking/AFNetworking.h>
#import <OWT/OWT.h>
#import "ConferenceConnectionViewController.h"
#import "AppDelegate.h"
#import "HorizontalSegue.h"

typedef NS_ENUM(NSInteger, StreamMode) {
    Mesh = 0,
    SFU,
    MCU
};

@interface ConferenceConnectionViewController () 

-(void)getTokenFromBasicSample:(NSString *)basicServer onSuccess:(void (^)(NSString *))onSuccess onFailure:(void (^)())onFailure;

@property (nonatomic) OWTConferenceClient* conferenceClient;

@end

@implementation ConferenceConnectionViewController{
  NSArray<NSString*> *_pickerData;
  NSMutableArray<NSDictionary*> *_roomsData;
  StreamMode _streamMode;
  NSDictionary *_room_info;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  self.hostTb.delegate=self;
  AppDelegate* appDelegate = (id)[[UIApplication sharedApplication]delegate];
  _conferenceClient=[appDelegate conferenceClient];
  NSString *tmpStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"userDefaultURL"];
  
  //init stream mode picker
  _pickerData = [[NSArray alloc] initWithObjects:@"Mesh",
                 @"SFU",
                 @"MCU",
                 nil];
  self.streamModePv.showsSelectionIndicator = YES;
  self.streamModePv.delegate = self;
  self.streamModePv.dataSource = self;
  [self.streamModePv selectRow:1 inComponent:0 animated:TRUE];
  _streamMode = SFU;
  
  //init rooms picker
  _roomsData = [[NSMutableArray alloc] init];
  self.roomPv.showsSelectionIndicator = YES;
  self.roomPv.delegate = self;
  self.roomPv.dataSource = self;
  _room_info = nil;

//  if (tmpStr && tmpStr.length != 0) {
//    [_hostTb setText: tmpStr];
//  }
  // Socket.IO library uese low level network APIs. In some iOS 10 devices, OS does not ask user for network permission. As a result, Socket.IO connection fails because app does not have network access. Following code uese Objective-C API to trigger a network request, so user will have the chance to allow network permission for this app.
  NSMutableURLRequest *request=[[NSMutableURLRequest alloc]init];
  [request setURL:[NSURL URLWithString:@"https://www.apple.com"]];
  NSOperationQueue *queue = [[NSOperationQueue alloc] init];
  [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
    // Nothing here.
  }];
  
  //update rooms picker info
  [self getRoomsFormServer:_hostTb.text onSuccess:^(NSDictionary * roomsdict) {
    NSLog(@"[ZSPDEBUG Function:%s Line:%d] rooms:%@", __FUNCTION__,__LINE__,roomsdict);
    _roomsData = [[NSMutableArray alloc] init];
    for (id key in roomsdict) {
      NSLog(@"[ZSPDEBUG Function:%s Line:%d] rooms:%@", __FUNCTION__,__LINE__,key);
      [_roomsData addObject:key];
    }
    [self.roomPv reloadAllComponents];
    _room_info = [_roomsData objectAtIndex:0];
  } onFailure:^{
    NSLog(@"Failed to get Rooms from basic server.");
  }];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField{
  [self.hostTb resignFirstResponder];
  return YES;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  if(pickerView == self.streamModePv){
    _streamMode = row;
  }else if(pickerView == self.roomPv){
    if(row < [_roomsData count])
      _room_info = [_roomsData objectAtIndex:row];
  }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view{
  UILabel *lable;
  if (view == nil) {
    lable = [[UILabel alloc] init];
    lable.font = [UIFont systemFontOfSize:20];
    lable.contentMode = UIViewContentModeCenter;
  }else
    lable = view;
  
  if(pickerView == self.streamModePv){
    lable.text = [_pickerData objectAtIndex:row];
  }else if(pickerView == self.roomPv){
    if(row < [_roomsData count]){
      NSDictionary *dictionary = [_roomsData objectAtIndex:row];
      NSString *room_id_str = [dictionary objectForKey:@"_id"];
      NSString *room_name_str = [dictionary objectForKey:@"name"];
      lable.text = [[NSString alloc] initWithFormat:@"%s(%s)",[room_name_str UTF8String],[room_id_str UTF8String]];
    }
  }
  return lable;
}

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
  return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
  if(pickerView == self.streamModePv){
    return [_pickerData count];
  }else if(pickerView == self.roomPv){
    return [_roomsData count];
  }
  return 0;
}


-(void)getTokenFromBasicSample:(NSString *)basicServer roomId:(NSString *)roomId onSuccess:(void (^)(NSString *))onSuccess onFailure:(void (^)())onFailure{
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  manager.requestSerializer = [AFJSONRequestSerializer serializer];
  [manager.requestSerializer setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  manager.responseSerializer = [AFHTTPResponseSerializer serializer];
  manager.securityPolicy.allowInvalidCertificates=YES;
  manager.securityPolicy.validatesDomainName=NO;
  NSDictionary *params = [[NSDictionary alloc]initWithObjectsAndKeys:roomId, @"room", @"user", @"username", @"presenter", @"role", nil];
  [manager POST:[basicServer stringByAppendingString:@"createToken/"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSData* data=[[NSData alloc]initWithData:responseObject];
    onSuccess([[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
  }];
}

-(void)getRoomsFormServer:(NSString *)basicServer onSuccess:(void (^)(NSDictionary *))onSuccess onFailure:(void (^)())onFailure{
  AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
  manager.requestSerializer = [AFJSONRequestSerializer serializer];
  [manager.requestSerializer setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
  manager.responseSerializer = [AFJSONResponseSerializer serializer];
//  manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json",@"text/json", @"text/plain", @"text/html", nil];
  manager.securityPolicy.allowInvalidCertificates=YES;
  manager.securityPolicy.validatesDomainName=NO;
  NSDictionary *params = [[NSDictionary alloc] init];
  [manager GET:[basicServer stringByAppendingString:@"rooms/"] parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
    NSDictionary *resp_data = responseObject;
    onSuccess([resp_data copy]);
  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
    NSLog(@"Error: %@", error);
  }];
}

- (IBAction)connectBtnTouchDown:(id)sender {
  [[NSUserDefaults standardUserDefaults] setValue:_hostTb.text forKey:@"userDefaultURL"];
  if (_room_info == nil) {
    NSLog(@"[ZSPDEBUG Function:%s Line:%d] can not read rooms info",__FUNCTION__,__LINE__);
    return;
  }
  NSString * room_id = [_room_info objectForKey:@"_id"];
  [self getTokenFromBasicSample:_hostTb.text roomId:room_id onSuccess:^(NSString *token) {
    NSData *base64_date = [[NSData alloc] initWithBase64EncodedString:token options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSString *raw_string =[[NSString alloc] initWithData:base64_date encoding:NSUTF8StringEncoding];
//    NSLog(@"[ZSPDEBUG Function:%s Line:%d] token:%@", __FUNCTION__,__LINE__,raw_string);
    [_conferenceClient joinWithToken:token onSuccess:^(OWTConferenceInfo* info) {
      dispatch_async(dispatch_get_main_queue(), ^{
//        NSLog(@"[ZSPDEBUG Function:%s Line:%d] RemoteStream Count:%lu", __FUNCTION__,__LINE__, (unsigned long)[info.remoteStreams count]);
        if([info.remoteStreams count]>0){
          AppDelegate* appDelegate = (AppDelegate*)[[UIApplication sharedApplication]delegate];
          appDelegate.conferenceId=info.conferenceId;
          appDelegate.remoteStreams = [[NSMutableArray alloc] init];
          for(OWTRemoteStream* s in info.remoteStreams){
            [appDelegate.remoteStreams addObject:s];
            s.delegate=appDelegate;
            if([s isKindOfClass:[OWTRemoteMixedStream class]]){
              appDelegate.mixedStream=(OWTRemoteMixedStream*)s;
//              break;
            }
          }
        }
        switch (_streamMode) {
          case Mesh:
            NSLog(@"UnSupport Mesh Mode.");
            break;
          case SFU:
            [self performSegueWithIdentifier:@"Login SFU" sender:self];
            break;
          case MCU:
            [self performSegueWithIdentifier:@"Login" sender:self];
            break;
          default:
            break;
        }
      });
    } onFailure:^(NSError* err) {
      NSLog(@"Join failed. %@", err);
    }];
  } onFailure:^{
    NSLog(@"Failed to get token from basic server.");
  }];
  
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  HorizontalSegue *s = (HorizontalSegue *)segue;
  s.isDismiss = NO;
}


@end
