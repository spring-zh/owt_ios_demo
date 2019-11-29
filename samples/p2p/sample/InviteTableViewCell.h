//
//  InviteTableViewCell.h
//  WoogeenChat
//
//  Created by webrtctest25 on 7/15/15.
//  Copyright (c) 2015 Intel Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol InviteCellDelegate <NSObject>

- (void) inviteById:(NSString*) remoteId;
- (void) stopById:(NSString*) remoteId;
@end

@interface InviteTableViewCell : UITableViewCell <UITextFieldDelegate> {
  UILabel* idLabel;
  UITextField* idTextField;
  UIButton* inviteBtn;
  UIButton* stopBtn;
}

@property (nonatomic,strong) NSString* inviter;
@property(nonatomic,weak) id<InviteCellDelegate> delegate;

@end
