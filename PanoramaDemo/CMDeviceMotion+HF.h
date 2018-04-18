//
//  CMDeviceMotion+HF.h
//  PanoramaDemo
//
//  Created by zyq on 2018/4/18.
//  Copyright © 2018 Mutsu. All rights reserved.
//

@import SceneKit;
@import SpriteKit;
@import ImageIO;
@import Metal;
@import CoreMotion;

@interface CMDeviceMotion (HF)

- (SCNVector4)hf_orientation;

@end
