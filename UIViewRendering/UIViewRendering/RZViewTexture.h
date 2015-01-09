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

- (instancetype)initWithWidth:(GLsizei)width height:(GLsizei)height;

- (void)updateWithView:(UIView *)view;

@end
