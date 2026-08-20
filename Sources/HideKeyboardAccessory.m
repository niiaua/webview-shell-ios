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

        // 路径3：通过 scrollView 里 WKContentView 的 private inputAccessoryViewController
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

        if (target != nil && [target isKindOfClass:[UIView class]]) {
            target.frame = CGRectZero;
            target.hidden = YES;
            // 有些版本需要把它移出可视区域才能彻底消失
            target.alpha = 0.01;
            return YES;
        }
    } @catch (NSException *e) {
        return NO;
    }
    return NO;
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
