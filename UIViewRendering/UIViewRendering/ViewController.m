//
//  ViewController.m
//  UIViewRendering
//
//  Created by Rob Visentin on 1/8/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import OpenGLES.ES2;
@import GLKit;

#import "ViewController.h"
#import "RZViewTexture.h"
#import "RZRenderLoop.h"
#import "RZQuadMesh.h"
#import "RZTransform3D.h"
#import "RZClothEffect.h"

@interface ViewController () <GLKViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet GLKView *glView;

@property (strong, nonatomic) RZRenderLoop *renderLoop;

@property (strong, nonatomic) RZClothEffect *effect;
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
    
    RZTransform3D *transform = [RZTransform3D transform];

    transform.translation = GLKVector3Make(0.0f, 0.0f, -3.72f);
    transform.scale = GLKVector3Make(aspectRatio, 1.0f, aspectRatio);
    transform.rotation = GLKQuaternionMake(-0.133518726, 0.259643972, 0.0340433009, 0.955821096);

    self.effect.modelViewMatrix = transform.modelMatrix;
    
    self.effect.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(30.0f), aspectRatio, 0.01f, 10.0f);
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
    
    self.mesh = [RZQuadMesh quadWithSubdivisionLevel:5];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
}

- (void)createShaders
{
    self.effect = [RZClothEffect clothEffect];
    
    self.effect.anchors = GLKVector2Make(-1.0f, 1.0f);
    
    self.effect.waveCount = 8.0f;
    self.effect.waveVelocity = 0.8f;
    
    self.effect.lightPosition = GLKVector3Make(0.0f, 1.0f, 2.0f);
    self.effect.lightAttenuation = GLKVector3Make(1.0f, 0.02f, 0.017f);
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

    self.effect.waveAmplitude = 0.1f + 0.3f * self.slider.value;

    [self.effect prepareToDraw];
    glBindTexture(GL_TEXTURE_2D, self.texture.name);
    
    [self.mesh render];
    
    glBindTexture(GL_TEXTURE_2D, 0);

    const GLenum discards[]  = {GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT};
    glDiscardFramebufferEXT(GL_FRAMEBUFFER, 2, discards);
}

@end
