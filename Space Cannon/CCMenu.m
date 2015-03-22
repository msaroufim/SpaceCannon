//
//  CCMenu.m
//  Space Cannon
//
//  Created by Mark Saroufim on 3/21/15.
//  Copyright (c) 2015 MarkInc. All rights reserved.
//

#import "CCMenu.h"

@implementation CCMenu

-(id)init
{
    self = [super init];
    if (self) {
        SKSpriteNode *title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        title.position = CGPointMake(0, 140);
        [self addChild:title];
        
        SKSpriteNode *scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        scoreBoard.position = CGPointMake(0, 70);
        [self addChild:scoreBoard];
        
        SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        playButton.position = CGPointMake(0, 0);
        [self addChild:playButton];
    }
    return self;
}

@end
