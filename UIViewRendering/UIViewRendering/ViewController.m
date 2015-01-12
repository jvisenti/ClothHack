//
//  ViewController.m
//  UIViewRendering
//
//  Created by Rob Visentin on 1/8/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import OpenGLES.ES2;

#import "ViewController.h"

#import "RZEffectView.h"
#import "RZClothEffect.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UISlider *slider;

@property (strong, nonatomic) RZEffectView *effectView;

@end

@implementation ViewController

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
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if ( self.effectView == nil ) {
        RZClothEffect *effect = [RZClothEffect clothEffect];
        effect.lightPosition = GLKVector3Make(0.0f, 1.0f, 2.0f);
        
        self.effectView = [[RZEffectView alloc] initWithBackingView:self.contentView effect:effect dynamicContent:YES];
        self.effectView.backgroundColor = [UIColor blackColor];
        self.effectView.userInteractionEnabled = NO;
        
        CGFloat aspectRatio = (self.view.bounds.size.width / self.view.bounds.size.height);
        
        self.effectView.effectTransform.translation = GLKVector3Make(0.0f, 0.0f, -3.72f);
        self.effectView.effectTransform.scale = GLKVector3Make(aspectRatio, 1.0f, aspectRatio);
        self.effectView.effectTransform.rotation = GLKQuaternionMake(-0.133518726, 0.259643972, 0.0340433009, 0.955821096);
        
        RZCamera *cam = [RZCamera cameraWithFieldOfView:GLKMathDegreesToRadians(30.0f) aspectRatio:aspectRatio nearClipping:0.01f farClipping:10.0f];
        
        self.effectView.effectCamera = cam;
    
        [self.view addSubview:self.effectView];
    }
}

@end
