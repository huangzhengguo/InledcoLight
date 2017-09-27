//
//  DeviceCodeInfo.h
//  FluvalSmartApp
//
//  Created by huang zhengguo on 2017/7/26.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceCodeInfo : NSObject

@property(nonatomic, copy) NSString *deviceCode;
@property(nonatomic, copy) NSString *brand;
@property(nonatomic, copy) NSString *group;
@property(nonatomic, copy) NSString *deviceName;
@property(nonatomic, copy) NSString *pictureName;
@property(nonatomic, assign) NSInteger channelNumber;
@property(nonatomic, assign) NSInteger firmwareId;
@property(nonatomic, strong) NSArray *channelColorArray;
@property(nonatomic, strong) NSArray *channelColorTitleArray;

@end
