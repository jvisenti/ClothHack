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
#import "RZModelNode.h"

static const int depth  = 100;
// 2 for 2 triangles and 3 for 3 vertexes per triangle.
#define depthSize   (depth)*(depth)*2*3

@interface ViewController () <GLKViewDelegate> {
    BHGLTextureVertex _textureVertex[depthSize];
}

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet GLKView *glView;

@property (strong, nonatomic) CADisplayLink *displayLink;
@property (assign, nonatomic) CFTimeInterval lastTimestamp;
@property (assign, nonatomic, readwrite) CFTimeInterval timeSinceLastUpdate;

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
    
    [self update];
    [self.glView display];
    
    [self setupDisplayLink];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if ( self.texture == nil ) {
        self.texture = [[RZViewTexture alloc] initWithWidth:CGRectGetWidth(self.view.bounds) height:CGRectGetHeight(self.view.bounds)];
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
    
    [self teardownDisplayLink];
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
    
    RZModelNode *model = [[RZModelNode alloc] initWithMesh:mesh material:nil];
    model.material.ambientColor = BHGLColorWhite;
    model.material.diffuseColor = BHGLColorWhite;
    model.material.specularColor = BHGLColorMake(0.6f, 0.6f, 0.6f, 1.0f);
    model.material.shininess = 10.0f;
    
    [self.rootNode addChild:model];
    
    BHGLLight *light = [[BHGLLight alloc] init];
    light.type = BHGLLightTypePoint;
    light.ambientColor = BHGLColorMake(0.8f, 0.8f, 0.8f, 1.0f);
    light.diffuseColor = BHGLColorWhite;
    light.specularColor = BHGLColorWhite;
    light.position = GLKVector3Make(0.0f, 1.0f, 2.0f);
    light.constantAttenuation = 1.0f;
    light.linearAttenuation = 0.02f;
    light.quadraticAttenuation = 0.017f;
    
    [self.scene addLight:light];
    
    self.scene.lightUniform = @"u_Lights";
    
    BHGLAnimation *rotate = [BHGLBasicAnimation rotateBy:GLKQuaternionMakeWithAngleAndAxis(M_PI, 1.0f, 0.0f, 0.0f) withDuration:2.0f];
    rotate.repeats = YES;
    
//    [model runAnimation:rotate];

    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
}

- (void)createShaders
{
    BHGLProgram *program = [[BHGLProgram alloc] initWithVertexShaderNamed:@"vertex.vsh" fragmentShaderNamed:@"pointLight.fsh"];
    
    program.mvpUniformName = kBHGLMVPUniformName;
    program.mvUniformName = kBHGLMVUniformName;
    program.normalMatrixUniformName = kBHGLNormalMatrixUniformName;
    
    [program setVertexAttribute:BHGLVertexAttribPosition forName:kBHGLPositionAttributeName];
    [program setVertexAttribute:BHGLVertexAttribTexCoord0 forName:kBHGLTexCoord0AttributeName];
    
    if ( [program link] ) {
        self.scene.program = program;
    }
}

- (void)setupDisplayLink
{
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    self.lastTimestamp = CACurrentMediaTime();
    self.timeSinceLastUpdate = 0.0f;
    
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)teardownDisplayLink
{
    [self.displayLink invalidate];
    self.displayLink = nil;
}

- (void)render:(CADisplayLink *)displayLink
{
    self.timeSinceLastUpdate = displayLink.timestamp - self.lastTimestamp;
    
    [self update];
    
    [self.glView display];
    self.lastTimestamp = displayLink.timestamp;
}

- (void)update
{
    [self.scene updateRecursive:self.timeSinceLastUpdate];
    
    [self.texture updateWithView:self.contentView];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.texture.name);

    glUniform1f([self.scene.program uniformPosition:@"u_anchor"], -1.0f);
    glUniform1f([self.scene.program uniformPosition:@"u_timeOffset"] , CACurrentMediaTime());
    glUniform1f([self.scene.program uniformPosition:@"u_velocity"] , 0.4f);
    glUniform1f([self.scene.program uniformPosition:@"u_waveNumber"] , 8.0f);
    glUniform1f([self.scene.program uniformPosition:@"u_amplitude"] , 0.1f + 0.3f * self.slider.value);

    [self.scene render];
    
    glBindTexture(GL_TEXTURE_2D, 0);

    const GLenum discards[]  = {GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT};
    glDiscardFramebufferEXT(GL_FRAMEBUFFER, 2, discards);
    
    glFlush();
}

@end
