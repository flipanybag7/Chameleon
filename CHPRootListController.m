#import "CHIdentityEngine.h"
#import <objc/runtime.h>

@interface CHPRootListController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *sections;
@end

@implementation CHPRootListController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Chameleon";
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    [self buildSections];
}

- (void)buildSections {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.chameleon.prefs"];
    [defaults registerDefaults:@{
        @"Enabled": @YES,
        @"SpoofUIDevice": @YES,
        @"SpoofMGCopyAnswer": @YES,
        @"SpoofASIdentifier": @YES,
        @"SpoofCanvas": @YES,
        @"SpoofSysctl": @YES,
        @"SpoofIOKit": @YES,
        @"SpoofNetwork": @YES,
    }];

    self.sections = @[
        @{@"header": @"Global Control",
          @"cells": @[
            @{@"type": @"switch", @"label": @"Chameleon Enabled", @"key": @"Enabled"}
          ]},
        @{@"header": @"Hooked APIs",
          @"cells": @[
            @{@"type": @"switch", @"label": @"Spoof UIDevice", @"key": @"SpoofUIDevice"},
            @{@"type": @"switch", @"label": @"Spoof MobileGestalt", @"key": @"SpoofMGCopyAnswer"},
            @{@"type": @"switch", @"label": @"Spoof Advertising ID", @"key": @"SpoofASIdentifier"},
            @{@"type": @"switch", @"label": @"Spoof Canvas / WebGL", @"key": @"SpoofCanvas"},
            @{@"type": @"switch", @"label": @"Spoof Sysctl", @"key": @"SpoofSysctl"},
            @{@"type": @"switch", @"label": @"Spoof IOKit", @"key": @"SpoofIOKit"},
            @{@"type": @"switch", @"label": @"Spoof Carrier Info", @"key": @"SpoofNetwork"},
          ]},
        @{@"header": @"Actions",
          @"cells": @[
            @{@"type": @"button", @"label": @"Reset Current App Identity", @"action": @"resetIdentity"},
            @{@"type": @"button", @"label": @"Reset All Identities", @"action": @"resetAll"},
          ]},
        @{@"header": @"About",
          @"cells": @[
            @{@"type": @"static", @"label": @"Version", @"value": @"1.0.0"},
            @{@"type": @"static", @"label": @"Target", @"value": @"iOS 13.0+"},
          ]},
    ];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[section][@"cells"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section][@"header"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *cellData = self.sections[indexPath.section][@"cells"][indexPath.row];
    NSString *type = cellData[@"type"];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.chameleon.prefs"];

    if ([type isEqualToString:@"switch"]) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text = cellData[@"label"];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        UISwitch *sw = [[UISwitch alloc] init];
        sw.on = [defaults boolForKey:cellData[@"key"]];
        sw.tag = indexPath.section * 1000 + indexPath.row;
        [sw addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = sw;
        return cell;
    }

    if ([type isEqualToString:@"button"]) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text = cellData[@"label"];
        cell.textLabel.textColor = self.view.tintColor;
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        return cell;
    }

    if ([type isEqualToString:@"static"]) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        cell.textLabel.text = cellData[@"label"];
        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.detailTextLabel.text = cellData[@"value"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    return [[UITableViewCell alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *cellData = self.sections[indexPath.section][@"cells"][indexPath.row];
    NSString *type = cellData[@"type"];
    NSString *action = cellData[@"action"];

    if ([type isEqualToString:@"button"]) {
        if ([action isEqualToString:@"resetIdentity"]) {
            [self confirmReset:NO];
        } else if ([action isEqualToString:@"resetAll"]) {
            [self confirmReset:YES];
        }
    }
}

- (void)switchChanged:(UISwitch *)sender {
    NSIndexPath *indexPath;
    for (NSInteger s = 0; s < self.sections.count; s++) {
        for (NSInteger r = 0; r < [self.sections[s][@"cells"] count]; r++) {
            if (s * 1000 + r == sender.tag) {
                indexPath = [NSIndexPath indexPathForRow:r inSection:s];
                break;
            }
        }
    }
    if (!indexPath) return;

    NSDictionary *cellData = self.sections[indexPath.section][@"cells"][indexPath.row];
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.chameleon.prefs"];
    [defaults setBool:sender.on forKey:cellData[@"key"]];
    [defaults synchronize];
}

- (void)confirmReset:(BOOL)all {
    NSString *title = all ? @"Reset All Identities" : @"Reset Identity";
    NSString *msg = all ? @"Generate new identities for ALL apps?" : @"Generate new identity for current app?";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        if (all) {
            NSString *path = @"/var/mobile/Library/Preferences/com.chameleon.identities.plist";
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        } else {
            NSString *bundleID = [NSBundle mainBundle].bundleIdentifier;
            if (bundleID) {
                [[CHIdentityEngine sharedEngine] resetIdentityForBundleID:bundleID];
            }
        }
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
