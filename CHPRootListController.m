#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import "CHIdentityEngine.h"

@interface CHPRootListController : PSListController
@end

@implementation CHPRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        NSString *suite = @"com.chameleon.prefs";
        NSArray *toggles = @[
            @{@"key": @"Enabled", @"label": @"Chameleon Enabled"},
            @{@"key": @"SpoofUIDevice", @"label": @"Spoof UIDevice"},
            @{@"key": @"SpoofMGCopyAnswer", @"label": @"Spoof MobileGestalt"},
            @{@"key": @"SpoofASIdentifier", @"label": @"Spoof Advertising ID"},
            @{@"key": @"SpoofCanvas", @"label": @"Spoof Canvas / WebGL"},
            @{@"key": @"SpoofSysctl", @"label": @"Spoof Sysctl"},
            @{@"key": @"SpoofIOKit", @"label": @"Spoof IOKit"},
            @{@"key": @"SpoofNetwork", @"label": @"Spoof Carrier Info"},
        ];

        NSMutableArray *specs = [NSMutableArray array];
        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Global Control"]];
        [specs addObject:[PSSpecifier preferenceSpecifierNamed:@"Chameleon Enabled"
            target:self set:@selector(setPreferenceValue:specifier:)
            get:@selector(readPreferenceValue:)
            detail:nil cell:PSSwitchCell edit:nil]];

        [specs addObject:[PSSpecifier groupSpecifierWithName:@"Hooked APIs"]];
        for (NSDictionary *item in toggles) {
            if ([item[@"key"] isEqualToString:@"Enabled"]) continue;
            PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:item[@"label"]
                target:self set:@selector(setPreferenceValue:specifier:)
                get:@selector(readPreferenceValue:)
                detail:nil cell:PSSwitchCell edit:nil];
            [spec setProperty:item[@"key"] forKey:@"key"];
            [spec setProperty:@YES forKey:@"default"];
            [specs addObject:spec];
        }

        _specifiers = specs;
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)spec {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.chameleon.prefs"];
    return [defaults objectForKey:[spec propertyForKey:@"key"]] ?: @YES;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)spec {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.chameleon.prefs"];
    [defaults setObject:value forKey:[spec propertyForKey:@"key"]];
    [defaults synchronize];
}

@end
