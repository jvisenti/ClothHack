//
//  RZOpenGLObject.h
//
//  Created by Rob Visentin on 1/14/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol RZOpenGLObject <NSObject>

- (void)setupGL;
- (void)bindGL;
- (void)teardownGL;

@end
