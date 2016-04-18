//
//  UIScrollView+TCRefresh.h
//  TCRefresh
//
//  Created by tauCross on 16/4/18.
//  Copyright © 2016年 tauCross. All rights reserved.
//

#import <UIKit/UIKit.h>



@interface UIScrollView (TCRefresh)

- (void)setupRefreshWithBottomAt:(CGFloat)bottomAt refreshBlock:(void (^)())refreshBlock;

- (void)startRefresh;
- (void)endRefresh;

@end
