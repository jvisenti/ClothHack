//
//  ViewController.m
//  UIViewRendering
//
//  Created by Rob Visentin on 1/8/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import GLKit;

#import "ViewController.h"
#import "BHGLMesh.h"
#import "BHGLCUtils.h"
#import "RZViewTexture.h"
#import "RZRenderLoop.h"
#import "RZQuadMesh.h"

@interface ViewController () <GLKViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet GLKView *glView;

@property (strong, nonatomic) RZRenderLoop *renderLoop;

@property (strong, nonatomic) BHGLProgram *program;
@property (strong, nonatomic) RZQuadMesh *mesh;
@property (strong, nonatomic) RZViewTexture *texture;

@property (assign, nonatomic) CGPoint lastPanPoint;


@end

@implementation ViewController

+ (EAGLContext *)bestContext
{
    EAGLContext *context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    
    if (!context)
    {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    return context;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
        [self.contentView.subviews[1] setAlpha:0.0f];
    } completion:nil];
    
    [UIView animateWithDuration:3.0 delay:0.0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionAllowUserInteraction animations:^{
        [(UIView *)self.contentView.subviews[2] setTransform:CGAffineTransformMakeTranslation(200.0f, 0.0f)];
    } completion:nil];
    
    [self setupGL];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupRenderLoop];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if ( self.texture == nil ) {
        self.texture = [[RZViewTexture alloc] initWithSize:self.contentView.bounds.size];
    }
    
    CGFloat aspectRatio = (self.view.bounds.size.width / self.view.bounds.size.height);
    
    self.program.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(30.0f), aspectRatio, 0.01f, 10.0f);

    GLKMatrix4 scale = GLKMatrix4MakeScale(aspectRatio, 1.0f, aspectRatio);
    GLKMatrix4 rotation = GLKMatrix4MakeWithQuaternion(GLKQuaternionMake(-0.133518726, 0.259643972, 0.0340433009, 0.955821096));
    
    GLKMatrix4 mat = GLKMatrix4Multiply(rotation, scale);
    
    mat.m[14] = -3.72f;
    
    self.program.modelViewMatrix = mat;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.renderLoop = nil;
}

- (void)setupGL
{
    self.glView.context = [[self class] bestContext];
    [EAGLContext setCurrentContext:self.glView.context];
    
    [self createShaders];
    
    self.mesh = [RZQuadMesh quadWithSubdivisionLevel:6];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
}

- (void)createShaders
{
    BHGLProgram *program = [[BHGLProgram alloc] initWithVertexShaderNamed:@"vertex.vsh" fragmentShaderNamed:@"fragment.fsh"];
    
    program.mvpUniformName = kBHGLMVPUniformName;
    program.mvUniformName = kBHGLMVUniformName;
    
    [program setVertexAttribute:0 forName:kBHGLPositionAttributeName];
    [program setVertexAttribute:1 forName:kBHGLTexCoord0AttributeName];
    
    if ( [program link] ) {
        
        [program use];
        glUniform1f([program uniformPosition:@"u_anchor"], -1.0f);
        glUniform1f([program uniformPosition:@"u_velocity"] , 0.8f);
        glUniform1f([program uniformPosition:@"u_waveNumber"] , 8.0f);
        
        glUniform3f([program uniformPosition:@"u_LightPosition"], 0.0f, 1.0f, 2.0f);
        glUniform3f([program uniformPosition:@"u_Ambient"], 1.0f, 1.0f, 1.0f);
        glUniform3f([program uniformPosition:@"u_Diffuse"], 1.0f, 1.0f, 1.0f);
        glUniform3f([program uniformPosition:@"u_Specular"], 0.6f, 0.6f, 0.6f);
        glUniform3f([program uniformPosition:@"u_Attenuation"], 1.0f, 0.02f, 0.017f);
        
        self.program = program;
    }
}

- (void)setupRenderLoop
{
    self.renderLoop = [RZRenderLoop renderLoop];
    
    [self.renderLoop setUpdateTarget:self action:@selector(update:)];
    [self.renderLoop setRenderTarget:self.glView action:@selector(display)];
    
    [self.renderLoop run];
}

- (void)update:(CFTimeInterval)dt
{
    [self.texture updateWithView:self.contentView synchronous:NO];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glBindTexture(GL_TEXTURE_2D, self.texture.name);

    glUniform1f([self.program uniformPosition:@"u_timeOffset"] , CACurrentMediaTime());
    glUniform1f([self.program uniformPosition:@"u_amplitude"] , 0.1f + 0.3f * self.slider.value);
    
    [self.program prepareToDraw];
    [self.mesh render];
    
    glBindTexture(GL_TEXTURE_2D, 0);

    const GLenum discards[]  = {GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT};
    glDiscardFramebufferEXT(GL_FRAMEBUFFER, 2, discards);
}

- (IBAction)switchChanged:(UISwitch *)sender
{
    glUniform1i([self.program uniformPosition:@"u_Emboss"], !sender.isOn);
}

@end
