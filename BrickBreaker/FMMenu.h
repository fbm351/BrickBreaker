//
//  FMMenu.h
//  BrickBreaker
//
//  Created by Fredrick Myers on 5/5/14.
//  Copyright (c) 2014 Fredrick Myers. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface FMMenu : SKNode

@property (nonatomic) int levelNumber;

- (void)hide;
- (void)show;

@end
