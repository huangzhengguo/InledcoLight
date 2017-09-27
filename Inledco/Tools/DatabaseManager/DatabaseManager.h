//
//  DatabaseManager.h
//  InledcoPlant
//
//  Created by huang zhengguo on 2017/2/9.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <FMDB.h>
#import "DeviceGroupModel.h"
#import "DeviceModel.h"

@interface DatabaseManager : NSObject

/*
 * 单例类
 * @return 返回数据库单例对象
 */
+(instancetype)defaultDatabaseManager;

/*
 * 插入数据库对象
 * @param tableName 数据库表名
 * @param columnDic 数据库列名和值的对应
 */
- (void)insertIntoTableWithTableName:(NSString *)tableName columnDic:(NSDictionary *)columnDic;

/*
 * 根据表名 列名 列值 查询符合条件的行
 * @param tableName 要查询的表名
 * @param colName 条件列名
 * @param colValue 条件列值
 * @return 符合条件的行
 */
-(NSMutableArray *)findDataFromTableWithTableName:(NSString *)tableName colName:(NSString *)colName colValue:(NSString *)colValue;

/*
 * 根据组名查找符合条件的行
 * @param tableName 表名
 * @param groupName 组名：如果组名为空，则返回所有数据；否则返回符合条件的行
 * @return 符合条件的行
 */
-(NSMutableArray *)findDataFromTableWithTableName:(NSString *)tableName groupName:(NSString *)groupName;

/*
 * 设置符合某个条件的行对应的某一列的值
 * @param tableName 表名
 * @param colName 要设置的列的名称
 * @param conditionColName 条件列的名称
 * @param conditionCol 条件列值
 * @param data 要设置的列的值
 */
- (void)updateDataWithTableName:(NSString *)tableName colName:(NSString *)colName conditionColName:(NSString *)conditionColName conditionCol:(NSString *)conditionCol data:(NSString *)data;

@end
