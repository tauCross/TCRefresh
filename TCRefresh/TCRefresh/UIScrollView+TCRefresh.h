//
//  UIScrollView+TCRefresh.h
//  TCRefresh
//
//  Created by tauCross on 16/4/18.
//  Copyright © 2016年 tauCross. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface UIScrollView (TCRefresh)

@property(nonatomic, strong, readonly)UILabel *refreshLabel;

- (void)setupRefreshWithBottomAt:(CGFloat)bottomAt refreshBlock:(void (^)(void))refreshBlock;

- (void)startRefresh;
- (void)endRefresh;
- (BOOL)isRefreshing;

@property(nonatomic, strong)NSString *hint_PullToRefresh;
@property(nonatomic, strong)NSString *hint_Refreshing;
@property(nonatomic, strong)NSString *hint_RefreshDone;
@property(nonatomic, strong)NSString *hint_LoosenToRefresh;

@end
