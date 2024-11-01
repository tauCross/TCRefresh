//
//  UIScrollView+TCRefresh.m
//  TCRefresh
//
//  Created by tauCross on 16/4/18.
//  Copyright © 2016年 tauCross. All rights reserved.
//

#import "UIScrollView+TCRefresh.h"

#import <objc/runtime.h>

#import "TCCocoaExpand.h"
#import "ReactiveObjC.h"



const CGFloat kRefreshViewHeight = 58;
const CGFloat kRefreshToggle = 66;

const NSString *kPullToRefresh = @"下拉刷新";
const NSString *kRefreshing = @"刷新中";
const NSString *kRefreshDone = @"刷新完成";
const NSString *kLoosenToRefresh = @"松开刷新";



typedef enum
{
    TCRefreshStatusNormal,
    TCRefreshStatusWillRefresh,
    TCRefreshStatusRefreshing,
    TCRefreshStatusDone,
    TCRefreshStatusDoneClose
}TCRefreshStatus;



@interface UIScrollView ()

@property(nonatomic, strong)UIView *refreshView;
@property(nonatomic, strong)UIView *refreshContentView;
@property(nonatomic, copy)void (^refreshBlock)(void);
@property(nonatomic, assign)CGFloat bottomAt;
@property(nonatomic, assign)TCRefreshStatus status;

@end



@implementation UIScrollView (TCRefresh)

- (void)setupRefreshWithBottomAt:(CGFloat)bottomAt refreshBlock:(void (^)(void))refreshBlock
{
    @weakify(self)
    self.refreshBlock = refreshBlock;
    self.bottomAt = bottomAt;
    if(self.refreshView == nil)
    {
        self.status = TCRefreshStatusNormal;
        self.refreshView = [[UIView alloc] init];
        self.refreshView.clipsToBounds = YES;
        self.refreshView.userInteractionEnabled = NO;
        [self addSubview:self.refreshView];
        {
            self.refreshContentView = [[UIView alloc] init];
            [self.refreshView addSubview:self.refreshContentView];
            {
                self.refreshLabel = [[UILabel alloc] init];
                self.refreshLabel.font = [UIFont tc_systemFontOfSize:13 weight:TCFontWeightRegular];
                self.refreshLabel.textColor = [UIColor darkGrayColor];
                self.refreshLabel.textAlignment = NSTextAlignmentCenter;
                [self.refreshContentView addSubview:self.refreshLabel];
                [RACObserve(self.refreshContentView, frame) subscribeNext:^(NSValue *value) {
                    @strongify(self)
                    CGRect rect = value.CGRectValue;
                    self.refreshLabel.tc_height = 20;
                    self.refreshLabel.tc_width = rect.size.width;
                    self.refreshLabel.tc_centerX = rect.size.width / 2;
                    self.refreshLabel.tc_bottom = rect.size.height - 10;
                }];
                RAC(self.refreshLabel, text) = [RACObserve(self, status) map:^id(NSNumber *number) {
                    TCRefreshStatus status = (TCRefreshStatus)number.integerValue;
                    switch(status)
                    {
                        case TCRefreshStatusRefreshing:
                            return self.hint_Refreshing;
                        case TCRefreshStatusNormal:
                            return self.hint_PullToRefresh;
                        case TCRefreshStatusWillRefresh:
                            return self.hint_LoosenToRefresh;
                        case TCRefreshStatusDone:
                        case TCRefreshStatusDoneClose:
                            return self.hint_RefreshDone;
                    }
                }];
            }
            [RACObserve(self.refreshView, frame) subscribeNext:^(id x) {
                @strongify(self)
                self.refreshContentView.tc_width = self.refreshView.tc_width;
                self.refreshContentView.tc_height = kRefreshViewHeight;
                self.refreshContentView.tc_left = 0;
                self.refreshContentView.tc_bottom = self.refreshView.tc_height;
            }];
        }
        [RACObserve(self, frame) subscribeNext:^(id x) {
            @strongify(self)
            self.refreshView.tc_width = self.tc_width;
            self.refreshView.tc_left = 0;
        }];
        [RACObserve(self, contentOffset) subscribeNext:^(NSValue *value) {
            @strongify(self)
            CGPoint offset = value.CGPointValue;
            if(self.status == TCRefreshStatusRefreshing)
            {
                return;
            }
            if(self.isDragging)
            {
                if(offset.y < - kRefreshToggle)
                {
                    self.status = TCRefreshStatusWillRefresh;
                }
                else
                {
                    self.status = TCRefreshStatusNormal;
                }
            }
            else
            {
                if(self.status == TCRefreshStatusWillRefresh)
                {
                    [UIView animateWithDuration:0.25
                                          delay:0
                                        options:UIViewAnimationOptionCurveEaseInOut
                                     animations:^{
                                         @strongify(self)
                                         self.status = TCRefreshStatusRefreshing;
                                     }
                                     completion:nil];
                }
            }
        }];
        [[RACSignal combineLatest:@[RACObserve(self, contentOffset), RACObserve(self, status)]] subscribeNext:^(RACTuple *tuple) {
            @strongify(self)
            RACTupleUnpack(NSValue *offsetValue, NSNumber *statusNumber) = tuple;
            CGPoint offset = offsetValue.CGPointValue;
            TCRefreshStatus status = (TCRefreshStatus)statusNumber.integerValue;
            if(offset.y <= 0)
            {
                if(offset.y < - kRefreshViewHeight)
                {
                    self.refreshView.tc_height = kRefreshViewHeight;
                }
                else
                {
                    self.refreshView.tc_height = - offset.y;
                }
            }
            else
            {
                self.refreshView.tc_height = 0;
            }
            if(status == TCRefreshStatusRefreshing || status == TCRefreshStatusDone)
            {
                self.refreshView.tc_height = kRefreshViewHeight;
            }
            self.refreshView.tc_bottom = self.bottomAt;
        }];
        [RACObserve(self, status) subscribeNext:^(NSNumber *number) {
            @strongify(self)
            TCRefreshStatus status = (TCRefreshStatus)[number integerValue];
            if(status == TCRefreshStatusRefreshing)
            {
                if(self.refreshBlock)
                {
                    self.refreshBlock();
                }
            }
            CGFloat top = (status == TCRefreshStatusDone || status == TCRefreshStatusRefreshing) ? kRefreshViewHeight : 0;
            if(self.contentInset.top != top)
            {
                self.contentInset = UIEdgeInsetsMake(top, 0, 0, 0);
                [self setContentOffset:CGPointMake(0, -top) animated:YES];
            }
        }];
    }
    [self bringSubviewToFront:self.refreshView];
}

- (void)startRefresh
{
    if(self.status == TCRefreshStatusRefreshing || self.refreshView == nil)
    {
        return;
    }
    @weakify(self)
    [UIView animateWithDuration:0.25
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         @strongify(self)
                         self.status = TCRefreshStatusRefreshing;
                         self.contentOffset = CGPointMake(0, -self.contentInset.top);
                     }
                     completion:nil];
}

- (void)endRefresh
{
    if(self.refreshView == nil || self.status != TCRefreshStatusRefreshing)
    {
        return;
    }
    self.status = TCRefreshStatusDone;
    [UIView animateWithDuration:0.25
                          delay:0.2
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.status = TCRefreshStatusDoneClose;
                     }
                     completion:^(BOOL finished) {
                         self.status = TCRefreshStatusNormal;
                     }];
}

- (BOOL)isRefreshing
{
    return self.status == TCRefreshStatusRefreshing;
}

#pragma mark - property
static char tcr_refresh_block_key;
static char tcr_refresh_view_key;
static char tcr_refresh_content_view_key;
static char tcr_refresh_label_key;
static char tcr_bottom_at_key;
static char tcr_status_key;
static char tcr_hint_PullToRefresh_key;
static char tcr_hint_Refreshing_key;
static char tcr_hint_RefreshDone_key;
static char tcr_hint_LoosenToRefresh_key;

- (UIView *)refreshView
{
    return objc_getAssociatedObject(self, &tcr_refresh_view_key);
}

- (void)setRefreshView:(UIView *)refreshView
{
    objc_setAssociatedObject(self, &tcr_refresh_view_key, refreshView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)refreshContentView
{
    return objc_getAssociatedObject(self, &tcr_refresh_content_view_key);
}

- (void)setRefreshContentView:(UIView *)refreshContentView
{
    objc_setAssociatedObject(self, &tcr_refresh_content_view_key, refreshContentView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UILabel *)refreshLabel
{
    return objc_getAssociatedObject(self, &tcr_refresh_label_key);
}

- (void)setRefreshLabel:(UILabel *)refreshLabel
{
    objc_setAssociatedObject(self, &tcr_refresh_label_key, refreshLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(void))refreshBlock
{
    return objc_getAssociatedObject(self, &tcr_refresh_block_key);
}

- (void)setRefreshBlock:(void (^)(void))refreshBlock
{
    return objc_setAssociatedObject(self, &tcr_refresh_block_key, refreshBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (CGFloat)bottomAt
{
    return [objc_getAssociatedObject(self, &tcr_bottom_at_key) doubleValue];
}

- (void)setBottomAt:(CGFloat)bottomAt
{
    objc_setAssociatedObject(self, &tcr_bottom_at_key, @(bottomAt), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (TCRefreshStatus)status
{
    return (TCRefreshStatus)[objc_getAssociatedObject(self, &tcr_status_key) integerValue];
}

- (void)setStatus:(TCRefreshStatus)status
{
    objc_setAssociatedObject(self, &tcr_status_key, @(status), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)hint_Refreshing
{
    NSString *s = objc_getAssociatedObject(self, &tcr_hint_Refreshing_key);
    if(s == nil)
    {
        s = (NSString *)kRefreshing;
    }
    return s;
}

- (void)setHint_Refreshing:(NSString *)hint_Refreshing
{
    objc_setAssociatedObject(self, &tcr_hint_Refreshing_key, hint_Refreshing, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)hint_RefreshDone
{
    NSString *s = objc_getAssociatedObject(self, &tcr_hint_RefreshDone_key);
    if(s == nil)
    {
        s = (NSString *)kRefreshDone;
    }
    return s;

}

- (void)setHint_RefreshDone:(NSString *)hint_RefreshDone
{
    objc_setAssociatedObject(self, &tcr_hint_RefreshDone_key, hint_RefreshDone, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)hint_PullToRefresh
{
    NSString *s = objc_getAssociatedObject(self, &tcr_hint_PullToRefresh_key);
    if(s == nil)
    {
        s = (NSString *)kPullToRefresh;
    }
    return s;

}

- (void)setHint_PullToRefresh:(NSString *)hint_PullToRefresh
{
    objc_setAssociatedObject(self, &tcr_hint_PullToRefresh_key, hint_PullToRefresh, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSString *)hint_LoosenToRefresh
{
    NSString *s = objc_getAssociatedObject(self, &tcr_hint_LoosenToRefresh_key);
    if(s == nil)
    {
        s = (NSString *)kLoosenToRefresh;
    }
    return s;

}

- (void)setHint_LoosenToRefresh:(NSString *)hint_LoosenToRefresh
{
    objc_setAssociatedObject(self, &tcr_hint_LoosenToRefresh_key, hint_LoosenToRefresh, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


@end
