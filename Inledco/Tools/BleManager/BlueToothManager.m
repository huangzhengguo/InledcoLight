//
//  BlueToothManager.m
//  InledcoPlant
//
//  Created by huang zhengguo on 2017/5/15.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

#import "BlueToothManager.h"
#import "BLEManager.h"
#import "DeviceInfo.h"
#import "DatabaseManager.h"
#import "StringRelatedManager.h"

// 发起连接设备的时长，超过该时长则视为扫描结束
#define CONNECTIONINTERVAL 2.0f
// 尝试连接的最大次数，超过此数则视为连接失败
#define MAXCONNECTIONCOUNT 3

@interface BlueToothManager()<BLEManagerDelegate>

// 数据库管理对象
@property(nonatomic, strong) DatabaseManager *databaseManager;
// 蓝牙管理对象
@property(nonatomic, strong) BLEManager *bleManager;
// 扫描定时器
@property(nonatomic, strong) NSTimer *scanTimer;
// 连接设备定时器
@property(nonatomic, strong) NSTimer *connTimer;
@property(nonatomic, assign) NSInteger connectCount;
// 设备模型数组
@property(nonatomic, strong) NSMutableArray *deviceModelArray;
// 接收数据完成标记
@property(nonatomic, assign) BOOL isReceiveAllData;
// 存储接收数据
@property(nonatomic, strong) NSString *receivedData;
// 发送命令类型
@property(nonatomic, assign) SendCommandType currentCommandType;

@end

@implementation BlueToothManager

// 设备模型数组
- (NSMutableArray *)deviceModelArray{
    if (_deviceModelArray == nil){
        self.deviceModelArray = [NSMutableArray array];
    }
    
    return _deviceModelArray;
}

// 类方法使用+号表示
+(instancetype)defaultBlueToothManager{
    static BlueToothManager *blueToothManager = nil;
    if (blueToothManager != nil){
        // 设置代理，保证代理只在该类中执行
        blueToothManager.bleManager.delegate = blueToothManager;
    }
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 初始化属性
        blueToothManager = [[BlueToothManager alloc] init];
        blueToothManager.isReceiveAllData = NO;
        blueToothManager.connectCount = 0;
        blueToothManager.currentCommandType = OTHER_COMMAND;
        blueToothManager.receivedData = @"";
        blueToothManager.lastDimmSendTime = [NSDate date].timeIntervalSince1970 * 1000;
        blueToothManager.bleManager = [BLEManager defaultManager];
        blueToothManager.bleManager.delegate = blueToothManager;
        blueToothManager.databaseManager = [DatabaseManager defaultDatabaseManager];
    });
    
    return blueToothManager;
}

/*
 * 扫描及连接设备方法
 * 1.开始扫描- (void)StartScanWithTime:(NSInteger)time
 * 2.停止扫描- (void)StopScan
 * 3.连接到设备- (void)connectToDeviceWithUUID:(NSString *)UUID
 * 4.断开设备连接- (void)disConnectToDeviceWithUUID:(NSString *)UUID
 */
- (void)StartScanWithTime:(NSInteger)time{
    // 清除记忆：否则无法再次扫描到已经扫描过的设备
    [self.bleManager.dev_DICARRAY removeAllObjects];
    // 设置定时器开始扫描
    self.scanTimer = [NSTimer scheduledTimerWithTimeInterval:time target:self selector:@selector(StopScan) userInfo:nil repeats:NO];
    [self.bleManager scanDeviceTime:time];
}

- (void)StopScan{
    // 取消定时器
    if (self.scanTimer != nil){
        [self.scanTimer invalidate];
        self.scanTimer = nil;
    }
    
    // 停止扫描
    [self.bleManager manualStopScanDevice];
    
    // 停止后的代理
    if (self.stopScanDeviceBlock){
        self.stopScanDeviceBlock();
    }
}

#pragma mark --- 蓝牙代理方法
- (void)scanDeviceRefrash:(NSMutableArray *)array{
    // 扫描到的设备信息保存在Array数组中
    [self.deviceModelArray removeAllObjects];
    
    // 开始解析数据
    for (DeviceInfo *deviceInfo in array) {
        // 查找数据库中是否已经保存在数据库中
        NSArray *array = [self.databaseManager findDataFromTableWithTableName:DEVICE_TABLE colName:DEVICE_UUID colValue:deviceInfo.UUIDString];
        if (array.count > 0){
            // 如果数据库中已经存在存在则跳过
            continue;
        }
        
        // 解析设备类型编码
        NSDictionary *advertismentDic = nil;
        for (NSDictionary *dic in self.bleManager.dev_DICARRAY) {
            advertismentDic = nil;
            CBPeripheral *cb = [dic objectForKey:@"DEVICE"];
            if (cb == deviceInfo.cb){
                advertismentDic = [dic objectForKey:@"ADVERTISEMENT_DATA"];
                break;
            }
        }
        
        // 如果没有获取到广播数据，则继续for循环
        if (advertismentDic == nil){
            continue;
        }
        
        // 构建设备模型
        DeviceModel *deviceModel = [[DeviceModel alloc] init];
        
        deviceModel.deviceGroupName = @"Default";
        deviceModel.deviceName = deviceInfo.localName;
        deviceModel.UUIDString = deviceInfo.UUIDString;
        deviceModel.cb = [self.bleManager getDeviceByUUID:deviceInfo.UUIDString];
        deviceModel.isSelected = NO;
        
        // 从广播数据中解析设备编码
        NSMutableString *deviceTypeCode = [NSMutableString string];
        if ([advertismentDic.allKeys containsObject:@"kCBAdvDataManufacturerData"]){
            NSData *advertisementData = [advertismentDic objectForKey:@"kCBAdvDataManufacturerData"];
            Byte *dataByts = (Byte *)[advertisementData bytes];
            for (int i=0;i<4;i++){
                [deviceTypeCode appendFormat:@"%c",dataByts[i]];
            }
        }
        
        deviceModel.deviceTypeCode = deviceTypeCode;
        
        [self.deviceModelArray addObject:deviceModel];
        
        deviceModel = nil;
    }
    
    // 解析扫描到的设备后
    if (self.scanDeviceBlock){
        self.scanDeviceBlock(self.deviceModelArray);
    }
}

#pragma mark --- 连接设备
- (void)connectToDeviceWithUUID:(NSString *)UUID{
    // 初始化连接次数
    self.connectCount = 0;
    // 初始化连接设备的定时器
    self.connTimer = [NSTimer scheduledTimerWithTimeInterval:CONNECTIONINTERVAL target:self selector:@selector(sendConnectCommandToDevice:) userInfo:UUID repeats:YES];
    // 连接到设备
    self.isReceiveAllData = NO;
}

- (void)sendConnectCommandToDevice:(NSTimer *)timer{
    // 还应该对连接设备的次数进行计数，连接超过最大次数则视为连接失败
    if (++self.connectCount > MAXCONNECTIONCOUNT){
        [self.connTimer invalidate];
        self.connTimer = nil;
        KMYLOG(@"连接失败!");
        // 调用连接失败的block
        if (self.connectDeviceFailedBlock){
            self.connectDeviceFailedBlock();
        }
        
        return;
    }
    KMYLOG(@"正在连接设备，第%ld次！",self.connectCount);
    // 解析定时器携带的数据
    NSString *uuid = timer.userInfo;
    
    // 获取设备
    CBPeripheral *cb = [self.bleManager getDeviceByUUID:uuid];
    if ([self.bleManager.dev_DICARRAY containsObject:cb] == NO){
        [self.bleManager.dev_DICARRAY addObject:cb];
    }
    // 应该考虑到连接失败的情况，然后进行多次连接，暂时没有考虑
    [self.bleManager connectToDevice:cb];
}

- (void)disConnectToDeviceWithUUID:(NSString *)UUID{
    // 获取设备
    CBPeripheral *cb = [self.bleManager getDeviceByUUID:UUID];
    // 把设备添加到蓝牙管理对象数组中
    if ([self.bleManager.dev_DICARRAY containsObject:cb] == NO){
        [self.bleManager.dev_DICARRAY addObject:cb];
    }
    // 断开设备连接
    [self.bleManager disconnectDevice:cb];
}

#pragma mark --- 连接回调
- (void)connectDeviceSuccess:(CBPeripheral *)device error:(NSError *)error{
    // 清空连接有关的信息
    if (self.connTimer != nil){
        [self.connTimer invalidate];
        self.connTimer = nil;
    }
    
    // 连接成功
    KMYLOG(@"连接成功;错误信息=%@",error);
    // 向设备发送同步时间命令，获取设备参数，会接收到两份返回的数据
    [self sendTimeSynchronizationCommand:device];
}

#pragma mark --- 断开设备
- (void)didDisconnectDevice:(CBPeripheral *)device error:(NSError *)error{
    // 断开成功
    KMYLOG(@"断开设备");
    if (self.disConnectDeviceBlock){
        self.disConnectDeviceBlock();
    }
}

#pragma mark --- 接收到设备数据
- (void)receiveDeviceDataSuccess_1:(NSData *)data device:(CBPeripheral *)device{
    /*
     * 此处判断数据是否已经接收完毕；如果接收完毕则不再接收数据；防止同一类型的命令多次接收数据
     */
    if (self.isReceiveAllData == YES){
        return;
    }
    // 接收完数据之后，取消正在连接设备的提示
    self.receivedData = [self.receivedData stringByAppendingString:[StringRelatedManager hexToStringWithData:data]];
    if ([[StringRelatedManager calculateXORWithString:[self.receivedData substringToIndex:self.receivedData.length-2]] isEqualToString:[self.receivedData substringFromIndex:self.receivedData.length-2]]){
        // 输出接收到的完整的数据
        KMYLOG(@"self.receivedData=%@",self.receivedData);
        switch (self.currentCommandType) {
            case TIMESYNCHRONIZATION_COMMAND:
            case POWERON_COMMAND:
            case POWEROFF_COMMAND:
            case MANUALMODE_COMMAND:
            case AUTOMODE_COMMAND:{
                // 返回的是设备信息
                if (self.completeReceiveDataBlock){
                    // 把解析到的数据传递出去
                    self.completeReceiveDataBlock(self.receivedData);
                }
                break;
            }
                
            default:
                break;
        }
        // 检验数据接收完毕
        self.isReceiveAllData = YES;
        self.receivedData = @"";
    }
}

/*
 * 发送命令方法
 * 0.发送命令，不包含校验码
 * 1.发送同步设备时间
 * 2.发送打开灯光命令
 * 3.发送关闭灯光命令
 * 4.发送手动模式命令
 * 5.发送自动模式命令
 * 6.发送读取时间命令
 * 7.发送查找设备命令
 * 8.发送OTA升级命令
 */
#pragma mark --- 0.间隔一段时间发送命令
- (void)sendCommandWithUUID:(NSString *)uuidString interval:(long)interval channelNum:(NSInteger)channelNum colorIndex:(NSInteger)colorIndex colorValue:(float)colorValue{
    // 如果两次发送命令的时间间隔小于50毫秒，则直接返回
    if ([NSDate date].timeIntervalSince1970 * 1000 - self.lastDimmSendTime < interval){
        return;
    }
    
    int colorIntValue = floor(colorValue);
    NSString *colorStr = [NSString stringWithFormat:@"%04x",colorIntValue];
    NSMutableString *commandStr = [@"6804" mutableCopy];
    for (int i=0;i<channelNum;i++){
        [commandStr appendString:@"FFFF"];
    }
    
    [commandStr replaceCharactersInRange:NSMakeRange(4+colorIndex*4, 4) withString:colorStr];
    
    [self sendCommandWithUUIDString:uuidString commandStr:commandStr];
    
    self.lastDimmSendTime = [NSDate date].timeIntervalSince1970 * 1000;
}

#pragma mark --- 0.发送不带校验码的命令，可以发送任意长度的命令
- (void)sendCommandWithUUIDString:(NSString *)uuidString commandStr:(NSString *)commandStr{
    CBPeripheral *device = [self.bleManager getDeviceByUUID:uuidString];
    
    [self sendCommandWithDevice:device commandStr:commandStr];
}
#pragma mark --- 0.发送不带校验码的命令，可以发送任意长度的命令
- (void)sendCommandWithDevice:(CBPeripheral *)device commandStr:(NSString *)commandStr{
    self.isReceiveAllData = NO;
    KMYLOG(@"发送命令=%@",commandStr);
    //计算校验码
    NSString *xorStr = [StringRelatedManager calculateXORWithString:commandStr];
    if (xorStr.length == 1){
        
        xorStr = [NSString stringWithFormat:@"0%@",xorStr];
    }
    
    // 带有校验码的命令
    NSString *commandStrXor = [NSString stringWithFormat:@"%@%@",commandStr,xorStr];
    if (commandStrXor.length <= 34){
        [self.bleManager sendDataToDevice1:commandStrXor device:device];
        
        return;
    }
    
    // 发送长度大于17字节的命令
    NSString *subLastCommandStr = commandStrXor;
    while (subLastCommandStr.length > 34) {
        NSString *subCommandStr = [subLastCommandStr substringToIndex:34];
        [self.bleManager sendDataToDevice1:subCommandStr device:device];
        
        subLastCommandStr = [subLastCommandStr substringFromIndex:34];
    }
    
    [self.bleManager sendDataToDevice1:subLastCommandStr device:device];
}

#pragma mark --- 1.发送同步时间命令
- (void)sendTimeSynchronizationCommand:(CBPeripheral *)device{
    // 标记命令类型
    self.currentCommandType = TIMESYNCHRONIZATION_COMMAND;
    
    /* 向设备发送获取参数的指令 */
    NSDate *dateNow = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    NSDateComponents *comps = [calendar components:NSCalendarUnitWeekday fromDate:dateNow];;
    NSInteger weekDay = ([comps weekday] - 1);
    
    format.dateFormat = [NSString stringWithFormat:@"yyMMdd%02ldHHmmss",weekDay];
    NSString *timeStr = [format stringFromDate:dateNow];
    NSString *commandStr = @"680E";
    //把时间字符串转换为16进制字符串
    for (int i=0; i<timeStr.length / 2; i++) {
        NSString *timeSubStr = [timeStr substringWithRange:NSMakeRange(i * 2, 2)];
        commandStr = [NSString stringWithFormat:@"%@%@",commandStr,[StringRelatedManager convertToHexStringWithString:timeSubStr]];
    }
    
    NSString *xorStr = [StringRelatedManager calculateXORWithString:commandStr];
    
    [self.bleManager sendDataToDevice1:[NSString stringWithFormat:@"%@%@",commandStr,xorStr] device:device];
}

#pragma mark --- 2.发送打开灯光命令
- (void)sendPowerOnCommand:(NSString *)uuidString{
    CBPeripheral *device = [self.bleManager getDeviceByUUID:uuidString];
    self.currentCommandType = POWERON_COMMAND;
    [self sendCommandWithDevice:device commandStr:@"680301"];
}

#pragma mark --- 3.发送关闭灯光命令
- (void)sendPowerOffCommand:(NSString *)uuidString{
    CBPeripheral *device = [self.bleManager getDeviceByUUID:uuidString];
    self.currentCommandType = POWEROFF_COMMAND;
    [self sendCommandWithDevice:device commandStr:@"680300"];
}

#pragma mark --- 4.发送手动模式命令
- (void)sendManualModeCommand:(NSString *)uuidString{
    CBPeripheral *device = [self.bleManager getDeviceByUUID:uuidString];
    self.currentCommandType = MANUALMODE_COMMAND;
    [self sendCommandWithDevice:device commandStr:@"680200"];
}

#pragma mark --- 5.发送自动模式命令
- (void)sendAutoModeCommand:(NSString *)uuidString{
    CBPeripheral *device = [self.bleManager getDeviceByUUID:uuidString];
    self.currentCommandType = AUTOMODE_COMMAND;
    [self sendCommandWithDevice:device commandStr:@"680201"];
}

#pragma mark --- 6.发送读取时间命令
- (void)sendReadTimeCommand:(NSString *)uuidString{
    CBPeripheral *device = [self.bleManager getDeviceByUUID:uuidString];
    self.currentCommandType = READTIME_COMMAND;
    [self sendCommandWithDevice:device commandStr:@"680D"];
}

#pragma mark --- 7.发送查找设备命令
- (void)sendFindDeviceCommand:(NSString *)uuidString{
    CBPeripheral *device = [self.bleManager getDeviceByUUID:uuidString];
    self.currentCommandType = FINDDEVICE_COMMAND;
    [self sendCommandWithDevice:device commandStr:@"680F"];
}

#pragma mark --- 8.发送OTA升级命令
- (void)sendOTACommand:(NSString *)uuidString{
    CBPeripheral *device = [self.bleManager getDeviceByUUID:uuidString];
    self.currentCommandType = OTA_COMMAND;
    [self sendCommandWithDevice:device commandStr:@"68000000"];
}

/*
 * 解析接收数据方法：对不同的灯具，由于协议的不同，所以解析方法也不相同
 * 1.读取设备信息
 */

#pragma mark --- Hagen App 使用的解析方法
- (void)parseDataFromReceiveData:(NSString *)receiveData deviceInfoModel:(DeviceParameterModel *)deviceInfoModel{
    // 定义游标
    NSInteger countIndex = 0;
    // 定义解析长度
    NSInteger count = 2;
    
    // 解析数据帧头
    deviceInfoModel.headerStr = [receiveData substringWithRange:NSMakeRange(countIndex, count)];
    
    // 解析命令码
    countIndex = countIndex + 2;
    deviceInfoModel.commandStr = [receiveData substringWithRange:NSMakeRange(countIndex, 2)];
    
    // 解析运行模式
    countIndex = countIndex + 2;
    deviceInfoModel.runMode = [receiveData substringWithRange:NSMakeRange(countIndex, 2)];
    
    // 根据工作模式解析数据:自动手动
    if (strtol([deviceInfoModel.runMode UTF8String], 0, 16) == MANUAL_MODE){
        // 解析手动模式数据
        // 解析开关状态
        countIndex = countIndex + 2;
        deviceInfoModel.powerState = [receiveData substringWithRange:NSMakeRange(countIndex, 2)];
        
        // 解析动态模式
        countIndex = countIndex + 2;
        deviceInfoModel.dynaMode = [receiveData substringWithRange:NSMakeRange(countIndex, 2)];
        
        // 解析手动模式值:解析所有通道的值，按照键值0 1 2 3 4 ....(colorIndex)存储到字典中
        NSString *colorValue = @"";
        NSInteger colorIndex = 0;
        countIndex = countIndex + 2;
        for (int i=0; i<deviceInfoModel.channelNum; i++) {
            // 解析出来的值保持高位在前，低位在后，并且保持16进制
            colorValue = @"";
            colorValue = [receiveData substringWithRange:NSMakeRange(countIndex, 4)];
            [deviceInfoModel.manualValueDic setObject:colorValue forKey:@(colorIndex)];
            colorIndex ++;
            countIndex = countIndex + 4;
        }
        
        // 解析用户自定义数值
        colorValue = @"";
        colorIndex = 0;
        // 这里的4是指P1 P2 P3 P4
        for (int i=0; i<4; i++) {
            colorValue = @"";
            colorValue = [receiveData substringWithRange:NSMakeRange(countIndex, deviceInfoModel.channelNum * 2)];
            [deviceInfoModel.userDefineValueDic setObject:colorValue forKey:@(colorIndex)];
            colorIndex ++;
            countIndex = countIndex + deviceInfoModel.channelNum * 2;
        }
    }else if (strtol([deviceInfoModel.runMode UTF8String], 0, 16) == AUTO_MODE){
        countIndex = countIndex + 2;
        NSString *timeStr = @"";
        NSString *colorStr = @"";
        for (int i=0; i<2; i++) {
            // 解析时间点
            timeStr = [receiveData substringWithRange:NSMakeRange(countIndex, 4)];
            [deviceInfoModel.timepointArray addObject:timeStr];
            //KMYLOG(@"timeStr=%@",timeStr);
            countIndex = countIndex + 4;
            timeStr = [receiveData substringWithRange:NSMakeRange(countIndex, 4)];
            [deviceInfoModel.timepointArray addObject:timeStr];
            //KMYLOG(@"timeStr=%@",timeStr);
            countIndex = countIndex + 4;
            // 根据通道数量解析颜色值
            colorStr = [receiveData substringWithRange:NSMakeRange(countIndex, deviceInfoModel.channelNum * 2)];
            countIndex = countIndex + deviceInfoModel.channelNum * 2;
            //KMYLOG(@"colorStr=%@",colorStr);
            // 添加到设备数据模型中
            [deviceInfoModel.timepointValueDic setObject:colorStr forKey:@(i)];
        }
    }
}

#pragma mark --- ECO Plant解析数据方法
- (void)parseECOPlantDataFromReceiveData:(NSString *)receiveData deviceInfoModel:(ECOPlantParameterModel *)deviceInfoModel{
    // 定义游标
    NSInteger countIndex = 0;
    
    // 定义解析长度
    NSInteger count = 2;
    
    // 解析数据帧头
    deviceInfoModel.headerStr = [receiveData substringWithRange:NSMakeRange(countIndex, count)];
    
    // 解析命令码
    countIndex = countIndex + 2;
    deviceInfoModel.commandStr = [receiveData substringWithRange:NSMakeRange(countIndex, 2)];
    
    // 解析设备运行模式:这里没有运行模式，这里的标志的是是否已开启周期模式
    countIndex = countIndex + 2;
    deviceInfoModel.runMode = [receiveData substringWithRange:NSMakeRange(countIndex, 2)];
    if ([deviceInfoModel.runMode isEqualToString:@"00"]){
        deviceInfoModel.isOpenCycleMode = NO;
    }else{
        deviceInfoModel.isOpenCycleMode = YES;
    }
    
    // 生长周期个数
    countIndex = countIndex + 2;
    deviceInfoModel.cycleCount = [[receiveData substringWithRange:NSMakeRange(countIndex, 2)] integerValue];
    
    // 生长周期的起始日期
    countIndex = countIndex + 2;
    deviceInfoModel.cycleStartDate = [receiveData substringWithRange:NSMakeRange(countIndex, 6)];
    
    // 解析周期数据
    NSString *cycleValueStr = @"";
    countIndex = countIndex + 6;
    // 12 为本周期持续天数 打开关闭灯光时间 关闭灯光类型 后面为每路颜色值字符串长度
    NSInteger cycleValueLength = 12 + deviceInfoModel.channelNum * 2;
    for (int i=0; i<deviceInfoModel.cycleCount; i++) {
        cycleValueStr = [receiveData substringWithRange:NSMakeRange(countIndex, cycleValueLength)];
        
        [deviceInfoModel.cycleDataDic setObject:cycleValueStr forKey:@(i)];
        
        cycleValueStr = @"";
        countIndex = countIndex + cycleValueLength;
    }
}

@end
































