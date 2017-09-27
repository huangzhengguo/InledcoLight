//
//  DeviceDataType.m
//  InledcoPlant
//
//  Created by huang zhengguo on 2017/6/12.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

#import "DeviceDataType.h"

@implementation DeviceDataType

- (NSMutableDictionary *)deviceCodeInfoDic{
    if (_deviceCodeInfoDic == nil){
        self.deviceCodeInfoDic = [NSMutableDictionary dictionary];
    }
    
    return _deviceCodeInfoDic;
}

+(instancetype)defaultDeviceDataType{
    static DeviceDataType *deviceDataType = nil;
    deviceDataType = [[DeviceDataType alloc] init];
    
    return deviceDataType;
}

- (instancetype)init{
    if (self=[super init]){
        self.deviceCodeArray = @[CODE_9999];
        for (NSString *deviceCode in self.deviceCodeArray) {
            DeviceCodeInfo *deviceCodeInfo = [[DeviceCodeInfo alloc] init];
            if ([deviceCode isEqualToString:CODE_9999]){
                deviceCodeInfo.deviceName = @"Plant Light";
                deviceCodeInfo.pictureName = @"led.png";
                deviceCodeInfo.channelNumber = 3;
            }
            
            [self.deviceCodeInfoDic setObject:deviceCodeInfo forKey:deviceCode];
        }
    }
    
    return self;
}

@end
