//
//  GameViewController.m
//  WSUCentipede
//
//  Created by Erik Buck on 6/13/16.
//  Copyright (c) 2016 WSU. All rights reserved.
//

#import "GameViewController.h"
#import "GameScene.h"
#import "WSUBoard.h"

@implementation GameViewController

// This is unmodified xcode template generated code
- (void)viewDidLoad
{
    [super viewDidLoad];

    SKView * skView = (SKView *)self.view;
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
    skView.ignoresSiblingOrder = YES;
    
    GameScene *gameScene = [[GameScene alloc]
       initWithSize:self.view.bounds.size];
    gameScene.scaleMode = SKSceneScaleModeAspectFit;
    [skView presentScene:gameScene];
}

// This is unmodified xcode template generated code
- (BOOL)shouldAutorotate
{
    return YES;
}

// This is unmodified xcode template generated code
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] ==
       UIUserInterfaceIdiomPhone)
    {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    else
    {
        return UIInterfaceOrientationMaskAll;
    }
}

// This is unmodified xcode template generated code
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

// This is unmodified xcode template generated code
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
