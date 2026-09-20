#import <UIKit/UIKit.h>

// 定義一個唯一的 View Tag，避免重複創建與識別衝突
static NSInteger const kDroidStatusOverlayTag = 0x1888D3;

%hook UIWindow

- (void)layoutSubviews {
    %orig;

    // 僅對主要視窗（KeyWindow）發揮作用
    if (!self.isKeyWindow) return;

    // 尋找是否已存在覆蓋層 View
    UIView *overlay = [self viewWithTag:kDroidStatusOverlayTag];
    if (!overlay) {
        overlay = [[UIView alloc] init];
        overlay.tag = kDroidStatusOverlayTag;
        overlay.backgroundColor = [UIColor blackColor];
        
        // 5. 手勢穿透：關閉互動回應，點擊狀態列（如返回頂部）功能完全正常
        overlay.userInteractionEnabled = NO;
        
        [self addSubview:overlay];
    }

    UIEdgeInsets insets = self.safeAreaInsets;
    CGRect bounds = self.bounds;

    // 透過視窗寬高判斷當前是否為直向 (Portrait)
    BOOL isPortrait = bounds.size.height > bounds.size.width;

    // 2 & 3. 處理直向顯示與橫向隱藏
    if (isPortrait && insets.top > 0) {
        overlay.hidden = NO;
        overlay.frame = CGRectMake(0, 0, bounds.size.width, insets.top);
        
        // 確保黑條永遠保持在視窗最上層
        [self bringSubviewToFront:overlay];
    } else {
        // 橫向模式下自動隱藏黑條
        overlay.hidden = YES;
    }
}

%end

%hook UIViewController

// 4. 強制將 App 內的狀態列文字與圖示樣式設定為白色
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

%end

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        
        // 1. 排除主畫面 (SpringBoard) 及背景進程，僅對普通 App 生效
        if (!bundleID || [bundleID isEqualToString:@"com.apple.springboard"]) {
            return;
        }
        
        %init;
    }
}
