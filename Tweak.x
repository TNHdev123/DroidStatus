#import <UIKit/UIKit.h>

@interface _UIStatusBar : UIView
@property (nonatomic, strong) UIView *droidBackgroundView;
@end

%hook _UIStatusBar

%property (nonatomic, strong) UIView *droidBackgroundView;

- (void)layoutSubviews {
    %orig;

    // 取得視窗 Bounds 判斷直橫向
    CGRect windowBounds = self.window ? self.window.bounds : [UIScreen mainScreen].bounds;
    BOOL isPortrait = windowBounds.size.height >= windowBounds.size.width;

    // 1. 動態建立黑色背景（若尚未建立）
    if (self.droidBackgroundView == nil) {
        UIView *bg = [[UIView alloc] initWithFrame:CGRectZero];
        bg.backgroundColor = [UIColor blackColor];
        bg.userInteractionEnabled = NO; // 禁用互動，手勢直接穿透
        
        // 核心：插入至 _UIStatusBar 最底層 (index 0)，絕對不會擋到狀態列文字與圖示
        [self insertSubview:bg atIndex:0];
        self.droidBackgroundView = bg;
    }

    // 2. 直向時顯示黑條並填滿狀態列，橫向時自動隱藏
    if (isPortrait) {
        self.droidBackgroundView.hidden = NO;
        self.droidBackgroundView.frame = self.bounds;
        [self sendSubviewToBack:self.droidBackgroundView];
    } else {
        self.droidBackgroundView.hidden = YES;
    }
}

// 3. 強制將狀態列的所有圖示與文字改為純白色
- (void)setForegroundColor:(UIColor *)color {
    %orig([UIColor whiteColor]);
}

%end

// 4. 源頭過濾：入口點直接擋下 SpringBoard
%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        // 只要是 SpringBoard (桌面/控制中心) 或無 Bundle ID 的進程，直接退出，完全不掛載 Hook
        if (!bundleID || [bundleID isEqualToString:@"com.apple.springboard"]) {
            return;
        }
        
        %init;
    }
}
