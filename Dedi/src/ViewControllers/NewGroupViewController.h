//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "OWSConversationSettingsViewDelegate.h"
#import <SignalMessaging/OWSViewController.h>

NS_ASSUME_NONNULL_BEGIN

@interface NewGroupViewController : OWSViewController

@property (nonatomic, weak) id<OWSConversationSettingsViewDelegate> delegate;
@property (nonatomic) BOOL isSendingBulkMessage;

@end

NS_ASSUME_NONNULL_END
