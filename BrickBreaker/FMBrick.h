//
//  FMBrick.h
//  BrickBreaker
//
//  Created by Fredrick Myers on 4/30/14.
//  Copyright (c) 2014 Fredrick Myers. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

typedef enum : NSUInteger {
    Green = 1,
    Blue = 2,
    Grey = 3,
    Yellow = 4
} BrickType;

static const uint32_t kFMBrickCatagory = 0x1 << 2;

@interface FMBrick : SKSpriteNode

@property (nonatomic) BrickType type;
@property (nonatomic) BOOL indestructible;
@property (nonatomic) BOOL spawnsExtraBall;

- (instancetype)initWithType:(BrickType)type;
- (void)hit;

@end
