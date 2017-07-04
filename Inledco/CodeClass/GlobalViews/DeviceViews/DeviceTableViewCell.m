//
//  DeviceTableViewCell.m
//  Inledco
//
//  Created by huang zhengguo on 2017/7/4.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

#import "DeviceTableViewCell.h"

@interface DeviceTableViewCell()

@property (weak, nonatomic) IBOutlet UIImageView *devicePictureImageView;

@property (weak, nonatomic) IBOutlet UILabel *deviceNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceDetailInfoLabel;

@end

@implementation DeviceTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
