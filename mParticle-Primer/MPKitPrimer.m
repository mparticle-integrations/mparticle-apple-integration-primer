#import "MPKitPrimer.h"

#if defined(__has_include) && __has_include(<Primer/Primer.h>)
#import <Primer/Primer.h>
#else
#import "Primer.h"
#endif


@implementation MPKitPrimer

#pragma mark - Class methods

+ (NSNumber *)kitCode {
    return @(100);
}

+ (void)load {
    MPKitRegister *kitRegister = [[MPKitRegister alloc] initWithName:@"Primer" className:@"MPKitPrimer"];
    [MParticle registerExtension:kitRegister];
}

#pragma mark - Kit instance and lifecycle

- (MPKitExecStatus *)didFinishLaunchingWithConfiguration:(NSDictionary *)configuration {
    MPKitExecStatus *execStatus = nil;

    if (![Primer isInitialized]) {
        NSLog(@"You must initialize the Primer SDK (e.g. using `startWithToken`) before starting mParticle!");
        execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeRequirementsNotMet];
        return execStatus;
    }

    _configuration = configuration;

    [self start];

    execStatus = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess];
    return execStatus;
}

- (void)start {

    static dispatch_once_t kitPredicate;

    dispatch_once(&kitPredicate, ^{

        self->_started = YES;

        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *userInfo = @{mParticleKitInstanceKey: [[self class] kitCode]};
            [[NSNotificationCenter defaultCenter] postNotificationName:mParticleKitDidBecomeActiveNotification object:nil userInfo:userInfo];
        });
    });
}

- (id const)providerKitInstance {

    return nil;
}

#pragma mark - Application

- (nonnull MPKitExecStatus *)continueUserActivity:(nonnull NSUserActivity *)userActivity restorationHandler:(void(^ _Nonnull)(NSArray * _Nullable restorableObjects))restorationHandler {

    [Primer continueUserActivity:userActivity];

    return [self statusWithCode:MPKitReturnCodeSuccess];
}

#pragma mark - User attributes and identities

- (nonnull MPKitExecStatus *)setUserAttribute:(nonnull NSString *)key value:(nonnull NSString *)value {

    if (!value) {
        return [self statusWithCode:MPKitReturnCodeFail];
    }

    NSString *prefixedKey = [NSString stringWithFormat:@"mParticle.%@", key];
    [Primer appendUserProperties:@{prefixedKey: value}];

    return [self statusWithCode:MPKitReturnCodeSuccess];
}

#pragma mark - e-Commerce

- (nonnull MPKitExecStatus *)logCommerceEvent:(nonnull MPCommerceEvent *)commerceEvent {

    MPKitExecStatus *status = [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:MPKitReturnCodeSuccess forwardCount:0];

    NSArray *expandedInstructions = [commerceEvent expandedInstructions];
    for (MPCommerceEventInstruction *commerceEventInstruction in expandedInstructions) {
        [self logEvent:commerceEventInstruction.event];
        [status incrementForwardCount];
    }

    return status;
}

#pragma mark - Events

- (nonnull MPKitExecStatus *)logEvent:(nonnull MPEvent *)event {

    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:@"mParticle" forKey:@"pmr_event_api"];

    if (event.info) {
        [parameters addEntriesFromDictionary:event.info];
    }

    [Primer trackEventWithName:event.name parameters:parameters];

    return [self statusWithCode:MPKitReturnCodeSuccess];
}

- (nonnull MPKitExecStatus *)logScreen:(nonnull MPEvent *)event {

    return [self logEvent:event];;
}

#pragma mark - Assorted

- (nonnull MPKitExecStatus *)setDebugMode:(BOOL)debugMode {

    PMRLoggingLevel loggingLevel = debugMode ? PMRLoggingLevelWarning : PMRLoggingLevelNone;
    [Primer setLoggingLevel:loggingLevel];

    return [self statusWithCode:MPKitReturnCodeSuccess];
}

#pragma mark - Utilities

- (nonnull MPKitExecStatus *)statusWithCode:(MPKitReturnCode)code {

    return [[MPKitExecStatus alloc] initWithSDKCode:[[self class] kitCode] returnCode:code];
}

@end
