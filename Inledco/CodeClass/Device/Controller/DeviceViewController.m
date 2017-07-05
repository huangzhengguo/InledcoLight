//
//  DeviceViewController.m
//  Inledco
//
//  Created by huang zhengguo on 2017/6/5.
//  Copyright © 2017年 huang zhengguo. All rights reserved.
//

#import "DeviceViewController.h"
#import "ScanViewController.h"
#import "DeviceTableViewCell.h"

@interface DeviceViewController ()<UITableViewDelegate,UITableViewDataSource>
// 列表视图
@property (weak, nonatomic) IBOutlet UITableView *tableView;
// 设备数据源
@property (nonatomic, strong) NSMutableArray *deviceDataArray;

@end

@implementation DeviceViewController

#pragma mark --- 懒加载部分
- (NSMutableArray *)deviceDataArray{
    if (_deviceDataArray == nil){
        self.deviceDataArray = [NSMutableArray array];
    }
    return _deviceDataArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    // 设置视图
    [self setViews];
}

- (void)setViews{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView registerNib:[UINib nibWithNibName:@"DeviceTableViewCell" bundle:nil] forCellReuseIdentifier:@"DeviceTableViewCell"];
    
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithRed:15.0f / 255.0f green:91.0f / 255.0f blue:20.0f / 255.0f alpha:1.0f]];
    self.navigationItem.title = @"Inledco";
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(scanDeviceAction:)];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = addBarButtonItem;
}

- (void)scanDeviceAction:(UIBarButtonItem *)barButtonItem{
    ScanViewController *scanViewController = [[ScanViewController alloc] init];
    
    scanViewController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:scanViewController animated:YES];
}

#pragma mark --- tableview代理方法
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.deviceDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceTableViewCell" forIndexPath:indexPath];

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80.0;
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
