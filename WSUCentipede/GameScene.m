//
//  GameScene.m
//  WSUCentipede
//
//  Created by Erik Buck on 6/13/16.
//  Copyright (c) 2016 WSU. All rights reserved.
//

#import "GameScene.h"
#import "WSUBoard.h"

@interface GameScene ()

@property (nonatomic, readwrite) WSUBoard *board; //< The board containing game objects
@property (nonatomic, readwrite) SKLabelNode *scoreLabel; //< the label to display current score
@property (nonatomic, readwrite) CFTimeInterval lastScoreUpdateTime; //< last time when score was displayed
@property (nonatomic, readwrite) SKNode *livesRemainingGroup;
@property (nonatomic, readwrite) SKNode *gameOverDisplayNode; //< the label to display "Game Over"

@end


@implementation GameScene

//////////////////////////////////////////////////////////////////////
/// Call this method to tell the board where to move the shooter.
- (void)moveShooterToPoint:(CGPoint)aPoint
{
    CGPoint location = [self convertPoint:(aPoint) toNode:self.board];
    [self.board moveShooterToPoint:location];
}

//////////////////////////////////////////////////////////////////////
/// This method is called by SpiteKit. It is implemented to call
/// -moveShooterToPoint: passing the event locations as teh point.
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(![self isGameOver])
    {
        for (UITouch *touch in touches)
        {
            [self moveShooterToPoint:[touch locationInNode:self]];
        }
    }
    else
    {
        [self startGame];
    }
}

//////////////////////////////////////////////////////////////////////
/// This method is called by SpiteKit. It is implemented to call
/// -moveShooterToPoint: passing the event locations as teh point.
- (void)touchesMoved:(NSSet<UITouch *> *)touches
    withEvent:(nullable UIEvent *)event;
{
    for (UITouch *touch in touches)
    {
        [self moveShooterToPoint:[touch locationInNode:self]];
    }
}

//////////////////////////////////////////////////////////////////////
/// This method is called by SpiteKit. It is implemented to update
/// display of the score.
-(void)update:(CFTimeInterval)currentTime
{
    [self.board update:currentTime];
    
    if((currentTime - self.lastScoreUpdateTime) > 0.1)
    {   // Limit score updates to every 1/10th second (no reason to
        // do it 1/60th second)
        self.scoreLabel.text = [NSString stringWithFormat:@"%05ld",
           (long)[self.board score]];
        self.lastScoreUpdateTime = currentTime;
        
        [self updateLivesRemainingDisplay];
    }
}

//////////////////////////////////////////////////////////////////////
///
- (void)updateLivesRemainingDisplay;
{
   if(nil == self.livesRemainingGroup)
   {
       self.livesRemainingGroup = [SKNode node];
       [self addChild:self.livesRemainingGroup];
   }
   [self.livesRemainingGroup removeAllChildren];
   
   for(NSInteger i = self.board.livesRemaining - 2; i >= 0; --i)
   {
      SKSpriteNode *symbol = [[self.board class] makeShooter];
      symbol.zPosition = 10.0f; // Make it in front of everything
      symbol.xScale = self.board.xScale;
      symbol.yScale = self.board.yScale;
      symbol.position = CGPointMake(0.5f * symbol.frame.size.width +
          i * symbol.frame.size.width,
          0.5f * symbol.frame.size.height +
          self.frame.size.height - symbol.frame.size.height);
      [self.livesRemainingGroup addChild:symbol];
   }
   
   if([self isGameOver] && nil == self.gameOverDisplayNode.parent)
   {
       [self addChild:self.gameOverDisplayNode];
   }
}

//////////////////////////////////////////////////////////////////////
/// This method sets up the score display label and adds the label as
/// a child of the scene.
- (void)setupScoreLabel;
{
    self.scoreLabel = [SKLabelNode labelNodeWithText:[NSString stringWithFormat:@"%05d", 0]];
    self.scoreLabel.fontName = @"Courier-Bold";
    self.scoreLabel.fontColor = [UIColor whiteColor];
    self.scoreLabel.fontSize = 16.0f;
    self.scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    self.scoreLabel.position = CGPointMake(
        self.frame.size.width - self.scoreLabel.frame.size.width * 0.15f,
        self.frame.size.height - self.scoreLabel.frame.size.height);
    [self addChild:self.scoreLabel];
}


//////////////////////////////////////////////////////////////////////
/// This method sets up the score display label and adds the label as
/// a child of the scene.
- (void)setupGameOverLabel;
{
    self.gameOverDisplayNode = [SKNode node];
    [self addChild:self.gameOverDisplayNode];
    
    SKLabelNode *label = [SKLabelNode labelNodeWithText:@"GAME OVER"];
    label.fontName = @"Courier-Bold";
    label.fontColor = [UIColor whiteColor];
    label.fontSize = 32.0f;
    label.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    CGPoint labelPosition = CGPointMake(self.frame.size.width * 0.45f,
        self.frame.size.height * 0.65f);
    label.position = labelPosition;
    label.zPosition = 10.0f; // In front of most other nodes
    [self.gameOverDisplayNode addChild:label];
    
    SKLabelNode *shadowLabel = [label copy];
    shadowLabel.fontColor = [UIColor blackColor];
    shadowLabel.zPosition = 9.0f;
    labelPosition.x += 1.0f;
    labelPosition.y -= 1.0f;
    shadowLabel.position = labelPosition;
    [self.gameOverDisplayNode addChild:shadowLabel];

    SKLabelNode *extraLabel = [SKLabelNode labelNodeWithText:@"Touch To Start"];
    extraLabel.fontName = @"Courier-Bold";
    extraLabel.fontColor = [UIColor whiteColor];
    extraLabel.fontSize = 18.0f;
    extraLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeCenter;
    CGPoint extraLabelPosition = CGPointMake(self.frame.size.width * 0.45f,
        label.frame.origin.y - extraLabel.frame.size.height * 1.1f);
    extraLabel.position = extraLabelPosition;
    extraLabel.zPosition = 10.0f; // In front of most other nodes
    [self.gameOverDisplayNode addChild:extraLabel];

    SKLabelNode *extraLabelShadow = [extraLabel copy];
    extraLabelShadow.fontColor = [UIColor blackColor];
    extraLabelShadow.zPosition = 9.0f;
    extraLabelPosition.x += 1.0f;
    extraLabelPosition.y -= 1.0f;
    extraLabelShadow.position = extraLabelPosition;
    [self.gameOverDisplayNode addChild:extraLabelShadow];
}

//////////////////////////////////////////////////////////////////////
//
- (void)startGame
{
    [self.gameOverDisplayNode removeFromParent];
    [self.board start];
    [self updateLivesRemainingDisplay];
}

//////////////////////////////////////////////////////////////////////
//
- (BOOL)isGameOver
{
    return 0 >= self.board.livesRemaining;
}

//////////////////////////////////////////////////////////////////////
/// This method performs one time setup at the start of a game. A
/// output interface for displaying a score is created, a board is
/// created and scaled to fit available space in the scene and added
/// as a child of the scene, and finally the board's -start method is
/// called.
-(void)didMoveToView:(SKView *)view
{
    // Set a reasonable arbitrary background color
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
    [self setupScoreLabel];
    [self setupGameOverLabel];
    
    // Setup the board
    self.board = [WSUBoard shapeNodeWithRect:CGRectMake(
        -0.5f, -0.5f, WSUBoardWidth, WSUBoardHeight)];
    self.board.fillColor = [UIColor colorWithWhite:0.9f alpha:1.0f];
    self.board.lineWidth = 0.0f;
    
    [self addChild:self.board];
    
    // When calculating the scale factor for the board, leave room for
    // the score label
    const float availableHeight =
        (self.frame.size.height - self.scoreLabel.frame.size.height);
    float scaleFactor = MIN(self.frame.size.width / WSUBoardWidth,
         availableHeight / WSUBoardHeight);
    
    // Position so that objects with anchors at their centers are
    // fully visible by shifting everything half the width of a
    // mushroom, {1, 1}, scaled appropriately for the scene.
    self.board.position =
        CGPointMake(0.5 * scaleFactor, 0.5 * scaleFactor);
    self.board.xScale = scaleFactor;
    self.board.yScale = scaleFactor;
    
    [self.board startDemoMode];
}

@end
