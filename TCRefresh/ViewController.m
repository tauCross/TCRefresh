//
//  ViewController.m
//  TCRefresh
//
//  Created by tauCross on 16/4/18.
//  Copyright © 2016年 tauCross. All rights reserved.
//

#import "ViewController.h"

#import "UIScrollView+TCRefresh.h"

#import <ReactiveObjC/ReactiveObjC.h>
#import "TCCocoaExpand.h"



@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong)UITableView *tableView;

@end


@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    @weakify(self)
    [self.tableView setupRefreshWithBottomAt:0 refreshBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self)
            [self.tableView endRefresh];
        });
    }];
    self.tableView.refreshLabel.textColor = HEXCOLOR(@"C7D1D6");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [self.tableView startRefresh];
    });
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
}

#pragma mark - TableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0)
    {
        return 200;
    }
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    if(cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    }
    if(indexPath.row == 0)
    {
        cell.textLabel.text = nil;
    }
    else
    {
        cell.textLabel.text = @(indexPath.row).stringValue;
    }
    return cell;
}

@end
