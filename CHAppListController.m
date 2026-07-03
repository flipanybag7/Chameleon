#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <objc/runtime.h>

@interface UIImage (ChameleonIcon)
+ (id)_applicationIconImageForBundleIdentifier:(id)arg1 format:(int)arg2 scale:(CGFloat)arg3;
@end

@interface CHAppListController : PSListController
@end

@implementation CHAppListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];
        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Installed Apps"]];

        NSMutableArray *appList = [NSMutableArray array];
        Class LSApp = objc_getClass("LSApplicationWorkspace");
        if (LSApp) {
            id workspace = [LSApp performSelector:@selector(defaultWorkspace)];
            NSArray *all = [workspace performSelector:@selector(allInstalledApplications)];
            for (id proxy in all) {
                NSString *bundleID = [proxy performSelector:@selector(applicationIdentifier)];
                NSString *name = [proxy performSelector:@selector(localizedName)] ?: bundleID;
                if (bundleID && name && ![bundleID hasPrefix:@"com.apple."] && ![bundleID hasPrefix:@"com.chameleon."]) {
                    [appList addObject:@{@"name": name, @"id": bundleID}];
                }
            }
        }

        [appList sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [a[@"name"] localizedCompare:b[@"name"]];
        }];

        for (NSDictionary *app in appList) {
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:app[@"name"]
                target:self set:NULL get:NULL
                detail:objc_getClass("CHProfileListController")
                cell:PSLinkCell edit:nil];
            [spec setProperty:app[@"id"] forKey:@"bundleID"];
            [spec setProperty:@YES forKey:@"isController"];

            UIImage *icon = [UIImage _applicationIconImageForBundleIdentifier:app[@"id"]
                              format:2 scale:[UIScreen mainScreen].scale];
            if (icon) [spec setProperty:icon forKey:@"iconImage"];

            [specs addObject:spec];
        }

        _specifiers = specs;
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)spec { return nil; }
- (void)setPreferenceValue:(id)v specifier:(PSSpecifier *)s {}

@end
