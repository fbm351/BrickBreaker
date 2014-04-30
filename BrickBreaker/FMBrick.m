//
//  FMBrick.m
//  BrickBreaker
//
//  Created by Fredrick Myers on 4/30/14.
//  Copyright (c) 2014 Fredrick Myers. All rights reserved.
//

#import "FMBrick.h"

@implementation FMBrick

- (instancetype)initWithType:(BrickType)type
{
    switch (type)
    {
        case Green:
            self = [super initWithImageNamed:@"BrickGreen"];
            break;
            
        case Blue:
            self = [super initWithImageNamed:@"BrickBlue"];
            break;
            
        case Grey:
            self = [super initWithImageNamed:@"BrickGrey"];
            break;
            
        default:
            self = nil;
            break;
    }
    if (self)
    {
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:self.size];
        self.physicsBody.categoryBitMask = kFMBrickCatagory;
        self.physicsBody.dynamic = NO;
        self.type = type;
        self.indestructible = (type == Grey);
    }
    return self;
}

- (void)hit
{
    switch (self.type) {
        case Green:
            [self runAction:[SKAction removeFromParent]];
            [self createExplosion];
            break;
            
        case Blue:
            self.texture = [SKTexture textureWithImageNamed:@"BrickGreen"];
            self.type = Green;
            break;
            
        default:
            //Grey Bricks do nothing.
            break;
    }
}

- (void)createExplosion
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"BrickExplosion" ofType:@"sks"];
    SKEmitterNode *explosion = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    explosion.position = self.position;
    [self.parent addChild:explosion];
    
    SKAction *removeExplosion = [SKAction sequence:@[[SKAction waitForDuration:explosion.particleLifetime + explosion.particleLifetimeRange], [SKAction removeFromParent]]];
    [explosion runAction:removeExplosion];
}

@end
