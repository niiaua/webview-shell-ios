#import "HideKeyboardAccessory.h"

@implementation HideKeyboardAccessory

+ (BOOL)applyToWebView:(UIView *)webView {
    if (webView == nil) return NO;

    // 私有 key：WKWebView 内部的 inputAccessoryViewController 和 inputAccessoryView
    // 全部用 @try/@catch 包住 —— 即使某个 key 不存在，KVC 抛的 NSUnknownKeyException
    // 也会被捕获，返回 nil，绝不让 app 崩溃。
    @try {
        UIView *target = nil;

        // 路径1：直接递归找实现 _inputAccessoryView 的视图
        target = [self findInputAccessoryViewIn:webView];

        // 路径2：通过 scrollView 里的 _inputAccessoryViewController
        if (target == nil) {
            UIScrollView *scrollView = (UIScrollView *)[webView valueForKey:@"scrollView"];
            if ([scrollView isKindOfClass:[UIScrollView class]]) {
                UIView *contentView = scrollView.subviews.firstObject;
                if (contentView) {
                    id vc = nil;
                    // 包一层，防止 contentView 不响应这个私有 key
                    @try {
                        vc = [contentView valueForKey:@"_inputAccessoryViewController"];
                    } @catch (NSException *e) {
                        vc = nil;
                    }
                    if ([vc isKindOfClass:[NSObject class]]) {
                        UIView *iv = [vc valueForKey:@"view"];
                        if ([iv isKindOfClass:[UIView class]]) {
                            target = iv;
                        }
                    }
                }
            }
        }

        if (target != nil && [target isKindOfClass:[UIView class]]) {
            target.frame = CGRectZero;
            target.hidden = YES;
            return YES;
        }
    } @catch (NSException *e) {
        // 任何意外异常都不外抛，保证 app 稳定
        return NO;
    }
    return NO;
}

/// 递归查找第一个对 _inputAccessoryView 有响应的视图（返回值做容错）
+ (nullable UIView *)findInputAccessoryViewIn:(UIView *)view {
    if (view == nil) return nil;
    @try {
        id acc = [view valueForKey:@"_inputAccessoryView"];
        if ([acc isKindOfClass:[UIView class]]) {
            return acc;
        }
    } @catch (NSException *e) {
        // 该视图不响应 _inputAccessoryView，继续往下找
    }
    for (UIView *sub in view.subviews) {
        UIView *found = [self findInputAccessoryViewIn:sub];
        if (found != nil) {
            return found;
        }
    }
    return nil;
}

@end
