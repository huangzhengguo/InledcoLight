//
//  DeviceDataType.h
//  InledcoPlant
//
//  Created by huang zhengguo on 2017/6/12.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeviceDataType : NSObject

//单例类实现
+(instancetype)defaultDeviceDataType;

@property(nonatomic, strong) NSArray *deviceCodeArray;
@property(nonatomic, strong) NSMutableDictionary *deviceCodeInfoDic;

@end
