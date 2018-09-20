//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

#import "TSAttachmentPointer.h"
#import "MIMETypeUtil.h"
#import <Reachability/Reachability.h>

NS_ASSUME_NONNULL_BEGIN

@implementation TSAttachmentPointer

- (nullable instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (!self) {
        return self;
    }

    // A TSAttachmentPointer is a yet-to-be-downloaded attachment.
    // If this is an old TSAttachmentPointer from another session,
    // we know that it failed to complete before the session completed.
    if (![coder containsValueForKey:@"state"]) {
        _state = TSAttachmentPointerStateFailed;
    }

    return self;
}

- (instancetype)initWithServerId:(UInt64)serverId
                             key:(NSData *)key
                          digest:(nullable NSData *)digest
                       byteCount:(UInt32)byteCount
                     contentType:(NSString *)contentType
                           relay:(NSString *)relay
                  sourceFilename:(nullable NSString *)sourceFilename
                  attachmentType:(TSAttachmentType)attachmentType
{
    self = [super initWithServerId:serverId
                     encryptionKey:key
                         byteCount:byteCount
                       contentType:contentType
                    sourceFilename:sourceFilename];
    if (!self) {
        return self;
    }

    _digest = digest;
    
    // -BTIDER UPDATE- Automatic Download
    NSInteger autoDownMode = 0;
    BOOL isReachableViaWiFi = [[Reachability reachabilityForInternetConnection] isReachableViaWiFi];
    if ([MIMETypeUtil isImage:contentType] || [MIMETypeUtil isAnimated:contentType]){
         autoDownMode= [[NSUserDefaults standardUserDefaults] integerForKey:@"AUTOMATIC_DOWNLOAD_MODE_FOR_IMAGES"];
    }else if ([MIMETypeUtil isAudio:contentType]){
         autoDownMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"AUTOMATIC_DOWNLOAD_MODE_FOR_SOUND"];
    }else if ([MIMETypeUtil isVideo:contentType]){
         autoDownMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"AUTOMATIC_DOWNLOAD_MODE_FOR_VIDEOS"];
    }else {
         autoDownMode = [[NSUserDefaults standardUserDefaults] integerForKey:@"AUTOMATIC_DOWNLOAD_MODE_FOR_DOCS"];
    }

    /* AutomaticDownloadMode -> Unassigned = 0, DownloadNever = 1, DownloadOnlyOnWifi = 2, DownloadOnWifiAndCellular = 3 */
    if (autoDownMode == 3 || ((autoDownMode == 2) && isReachableViaWiFi)){
        _state = TSAttachmentPointerStateEnqueued;
    }else{
        _state = TSAttachmentPointerStateOnHold;
    }
    
    _relay = relay;
    self.attachmentType = attachmentType;

    return self;
}


+ (TSAttachmentPointer *)attachmentPointerFromProto:(OWSSignalServiceProtosAttachmentPointer *)attachmentProto
                                              relay:(NSString *_Nullable)relay
{
    OWSAssert(attachmentProto.id != 0);
    OWSAssert(attachmentProto.key != nil);
    OWSAssert(attachmentProto.contentType != nil);

    // digest will be empty for old clients.
    NSData *digest = attachmentProto.hasDigest ? attachmentProto.digest : nil;

    TSAttachmentType attachmentType = TSAttachmentTypeDefault;
    if ([attachmentProto hasFlags]) {
        UInt32 flags = attachmentProto.flags;
        if ((flags & (UInt32)OWSSignalServiceProtosAttachmentPointerFlagsVoiceMessage) > 0) {
            attachmentType = TSAttachmentTypeVoiceMessage;
        }
    }

    TSAttachmentPointer *pointer = [[TSAttachmentPointer alloc] initWithServerId:attachmentProto.id
                                                                             key:attachmentProto.key
                                                                          digest:digest
                                                                       byteCount:attachmentProto.size
                                                                     contentType:attachmentProto.contentType
                                                                           relay:relay
                                                                  sourceFilename:attachmentProto.fileName
                                                                  attachmentType:attachmentType];
    return pointer;
}

- (BOOL)isDecimalNumberText:(NSString *)text
{
    return [text componentsSeparatedByCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]].count == 1;
}

- (void)upgradeFromAttachmentSchemaVersion:(NSUInteger)attachmentSchemaVersion
{
    // Legacy instances of TSAttachmentPointer apparently used the serverId as their
    // uniqueId.
    if (attachmentSchemaVersion < 2 && self.serverId == 0) {
        OWSAssert([self isDecimalNumberText:self.uniqueId]);
        if ([self isDecimalNumberText:self.uniqueId]) {
            // For legacy instances, try to parse the serverId from the uniqueId.
            self.serverId = [self.uniqueId integerValue];
        } else {
            DDLogError(@"%@ invalid legacy attachment uniqueId: %@.", self.logTag, self.uniqueId);
        }
    }
}

@end

NS_ASSUME_NONNULL_END
