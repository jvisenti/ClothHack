//
//  RZEffect.h
//
//  Created by Rob Visentin on 1/11/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKMath.h>

#define RZ_SHADER_SRC(src) (@#src)

@interface RZEffect : NSObject

@property (assign, nonatomic, readonly) GLuint name;
@property (nonatomic, readonly, getter = isLinked) BOOL linked;

@property (nonatomic, assign) GLKMatrix4 modelViewMatrix;
@property (nonatomic, assign) GLKMatrix4 projectionMatrix;
@property (nonatomic, assign) GLKMatrix3 normalMatrix;

@property (nonatomic, copy) NSString *mvpUniform;
@property (nonatomic, copy) NSString *mvUniform;
@property (nonatomic, copy) NSString *normalMatrixUniform;

+ (instancetype)effectWithVertexShaderNamed:(NSString *)vshName fragmentShaderNamed:(NSString *)fshName;

+ (instancetype)effectWithVertexShader:(NSString *)vsh fragmentShader:(NSString *)fsh;

- (void)createProgram;

- (BOOL)link;

- (void)use;
- (void)prepareToDraw;

- (GLint)uniformLoc:(NSString *)uniformName;

@end
