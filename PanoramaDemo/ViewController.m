//
//  ViewController.m
//  PanoramaDemo
//
//  Created by zyq on 26/10/2017.
//  Copyright © 2017 Mutsu. All rights reserved.
//

#import "ViewController.h"
@import SceneKit;
@import SpriteKit;
@import ImageIO;
@import Metal;

#define DEFAULT_FIELD_OF_VIEW 85

@interface ViewController ()

@property (nonatomic, strong) SCNView *sceneView;
@property (nonatomic, strong) UIButton *sceneSwitchBtn;

@property (nonatomic, strong) SCNScene *scene;
@property (nonatomic, strong) SCNNode *geometryNode;
@property (nonatomic, strong) SCNNode *cameraNode;

@property (nonatomic, strong) SCNScene *almaScene;
@property (nonatomic, strong) SCNNode *almaGeometryNode;
@property (nonatomic, strong) SCNNode *almaCameraNode;

@property (nonatomic, strong) SCNScene *currentScene;
@property (nonatomic, strong) SCNNode *currentGeometryNode;
@property (nonatomic, strong) SCNNode *currentCameraNode;

@property (nonatomic, assign) CGPoint prevLocation;
@property (nonatomic, assign) CGPoint panSpeed;
@property (nonatomic, assign) CGFloat initialScale;

@property (nonatomic, strong) NSMutableDictionary *noteDict;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _sceneView = [[SCNView alloc] initWithFrame:self.view.bounds];
//    _sceneView.autoenablesDefaultLighting = YES;
    [self.view addSubview:_sceneView];
    // 防锯齿
    _sceneView.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    
    _sceneSwitchBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _sceneSwitchBtn.frame = CGRectMake(15, 20, 140, 40);
    [_sceneSwitchBtn setTitle:@"Next Scene" forState:UIControlStateNormal];
    _sceneSwitchBtn.layer.cornerRadius = 4;
    _sceneSwitchBtn.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    [_sceneSwitchBtn setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
    [_sceneSwitchBtn addTarget:self action:@selector(nextSceneBtnTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_sceneSwitchBtn];

    _cameraNode = [SCNNode new];
    _cameraNode.name = @"cameraNode";
    SCNCamera *camera = [SCNCamera new];
    _cameraNode.camera = camera;
    _cameraNode.camera.fieldOfView = DEFAULT_FIELD_OF_VIEW;

    _scene = [SCNScene new];
    [_scene.rootNode addChildNode:_cameraNode];
    [_scene.rootNode addChildNode:self.geometryNode];

    _sceneView.scene = _scene;
    
    _almaCameraNode = [SCNNode new];
    SCNCamera *almaCamera = [SCNCamera new];
    _almaCameraNode.camera = almaCamera;
    _almaCameraNode.camera.fieldOfView = DEFAULT_FIELD_OF_VIEW;
    
    _almaScene = [SCNScene new];
    [_almaScene.rootNode addChildNode:_almaCameraNode];
    [_almaScene.rootNode addChildNode:self.almaGeometryNode];
    
    // 拖动速度
    _panSpeed = CGPointMake(0.005, 0.005);
    
    
    _currentScene = _scene;
    _currentCameraNode = _cameraNode;
    _currentGeometryNode = _geometryNode;
    
    [self addPanGesture];
    [self addPinchGesture];
    [self addTapGesture];
    [self addLongpressGesture];
}

- (void)addTapGesture {
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [_sceneView addGestureRecognizer:tapGR];
}

- (void)addPanGesture {
    UIPanGestureRecognizer *panGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [_sceneView addGestureRecognizer:panGR];
}

- (void)addPinchGesture {
    UIPinchGestureRecognizer *pinchGR = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    [_sceneView addGestureRecognizer:pinchGR];
}

- (void)addLongpressGesture {
    UILongPressGestureRecognizer *lpGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongpress:)];
    [_sceneView addGestureRecognizer:lpGR];
}

#pragma mark - Action

- (void)nextSceneBtnTapped {
    SCNScene *nextScene;
    if (_currentScene == _scene) {
        nextScene = _almaScene;
    } else {
        nextScene = _scene;
    }
    
    SKTransition *trans = [SKTransition revealWithDirection:SKTransitionDirectionDown duration:1.0];
    trans = [SKTransition fadeWithDuration:1.0];
    [self.sceneView presentScene:nextScene withTransition:trans incomingPointOfView:nil completionHandler:^{
        _currentScene = nextScene;
        
        if (_currentScene == _scene) {
            _currentCameraNode = _cameraNode;
            _currentGeometryNode = _geometryNode;
        } else {
            _currentCameraNode = _almaCameraNode;
            _currentGeometryNode = _almaGeometryNode;
        }
    }];
}

- (void)handleLongpress:(UILongPressGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        CGPoint tapPoint = [gr locationInView:self.sceneView];
        NSArray<SCNHitTestResult *> *hitTestResults = [self.sceneView hitTest:tapPoint options:nil];

        if (hitTestResults.count == 0) {
            return;
        }

        [self insertGeomerty:hitTestResults.firstObject];
    }
}

- (void)handleTap:(UITapGestureRecognizer *)gr {
    CGPoint tapPoint = [gr locationInView:self.sceneView];
    NSArray<SCNHitTestResult *> *hitTestResults = [self.sceneView hitTest:tapPoint options:nil];
    
    if (hitTestResults.count == 0) {
        return;
    }
    
    SCNNode *node = hitTestResults.firstObject.node;
    [self showMessage:self.noteDict[[self keyOfObject:node]]];
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        _initialScale = gr.scale;
    } else if (gr.state == UIGestureRecognizerStateChanged) {
        if (gr.scale < _initialScale) {
            // 思考：fieldOfView的物理意义
            _currentCameraNode.camera.fieldOfView += 1;
        } else {
            _currentCameraNode.camera.fieldOfView -= 1;
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gr {
    if (gr.state == UIGestureRecognizerStateBegan) {
        _prevLocation = CGPointZero;
    } else if (gr.state == UIGestureRecognizerStateChanged) {
        CGPoint panSpeed = _panSpeed;
        CGPoint location = [gr translationInView:_sceneView];
        SCNVector3 orientation = _currentCameraNode.eulerAngles;
        SCNVector3 newOrientation = SCNVector3Make(orientation.x + (location.y - _prevLocation.y) * panSpeed.y,
                                                   orientation.y + (location.x - _prevLocation.x) * panSpeed.x,
                                                   orientation.z);
        
        newOrientation.x = MAX(MIN(newOrientation.x, 1.1), -1.1);
        
        // eulerAngles 是啥?
        _currentCameraNode.eulerAngles = newOrientation;
        _prevLocation = location;
    }
}

// 创建一个球几何体，并用全景图作为球的表面
- (SCNNode *)geometryNode {
    if (_geometryNode) {
        return _geometryNode;
    }
    
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
    
    _geometryNode = sphereNode;
    
    return _geometryNode;
}

- (SCNNode *)almaGeometryNode {
    if (_almaGeometryNode) {
        return _almaGeometryNode;
    }
    
    SCNMaterial *material = [SCNMaterial new];
    material.diffuse.contents = [UIImage imageNamed:@"paris"];
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
    
    _almaGeometryNode = sphereNode;
    
    return _almaGeometryNode;
}

- (SCNNode *)insertGeomerty:(SCNHitTestResult *)hitResult {
    SCNNode *boxNode = [self boxNode];
    
    // 限制该node一直朝向相机，如果不设置的话，会导致box变形
    SCNLookAtConstraint *constraint = [SCNLookAtConstraint lookAtConstraintWithTarget:_cameraNode];
    constraint.gimbalLockEnabled = YES;
    boxNode.constraints = @[constraint];
    boxNode.position = hitResult.localCoordinates;
    [_currentGeometryNode addChildNode:boxNode];
    
    [self alertForObject:boxNode location:boxNode.position];

    [self printVector3:hitResult.localCoordinates label:@"localCoordinates"];
    [self printVector3:hitResult.worldCoordinates label:@"worldCoordinates"];
    [self printVector3:hitResult.localNormal label:@"localNormal"];
    [self printVector3:hitResult.worldNormal label:@"worldNormal"];
    
    return boxNode;
}

- (SCNNode *)boxNode {
    float dimension = 0.5;
    SCNBox *cube = [SCNBox boxWithWidth:dimension height:dimension length:dimension chamferRadius:dimension/2];
    SCNNode *node = [SCNNode nodeWithGeometry:cube];

    return node;
}

#pragma mark - Debug

- (void)printVector3:(SCNVector3)v label:(NSString *)str {
    NSLog(@"%@ is: {x = %f, y = %f, z = %f}", str, v.x, v.y, v.z);
}

- (NSString *)vector3Description:(SCNVector3)v {
    return [NSString stringWithFormat:@"(x:%.2f, y:%.2f, z:%.2f)", v.x, v.y, v.z];
}

- (void)alertForObject:(id)obj location:(SCNVector3)loc {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Notes"
                                                                              message:@"Note for current hotspot"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Note";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray *textfields = alertController.textFields;
        UITextField *notefield = textfields[0];
        
        NSLog(@"Note is: %@", notefield.text);
        if (!self.noteDict) {
            self.noteDict = @{}.mutableCopy;
        }
        self.noteDict[[self keyOfObject:obj]] = [[notefield.text stringByAppendingString:@"\n"] stringByAppendingString:[self vector3Description:loc]];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)showMessage:(NSString *)str {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Notes"
                                                                              message:str ? : @"Empty"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (NSString *)keyOfObject:(NSObject *)obj {
    return [NSString stringWithFormat:@"%ld", obj.hash];
}

#pragma mark - Helper

// 该方法将二维平面里面的一个点的像素坐标(x, y)，映射为球面三维空间里面的一个点(x, y, z)

- (SCNVector3)unprojectPoint:(CGPoint)p {
    CGSize size = [UIImage imageNamed:@"spherical"].size;
    CGFloat W = size.width;
    CGFloat R = W / (2 * M_PI);

    p = CGPointMake(400, 200);
    
    
    CGFloat newR = sqrt(R*R - p.y*p.y);
    CGFloat theta = 2 * M_PI * p.x / W;
    
    SCNVector3 v = SCNVector3Make(newR * sin(theta), p.y, newR * cos(theta));
    
    CGFloat scale = 10 / R;
    
    return SCNVector3Make(v.x * scale, v.y * scale, v.z * scale);
}

@end
