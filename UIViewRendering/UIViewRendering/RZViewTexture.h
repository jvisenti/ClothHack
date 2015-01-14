//
//  RZViewTexture.h
//
//  Created by Rob Visentin on 1/9/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RZEffects.h"

@interface RZViewTexture : NSObject <RZOpenGLObject>

@property (assign, nonatomic, readonly) CGSize size;
@property (assign, nonatomic, readonly) CGFloat scale;

+ (instancetype)textureWithSize:(CGSize)size;
+ (instancetype)textureWithSize:(CGSize)size scale:(CGFloat)scale;

- (void)updateWithView:(UIView *)view synchronous:(BOOL)synchronous;

@end
