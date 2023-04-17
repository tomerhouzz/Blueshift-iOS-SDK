//
//  BlueshiftInAppNotificationRequest.m
//  BlueShift-iOS-Extension-SDK
//
//  Created by Noufal on 29/10/19.
//

#import "BlueshiftInAppNotificationRequest.h"
#import "BlueshiftLog.h"
#import "InAppNotificationEntity.h"

@implementation BlueshiftInAppNotificationRequest

+ (void)fetchInAppNotificationWithSuccess:(void (^)(NSDictionary*))success failure:(void (^)(NSError*))failure {
    [BlueshiftInboxAPIManager getMessagesForMessageUUIDs:nil success:^(NSDictionary * _Nonnull data) {
        success(data);
    } failure:^(NSError * _Nullable err, NSArray * _Nullable batch) {
        failure(err);
    }];
}

@end

@implementation BlueshiftInboxAPIManager

+ (void)getMessageIdsAndStatus:(void (^)(NSArray* _Nullable))success failure:(void (^)(NSError*))failure {
        [[BlueShift sharedInstance] getInAppNotificationAPIPayloadWithCompletionHandler:^(NSDictionary * apiPayload) {
            if(apiPayload) {
                NSString *url = [BlueshiftRoutes getInboxStatusURL];
                [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: apiPayload completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
                    if (status) {
                        [BlueshiftLog logAPICallInfo:@"Succesfully fetched status for messages." withDetails:data statusCode:0];
                        NSArray* statusArray = (NSArray*)data[kInAppNotificationContentPayloadKey];
                        if (![statusArray isEqual: [NSNull null]] && statusArray && statusArray.count > 0) {
                            success(statusArray);
                        } else {
                            success(@[]);
                        }
                    } else {
                        failure(error);
                    }
                }];
            }
        }];
}

+ (void)getMessagesForMessageUUIDs:(NSArray* _Nullable)messageIds success:(void (^)(NSDictionary*))success failure:(void (^)(NSError*, NSArray*))failure {
    [[BlueShift sharedInstance] getInAppNotificationAPIPayloadWithCompletionHandler:^(NSDictionary * apiPayload) {
        if(apiPayload) {
            NSMutableDictionary* payload = [apiPayload mutableCopy];
            NSString *url = nil;
            if (BlueShift.sharedInstance.config.enableMobileInbox == YES) {
                url = [BlueshiftRoutes getInboxMessagesURL];
                if (messageIds) {
                    [payload setValue:messageIds forKey:@"message_uuids"];
                }
            } else {
                url = [BlueshiftRoutes getInAppMessagesURL];
            }
            
            [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: payload completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
                if (status) {
                    [BlueshiftLog logAPICallInfo:@"Succesfully fetched Inbox messages." withDetails:data statusCode:0];
                    success(data);
                } else {
                    failure(error, messageIds);
                }
            }];
        } else {
            NSError *error = (NSError*)@"Unable to fetch Inbox messages as device_id is missing.";
            failure(error, messageIds);
        }
    }];
}

+ (void)deleteMessagesWithMessageUUIDs:(NSArray*)messageIds success:(void (^)(BOOL))success failure:(void (^)(NSError*))failure {
    if(BlueShift.sharedInstance.config.apiKey && messageIds && messageIds.count > 0 && [BlueShiftNetworkReachabilityManager networkConnected]) {
        NSString *url = [BlueshiftRoutes getInboxUpdateURL];
        NSDictionary* payload = @{
            @"api_key": BlueShift.sharedInstance.config.apiKey,
            @"device_id": BlueShiftDeviceData.currentDeviceData.deviceUUID,
            @"action": @"delete",
            @"message_uuids": messageIds
        };
        
        [[BlueShiftRequestOperationManager sharedRequestOperationManager] postRequestWithURL: url andParams: payload completetionHandler:^(BOOL status, NSDictionary *data, NSError *error) {
            if (status) {
                [BlueshiftLog logAPICallInfo:@"Succesfully deleted messages." withDetails:nil statusCode:0];
                success(status);
            } else {
                failure(error);
            }
        }];
    } else {
        NSError *error = (NSError*)@"Unable to delete messages as API key is missing or device is offline.";
        failure(error);
    }
}


@end
