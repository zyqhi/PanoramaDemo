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

@end