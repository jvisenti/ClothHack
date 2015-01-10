//
//  RZViewTexture.h
//  UIViewRendering
//
//  Created by Rob Visentin on 1/9/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/gltypes.h>

@interface RZViewTexture : NSObject

@property (assign, nonatomic, readonly) GLuint name;
@property (assign, nonatomic, readonly) CGSize size;
@property (assign, nonatomic, readonly) CGFloat scale;

- (instancetype)initWithSize:(CGSize)size;
- (instancetype)initWithSize:(CGSize)size scale:(CGFloat)scale;

- (void)updateWithView:(UIView *)view synchronous:(BOOL)synchronous;

@end
