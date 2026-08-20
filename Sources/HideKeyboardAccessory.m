#import "HideKeyboardAccessory.h"

@implementation HideKeyboardAccessory

+ (BOOL)applyToWebView:(UIView *)webView {
    if (webView == nil) return NO;

    @try {
        UIView *target = nil;

        // 路径1：第一响应者（通常是 WKContentView）的 inputAccessoryView
        UIResponder *firstResponder = [self findFirstResponder];
        @try {
            if (firstResponder && [firstResponder respondsToSelector:@selector(inputAccessoryView)]) {
                UIView *acc = firstResponder.inputAccessoryView;
                if ([acc isKindOfClass:[UIView class]] && acc.frame.size.height > 0) {
                    target = acc;
                }
            }
        } @catch (NSException *e) {}

        // 路径2：递归找实现 _inputAccessoryView 的视图
        if (target == nil) {
            target = [self findInputAccessoryViewIn:webView];
        }

        // 路径3：scrollView 里 WKContentView 的 private inputAccessoryViewController
        if (target == nil) {
            UIScrollView *scrollView = (UIScrollView *)[webView valueForKey:@"scrollView"];
            if ([scrollView isKindOfClass:[UIScrollView class]]) {
                for (UIView *sub in scrollView.subviews) {
                    id vc = nil;
                    @try {
                        vc = [sub valueForKey:@"_inputAccessoryViewController"];
                    } @catch (NSException *e) { vc = nil; }
                    if ([vc isKindOfClass:[NSObject class]]) {
                        UIView *iv = nil;
                        @try { iv = [vc valueForKey:@"view"]; } @catch (NSException *e) {}
                        if ([iv isKindOfClass:[UIView class]]) { target = iv; break; }
                    }
                }
            }
        }

        // 若前面的路径都没找到，用「几何特征」扫描整个窗口：
        // 辅助栏是一条浮在键盘上方、横向的窄条（通常高约 37~49pt、宽约屏宽）。
        // 这条对系统版本免疫，不依赖私有 key 名，iOS 大版本升级也不怕。
        if (target == nil || [target isKindOfClass:[UIView class]] == NO) {
            target = [HideKeyboardAccessory findAccessoryBarInWindows];
        }

        if (target != nil && [target isKindOfClass:[UIView class]]) {
            target.frame = CGRect(0, 0, 1, 1);
            target.hidden = YES;
            return YES;
        }
    } @catch (NSException *e) {
        return NO;
    }
    return NO;
}

/// 在 App 所有 window 里，找一个「键盘上方、横向窄条」的辅助栏视图。
/// 用几何特征匹配：宽≈屏宽、高在 20~60pt 之间、且 y 坐标在屏幕底部区域。
+ (nullable UIView *)findAccessoryBarInWindows {
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        UIView *found = [self scanForAccessoryBar:window screen:window.bounds];
        if (found) { return found; }
    }
    return nil;
}

+ (nullable UIView *)scanForAccessoryBar:(UIView *)view screen:(CGRect)screen {
    if (view == nil || view.isHidden) return nil;
    @try {
        CGRect f = view.frame;
        // 键盘弹出时屏上通常有 2~3 个 window；取当前 keyWindow 的高度近似屏幕高
        CGFloat screenH = screen.size.height;
        // 辅助栏：接近全屏宽、高适中、位于屏底部附近（在键盘之上）
        if (f.size.width > screen.size.width * 0.8 &&
            f.size.height >= 20 && f.size.height <= 65 &&
            f.origin.y > screenH * 0.5) {
            return view;
        }
    } @catch (NSException *e) {
        return nil;
    }
    // 递归子视图
    for (UIView *sub in view.subviews) {
        UIView *found = [self scanForAccessoryBar:sub screen:screen];
        if (found) { return found; }
    }
    return nil;
}

+ (nullable UIResponder *)findFirstResponder {
    return [[UIApplication sharedApplication] valueForKey:@"_firstResponder"];
}

+ (nullable UIView *)findInputAccessoryViewIn:(UIView *)view {
    if (view == nil) return nil;
    @try {
        id acc = [view valueForKey:@"_inputAccessoryView"];
        if ([acc isKindOfClass:[UIView class]]) {
            return acc;
        }
    } @catch (NSException *e) {}
    for (UIView *sub in view.subviews) {
        UIView *found = [self findInputAccessoryViewIn:sub];
        if (found != nil) return found;
    }
    return nil;
}

@end
