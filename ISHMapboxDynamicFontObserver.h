//
//  ISHMapboxDynamicFontObserver.h
//  MapboxDynamicFontStyle
//
//  Created by Felix Lamouroux on 18.08.17.
//  Copyright © 2017 iosphere GmbH. All rights reserved.
//

@import Mapbox;

NS_ASSUME_NONNULL_BEGIN

/**
 *  `ISHMapboxDynamicFontObserver` applies the user's preferred content size setting to a Mapbox style.
 *
 *  The provided style is assumed to be designed for the content category UIContentSizeCategoryLarge.
 *  All symbol layers' text sizes are then scaled according to the user's preferred content size setting.
 *  For layers that contain a text size attribute and an icon image, the icon image is also scaled accordingly.
 *
 *  The observer listens to changes in the user's preferred content size setting and automatically applies the setting
 *  on initialization, when the style changes or when the setting changes.
 *
 *  It currently supports style values of the following types:
 *
 *      - MGLCameraStyleFunction
 *      - MGLConstantStyleValue
 *
 *  @note When scaling, style values will be copied/re-created internally. For values of type MGLCameraStyleFunction,
 *  options are currently not copied and thus will be ignored.
 *
 */
@interface ISHMapboxDynamicFontObserver : NSObject
- (instancetype)initWithStyle:(MGLStyle *)style;
@property (nonatomic, nullable) MGLStyle *style;
@end

NS_ASSUME_NONNULL_END
