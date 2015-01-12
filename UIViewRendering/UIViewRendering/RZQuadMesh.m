//
//  RZQuadMesh.m
//
//  Created by Rob Visentin on 1/10/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

@import OpenGLES.EAGL;
@import OpenGLES.ES2;
#import "RZQuadMesh.h"

typedef struct _RZBufferSet {
    GLuint vbo, ibo;
} RZBufferSet;

void RZGenerateQuadMesh(GLubyte subdivisions, GLvoid **vertices, GLuint *numVerts, GLvoid **indices, GLuint *numIdxs);

@interface RZQuadMesh ()

@property (assign, nonatomic) GLuint vao;
@property (assign, nonatomic) RZBufferSet bufferSet;

@property (assign, nonatomic) GLuint vertexCount;
@property (assign, nonatomic) GLuint indexCount;

@property (assign, nonatomic) GLvoid *vertexData;
@property (assign, nonatomic) GLvoid *indexData;

@end

@implementation RZQuadMesh

#pragma mark - lifecycle

+ (instancetype)quad
{
    return [self quadWithSubdivisionLevel:0];
}

+ (instancetype)quadWithSubdivisionLevel:(GLubyte)subdivisons
{
    RZQuadMesh *mesh = nil;
    
    if ( [EAGLContext currentContext] != nil ) {
        mesh = [[self alloc] initWithSubdivisionLevel:subdivisons];
    }
    else {
        NSLog(@"Failed to initialize %@: No active EAGLContext.", NSStringFromClass(self));
    }
    
    return mesh;
}

- (void)dealloc
{
    free(_vertexData);
    free(_indexData);
    
    glDeleteVertexArraysOES(1, &_vao);
    glDeleteBuffers(2, &_bufferSet.vbo);
}

#pragma mark - public methods

- (void)render
{
    glBindVertexArrayOES(_vao);
    glBindBuffer(GL_ARRAY_BUFFER, _bufferSet.vbo);
    
    glDrawElements(GL_TRIANGLES, _indexCount, GL_UNSIGNED_SHORT, NULL);

    glBindVertexArrayOES(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

#pragma mark - private methods

- (instancetype)initWithSubdivisionLevel:(GLubyte)subdivisions
{
    self = [super init];
    if ( self ) {
        RZGenerateQuadMesh(subdivisions, &_vertexData, &_vertexCount, &_indexData, &_indexCount);

        glGenVertexArraysOES(1, &_vao);
        glGenBuffers(2, &_bufferSet.vbo);
        
        glBindVertexArrayOES(_vao);
        
        glBindBuffer(GL_ARRAY_BUFFER, _bufferSet.vbo);
        glBufferData(GL_ARRAY_BUFFER, 5 * _vertexCount * sizeof(GLfloat), _vertexData, GL_STATIC_DRAW);
        
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _bufferSet.ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, _indexCount * sizeof(GLushort), _indexData, GL_STATIC_DRAW);
        
        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (const GLvoid *)0);
        
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), (const GLvoid *)12);
        
        glBindVertexArrayOES(0);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    return self;
}

void RZGenerateQuadMesh(GLubyte subdivisions, GLvoid **vertices, GLuint *numVerts, GLvoid **indices, GLuint *numIdxs)
{
    GLuint subs = pow(2.0, subdivisions);
    GLuint pts = subs + 1;
    
    GLfloat ptStep = 2.0f / subs;
    GLfloat texStep = 1.0f / subs;
    
    *numVerts = pts * pts;
    *numIdxs = 6 * subs * subs;
    
    GLfloat *verts = (GLfloat *)malloc(5 * *numVerts * sizeof(GLfloat));
    GLushort *idxs = (GLushort *)malloc(*numIdxs * sizeof(GLushort));
    
    int v = 0;
    int i = 0;
    
    for ( int y = 0; y < pts; y++ ) {
        for ( int x = 0; x < pts; x++ ) {
            verts[v++] = -1.0f + ptStep * x;
            verts[v++] = 1.0f - ptStep * y;
            verts[v++] = 0.0f;
            verts[v++] = texStep * x;
            verts[v++] = texStep * y;
            
            if ( x < subs && y < subs ) {
                idxs[i++] = y * pts + x;
                idxs[i++] = (y + 1) * pts + x;
                idxs[i++] = y * pts + x + 1;
                idxs[i++] = y * pts + x + 1;
                idxs[i++] = (y + 1) * pts + x;
                idxs[i++] = (y + 1) * pts + x + 1;
            }
        }
    }
    
    *vertices = verts;
    *indices = idxs;
}

@end
