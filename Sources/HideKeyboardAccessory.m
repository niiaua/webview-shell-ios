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

        // 几何特征兜底：用窗口绝对坐标找键盘上方的横条
        if (target == nil || [target isKindOfClass:[UIView class]] == NO) {
            target = [HideKeyboardAccessory findAccessoryBarInWindows];
        }

        if (target != nil && [target isKindOfClass:[UIView class]]) {
            target.frame = CGRectMake(0, 0, 1, 1);
            target.hidden = YES;
            return YES;
        }
    } @catch (NSException *e) {
        return NO;
    }
    return NO;
}

+ (nullable UIView *)findAccessoryBarInWindows {
    @try {
        for (UIWindow *window in UIApplication.sharedApplication.windows) {
            UIView *found = [self scanForAccessoryBar:window
                                             inWindow:window
                                       screenBounds:window.bounds];
            if (found) { return found; }
        }
    } @catch (NSException *e) {}
    return nil;
}

+ (nullable UIView *)scanForAccessoryBar:(UIView *)view
                                inWindow:(UIWindow *)window
                            screenBounds:(CGRect)screen {
    if (view == nil || view.isHidden) return nil;
    @try {
        // 转成窗口绝对坐标判断（frame 本身是相对父视图的）
        CGRect absRect = [view.superview convertRect:view.frame toView:window];
        CGFloat screenW = screen.size.width;
        CGFloat screenH = screen.size.height;
        // 辅助栏特征：接近全屏宽、高 20~65pt、位于下部（键盘之上）
        if (absRect.size.width > screenW * 0.8 &&
            absRect.size.height >= 20 && absRect.size.height <= 65 &&
            absRect.origin.y > screenH * 0.4) {
            return view;
        }
    } @catch (NSException *e) {}
    for (UIView *sub in view.subviews) {
        UIView *found = [self scanForAccessoryBar:sub inWindow:window screenBounds:screen];
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
