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

@property (strong, nonatomic) RZEffectView *effectView;
@property (strong, nonatomic) RZClothEffect *effect;

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
    
    [UIView animateWithDuration:3.0 delay:0.0 options:UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse animations:^{
        [(UIView *)self.contentView.subviews[2] setTransform:CGAffineTransformMakeTranslation(200.0f, 0.0f)];
    } completion:nil];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if ( self.effectView == nil ) {
        self.effect = [RZClothEffect effect];
        
//        self.effect.lightOffset = GLKVector3Make(0.0f, 1.1f, -3.0f);
        
        self.effectView = [[RZEffectView alloc] initWithBackingView:self.contentView effect:self.effect dynamicContent:YES];
        self.effectView.backgroundColor = [UIColor blackColor];
        self.effectView.userInteractionEnabled = NO;
        
        self.effectView.effectTransform.rotation = GLKQuaternionMake(-0.133518726, 0.259643972, 0.0340433009, 0.955821096);
        
        [self.view addSubview:self.effectView];
    }
}

- (IBAction)sliderChanged:(UISlider *)slider
{
    self.effect.waveAmplitude = 0.05f + 0.2f * slider.value;
}

@end
