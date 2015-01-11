//
//  RZViewTexture.m
//
//  Created by Rob Visentin on 1/9/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import OpenGLES.ES2;
#import "RZViewTexture.h"

@interface RZViewTexture () {
    GLsizei _texWidth;
    GLsizei _texHeight;
    
    CGContextRef _context;
    void *_pixData;
    
    dispatch_queue_t _renderQueue;
    dispatch_semaphore_t _renderSemaphore;
}

@end

@implementation RZViewTexture

+ (instancetype)textureWithSize:(CGSize)size
{
    return [self textureWithSize:size scale:[UIScreen mainScreen].scale];
}

+ (instancetype)textureWithSize:(CGSize)size scale:(CGFloat)scale
{
    return [[[self class] alloc] initWithSize:size scale:scale];
}

- (void)dealloc
{
    CGContextRelease(_context);
    
    if ( _name != 0 ) {
        GLuint n = _name;
        dispatch_async(dispatch_get_main_queue(), ^{
            glDeleteTextures(1, &n);
        });
    }
}

- (void)updateWithView:(UIView *)view synchronous:(BOOL)synchronous
{
    NSAssert(CGSizeEqualToSize(view.bounds.size, _size), @"%@ view must match texture size!", NSStringFromClass([self class]));
    
    if ( _name == 0 ) {
        [self generateTextureOnMainThread];
    }
    
    if ( synchronous ) {
        [self renderView:view];
        [self updateTextureOnMainThread];
    }
    else if ( dispatch_semaphore_wait(_renderSemaphore, DISPATCH_TIME_NOW ) == 0 ) {
        dispatch_async(_renderQueue, ^{
            [self renderView:view];
            
            dispatch_semaphore_signal(_renderSemaphore);
            
            [self updateTextureOnMainThread];
        });
    }
}

#pragma mark - private methods

- (instancetype)initWithSize:(CGSize)size scale:(CGFloat)scale
{
    self = [super init];
    if ( self ) {
        _size = size;
        _scale = scale;
        
        _texWidth = size.width * scale;
        _texHeight = size.height * scale;
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        _context = CGBitmapContextCreate(NULL, _texWidth, _texHeight, 8, 4 * _texWidth, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        CGColorSpaceRelease(colorSpace);
        
        CGContextTranslateCTM(_context, 0.0f, _texHeight);
        CGContextScaleCTM(_context, scale, -scale);
        
        _pixData = CGBitmapContextGetData(_context);
        
        _renderQueue = dispatch_queue_create("com.raizlabs.view-texture-render", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(_renderQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        
        _renderSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)generateTextureOnMainThread
{
    void (^genBlock)() = ^{
        glGenTextures(1, &_name);
        glBindTexture(GL_TEXTURE_2D, _name);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _texWidth, _texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, _pixData);
        
        glBindTexture(GL_TEXTURE_2D, 0);
    };
    
    if ( [NSThread isMainThread] ) {
        genBlock();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), genBlock);
    }
}

- (void)renderView:(UIView *)view
{
    UIGraphicsPushContext(_context);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
    UIGraphicsPopContext();
}

- (void)updateTextureOnMainThread
{
    void (^updateBlock)() = ^{
        glBindTexture(GL_TEXTURE_2D, _name);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _texWidth, _texHeight, GL_RGBA, GL_UNSIGNED_BYTE, _pixData);
        
        glBindTexture(GL_TEXTURE_2D, 0);
    };
    
    if ( [NSThread isMainThread] ) {
        updateBlock();
    }
    else {
        dispatch_async(dispatch_get_main_queue(), updateBlock);
    }
}

@end
