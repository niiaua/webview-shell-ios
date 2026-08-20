#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 隐藏 WKWebView 键盘顶部辅助栏的安全函数。
/// 所有对私有 key 的 KVC 访问都在 @try/@catch 里进行，
/// 这样即使某个 key 不存在也只会安静地返回 nil，绝不会崩溃。
@interface HideKeyboardAccessory : NSObject

/// 尝试隐藏给定 webView 的键盘辅助栏。多次调用安全（内部有保护）。
/// @return 是否成功找到并隐藏了辅助栏视图
+ (BOOL)applyToWebView:(UIView *)webView;

@end

NS_ASSUME_NONNULL_END
