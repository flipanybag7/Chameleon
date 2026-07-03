#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface CHAppListController : PSListController
@end

@implementation CHAppListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSMutableArray *specs = [NSMutableArray array];
        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Installed Apps"]];

        NSMutableDictionary *apps = [NSMutableDictionary dictionary];
        for (NSDictionary *dict in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:
             @"/var/jb/Applications" error:nil] ?: @[]) {
            NSString *infoPath = [NSString stringWithFormat:@"/var/jb/Applications/%@/Info.plist", dict];
            NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:infoPath];
            NSString *bundleID = info[@"CFBundleIdentifier"];
            NSString *name = info[@"CFBundleDisplayName"] ?: info[@"CFBundleName"] ?: dict;
            if (bundleID) apps[bundleID] = name;
        }

        NSArray *sorted = [apps.allKeys sortedArrayUsingSelector:@selector(compare:)];
        for (NSString *bundleID in sorted) {
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:apps[bundleID]
                target:self set:NULL get:NULL
                detail:objc_getClass("CHProfileListController")
                cell:PSLinkCell edit:nil];
            [spec setProperty:bundleID forKey:@"bundleID"];
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
