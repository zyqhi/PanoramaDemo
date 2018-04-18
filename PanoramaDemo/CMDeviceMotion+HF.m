//
//  CMDeviceMotion+HF.m
//  PanoramaDemo
//
//  Created by zyq on 2018/4/18.
//  Copyright © 2018 Mutsu. All rights reserved.
//

#import "CMDeviceMotion+HF.h"

@implementation CMDeviceMotion (HF)

- (SCNVector4)hf_orientation {
    CMQuaternion attitude = self.attitude.quaternion;
    GLKQuaternion aq = GLKQuaternionMake(attitude.x, attitude.y, attitude.z, attitude.w);
    
    GLKQuaternion cq = GLKQuaternionMakeWithAngleAndAxis(-(M_PI / 2), 1, 0, 0);
    GLKQuaternion q = GLKQuaternionMultiply(cq, aq);
    
    SCNVector4 vec4 = SCNVector4Make(q.x, q.y, q.z, q.w);
    
    return vec4;
}

@end
