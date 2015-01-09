//
//  RZModelNode.m
//  UIViewRendering
//
//  Created by Rob Visentin on 1/9/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import "RZModelNode.h"

@implementation RZModelNode

- (void)configureProgram:(BHGLProgram *)program
{
    [super configureProgram:program];
    
    [program setUniform:@"u_Material" withMaterial:self.material];
}

@end
