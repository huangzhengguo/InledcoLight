//
//  BlueToothManager.h
//  InledcoPlant
//
//  Created by huang zhengguo on 2017/5/15.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

// 版本信息2017.06.22确认

#import <Foundation/Foundation.h>
#import "DeviceParameterModel.h"
#import "ECOPlantParameterModel.h"

// 设备运行模式
typedef NS_ENUM(NSInteger, DeviceRunMode) {
    MANUAL_MODE = 0,
    AUTO_MODE,
    UNKNOWN_MODE
};

// 指令类型：用于判断当前接收到的数据是由于什么类型的指令引起的
typedef NS_ENUM(NSInteger, SendCommandType) {
    TIMESYNCHRONIZATION_COMMAND, // 同步时间命令
    POWERON_COMMAND,             // 打开灯光命令
    POWEROFF_COMMAND,            // 关闭灯光命令
    MANUALMODE_COMMAND,          // 手动模式命令
    AUTOMODE_COMMAND,            // 自动模式命令
    READTIME_COMMAND,            // 读取时间命令
    FINDDEVICE_COMMAND,          // 查找设备命令
    OTA_COMMAND,                 // OTA升级命令
    READDEVICEINFO_COMMAND,      // 读取设备
    
    // OTA下的命令
    READBLEINFOR_COMMAND,        // 获取蓝牙版本等信息
    ERASURE_COMMAND,             // 擦除闪存命令
    WRITE_COMMAND,               // 写入闪存命令
    RESTART_COMMAND,             // 重启命令
    OTHER_COMMAND
};

typedef void(^scanBlock)(NSArray *);
typedef void(^noneParameterBlock)();
typedef void(^passStringBlock)(NSString *);

@interface BlueToothManager : NSObject
/*
 * 蓝牙管理单例对象
 */
+(instancetype)defaultBlueToothManager;

/*
 * 开始扫描设备，扫描时长为time
 * 
 * @param time 扫描持续的时长
 *
 */
- (void)StartScanWithTime:(NSInteger)time;

/*
 * 停止扫描设备
 */
- (void)StopScan;

/*
 * 使用UUID连接到设备
 *
 * @param UUID 设备UUID
 */
- (void)connectToDeviceWithUUID:(NSString *)UUID;

/*
 * 断开设备
 *
 * @param UUID 设备UUID
 */
- (void)disConnectToDeviceWithUUID:(NSString *)UUID;

// 开始扫面设备回调
@property(nonatomic, copy) scanBlock scanDeviceBlock;
// 停止扫描设备回调
@property(nonatomic, copy) noneParameterBlock stopScanDeviceBlock;
// 连接设备成功回调
@property(nonatomic, copy) passStringBlock completeReceiveDataBlock;
// 连接设备失败回调
@property(nonatomic, copy) noneParameterBlock connectDeviceFailedBlock;
// 断开连接回调
@property(nonatomic, copy) noneParameterBlock disConnectDeviceBlock;

/*
 * Hagen App使用的解析方法
 * @param receiveData 从设备接收到的数据
 * @param deviceInfoModel 设备模型
 */
- (void)parseDataFromReceiveData:(NSString *)receiveData deviceInfoModel:(DeviceParameterModel *)deviceInfoModel;

/*
 * ECO植物灯App使用的解析方法
 */
- (void)parseECOPlantDataFromReceiveData:(NSString *)receiveData deviceInfoModel:(ECOPlantParameterModel *)deviceInfoModel;

// 上次发送命令的时间
@property (nonatomic, assign) UInt64 lastDimmSendTime;
- (void)sendCommandWithUUID:(NSString *)uuidString interval:(long)interval channelNum:(NSInteger)channelNum colorIndex:(NSInteger)colorIndex colorValue:(float)colorValue;
- (void)sendCommandWithUUIDString:(NSString *)uuidString commandStr:(NSString *)commandStr;
- (void)sendCommandWithDevice:(CBPeripheral *)device commandStr:(NSString *)commandStr;

// 常用命令封装
- (void)sendPowerOnCommand:(NSString *)uuidString;
- (void)sendPowerOffCommand:(NSString *)uuidString;
- (void)sendManualModeCommand:(NSString *)uuidString;
- (void)sendAutoModeCommand:(NSString *)uuidString;
- (void)sendReadTimeCommand:(NSString *)uuidString;
- (void)sendFindDeviceCommand:(NSString *)uuidString;
- (void)sendOTACommand:(NSString *)uuidString;
@end

































