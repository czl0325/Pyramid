//
//  CCViewController.m
//  001--GLSL三角形变换
//
//  Created by CC老师 on 2017/12/25.
//  Copyright © 2017年 CC老师. All rights reserved.
//

#import "CCViewController.h"
#import "CCView.h"
@interface CCViewController ()

@property(nonatomic,strong)CCView *cView;


@end

@implementation CCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.cView = (CCView *)self.view;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


@end
