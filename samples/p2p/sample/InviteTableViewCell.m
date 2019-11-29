//
//  InviteTableViewCell.m
//  WoogeenChat
//
//  Created by webrtctest25 on 7/15/15.
//  Copyright (c) 2015 Intel Corporation. All rights reserved.
//

#import "InviteTableViewCell.h"


@implementation InviteTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

//override it
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
//    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
    [self initSubView];
  }
  return self;
}

-(void)initSubView{
  // label
  idLabel = [[UILabel alloc]init];
  idLabel.text = @"Target id:";
  idLabel.textColor = [UIColor blueColor];
  idLabel.frame = CGRectMake(10, 0, 100, self.frame.size.height);
  [self addSubview:idLabel];
  
  // textField
  idTextField = [[UITextField alloc]init];
  [idTextField setBorderStyle:UITextBorderStyleRoundedRect];
  idTextField.returnKeyType = UIReturnKeyDefault;
  idTextField.delegate = self;
  [self addSubview:idTextField];
  
  // inviteBtn
  inviteBtn = [[UIButton alloc]init];
  [inviteBtn setTitle:@"Invite" forState:UIControlStateNormal];
  [inviteBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
  [inviteBtn addTarget:self action:@selector(onInviteBtnDown:) forControlEvents:UIControlEventTouchUpInside];
  inviteBtn.frame = CGRectMake(230, 0, 100, self.frame.size.height);
  [self addSubview:inviteBtn];
  
  // stopBtn
  stopBtn = [[UIButton alloc]init];
  [stopBtn setTitle:@"Stop" forState:UIControlStateNormal];
  [stopBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
  [stopBtn addTarget:self action:@selector(onStopBtnDown:) forControlEvents:UIControlEventTouchUpInside];
  stopBtn.frame = CGRectMake(340, 0, 100, self.frame.size.height);
  [self addSubview:stopBtn];
}

- (void) setInviter:(NSString *)inviter {
  idTextField.text = inviter;
  idTextField.frame = CGRectMake(120, 0, 60, self.frame.size.height);
  
}

// change state
- (void) onInviteBtnDown:(id) sender {
  [_delegate inviteById: idTextField.text];
}

- (void) onStopBtnDown:(id) sender {
  [_delegate stopById: idTextField.text];
}

// keyboard invisible
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
  if (theTextField == self->idTextField) {
    [theTextField resignFirstResponder];
  }
  return YES;
}

@end
