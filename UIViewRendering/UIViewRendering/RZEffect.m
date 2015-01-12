//
//  RZEffect.m
//
//  Created by Rob Visentin on 1/11/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import OpenGLES.EAGL;
@import OpenGLES.ES2;
#import "RZEffect.h"

GLuint RZCompileShader(const GLchar *source, GLenum type);

@interface RZEffect () {
    GLint _mvpMatrixLoc;
    GLint _mvMatrixLoc;
    GLint _normalMatrixLoc;
}

@property (nonatomic, readwrite, getter = isLinked) BOOL linked;

@property (nonatomic, strong) NSCache *uniforms;

@end

@implementation RZEffect

+ (instancetype)effectWithVertexShaderNamed:(NSString *)vshName fragmentShaderNamed:(NSString *)fshName
{
    NSString *vshPath = [[NSBundle mainBundle] pathForResource:vshName ofType:@"vsh"];
    NSString *fshPath = [[NSBundle mainBundle] pathForResource:fshName ofType:@"fsh"];
    
    NSString *vsh = [NSString stringWithContentsOfFile:vshPath encoding:NSASCIIStringEncoding error:nil];
    NSString *fsh = [NSString stringWithContentsOfFile:fshPath encoding:NSASCIIStringEncoding error:nil];
    
    RZEffect *effect = nil;

#if DEBUG
    if ( vsh == nil ) {
        NSLog(@"%@ failed to load vertex shader %@.vsh", NSStringFromClass(self), vshName);
    }
    
    if ( fsh == nil ) {
        NSLog(@"%@ failed to load fragment shader %@.fsh", NSStringFromClass(self), fshName);
    }
#endif
    
    if ( vsh != nil && fsh != nil ) {
        effect = [self effectWithVertexShader:vsh fragmentShader:fsh];
    }
    
    return effect;
}

+ (instancetype)effectWithVertexShader:(NSString *)vsh fragmentShader:(NSString *)fsh
{
    RZEffect *effect = nil;
    
    if ( [EAGLContext currentContext] != nil ) {
        effect = [[self alloc] initWithVertexShader:vsh fragmentShader:fsh];
    }
    else {
        NSLog(@"Failed to initialize %@: No active EAGLContext.", NSStringFromClass(self));
    }
    
    return effect;
}

- (BOOL)link
{
    [self.uniforms removeAllObjects];
    
    glLinkProgram(_name);
    
    GLint success;
    glGetProgramiv(_name, GL_LINK_STATUS, &success);
    
#if DEBUG
    if ( success != GL_TRUE ) {
        GLint length;
        glGetProgramiv(_name, GL_INFO_LOG_LENGTH, &length);
        
        GLchar *logText = (GLchar *)malloc(length + 1);
        logText[length] = '\0';
        glGetProgramInfoLog(_name, length, NULL, logText);
        
        fprintf(stderr, "Error linking %s: %s\n", [NSStringFromClass([self class]) UTF8String], logText);
        
        free(logText);
    }
#endif

    self.linked = (success == GL_TRUE);
    
    if ( self.isLinked && self.mvpUniform != nil ) {
        _mvpMatrixLoc = [self uniformLoc:self.mvpUniform];
    }
    
    if (self.isLinked && self.mvUniform != nil ) {
        _mvMatrixLoc = [self uniformLoc:self.mvUniform];
    }
    
    if ( self.isLinked && self.normalMatrixUniform != nil ) {
        _normalMatrixLoc = [self uniformLoc:self.normalMatrixUniform];
    }
    
    return self.isLinked;
}

- (void)use
{
    glUseProgram(_name);
}

- (void)prepareToDraw
{
    [self use];
        
    if ( _mvpMatrixLoc >= 0 )
    {
        GLKMatrix4 mvpMatrix = GLKMatrix4Multiply(_projectionMatrix, _modelViewMatrix);
        glUniformMatrix4fv(_mvpMatrixLoc, 1, GL_FALSE, mvpMatrix.m);
    }
    
    if ( _mvMatrixLoc >= 0 ) {
        glUniformMatrix4fv(_mvMatrixLoc, 1, GL_FALSE, _modelViewMatrix.m);
    }
    
    if ( _normalMatrixLoc >= 0 )
    {
        glUniformMatrix3fv(_normalMatrixLoc, 1, GL_FALSE, _normalMatrix.m);
    }
}

- (GLint)uniformLoc:(NSString *)uniformName
{
    GLuint loc;
    NSNumber *cachedLoc = [self.uniforms objectForKey:uniformName];
    
    if ( cachedLoc != nil ) {
        loc = cachedLoc.intValue;
    }
    else {
        loc = glGetUniformLocation(_name, [uniformName UTF8String]);
        
        if ( loc != -1 ) {
            [self.uniforms setObject:@(loc) forKey:uniformName];
        }
    }
    
    return loc;
}

#pragma mark - private methods

- (instancetype)initWithVertexShader:(NSString *)vsh fragmentShader:(NSString *)fsh
{
    self = [super init];
    if ( self ) {
        GLuint vs = RZCompileShader([vsh UTF8String], GL_VERTEX_SHADER);
        GLuint fs = RZCompileShader([fsh UTF8String], GL_FRAGMENT_SHADER);
        
        _name = glCreateProgram();
        
        glAttachShader(_name, vs);
        glAttachShader(_name, fs);
        
        _mvpMatrixLoc = -1;
        _mvMatrixLoc = -1;
        _normalMatrixLoc = -1;
        
        _modelViewMatrix = GLKMatrix4Identity;
        _projectionMatrix = GLKMatrix4Identity;
        
        _uniforms = [[NSCache alloc] init];
    }
    return self;
}

GLuint RZCompileShader(const GLchar *source, GLenum type)
{
    GLuint shader = glCreateShader(type);
    GLint length = (GLuint)strlen(source);
    
    glShaderSource(shader, 1, &source, &length);
    glCompileShader(shader);
    
#if DEBUG
    GLint success;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
    
    if ( success != GL_TRUE ) {
        GLint length;
        glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &length);
        
        GLchar *logText = malloc(length + 1);
        logText[length] = '\0';
        glGetShaderInfoLog(shader, length, NULL, logText);
        
        fprintf(stderr, "Error compiling shader: %s\n", logText);
        
        free(logText);
    }
#endif
    
    return shader;
}

@end
