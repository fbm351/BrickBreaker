//
//  FMMyScene.m
//  BrickBreaker
//
//  Created by Fredrick Myers on 4/29/14.
//  Copyright (c) 2014 Fredrick Myers. All rights reserved.
//

#import "FMMyScene.h"
#import "FMBrick.h"
#import "FMMenu.h"

@interface FMMyScene()

@property (nonatomic) int lives;
@property (nonatomic) int currentLevel;

@end

@implementation FMMyScene
{
    SKSpriteNode *_paddle;
    CGPoint _touchLocation;
    CGFloat _ballSpeed;
    SKNode *_brickLayer;
    BOOL _ballReleased;
    BOOL _positionBall;
    NSArray *_hearts;
    SKLabelNode *_levelDisplay;
    FMMenu *_menu;
    SKAction *_ballBounceSound;
    SKAction *_paddleBounceSound;
    SKAction *_levelUpSound;
    SKAction *_loseLifeSound;
}

static const uint32_t kFMBallCatagory = 0x1 << 0;
static const uint32_t kFMPaddleCatagory = 0x1 << 1;
static const uint32_t kFMEdgeCatagory = 0x1 << 2;


static inline CGVector radiansToVector(CGFloat radians)
{
    CGVector vector;
    vector.dx = cosf(radians);
    vector.dy = sinf(radians);
    
    return vector;
}


-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size])
    {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor whiteColor];
        
        // Turn off Gravity
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
        
        // Set contact Delegate
        self.physicsWorld.contactDelegate = self;
        
        // Setup Edge
        self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:CGRectMake(0, -128, size.width, size.height + 100)];
        self.physicsBody.categoryBitMask = kFMEdgeCatagory;
        
        // Add HUD bar
        SKSpriteNode *bar = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:0.831 green:0.831 blue:0.831 alpha:1.0] size:CGSizeMake(size.width, 28)];
        bar.position = CGPointMake(0, size.height);
        bar.anchorPoint = CGPointMake(0, 1);
        [self addChild:bar];
        
        // Setup Level display
        _levelDisplay = [SKLabelNode labelNodeWithFontNamed:@"Futura"];
        _levelDisplay.text = @"LEVEL 1";
        _levelDisplay.fontColor = [SKColor grayColor];
        _levelDisplay.fontSize = 15;
        _levelDisplay.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
        _levelDisplay.verticalAlignmentMode = SKLabelVerticalAlignmentModeTop;
        _levelDisplay.position = CGPointMake(10, -10);
        [bar addChild:_levelDisplay];
        
        //Setup Sounds
        
        _ballBounceSound = [SKAction playSoundFileNamed:@"BallBounce.caf" waitForCompletion:NO];
        _paddleBounceSound = [SKAction playSoundFileNamed:@"PaddleBounce.caf" waitForCompletion:NO];
        _levelUpSound = [SKAction playSoundFileNamed:@"LevelUp.caf" waitForCompletion:NO];
        _loseLifeSound = [SKAction playSoundFileNamed:@"LoseLife.caf" waitForCompletion:NO];
        
        //Setup brick layer
        _brickLayer = [SKNode node];
        _brickLayer.position = CGPointMake(0, self.size.height - 28);
        [self addChild:_brickLayer];
        
        //Setup Hearts. 26x22
        _hearts = @[[SKSpriteNode spriteNodeWithImageNamed:@"HeartFull"],
                    [SKSpriteNode spriteNodeWithImageNamed:@"HeartFull"]];
        
        for (NSUInteger i = 0; i < _hearts.count; i++)
        {
            SKSpriteNode *heart = (SKSpriteNode *)_hearts[i];
            heart.position = CGPointMake(self.size.width - (16 + (29 * i)), self.size.height - 14);
            [self addChild:heart];
            
        }
    
        // Add Paddle
        _paddle = [SKSpriteNode spriteNodeWithImageNamed:@"Paddle"];
        _paddle.position = CGPointMake(self.size.width * 0.5, 80);
        _paddle.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:_paddle.size];
        _paddle.physicsBody.categoryBitMask = kFMPaddleCatagory;
        _paddle.physicsBody.dynamic = NO;
        [self addChild:_paddle];
        
        // Set Menu
        
        _menu = [[FMMenu alloc] init];
        _menu.position = CGPointMake(self.size.width * 0.5, self.size.height * 0.5);
        [self addChild:_menu];
        
        //Set Initial values
        _ballSpeed = 250.0;
        _ballReleased = NO;
        self.currentLevel = 1;
        self.lives = 2;
        
        [self newBall];
        [self loadLevel:self.currentLevel];
    }
    return self;
}

- (void)newBall
{
    [self enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        [node removeFromParent];
    }];
    
    // Create positioning ball.
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"BallBlue"];
    ball.position = CGPointMake(0, _paddle.size.height);
    [_paddle addChild:ball];
    _ballReleased = NO;
    _paddle.position = CGPointMake(self.size.width * 0.5, _paddle.position.y);
}

- (void)setLives:(int)lives
{
    _lives = lives;
    for (NSUInteger i = 0; i < _hearts.count; i++)
    {
        SKSpriteNode *heart = (SKSpriteNode *)_hearts[i];
        if (lives > i)
        {
            heart.texture = [SKTexture textureWithImageNamed:@"HeartFull"];
        }
        else
        {
            heart.texture = [SKTexture textureWithImageNamed:@"HeartEmpty"];
        }
    }
}

- (void)setCurrentLevel:(int)currentLevel
{
    _currentLevel = currentLevel;
    _levelDisplay.text = [NSString stringWithFormat:@"Level %i", currentLevel];
    _menu.levelNumber = currentLevel;
}

- (void)loadLevel:(int)levelNumber
{
    [_brickLayer removeAllChildren];
    NSArray *level = nil;
    switch (levelNumber)
    {
        case 1:
            level = @[@[@1, @1, @1, @1, @1, @1],
                      @[@0, @1, @1, @1, @1, @0],
                      @[@0, @0, @0, @0, @0, @0],
                      @[@0, @0, @0, @0, @0, @0],
                      @[@0, @2, @2, @2, @2, @0]];
            break;
            
        case 2:
            level = @[@[@4, @1, @2, @2, @1, @4],
                      @[@2, @2, @0, @0, @2, @2],
                      @[@2, @0, @0, @0, @0, @2],
                      @[@1, @0, @1, @1, @0, @1],
                      @[@1, @1, @3, @3, @1, @1]];
            break;
            
        case 3:
            level = @[@[@1, @0, @1, @1, @0, @1],
                      @[@1, @0, @1, @1, @0, @1],
                      @[@0, @0, @3, @3, @0, @0],
                      @[@0, @0, @1, @1, @0, @0],
                      @[@3, @2, @1, @1, @2, @3]];
            break;
            
        default:
            break;
    }
    int row = 0;
    int col = 0;
    
    for (NSArray *rowBricks in level)
    {
        col = 0;
        for (NSNumber *brickType in rowBricks)
        {
            if ([brickType intValue] > 0)
            {
                FMBrick *brick = [[FMBrick alloc] initWithType:(BrickType)[brickType intValue]];
                if (brick)
                {
                    brick.position = CGPointMake(2 + (brick.size.width * 0.5) + ((brick.size.width + 3) * col),
                                                 -(2 + (brick.size.height * 0.5) + ((brick.size.height +3) * row)));
                    [_brickLayer addChild:brick];
                }
            }
            col ++;
        }
        row ++;
    }
}

- (SKSpriteNode *)createBallWithLocation:(CGPoint)position andVelocity:(CGVector)velocity
{
    SKSpriteNode *ball = [SKSpriteNode spriteNodeWithImageNamed:@"BallBlue"];
    ball.name = @"ball";
    ball.position = position;
    ball.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:ball.size.width * 0.5];
    ball.physicsBody.friction = 0;
    ball.physicsBody.linearDamping = 0;
    ball.physicsBody.restitution = 1.0;
    ball.physicsBody.velocity = velocity;
    ball.physicsBody.categoryBitMask = kFMBallCatagory;
    ball.physicsBody.contactTestBitMask = kFMPaddleCatagory | kFMBrickCatagory | kFMEdgeCatagory;
    ball.physicsBody.collisionBitMask = kFMPaddleCatagory | kFMBrickCatagory | kFMEdgeCatagory;
    [self addChild:ball];
    return ball;
}

- (void)spawnExtraBall:(CGPoint)position
{
    CGVector direction;
    if (arc4random_uniform(2) == 0)
    {
        direction = radiansToVector(M_PI_4);
    }
    else
    {
        direction = radiansToVector(M_PI * 0.75);
    }
    
    [self createBallWithLocation:position andVelocity:CGVectorMake(direction.dx * _ballSpeed, direction.dy * _ballSpeed)];
}

- (void)didBeginContact:(SKPhysicsContact *)contact
{
    SKPhysicsBody *firstBody;
    SKPhysicsBody *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
    {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    }
    else
    {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if (firstBody.categoryBitMask == kFMBallCatagory && secondBody.categoryBitMask == kFMPaddleCatagory)
    {
        if (firstBody.node.position.y > secondBody.node.position.y)
        {
            //Get Contact point in paddle cords.
            CGPoint pointInPaddle = [secondBody.node convertPoint:contact.contactPoint fromNode:self];
            //Get contact as % of paddle width
            CGFloat x = (pointInPaddle.x + secondBody.node.frame.size.width * 0.5) / secondBody.node.frame.size.width;
            //Cap Percent and flip it.
            CGFloat multiplier = 1.0 - fmaxf(fminf(x, 1.0),0.0);
            //Calculate angle based on ball position in paddle.
            CGFloat angle = (M_PI_2 * multiplier) + M_PI_4;
            //Convert angle to vector
            CGVector direction = radiansToVector(angle);
            firstBody.velocity = CGVectorMake(direction.dx * _ballSpeed, direction.dy *_ballSpeed);
        }
        [self runAction:_paddleBounceSound];
    }
    
    if (firstBody.categoryBitMask == kFMBallCatagory && secondBody.categoryBitMask == kFMBrickCatagory)
    {
        if ([secondBody.node respondsToSelector:@selector(hit)])
        {
            [secondBody.node performSelector:@selector(hit)];
            if (((FMBrick *)secondBody.node).spawnsExtraBall)
            {
                [self spawnExtraBall:[_brickLayer convertPoint:secondBody.node.position toNode:self]];
            }
        }
        [self runAction:_ballBounceSound];
    }
    
    if (firstBody.categoryBitMask == kFMBallCatagory && secondBody.categoryBitMask == kFMEdgeCatagory)
    {
        [self runAction:_ballBounceSound];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    /* Called when a touch begins */
    for (UITouch *touch in touches)
    {
        if (_menu.hidden)
        {
            if (!_ballReleased)
            {
                _positionBall = YES;
            }
            _touchLocation = [touch locationInNode:self];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_menu.hidden)
    {
        for (UITouch *touch in touches)
        {
            //Calculate how far touch has moved
            CGFloat xMovement = [touch locationInNode:self].x - _touchLocation.x;
            
            //Move Paddle distance of moved touch
            _paddle.position = CGPointMake(_paddle.position.x + xMovement, _paddle.position.y);
            
            CGFloat paddleMinX = -_paddle.size.width * 0.25;
            CGFloat paddleMaxX = self.size.width + (_paddle.size.width * 0.25);
            
            if (_positionBall)
            {
                paddleMinX = _paddle.size.width * 0.5;
                paddleMaxX = self.size.width - (_paddle.size.width * 0.5);
            }
            
            //Keep Paddle in Screen
            if (_paddle.position.x < paddleMinX)
            {
                _paddle.position = CGPointMake(paddleMinX, _paddle.position.y);
            }
            
            if (_paddle.position.x > paddleMaxX)
            {
                _paddle.position = CGPointMake(paddleMaxX, _paddle.position.y);
            }
            
            _touchLocation = [touch locationInNode:self];
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_menu.hidden)
    {
        if (_positionBall)
        {
            _ballReleased = YES;
            _positionBall = NO;
            [_paddle removeAllChildren];
            [self createBallWithLocation:CGPointMake(_paddle.position.x, _paddle.position.y + _paddle.size.height) andVelocity:CGVectorMake(0, _ballSpeed)];
        }
    }
    else
    {
        for (UITouch *touch in touches)
        {
            if ([[_menu nodeAtPoint:[touch locationInNode:_menu]].name isEqualToString:@"Play Button"])
            {
                [_menu hide];
            }
        }
    }
    
}

- (void)didSimulatePhysics
{
    [self enumerateChildNodesWithName:@"ball" usingBlock:^(SKNode *node, BOOL *stop) {
        if (node.frame.origin.y + node.frame.size.height < 0)
        {
            //Lost ball
            [node removeFromParent];
        }
    }];
}

-(void)update:(CFTimeInterval)currentTime
{
    /* Called before each frame is rendered */
    if ([self isLevelComplete])
    {
        self.currentLevel ++;
        if (self.currentLevel > 3)
        {
            self.currentLevel = 1;
            self.lives = 2;
        }
        [self loadLevel:self.currentLevel];
        [self newBall];
        [_menu show];
        [self runAction:_levelUpSound];
    }
    else if (![self childNodeWithName:@"ball"] && !_positionBall && _ballReleased)
    {
        //Lost Ball
        self.lives --;
        
        if (self.lives < 0)
        {
            self.lives = 2;
            self.currentLevel = 1;
            [self loadLevel:self.currentLevel];
            [_menu show];
        }
        [self newBall];
        [self runAction:_loseLifeSound];
        
    }
}

- (BOOL)isLevelComplete
{
    for (SKNode *node in _brickLayer.children)
    {
        if ([node isKindOfClass:[FMBrick class]])
        {
            if (!((FMBrick *)node).indestructible)
            {
                return NO;
            }
        }
    }
    //Can't find any non-indestructible bricks
    return YES;
}

@end
