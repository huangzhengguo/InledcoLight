//
//  BaseViewController.m
//  Inledco
//
//  Created by huang zhengguo on 2017/6/5.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseViewController ()

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self prepareBaseData];
    
    // 设置背景色
    self.view.backgroundColor = [UIColor whiteColor];
}

#pragma mark --- 初始化工具对象
- (void)prepareBaseData{
    // self.blueToothManager = [BlueToothManager defaultBlueToothManager];
    self.databaseManager = [DatabaseManager defaultDatabaseManager];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
