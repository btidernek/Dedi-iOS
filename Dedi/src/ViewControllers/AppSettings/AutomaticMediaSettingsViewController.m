//
//  MediaAndDataUsageSettingsViewController.h
//  Dedi
//
//  Created by btider-salih on 12.09.2018.
//  Copyright © 2018 BTIDER. All rights reserved.
//

#import "AutomaticMediaSettingsViewController.h"
#import "Dedi-Swift.h"
#import "SignalApp.h"
#import <SignalMessaging/Environment.h>

@interface AutomaticMediaSettingsViewController ()

@end

@implementation AutomaticMediaSettingsViewController

- (void)viewDidLoad
{
    [self updateTableContents];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];
    
    OWSTableSection *section = [OWSTableSection new];
    
    OWSPreferences *prefs = [Environment preferences];
    NSUInteger selectedAutomaticDownloadMode = (NSUInteger)[[NSUserDefaults standardUserDefaults] integerForKey:self.selectedMediaTypeString];
    for (NSNumber *option in
         @[ @(DownloadNever), @(DownloadOnlyOnWifi), @(DownloadOnWifiAndCellular) ]) {
        AutomaticDownloadMode automaticDownloadMode = (AutomaticDownloadMode)option.intValue;
        
        [section addItem:[OWSTableItem itemWithCustomCellBlock:^{
            UITableViewCell *cell = [UITableViewCell new];
            [[cell textLabel] setText:[prefs nameForAutomaticDownloadMode:automaticDownloadMode]];
            if (selectedAutomaticDownloadMode == automaticDownloadMode) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
            return cell;
        }
                                                   actionBlock:^{
                                                       [[NSUserDefaults standardUserDefaults] setInteger:option.intValue forKey:self.selectedMediaTypeString];
                                                       [[NSUserDefaults standardUserDefaults] synchronize];
                                                       [self.navigationController popViewControllerAnimated:YES];
                                                   }]];
    }
    [contents addSection:section];
    
    self.contents = contents;
}

@end
