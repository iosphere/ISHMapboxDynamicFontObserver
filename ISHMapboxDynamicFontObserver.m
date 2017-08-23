//
//  ISHMapboxDynamicFontObserver.m
//  MapboxDynamicFontStyle
//
//  Created by Felix Lamouroux on 18.08.17.
//  Copyright © 2017 iosphere GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ISHMapboxDynamicFontObserver.h"

@interface ISHMapboxDynamicFontObserver ()
@property (nonatomic) NSDictionary<NSString *, MGLStyleValue *> *baseTextSizeValues;
@property (nonatomic) NSDictionary<NSString *, MGLStyleValue *> *baseIconSizeValues;
@end

@implementation ISHMapboxDynamicFontObserver

#pragma mark - Setup

- (instancetype)init {
    self = [super init];

    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(UIContentSizeCategoryDidChangeNotification:)
                                                     name:UIContentSizeCategoryDidChangeNotification
                                                   object:nil];
    }

    return self;
}

- (instancetype)initWithStyle:(MGLStyle *)style {
    NSParameterAssert(style);

    self = [self init];
    self.style = style;
    return self;
}

- (void)setStyle:(MGLStyle *)style {
    _style = style;

    if (!style) {
        self.baseTextSizeValues = nil;
        self.baseIconSizeValues = nil;
        return;
    }

    [self setupBaseValuesForStyle:style];
    [self updateStyleForPreferredContentSizeCategory];
}

- (void)setupBaseValuesForStyle:(MGLStyle *)style {
    NSMutableDictionary<NSString *, MGLStyleValue *> *baseTextSizeValues = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, MGLStyleValue *> *baseIconSizeValues = [NSMutableDictionary new];

    for (MGLSymbolStyleLayer *symbolLayer in style.layers) {
        if (![symbolLayer isKindOfClass:[MGLSymbolStyleLayer class]]) {
            continue;
        }

        if (!symbolLayer.textFontSize || !symbolLayer.identifier) {
            continue;
        }

        baseTextSizeValues[symbolLayer.identifier] = symbolLayer.textFontSize;

        if (!symbolLayer.iconImageName) {
            continue;
        }

        baseIconSizeValues[symbolLayer.identifier] = symbolLayer.iconScale ? : [MGLStyleValue valueWithRawValue:@1];
    }

    self.baseTextSizeValues = [baseTextSizeValues copy];
    self.baseIconSizeValues = [baseIconSizeValues copy];
}

#pragma mark - Dynamic Type Integration

- (void)UIContentSizeCategoryDidChangeNotification:(NSNotification *)note {
    [self updateStyleForPreferredContentSizeCategory];
}

- (void)updateStyleForPreferredContentSizeCategory {
    [self updateStyleForContentSizeCategory:[UIApplication sharedApplication].preferredContentSizeCategory];
}

- (void)updateStyleForContentSizeCategory:(UIContentSizeCategory)category {
    CGFloat scale = [ISHMapboxDynamicFontObserver fontScaleForContentSizeCategory:category];

    for (NSString *identifier in self.baseTextSizeValues) {
        MGLStyleLayer *layer = [self.style layerWithIdentifier:identifier];

        if (![layer isKindOfClass:[MGLSymbolStyleLayer class]]) {
            continue;
        }

        MGLSymbolStyleLayer *symbolLayer = (MGLSymbolStyleLayer *)layer;

        MGLStyleValue *textValue = [self.baseTextSizeValues objectForKey:identifier];
        symbolLayer.textFontSize = [ISHMapboxDynamicFontObserver styleValue:textValue multipliedByScale:scale];

        if (!symbolLayer.iconImageName) {
            continue;
        }

        MGLStyleValue *iconScaleValue = [self.baseIconSizeValues objectForKey:identifier];
        symbolLayer.iconScale = [ISHMapboxDynamicFontObserver styleValue:iconScaleValue multipliedByScale:scale];
    }
}

#pragma mark - Style Value Scaling

+ (MGLStyleValue *)styleValue:(MGLStyleValue *)value multipliedByScale:(CGFloat)scale {
    if ([value isKindOfClass:[MGLConstantStyleValue class]]) {
        return [self styleConstantValue:(MGLConstantStyleValue *)value multipliedByScale:scale];
    }

    if ([value isKindOfClass:[MGLCameraStyleFunction class]]) {
        return [self styleCameraValue:(MGLCameraStyleFunction *)value multipliedByScale:scale];
    }

    return value;
}

+ (MGLStyleValue *)styleConstantValue:(MGLConstantStyleValue *)constantValue multipliedByScale:(CGFloat)scale {
    if (![constantValue.rawValue isKindOfClass:[NSNumber class]]) {
        return constantValue;
    }

    return [MGLStyleValue valueWithRawValue:@([(NSNumber *)constantValue.rawValue doubleValue] * scale)];
}

+ (MGLStyleValue *)styleCameraValue:(MGLCameraStyleFunction *)cameraValue multipliedByScale:(CGFloat)scale {
    __block NSMutableDictionary<id, MGLStyleValue *> *newStops = [NSMutableDictionary dictionaryWithCapacity:cameraValue.stops.count];

    [cameraValue.stops enumerateKeysAndObjectsUsingBlock:^(id key, MGLStyleValue *value, BOOL *stop) {
        newStops[key] = [self styleValue:value multipliedByScale:scale];
    }];

    MGLCameraStyleFunction *newValue = (MGLCameraStyleFunction *)[MGLStyleValue valueWithInterpolationMode:cameraValue.interpolationMode
                                                                                               cameraStops:newStops
                                                                                                   options:nil];
    newValue.interpolationBase = cameraValue.interpolationBase;
    return newValue ? : cameraValue;
}

+ (CGFloat)fontScaleForContentSizeCategory:(UIContentSizeCategory)category {
    static NSDictionary<UIContentSizeCategory, NSNumber *> *scales;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        scales = @{
                   UIContentSizeCategoryUnspecified: @1,
                   UIContentSizeCategoryExtraSmall: @0.7,
                   UIContentSizeCategorySmall: @0.8,
                   UIContentSizeCategoryMedium: @0.9,
                   UIContentSizeCategoryLarge: @1,
                   UIContentSizeCategoryExtraLarge: @1.15,
                   UIContentSizeCategoryExtraExtraLarge: @1.3,
                   UIContentSizeCategoryExtraExtraExtraLarge: @1.4,
                   UIContentSizeCategoryAccessibilityMedium: @1.7,
                   UIContentSizeCategoryAccessibilityExtraLarge: @2,
                   UIContentSizeCategoryAccessibilityExtraExtraLarge: @2.5,
                   UIContentSizeCategoryAccessibilityExtraExtraExtraLarge: @3,
                   };
    });
    NSNumber *scale = scales[category];

    if (!scale) {
        return 1;
    }

    return [scale doubleValue];
}

@end

