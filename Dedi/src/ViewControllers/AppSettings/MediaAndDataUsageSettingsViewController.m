//
//  MediaAndDataUsageSettingsViewController.h
//  Dedi
//
//  Created by btider-salih on 12.09.2018.
//  Copyright © 2018 BTIDER. All rights reserved.
//

#import "MediaAndDataUsageSettingsViewController.h"
#import "AutomaticMediaSettingsViewController.h"
#import "Dedi-Swift.h"
#import "SignalApp.h"
#import <SignalMessaging/Environment.h>

@implementation MediaAndDataUsageSettingsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTitle:NSLocalizedString(@"MEDIA_AND_DATA_USAGE_TITLE", nil)];
    
    [self updateTableContents];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self updateTableContents];
}

#pragma mark - Table Contents

- (void)updateTableContents
{
    OWSTableContents *contents = [OWSTableContents new];
    
    __weak MediaAndDataUsageSettingsViewController *weakSelf = self;
    OWSPreferences *prefs = [Environment preferences];
    
    OWSTableSection *automaticMediaDownloadSection = [OWSTableSection new];
    
    AutomaticDownloadMode autoDownModeForImages = (AutomaticDownloadMode)[[NSUserDefaults standardUserDefaults] integerForKey:@"AUTOMATIC_DOWNLOAD_MODE_FOR_IMAGES"];
    AutomaticDownloadMode autoDownModeForSound = (AutomaticDownloadMode)[[NSUserDefaults standardUserDefaults] integerForKey:@"AUTOMATIC_DOWNLOAD_MODE_FOR_SOUND"];
    AutomaticDownloadMode autoDownModeForVideos = (AutomaticDownloadMode)[[NSUserDefaults standardUserDefaults] integerForKey:@"AUTOMATIC_DOWNLOAD_MODE_FOR_VIDEOS"];
    AutomaticDownloadMode autoDownModeForDocs = (AutomaticDownloadMode)[[NSUserDefaults standardUserDefaults] integerForKey:@"AUTOMATIC_DOWNLOAD_MODE_FOR_DOCS"];

    automaticMediaDownloadSection.headerTitle = NSLocalizedString(@"SETTINGS_AUTOMATIC_MEDIA_DOWNLOAD_TITLE", @"table section header");
    [automaticMediaDownloadSection
     addItem:[OWSTableItem
              disclosureItemWithText:NSLocalizedString(@"SETTINGS_AUTOMATIC_MEDIA_DOWNLOAD_IMAGES", nil)
              detailText:[prefs nameForAutomaticDownloadMode:autoDownModeForImages]
              actionBlock:^{
                  AutomaticMediaSettingsViewController *vc =
                  [AutomaticMediaSettingsViewController new];
                  vc.selectedMediaTypeString = @"AUTOMATIC_DOWNLOAD_MODE_FOR_IMAGES";
                  [weakSelf.navigationController pushViewController:vc animated:YES];
              }]];
    [automaticMediaDownloadSection
     addItem:[OWSTableItem
              disclosureItemWithText:NSLocalizedString(@"SETTINGS_AUTOMATIC_MEDIA_DOWNLOAD_SOUND", nil)
              detailText:[prefs nameForAutomaticDownloadMode:autoDownModeForSound]
              actionBlock:^{
                  AutomaticMediaSettingsViewController *vc =
                  [AutomaticMediaSettingsViewController new];
                  vc.selectedMediaTypeString = @"AUTOMATIC_DOWNLOAD_MODE_FOR_SOUND";
                  [weakSelf.navigationController pushViewController:vc animated:YES];
              }]];
    [automaticMediaDownloadSection
     addItem:[OWSTableItem
              disclosureItemWithText:NSLocalizedString(@"SETTINGS_AUTOMATIC_MEDIA_DOWNLOAD_VIDEOS", nil)
              detailText:[prefs nameForAutomaticDownloadMode:autoDownModeForVideos]
              actionBlock:^{
                  AutomaticMediaSettingsViewController *vc =
                  [AutomaticMediaSettingsViewController new];
                  vc.selectedMediaTypeString = @"AUTOMATIC_DOWNLOAD_MODE_FOR_VIDEOS";
                  [weakSelf.navigationController pushViewController:vc animated:YES];
              }]];
    [automaticMediaDownloadSection
     addItem:[OWSTableItem
              disclosureItemWithText:NSLocalizedString(@"SETTINGS_AUTOMATIC_MEDIA_DOWNLOAD_DOCS", nil)
              detailText:[prefs nameForAutomaticDownloadMode:autoDownModeForDocs]
              actionBlock:^{
                  AutomaticMediaSettingsViewController *vc =
                  [AutomaticMediaSettingsViewController new];
                  vc.selectedMediaTypeString = @"AUTOMATIC_DOWNLOAD_MODE_FOR_DOCS";
                  [weakSelf.navigationController pushViewController:vc animated:YES];
              }]];
    automaticMediaDownloadSection.footerTitle
    = NSLocalizedString(@"SETTINGS_AUTOMATIC_MEDIA_DOWNLOAD_DESCRIPTION", @"table section footer");
    [contents addSection:automaticMediaDownloadSection];
    
    // Low Data Mode Section
    OWSTableSection *lowDataModeSection = [OWSTableSection new];
    lowDataModeSection.headerTitle = NSLocalizedString(@"SETTINGS_LOW_DATA_MODE_HEADER",
                                                       @"Table header for the 'low  data usage' section.");
    lowDataModeSection.footerTitle = NSLocalizedString(@"SETTINGS_LOW_DATA_MODE_HEADER_FOOTER",
                                                       @"Table footer for the 'low  data usage' section.");
    
    BOOL isLowDataModeOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"IS_LOW_DATA_MODE_ON"];
    [lowDataModeSection
     addItem:[OWSTableItem switchItemWithText:NSLocalizedString(@"SETTINGS_LOW_DATA_MODE",
                                                                @"Label for the  'low  data usage' switch.")
                                         isOn:isLowDataModeOn
                                    isEnabled:YES
                                       target:weakSelf
                                     selector:@selector(didToggleEnableLowDataModeSwitch:)]];
    
    [contents addSection:lowDataModeSection];
    
    self.contents = contents;
}

#pragma mark - Events

- (void)didToggleEnableLowDataModeSwitch:(UISwitch *)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"IS_LOW_DATA_MODE_ON"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self updateTableContents];
}

@end
