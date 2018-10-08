//
//  Copyright (c) 2017 Open Whisper Systems. All rights reserved.
//

#import "SelectThreadViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class SignalAttachment;
@protocol ShareViewDelegate;

@interface SharingThreadPickerViewController : SelectThreadViewController

@property (nonatomic) NSMutableArray<SignalAttachment *> *attachments;

- (instancetype)initWithShareViewDelegate:(id<ShareViewDelegate>)shareViewDelegate;

@end

NS_ASSUME_NONNULL_END
