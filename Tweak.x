#import <UIKit/UIKit.h>

@interface UIWindow (DroidStatus)
@property (nonatomic, strong) UIView *droidStatusOverlayView;
- (void)updateDroidStatusOverlay;
@end

// 1. 強制將 iOS 底層狀態列所有圖示與文字（時間、電量、訊號等）設為純白色
%hook _UIStatusBar
- (void)setForegroundColor:(UIColor *)color {
    %orig([UIColor whiteColor]);
}
%end

%hook UIWindow

%property (nonatomic, strong) UIView *droidStatusOverlayView;

- (void)layoutSubviews {
    %orig;

    // 僅針對主 UIWindow 處理，避開內部鍵盤與彈窗視窗
    if (![self isKeyWindow] && ![NSStringFromClass([self class]) isEqualToString:@"UIWindow"]) {
        return;
    }

    [self updateDroidStatusOverlay];
}

%new
- (void)updateDroidStatusOverlay {
    UIEdgeInsets insets = self.safeAreaInsets;
    
    // 依據視窗高寬比判定直橫向
    BOOL isPortrait = self.bounds.size.height >= self.bounds.size.width;

    // 建立黑色覆蓋層（若尚未建立）
    if (self.droidStatusOverlayView == nil) {
        UIView *overlay = [[UIView alloc] initWithFrame:CGRectZero];
        overlay.backgroundColor = [UIColor blackColor];
        
        // 手勢穿透，確保不干擾狀態列點擊（如點擊返回頂部）
        overlay.userInteractionEnabled = NO;
        
        [self addSubview:overlay];
        self.droidStatusOverlayView = overlay;
    }

    // 直向且有 Safe Area 時顯示全黑背景；橫向或無 Safe Area 時自動隱藏
    if (isPortrait && insets.top > 0) {
        self.droidStatusOverlayView.hidden = NO;
        self.droidStatusOverlayView.frame = CGRectMake(0, 0, self.bounds.size.width, insets.top);
        
        // 確保黑色背景位於 App 視窗最上層，填滿 Safe Area
        [self bringSubviewToFront:self.droidStatusOverlayView];
    } else {
        self.droidStatusOverlayView.hidden = YES;
    }
}

%end

// 2. 備用：覆蓋控制器層級的狀態列樣式為白色
%hook UIViewController
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
%end

// 3. 全局構造函數：%ctor 在套件載入最前端執行
%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        // 若為 SpringBoard (主畫面/鎖屏/控制中心) 或無 Bundle ID 的系統進程，直接退出，不載入任何 Hook
        if ([bundleID isEqualToString:@"com.apple.springboard"] || !bundleID) {
            return;
        }
        
        %init;
    }
}
