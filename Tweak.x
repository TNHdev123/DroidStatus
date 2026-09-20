#import <UIKit/UIKit.h>

@interface UIWindow (DroidStatus)
@property (nonatomic, strong) UIView *droidStatusOverlayView;
- (void)updateDroidStatusOverlay;
@end

%hook UIWindow

%property (nonatomic, strong) UIView *droidStatusOverlayView;

- (void)layoutSubviews {
    %orig;

    // 1. 嚴格排除 SpringBoard 進程 (包含主畫面、控制中心、鎖屏)
    NSString *processName = [NSProcessInfo processInfo].processName;
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if ([processName isEqualToString:@"SpringBoard"] || 
        [bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        return;
    }

    // 2. 僅針對擁有 rootViewController 的 App 主視窗生效，避開系統彈窗與透明背景層
    if (self.rootViewController == nil) {
        return;
    }

    [self updateDroidStatusOverlay];
}

%new
- (void)updateDroidStatusOverlay {
    UIEdgeInsets insets = self.safeAreaInsets;
    
    // 取得當前螢幕方向
    UIInterfaceOrientation orientation = UIInterfaceOrientationUnknown;
    if (@available(iOS 13.0, *)) {
        if (self.windowScene) {
            orientation = self.windowScene.interfaceOrientation;
        }
    }
    if (orientation == UIInterfaceOrientationUnknown) {
        orientation = [UIApplication sharedApplication].statusBarOrientation;
    }

    BOOL isPortrait = UIInterfaceOrientationIsPortrait(orientation);

    // 建立黑色覆蓋層（若尚未建立）
    if (self.droidStatusOverlayView == nil) {
        UIView *overlay = [[UIView alloc] initWithFrame:CGRectZero];
        overlay.backgroundColor = [UIColor blackColor];
        
        // 手勢穿透，確保不干擾狀態列點擊
        overlay.userInteractionEnabled = NO;
        
        self.droidStatusOverlayView = overlay;
    }

    // 直向且有 Safe Area 時顯示全黑背景；橫向或無 Safe Area 時自動隱藏
    if (isPortrait && insets.top > 0) {
        self.droidStatusOverlayView.hidden = NO;
        self.droidStatusOverlayView.frame = CGRectMake(0, 0, self.bounds.size.width, insets.top);
        
        // 尋找狀態列 View，確保黑色遮罩位於狀態列「下方」，避免遮擋時間與電量
        UIView *statusBarView = nil;
        for (UIView *subview in self.subviews) {
            NSString *className = NSStringFromClass([subview class]);
            if ([className containsString:@"StatusBar"]) {
                statusBarView = subview;
                break;
            }
        }

        if (statusBarView) {
            [self insertSubview:self.droidStatusOverlayView belowSubview:statusBarView];
        } else {
            [self addSubview:self.droidStatusOverlayView];
        }
    } else {
        self.droidStatusOverlayView.hidden = YES;
    }
}

%end

// 3. 強制將 App 的狀態列圖示與文字設定為白色
%hook UIViewController

- (UIStatusBarStyle)preferredStatusBarStyle {
    NSString *processName = [NSProcessInfo processInfo].processName;
    if ([processName isEqualToString:@"SpringBoard"]) {
        return %orig;
    }
    return UIStatusBarStyleLightContent;
}

%end
