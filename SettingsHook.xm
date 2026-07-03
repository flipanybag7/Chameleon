#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>

@interface PSSpecifier : NSObject
+ (id)groupSpecifierWithName:(id)arg1;
+ (id)preferenceSpecifierNamed:(id)arg1 target:(id)arg2 set:(SEL)arg3 get:(SEL)arg4 detail:(Class)arg5 cell:(int)arg6 edit:(id)arg7;
@end

static NSArray *(*orig_specifiers)(id, SEL);
static NSArray *hooked_specifiers(id self, SEL _cmd) {
    NSArray *specs = orig_specifiers(self, _cmd);
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (![bundleID isEqualToString:@"com.apple.Preferences"]) return specs;
    if (![NSStringFromClass([self class]) isEqualToString:@"PSSettingsController"]) return specs;

    Class vc = objc_getClass("CHPRootListController");
    if (!vc) return specs;

    NSMutableArray *mspecs = [specs mutableCopy];
    [mspecs insertObject:[PSSpecifier groupSpecifierWithName:@""] atIndex:0];
    [mspecs insertObject:[PSSpecifier preferenceSpecifierNamed:@"Chameleon"
        target:self set:NULL get:NULL detail:vc cell:1 edit:nil] atIndex:1];
    return mspecs;
}

%ctor {
    Class psLC = objc_getClass("PSListController");
    if (psLC) {
        MSHookMessageEx(psLC, @selector(specifiers), (IMP)hooked_specifiers, (IMP *)&orig_specifiers);
    }
}
