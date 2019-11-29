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
#import "OWT/OWT.h"
#import "SocketSignalingChannel.h"

#include "sio_client.h"
#include "sio_message.h"

@interface SocketSignalingChannel()

-(void)onOWTMessage:(NSString*)message from:(NSString*)senderId;
-(void)onServerAuthenticated:(NSString*)uid;

@end

@implementation SocketSignalingChannel{
  sio::client *_io;
  NSMutableArray *_observers;
  void (^_connectSuccessCallback)(NSString *);
  void (^_connectFailureCallback)(NSError *);
  void (^_disconnectComplete)();
}

-(id)init{
  self=[super init];
  _io=new sio::client();
  _observers=[[NSMutableArray alloc]init];
  return self;
}

-(void)connect:(NSString *)token onSuccess:(void (^)(NSString *))onSuccess onFailure:(void (^)(NSError*))onFailure{
  NSError *error = nil;
  NSData* stringData=[token dataUsingEncoding:NSUTF8StringEncoding ];
  NSDictionary* loginInfo=[NSJSONSerialization JSONObjectWithData:stringData options:NSJSONReadingMutableContainers error:&error];
  if(error){
    if(onFailure)
      onFailure(error);
    return;
  }
  _connectSuccessCallback=onSuccess;
  _connectFailureCallback=onFailure;

  // NSDictionary *infoDict = [[NSBundle bundleForClass:self] infoDictionary];
  // NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
  std::map<std::string, std::string> query;
  query.insert(std::pair<std::string, std::string>("clientVersion","4.2"));
  query.insert(std::pair<std::string, std::string>("clientType","iOS"));
  query.insert(std::pair<std::string, std::string>("token", [[loginInfo objectForKey:@"token"] UTF8String]));

  sio::socket::ptr socket = _io->socket();
  socket->on("owt-message",std::bind(&OnWoogeenMessage, (__bridge CFTypeRef)self, std::placeholders::_1,std::placeholders::_2,std::placeholders::_3,std::placeholders::_4));
  socket->on("server-authenticated",std::bind(&OnServerAuthenticated, (__bridge CFTypeRef)self, std::placeholders::_1,std::placeholders::_2,std::placeholders::_3,std::placeholders::_4));

  NSLog(@"Connect to %@",[loginInfo objectForKey:@"host"]);
  _io->set_reconnect_attempts(0);
  _io->set_fail_listener(std::bind(&OnSocketClientError, (__bridge CFTypeRef)self));
  _io->set_socket_close_listener(std::bind(&OnSocketClosed, (__bridge CFTypeRef)self));
  _io->connect([[loginInfo objectForKey:@"host"] UTF8String],query);
}

-(void)sendMessage:(NSString *)message to:(NSString *)targetId onSuccess:(void (^)())onSuccess onFailure:(void (^)(NSError *))onFailure{
  sio::message::ptr jsonObject = sio::object_message::create();
  jsonObject->get_map()["to"]=sio::string_message::create([targetId UTF8String]);
  jsonObject->get_map()["data"]=sio::string_message::create([message UTF8String]);
  _io->socket()->emit("owt-message",jsonObject, [=](sio::message::list const& msg){
    if(msg.size()==0){
      if(onSuccess==nil)
        return;
      onSuccess();
    } else{
      if(onFailure==nil)
        return;
      NSError *err=[[NSError alloc]initWithDomain:OWTErrorDomain code:OWTP2PErrorClientInvalidState userInfo:[[NSDictionary alloc]initWithObjectsAndKeys:@"Emit message to server failed.", NSLocalizedDescriptionKey, nil]];
      onFailure(err);
    }
  });
}

-(void)onOWTMessage:(NSString *)message from:(NSString *)senderId{
  if([_delegate respondsToSelector:@selector(channel:didReceiveMessage:from:)]){
    [_delegate channel:self didReceiveMessage:message from:senderId];
  }
}

- (void) onSocketClientError:(NSError *)err {
  // restore the state
  if (_io->opened()) {
    _io->close();
  }
  if(_connectFailureCallback){
    _connectFailureCallback(err);
    _connectFailureCallback=nil;
  }
}

-(void)onSocketClosed{
  if(_disconnectComplete){
    _disconnectComplete();
    _disconnectComplete=nil;
  }
  if([_delegate respondsToSelector:@selector(channelDidDisconnect:)]){
    [_delegate channelDidDisconnect:self];
  }
}

-(void)onServerAuthenticated:(NSString *)uid{
  if(_connectSuccessCallback){
    _connectSuccessCallback(uid);
    _connectSuccessCallback=nil;
  }
}

-(void)disconnectWithOnSuccess:(void (^)())onSuccess onFailure:(void (^)(NSError *))onFailure{
  if(!_io->opened()){
    if(onFailure){
      NSError *err = [[NSError alloc] initWithDomain:OWTErrorDomain code:OWTP2PErrorClientInvalidState userInfo:nil];
      onFailure(err);
    }
    return;
  }
  _io->close();
  _disconnectComplete=onSuccess;
}

void OnSocketClientError(CFTypeRef ctrl) {
  NSError *err = [[NSError alloc] initWithDomain:OWTErrorDomain code:OWTP2PErrorClientIllegalArgument userInfo:nil];
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [((__bridge SocketSignalingChannel*)ctrl) onSocketClientError:err];
  });
}

void OnSocketClosed(CFTypeRef ctrl){
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [((__bridge SocketSignalingChannel*)ctrl) onSocketClosed];
  });
}

void OnWoogeenMessage(CFTypeRef ctrl,std::string const& name,sio::message::ptr const& data,bool needACK,sio::message::list ackResp){
  if(data->get_flag() == sio::message::flag_object)
  {
    NSString* msg = [NSString stringWithUTF8String:data->get_map()["data"]->get_string().data()];
    NSString* from = [NSString stringWithUTF8String:data->get_map()["from"]->get_string().data()];
    [((__bridge SocketSignalingChannel*)ctrl) onOWTMessage:msg from:from];
  }
}

void OnServerAuthenticated(CFTypeRef ctrl,std::string const& name,sio::message::ptr const& data,bool needACK,sio::message::list ackResp){
  if(data->get_flag() == sio::message::flag_object)
  {
    NSString* uid = [NSString stringWithUTF8String:data->get_map()["uid"]->get_string().data()];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      [((__bridge SocketSignalingChannel*)ctrl) onServerAuthenticated:uid];
    });
  }
}


@end
