//
//  BaseViewController.h
//  Inledco
//
//  Created by huang zhengguo on 2017/6/5.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

/*
 * 基类中实现一些所有控制器中都需要的对象
 */

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

// 蓝牙管理对象
@property(nonatomic, strong) BlueToothManager *blueToothManager;

// 数据库管理对象
@property(nonatomic, strong) DatabaseManager *databaseManager;

@end
