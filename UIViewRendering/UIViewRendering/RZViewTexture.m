//
//  RZViewTexture.m
//  UIViewRendering
//
//  Created by Rob Visentin on 1/9/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZViewTexture.h"
#import <OpenGLES/ES2/gl.h>

@interface RZViewTexture ()

@property (assign, nonatomic, readwrite) GLuint name;
@property (assign, nonatomic, readwrite) CGSize size;
@property (assign, nonatomic, readwrite) CGFloat scale;

@property (assign, nonatomic) GLsizei texWidth;
@property (assign, nonatomic) GLsizei texHeight;

@property (assign, nonatomic) CGContextRef context;

@property (strong, nonatomic) dispatch_queue_t renderQueue;
@property (strong, nonatomic) dispatch_semaphore_t renderSemaphore;

@property (assign, nonatomic, getter=isLoaded) BOOL loaded;

@end

@implementation RZViewTexture

- (instancetype)initWithSize:(CGSize)size
{
    return [self initWithSize:size scale:[UIScreen mainScreen].scale];
}

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
        
        self.renderQueue = dispatch_queue_create("com.raizlabs.draw", DISPATCH_QUEUE_SERIAL);
        self.renderSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (void)dealloc
{
    CGContextRelease(_context);
    
    GLuint n = _name;
    dispatch_async(dispatch_get_main_queue(), ^{
        glDeleteTextures(1, &n);
    });
}

- (void)updateWithView:(UIView *)view
{
    NSAssert([EAGLContext currentContext] != nil, @"%@ requires an active EAGLContext to update!", NSStringFromClass([self class]));

    NSAssert(CGSizeEqualToSize(view.bounds.size, self.size), @"%@ view must match texture size!", NSStringFromClass([self class]));
    
    if ( dispatch_semaphore_wait(self.renderSemaphore, DISPATCH_TIME_NOW ) == 0) {
        dispatch_async(self.renderQueue, ^{
            UIGraphicsPushContext(self.context);
            
            [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:NO];
            
            UIGraphicsPopContext();
            
            dispatch_semaphore_signal(self.renderSemaphore);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                void *data = CGBitmapContextGetData(self.context);
                
                if ( self.isLoaded ) {
                    glBindTexture(GL_TEXTURE_2D, _name);
                    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, _texWidth, _texHeight, GL_RGBA, GL_UNSIGNED_BYTE, data);
                }
                else {
                    [self generateObjects];
                    
                    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _texWidth, _texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
                    
                    self.loaded = YES;
                }
                
                glBindTexture(GL_TEXTURE_2D, 0);
            });
        });
    }
}

#pragma mark - private methods

- (void)generateObjects
{
    glGenTextures(1, &_name);
    glBindTexture(GL_TEXTURE_2D, _name);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
}

@end
