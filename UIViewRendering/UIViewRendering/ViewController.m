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
    model.material.texture = [[BHGLTexture alloc] initWithImageNamed:@"test" options:nil error:nil];
    
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
    
    UIGraphicsBeginImageContextWithOptions(self.contentView.bounds.size, NO, 0.0f);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    [self.contentView.layer drawInContext:ctx];
    
    __unused void *data = CGBitmapContextGetData(ctx);
    __unused UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.scene render];
}

@end
