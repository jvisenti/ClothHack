//
//  RZQuadMesh.h
//
//  Created by Rob Visentin on 1/10/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/gltypes.h>

OBJC_EXTERN NSInteger const kRZQuadMeshMaxSubdivisions;

@interface RZQuadMesh : NSObject

+ (instancetype)quad;
+ (instancetype)quadWithSubdivisionLevel:(NSInteger)subdivisons;

- (void)render;

@end
