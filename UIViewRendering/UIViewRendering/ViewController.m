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

static const BHGLTextureVertex RZQuad[] = {
    {{-1.0f, 1.0f, 0.0f}, {0.0f, 0.0f}},
    {{-1.0f, -1.0f, 0.0f}, {0.0f, 1.0f}},
    {{1.0f, 1.0f, 0.0f}, {1.0f, 0.0f}},
    {{1.0f, -1.0f, 0.0f}, {1.0f, 1.0f}}
};

@interface ViewController () <GLKViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentView;
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
        [self.contentView.subviews[0] setAlpha:0.0f];
    } completion:nil];
    
    [UIView animateWithDuration:2.0 delay:0.0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
        [(UIView *)self.contentView.subviews[1] setTransform:CGAffineTransformMakeTranslation(200.0f, 100.0f)];
    } completion:nil];
    
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

- (void)setupGL
{
    self.glView.context = [[self class] bestContext];
    [EAGLContext setCurrentContext:self.glView.context];
    
    self.scene = [[BHGLScene alloc] init];
    
    BHGLCamera *camera = [[BHGLCamera alloc] initWithFieldOfView:GLKMathDegreesToRadians(30.0f) aspectRatio:(CGRectGetWidth(self.glView.bounds) / CGRectGetHeight(self.glView.bounds)) nearClippingPlane:0.01f farClippingPlane:10.0f];
    
    [self.scene addCamera:camera];
    
    self.rootNode = [[BHGLNode alloc] init];
    [self.scene addChild:self.rootNode];
    
    [self createShaders];
    
    BHGLVertexType vType = BHGLVertexTypeCreateWithType(BHGL_TEXTURE_VERTEX);
    BHGLMesh *mesh = [[BHGLMesh alloc] initWithVertexData:RZQuad vertexDataSize:sizeof(RZQuad) vertexType:&vType];
    mesh.primitiveMode = GL_TRIANGLE_STRIP;
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
    
    glBindTexture(GL_TEXTURE_2D, self.texture.name);
    
    [self.scene render];
    
    glBindTexture(GL_TEXTURE_2D, 0);

    const GLenum discards[]  = {GL_COLOR_ATTACHMENT0, GL_DEPTH_ATTACHMENT};
    glDiscardFramebufferEXT(GL_FRAMEBUFFER, 2, discards);
    
    glFlush();
}

#pragma mark - touch handling

- (IBAction)pan:(UIPanGestureRecognizer *)panGr
{
    CGPoint p = [panGr locationInView:self.view];
    
    if ( panGr.state == UIGestureRecognizerStateChanged ) {
        
        CGFloat dx = (p.x - self.lastPanPoint.x) / CGRectGetWidth(self.view.bounds);
        CGFloat dy = (p.y - self.lastPanPoint.y) / CGRectGetHeight(self.view.bounds);
        
        GLKQuaternion xRotation = GLKQuaternionMakeWithAngleAndAxis(M_PI * dy, 1.0f, 0.0f, 0.0f);
        GLKQuaternion yRotation = GLKQuaternionMakeWithAngleAndAxis(M_PI * dx, 0.0f, 1.0f, 0.0f);
        
        [self.rootNode runAnimation:[BHGLBasicAnimation rotateBy:GLKQuaternionMultiply(xRotation, yRotation)]];
        
    }
    
    self.lastPanPoint = p;
}

@end
