
#import "KWShape.h"
#import "KWAnimation.h"

@interface KWShape ()

@property (nonatomic, weak) KWShape* parent;
@property (nonatomic, strong) GLKTextureInfo* texture;

@end

@implementation KWShape {
    KWVertex* vertices;
    
    KWVertex* txvertices;
    
    NSMutableArray* animations;
    
    NSMutableArray* children;
        
    GLKVector2 velocity;
    GLKVector2 acceleration;
    
    CGFloat angularVelocity;
    CGFloat angularAcceleration;
}

- (id) initWithVertices:(KWVertex*)vdata {
    if (self = [super init]) {
        vertices = vdata;
                
        self.position = GLKVector2Make(0,0);
        self.scale = GLKVector2Make(1,1);
        self.rotation = 0;
        self.color = GLKVector4Make(1,1,1,1);
        
        children = [[NSMutableArray alloc] init];
        animations = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) setTextureImage:(UIImage*)image {
    NSError* error;
    self.texture = [GLKTextureLoader textureWithCGImage:image.CGImage
                                           options:@{GLKTextureLoaderOriginBottomLeft : @YES}
                                             error:&error];
    elog(error);
    
    txvertices = [KWVertex build:^(KWVertex* vx) {
        [vx append:GLKVector2Make(1,0)];
        [vx append:GLKVector2Make(1,1)];
        [vx append:GLKVector2Make(0,1)];
        [vx append:GLKVector2Make(0,0)];
    }];    
}

- (GLKMatrix4) matrix {
    
    GLKMatrix4 matrix = GLKMatrix4MakeTranslation(self.position.x, self.position.y, 0);

    matrix = GLKMatrix4Multiply(matrix, GLKMatrix4MakeRotation(self.rotation, 0, 0, 1));
    matrix = GLKMatrix4Multiply(matrix, GLKMatrix4MakeScale(self.scale.x, self.scale.y, 1));
    
    if (self.parent) {
        matrix = GLKMatrix4Multiply(self.parent.matrix, matrix);
    }
    
    return matrix;
}

- (void) update:(NSTimeInterval)dt {
    
    angularVelocity += angularAcceleration * dt;
    self.rotation += angularVelocity * dt;
    
    GLKVector2 changeInVelocity = GLKVector2MultiplyScalar(acceleration, dt);
    velocity = GLKVector2Add(velocity, changeInVelocity);
    
    GLKVector2 distanceTraveled = GLKVector2MultiplyScalar(velocity, dt);
    self.position = GLKVector2Add(self.position, distanceTraveled);
    
    [animations enumerateObjectsUsingBlock:^(KWAnimation *animation, NSUInteger idx, BOOL *stop) {
        [animation animate:self dt:dt];
    }];
    
    [animations filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(KWAnimation *animation, NSDictionary *bindings) {
        return animation.elapsed <= animation.duration;
    }]];
}

- (void) renderInScene:(KWScene*)scene {
    GLKBaseEffect* effect = [[GLKBaseEffect alloc] init];    
    effect.useConstantColor = YES;
    effect.constantColor = self.color;
    
    GLKTextureInfo* texture = self.texture;
    
    if (texture) {
        effect.texture2d0.envMode = GLKTextureEnvModeReplace;
        effect.texture2d0.target = GLKTextureTarget2D;
        effect.texture2d0.name = texture.name;
    }
    
    effect.transform.modelviewMatrix = self.matrix;
    effect.transform.projectionMatrix = scene.projection;
    [effect prepareToDraw];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 0, vertices.data);
    
    if (texture) {
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, txvertices.data);
    }
    
    glDrawArrays(GL_TRIANGLE_FAN, 0, vertices.count);
    
    glDisableVertexAttribArray(GLKVertexAttribPosition);
    
    if (texture) {
        glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    }
    
    glDisable(GL_BLEND);
    
    [children enumerateObjectsUsingBlock:^(KWShape* shape, NSUInteger idx, BOOL *stop) {
        [shape renderInScene:scene];
    }];
}

- (void) addChild:(KWShape*)child {
    child.parent = self;
    [children addObject:child];
}

- (void) animateWithDuration:(NSTimeInterval)duration animations:(void(^)(void))animationsBlock {
    GLKVector2 currentPosition = self.position;
    GLKVector2 currentScale = self.scale;
    GLKVector4 currentColor = self.color;
    CGFloat currentRotation = self.rotation;
    
    animationsBlock();
    
    KWAnimation *animation = [[KWAnimation alloc] init];
    animation.delta = KWDeltaMake(
        GLKVector2Subtract(self.position, currentPosition),
        GLKVector2Subtract(self.scale, currentScale),
        self.rotation - currentRotation,
        GLKVector4Subtract(self.color, currentColor)
    );
    
    animation.duration = duration;
    [animations addObject:animation];
    
    self.position = currentPosition;
    self.scale = currentScale;
    self.color = currentColor;
    self.rotation = currentRotation;
}

@end
