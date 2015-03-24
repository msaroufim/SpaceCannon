//
//  CCBall.m
//  Space Cannon
//
//  Created by Mark Saroufim on 3/24/15.
//  Copyright (c) 2015 MarkInc. All rights reserved.
//

#import "CCBall.h"

@implementation CCBall

-(void)updateTrail {
    if(self.trail) {
        self.trail.position = self.position;
    }
}

-(void)removeFromParent {
    
    if(self.trail) {
        self.trail.particleBirthRate = 0.0;
        
        
        SKAction *removeTrail = [SKAction sequence:@[[SKAction waitForDuration:self.trail.particleLifetime + self.trail.particleLifetimeRange],[SKAction removeFromParent]]];
        
        [self runAction:removeTrail];
        
    }
    
    [super removeFromParent];
    
}

@end
