#import <UIKit/UIKit.h>

@interface UIWindow (DroidStatus)
@property (nonatomic, strong) UIView *droidStatusOverlayView;
- (void)updateDroidStatusOverlay;
@end

@interface _UIStatusBar : UIView
@property (nonatomic, strong) UIColor *foregroundColor;
@end

// 1. 強制將 iOS 底層狀態列所有圖示與文字（時間、電量、Wi-Fi 等）改為純白色
%hook _UIStatusBar
- (void)setForegroundColor:(UIColor *)color {
    %orig([UIColor whiteColor]);
}
- (UIColor *)foregroundColor {
    return [UIColor whiteColor];
}
%end

// 2. 強制宣告 ViewController 使用亮色模式狀態列
%hook UIViewController
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
%end

// 3. 在 App 主視窗頂部 Safe Area 建立黑色覆蓋層
%hook UIWindow

%property (nonatomic, strong) UIView *droidStatusOverlayView;

- (void)layoutSubviews {
    %orig;

    // 避開無 RootViewController 的系統輔助視窗（如鍵盤層、彈窗層）
    if (self.rootViewController == nil) {
        return;
    }

    [self updateDroidStatusOverlay];
}

%new
- (void)updateDroidStatusOverlay {
    UIEdgeInsets insets = self.safeAreaInsets;
    BOOL isPortrait = self.bounds.size.height >= self.bounds.size.width;

    // 動態建立黑色覆蓋層（若尚未建立）
    if (self.droidStatusOverlayView == nil) {
        UIView *overlay = [[UIView alloc] initWithFrame:CGRectZero];
        overlay.backgroundColor = [UIColor blackColor];
        overlay.userInteractionEnabled = NO; // 手勢穿透，確保不干擾頂部點擊
        
        self.droidStatusOverlayView = overlay;
    }

    // 直向且有 Safe Area 時顯示全黑背景；橫向或無 Safe Area 時自動隱藏
    if (isPortrait && insets.top > 0) {
        self.droidStatusOverlayView.hidden = NO;
        self.droidStatusOverlayView.frame = CGRectMake(0, 0, self.bounds.size.width, insets.top);
        
        // 尋找視窗內的 StatusBar View，確保黑色遮罩插入在狀態列「下方」，不遮擋白色的圖示
        UIView *statusBarView = nil;
        for (UIView *subview in self.subviews) {
            if ([NSStringFromClass([subview class]) containsString:@"StatusBar"]) {
                statusBarView = subview;
                break;
            }
        }

        if (statusBarView) {
            [self insertSubview:self.droidStatusOverlayView belowSubview:statusBarView];
        } else {
            // 若狀態列位於獨立的 UIStatusBarWindow，將遮罩置於當前視窗最底層即可
            [self insertSubview:self.droidStatusOverlayView atIndex:0];
        }
    } else {
        self.droidStatusOverlayView.hidden = YES;
    }
}

%end

// 4. 源頭隔離：只要是 SpringBoard 進程，完全不載入此 Tweak
%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if (!bundleID || [bundleID isEqualToString:@"com.apple.springboard"]) {
            return;
        }
        %init;
    }
}
