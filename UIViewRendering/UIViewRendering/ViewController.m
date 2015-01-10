//
//  ViewController.m
//  UIViewRendering
//
//  Created by Rob Visentin on 1/8/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import GLKit;

#import "ViewController.h"
#import "BHGL.h"
#import "RZViewTexture.h"
#import "RZRenderLoop.h"

static const int depth  = 40;
// 2 for 2 triangles and 3 for 3 vertexes per triangle.
#define depthSize   (depth)*(depth)*2*3

@interface ViewController () <GLKViewDelegate> {
    BHGLTextureVertex _textureVertex[depthSize];
}

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet GLKView *glView;

@property (strong, nonatomic) RZRenderLoop *renderLoop;

@property (strong, nonatomic) BHGLScene *scene;
@property (strong, nonatomic) BHGLNode *rootNode;
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
    
    [self setupTextureVertex];

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
    
    self.scene.activeCamera.aspectRatio = aspectRatio;
    
    // TODO: correct position calculation here
    self.rootNode.position = GLKVector3Make(0.0f, 0.0f, -3.72f);
    self.rootNode.scale = GLKVector3Make(aspectRatio, 1.0f, aspectRatio);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.renderLoop = nil;
}

- (void)setupTextureVertex {
    float glIncrementer = 2.0/depth;
    float imgIncrmementer = 1.0f/depth;
    int counter = 0;
    for (int y = 0; y < depth; y++) {
        for (int x = 0; x < depth; x++) {
            BHGLTextureVertex topLeftVertex = {{ -1.0f + glIncrementer * x, 1.0f - glIncrementer * y, 0.0f}, { imgIncrmementer * x, imgIncrmementer * y }};
            BHGLTextureVertex bottomLeftVertex = {{ -1.0f + glIncrementer * x, 1.0f - glIncrementer * (y+1), 0.0f}, { imgIncrmementer * x, imgIncrmementer * (y+1) }};
            BHGLTextureVertex topRightVertex = {{ -1.0f + glIncrementer * (x+1), 1.0f - glIncrementer * y, 0.0f}, { imgIncrmementer * (x+1), imgIncrmementer * y }};
            BHGLTextureVertex bottomRightVertex = {{ -1.0f + glIncrementer * (x+1), 1.0f - glIncrementer * (y+1), 0.0f}, { imgIncrmementer * (x+1), imgIncrmementer * (y+1) }};
            _textureVertex[counter++] = topLeftVertex;
            _textureVertex[counter++] = bottomLeftVertex;
            _textureVertex[counter++] = topRightVertex;

            _textureVertex[counter++] = bottomLeftVertex;
            _textureVertex[counter++] = topRightVertex;
            _textureVertex[counter++] = bottomRightVertex;
        }
    }
}

- (void)setupGL
{
    self.glView.context = [[self class] bestContext];
    [EAGLContext setCurrentContext:self.glView.context];
    
    self.scene = [[BHGLScene alloc] init];
    
    BHGLCamera *camera = [[BHGLCamera alloc] initWithFieldOfView:GLKMathDegreesToRadians(30.0f) aspectRatio:(CGRectGetWidth(self.glView.bounds) / CGRectGetHeight(self.glView.bounds)) nearClippingPlane:0.01f farClippingPlane:10.0f];
    
    [self.scene addCamera:camera];
    
    self.rootNode = [[BHGLNode alloc] init];
    [self.scene addChild:self.rootNode];
    
    self.rootNode.rotation = GLKQuaternionMake(-0.133518726, 0.259643972, 0.0340433009, 0.955821096);
    [self createShaders];
    
    BHGLVertexType vType = BHGLVertexTypeCreateWithType(BHGL_TEXTURE_VERTEX);
    BHGLMesh *mesh = [[BHGLMesh alloc] initWithVertexData:_textureVertex vertexDataSize:sizeof(_textureVertex) vertexType:&vType];
//    mesh.primitiveMode = GL_TRIANGLES;
    mesh.cullFaces = GL_NONE;
    BHGLVertexTypeFree(vType);
    
    BHGLModelNode *model = [[BHGLModelNode alloc] initWithMesh:mesh material:nil];
    
    [self.rootNode addChild:model];
    
    BHGLAnimation *rotate = [BHGLBasicAnimation rotateBy:GLKQuaternionMakeWithAngleAndAxis(M_PI, 1.0f, 0.0f, 0.0f) withDuration:2.0f];
    rotate.repeats = YES;
    
//    [model runAnimation:rotate];

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
}

- (void)createShaders
{
    BHGLProgram *program = [[BHGLProgram alloc] initWithVertexShaderNamed:@"vertex.vsh" fragmentShaderNamed:@"fragment.fsh"];
    
    program.mvpUniformName = kBHGLMVPUniformName;
    program.mvUniformName = kBHGLMVUniformName;
    program.normalMatrixUniformName = kBHGLNormalMatrixUniformName;
    
    [program setVertexAttribute:BHGLVertexAttribPosition forName:kBHGLPositionAttributeName];
    [program setVertexAttribute:BHGLVertexAttribTexCoord0 forName:kBHGLTexCoord0AttributeName];
    
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
        
        self.scene.program = program;
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
    [self.scene updateRecursive:dt];
    
    [self.texture updateWithView:self.contentView synchronous:NO];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glBindTexture(GL_TEXTURE_2D, self.texture.name);

    glUniform1f([self.scene.program uniformPosition:@"u_timeOffset"] , CACurrentMediaTime());
    glUniform1f([self.scene.program uniformPosition:@"u_amplitude"] , 0.1f + 0.3f * self.slider.value);
    
    [self.scene render];
    
    glBindTexture(GL_TEXTURE_2D, 0);

    const GLenum discards[]  = {GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT};
    glDiscardFramebufferEXT(GL_FRAMEBUFFER, 2, discards);
    
    glFlush();
}

- (IBAction)switchChanged:(UISwitch *)sender
{
    glUniform1i([self.scene.program uniformPosition:@"u_Emboss"], !sender.isOn);
}

@end
