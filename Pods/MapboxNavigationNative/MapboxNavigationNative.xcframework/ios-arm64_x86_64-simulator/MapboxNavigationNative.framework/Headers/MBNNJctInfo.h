// This file is generated and will be overwritten automatically.

#import <Foundation/Foundation.h>

@class MBNNLocalizedString;

/** Japan-specific Junction info, refers to a place where multiple expressways meet, e.g. Ariake JCT */
NS_SWIFT_NAME(JctInfo)
__attribute__((visibility ("default")))
@interface MBNNJctInfo : NSObject

// This class provides custom init which should be called
- (nonnull instancetype)init NS_UNAVAILABLE;

// This class provides custom init which should be called
+ (nonnull instancetype)new NS_UNAVAILABLE;

- (nonnull instancetype)initWithName:(nonnull NSArray<MBNNLocalizedString *> *)name;

/** Language order is not guaranteed */
@property (nonatomic, readonly, nonnull, copy) NSArray<MBNNLocalizedString *> *name;


@end
