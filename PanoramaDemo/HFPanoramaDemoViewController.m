//
//  HFPanoramaDemoViewController.m
//  PanoramaDemo
//
//  Created by zyq on 2018/4/17.
//  Copyright © 2018 Mutsu. All rights reserved.
//

#import "HFPanoramaDemoViewController.h"
#import "HFPanoramaView.h"

@interface HFPanoramaDemoViewController ()

@property (nonatomic, strong) HFPanoramaView *panoramaView;

@end

@implementation HFPanoramaDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _panoramaView = [[HFPanoramaView alloc] initWithFrame:self.view.bounds];
    _panoramaView.backgroundColor = [UIColor blueColor];
    [self.view addSubview:_panoramaView];
}


@end
