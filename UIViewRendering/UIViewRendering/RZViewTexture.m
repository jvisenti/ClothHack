//
//  RZViewTexture.m
//  UIViewRendering
//
//  Created by Rob Visentin on 1/9/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZViewTexture.h"
#import <OpenGLES/ES3/gl.h>

@interface RZViewTexture ()

@property (assign, nonatomic, readwrite) GLuint name;
@property (assign, nonatomic, readwrite) CGSize size;

@property (assign, nonatomic) void *data;
@property (assign, nonatomic) GLuint pixBuffer;

@property (assign, nonatomic, getter=isLoaded) BOOL loaded;

@end

@implementation RZViewTexture

- (instancetype)initWithWidth:(GLsizei)width height:(GLsizei)height
{
    self = [super init];
    if ( self ) {
        _size = CGSizeMake(width, height);
        _data = calloc(8 * [UIScreen mainScreen].scale * width * height, 1);
    }
    return self;
}

- (void)dealloc
{
    free(self.data);
    
    GLuint n = _name;
    GLuint b = _pixBuffer;
    dispatch_async(dispatch_get_main_queue(), ^{
        glDeleteTextures(1, &n);
        glDeleteBuffers(1, &b);
    });
}

- (void)updateWithView:(UIView *)view
{
    NSAssert([EAGLContext currentContext] != nil, @"%@ requires an active EAGLContext to update!", NSStringFromClass([self class]));

    NSAssert(CGSizeEqualToSize(view.bounds.size, self.size), @"%@ view must match texture size!", NSStringFromClass([self class]));
    
    CGFloat scale = [UIScreen mainScreen].scale;
    GLsizei width = _size.width * scale;
    GLsizei height = _size.height * scale;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx =  CGBitmapContextCreate(self.data, width, height, 8, 4 * width, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    
    CGContextTranslateCTM(ctx, 0.0f, height);
    CGContextScaleCTM(ctx, scale, -scale);
    
    UIGraphicsPushContext(ctx);
        
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    
    UIGraphicsPopContext();
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(ctx);
    
    if ( self.isLoaded ) {
        glBindBuffer(GL_PIXEL_UNPACK_BUFFER, _pixBuffer);
        glBindTexture(GL_TEXTURE_2D, _name);
        
        glBufferSubData(GL_PIXEL_UNPACK_BUFFER, 0, 4 * width * height, self.data);
        
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    }
    else {
        [self generateObjects];
        
        glBufferData(GL_PIXEL_UNPACK_BUFFER, 4 * width * height, self.data, GL_DYNAMIC_DRAW);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
        
        self.loaded = YES;
    }
    
    glBindTexture(GL_TEXTURE_2D, 0);
}

#pragma mark - private interface

- (void)generateObjects
{
    glGenBuffers(1, &_pixBuffer);
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, _pixBuffer);
    
    glGenTextures(1, &_name);
    glBindTexture(GL_TEXTURE_2D, _name);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
}

@end
