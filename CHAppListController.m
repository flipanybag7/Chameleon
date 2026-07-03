#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <objc/runtime.h>

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
                NSString *bundleID = [proxy valueForKey:@"applicationIdentifier"];
                NSString *name = [proxy valueForKey:@"localizedName"] ?: bundleID;
                if (bundleID && name && ![bundleID hasPrefix:@"com.apple."]) {
                    [appList addObject:@{@"name": name, @"id": bundleID}];
                }
            }
        }

        [appList sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [a[@"name"] compare:b[@"name"]];
        }];

        for (NSDictionary *app in appList) {
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:app[@"name"]
                target:self set:NULL get:NULL
                detail:objc_getClass("CHProfileListController")
                cell:PSLinkCell edit:nil];
            [spec setProperty:app[@"id"] forKey:@"bundleID"];
            [spec setProperty:@YES forKey:@"isController"];
            [specs addObject:spec];
        }

        _specifiers = specs;
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)spec { return nil; }
- (void)setPreferenceValue:(id)v specifier:(PSSpecifier *)s {}

@end
