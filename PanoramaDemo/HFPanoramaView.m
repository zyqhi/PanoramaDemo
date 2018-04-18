//
//  HFPanoramaView.m
//  PanoramaDemo
//
//  Created by zyq on 2018/4/17.
//  Copyright © 2018 Mutsu. All rights reserved.
//

@import SceneKit;
@import SpriteKit;
@import ImageIO;
@import Metal;

#import "HFPanoramaView.h"

#define HF_DEFAULT_FIELD_OF_VIEW 85

@interface HFPanoramaView ()

@property (nonatomic, strong) SCNView *sceneView;

@property (nonatomic, strong) SCNScene *scene;
@property (nonatomic, strong) SCNNode *geometryNode;
@property (nonatomic, strong) SCNNode *cameraNode;

@property (nonatomic, assign) CGPoint prevLocation;
/// 拖动速度
@property (nonatomic, assign) CGPoint panSpeed;
@property (nonatomic, assign) CGFloat initialScale;

@end

@implementation HFPanoramaView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        [self loadSubviews];
        [self addGestures];
        
        _panSpeed = CGPointMake(0.005, 0.005);
    }
    
    return self;
}

- (void)loadSubviews {
    _cameraNode = [self createCameraNode];
    _geometryNode = [self createGeometryNode];
    
    _scene = [SCNScene new];
    [_scene.rootNode addChildNode:_cameraNode];
    [_scene.rootNode addChildNode:_geometryNode];
    
    _sceneView = [[SCNView alloc] initWithFrame:self.bounds];
    [self addSubview:_sceneView];
    _sceneView.scene = _scene;
}

- (SCNNode *)createCameraNode {
    SCNNode *cameraNode = [SCNNode new];
    cameraNode.name = @"cameraNode";
    SCNCamera *camera = [SCNCamera new];
    cameraNode.camera = camera;
    cameraNode.camera.fieldOfView = HF_DEFAULT_FIELD_OF_VIEW;
    
    return cameraNode;
}

- (SCNNode *)createGeometryNode {
    SCNMaterial *material = [SCNMaterial new];
    material.diffuse.contents = [UIImage imageNamed:@"home2"];
    // mipFilter 选错会在顶部和底部产生"缝合感"
    material.diffuse.mipFilter = SCNFilterModeNone;
    material.diffuse.magnificationFilter = SCNFilterModeNearest;
    material.diffuse.contentsTransform = SCNMatrix4MakeScale(-1, 1, 1);
    material.diffuse.wrapS = SCNWrapModeRepeat;
    material.cullMode = SCNCullModeFront;
    
    SCNSphere *sphere = [SCNSphere new];
    sphere.radius = 10;
    sphere.segmentCount = 300;
    sphere.firstMaterial = material;
    
    SCNNode *sphereNode = [SCNNode new];
    sphereNode.geometry = sphere;
    sphereNode.name = @"sphereNode";
    
    return sphereNode;
}

- (void)addGestures {
    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_sceneView addGestureRecognizer:panGR];
    
    UIPinchGestureRecognizer *pinchGR = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [_sceneView addGestureRecognizer:pinchGR];
    
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [_sceneView addGestureRecognizer:tapGR];
}

#pragma mark - Gesture handlers

- (void)handlePan:(UIPanGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        _prevLocation = CGPointZero;
    } else if (gr.state == UIGestureRecognizerStateChanged) {
        CGPoint panSpeed = _panSpeed;
        CGPoint location = [gr translationInView:_sceneView];
        SCNVector3 orientation = _cameraNode.eulerAngles;
        SCNVector3 newOrientation = SCNVector3Make(orientation.x + (location.y - _prevLocation.y) * panSpeed.y,
                                                   orientation.y + (location.x - _prevLocation.x) * panSpeed.x,
                                                   orientation.z);
        
        newOrientation.x = MAX(MIN(newOrientation.x, 1.1), -1.1);
        
        // eulerAngles 是啥?
        _cameraNode.eulerAngles = newOrientation;
        _prevLocation = location;
    }
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        _initialScale = gr.scale;
    } else if (gr.state == UIGestureRecognizerStateChanged) {
        if (gr.scale < _initialScale) {
            // 思考：fieldOfView的物理意义
            _cameraNode.camera.fieldOfView += 1;
        } else {
            _cameraNode.camera.fieldOfView -= 1;
        }
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gr {
    CGPoint tapPoint = [gr locationInView:self.sceneView];
    NSArray<SCNHitTestResult *> *hitTestResults = [self.sceneView hitTest:tapPoint options:nil];
    
    if (hitTestResults.count == 0) {
        return;
    }
    
    SCNNode *boxNode = [self createBoxNodeWithDimension:1.0 animated:YES];
    boxNode.position = hitTestResults.firstObject.localCoordinates;
    [_geometryNode addChildNode:boxNode];
    
    SCNNode *innerNode = [self createBoxNodeWithDimension:0.5 animated:NO];
    innerNode.position = hitTestResults.firstObject.localCoordinates;
    [_geometryNode addChildNode:innerNode];
}

- (SCNNode *)createBoxNodeWithDimension:(CGFloat)dimension animated:(BOOL)animated {
    SCNMaterial *material = [SCNMaterial new];
    material.diffuse.contents = [UIColor redColor];
    
    SCNSphere *sphere = [SCNSphere new];
    sphere.radius = dimension / 2;
    sphere.segmentCount = 300;
    sphere.firstMaterial = material;

    SCNNode *node = [SCNNode nodeWithGeometry:sphere];
    
    // 限制该node一直朝向相机，如果不设置的话，会导致box变形
//    SCNLookAtConstraint *constraint = [SCNLookAtConstraint lookAtConstraintWithTarget:_cameraNode];
//    constraint.gimbalLockEnabled = YES;
//    node.constraints = @[constraint];
    if (animated) {
        CABasicAnimation *animScale = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        animScale.toValue = @(4);
        
        CABasicAnimation *animOpa = [CABasicAnimation animationWithKeyPath:@"opacity"];
        animOpa.toValue = @(0);
        
        CAAnimationGroup *group = [CAAnimationGroup animation];
        group.animations = @[animScale, animOpa];
        group.repeatCount = HUGE_VALF;
        group.duration = 1.0f;
        group.removedOnCompletion = NO;
        
        [node addAnimation:group forKey:@"scaleAnimation"];
    }
    
    return node;
}


@end
