//
//  AnnotationClusterViewController.m
//  officialDemo2D
//
//  Created by yi chen on 14-5-15.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import "AnnotationClusterViewController.h"
#import "PoiDetailViewController.h"
#import "CoordinateQuadTree.h"
#import "ClusterAnnotation.h"
#import "ClusterAnnotationView.h"

#define kCalloutViewMargin -8

@interface AnnotationClusterViewController ()<UITableViewDelegate, CoordinateQuadTreeDelegate>

@property (nonatomic, strong) CoordinateQuadTree* coordinateQuadTree;

@end

@implementation AnnotationClusterViewController

#pragma mark - update Annotation

/* 更新annotation. */
- (void)updateMapViewAnnotationsWithAnnotations:(NSArray *)annotations
{
    /* 用户滑动时，保留仍然可用的标注，去除屏幕外标注，添加新增区域的标注 */
    NSMutableSet *before = [NSMutableSet setWithArray:self.mapView.annotations];
    [before removeObject:[self.mapView userLocation]];
    NSSet *after = [NSSet setWithArray:annotations];
    
    /* 保留仍然位于屏幕内的annotation. */
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    /* 需要添加的annotation. */
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    /* 删除位于屏幕外的annotation. */
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    /* 更新. */
    [[NSOperationQueue mainQueue] addOperationWithBlock:^
    {
        [self.mapView addAnnotations:[toAdd allObjects]];
        [self.mapView removeAnnotations:[toRemove allObjects]];
    }];
}


- (void)addAnnotationsToMapView:(MAMapView *)mapView
{
    NSLog(@"calculate annotations.");
    if (self.coordinateQuadTree.root == nil)
    {
        NSLog(@"tree is not ready.");
        return;
    }

    /* 根据当前zoomLevel和zoomScale 进行annotation聚合. */
    double zoomScale = self.mapView.bounds.size.width / self.mapView.visibleMapRect.size.width;

    NSArray *annotations = [self.coordinateQuadTree clusteredAnnotationsWithinMapRect:mapView.visibleMapRect
                                                                        withZoomScale:zoomScale
                                                                         andZoomLevel:mapView.zoomLevel];
   
    /* 更新annotation. */
    [self updateMapViewAnnotationsWithAnnotations:annotations];
}

#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    /* mapView区域变化时重算annotation. */
    [[NSOperationQueue new] addOperationWithBlock:^
    {
        [self addAnnotationsToMapView:mapView];
    }];
}

- (void)mapView:(MAMapView *)mapView annotationView:(MAAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    id<MAAnnotation> annotation = view.annotation;
    
    if ([annotation isKindOfClass:[ClusterAnnotation class]])
    {
        ClusterAnnotation *clusterAnnotation = (ClusterAnnotation*)annotation;
        
        PoiDetailViewController *detail = [[PoiDetailViewController alloc] init];
        detail.poi = [clusterAnnotation.pois lastObject];
        
        /* 进入POI详情页面. */
        [self.navigationController pushViewController:detail animated:YES];
    }
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation
{
    if ([annotation isKindOfClass:[ClusterAnnotation class]])
    {
        static NSString *const AnnotatioViewReuseID = @"AnnotatioViewReuseID";
        
        ClusterAnnotationView *annotationView = (ClusterAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotatioViewReuseID];
        
        if (!annotationView)
        {
            annotationView = [[ClusterAnnotationView alloc] initWithAnnotation:annotation
                                                               reuseIdentifier:AnnotatioViewReuseID];
        }
        
        annotationView.annotation = annotation;
        annotationView.canShowCallout = YES;
        annotationView.count = [(ClusterAnnotation *)annotation count];
        if (annotationView.count == 1)
        {
            annotationView.rightCalloutAccessoryView    = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        
        return annotationView;
    }
    
    return nil;
}

- (void)mapView:(MAMapView *)mapView didAddAnnotationViews:(NSArray *)views
{
    for (UIView *view in views)
    {
        [self addBounceAnnimationToView:view];
    }
}

#pragma mark - AMapSearchDelegate

/* POI 搜索回调. */
- (void)onPlaceSearchDone:(AMapPlaceSearchRequest *)request response:(AMapPlaceSearchResponse *)respons
{
    if (respons.pois.count == 0)
    {
        return;
    }
    
    [[NSOperationQueue new] addOperationWithBlock:^
     {
         [self.coordinateQuadTree buildTreeWithPOIs:respons.pois];
     }];
    
    /* 如果只有一个结果，设置其为中心点. */
    if (respons.pois.count == 1)
    {
        self.mapView.centerCoordinate = [respons.pois[0] coordinate];
    }
    /* 如果有多个结果, 设置地图使所有的annotation都可见. */
    else
    {
        [self.mapView showAnnotations:self.mapView.annotations animated:NO];
    }
}

#pragma mark - CoordinateQuadTreeDelegate

- (void)coordinateQuadTreeDidBuild:(QuadTreeNode *)root
{
    NSLog(@"First time calculate annotations.");
    [self addAnnotationsToMapView:self.mapView];
}

#pragma mark - Utility

/* 搜索POI. */
- (void)searchPoi
{
    AMapPlaceSearchRequest *request = [[AMapPlaceSearchRequest alloc] init];
    
    request.searchType          = AMapSearchType_PlaceKeyword;
    request.keywords            = @"Apple";
    request.city                = @[@"010"];
    request.requireExtension    = YES;
    
    [self.search AMapPlaceSearch:request];
}

/* annotation弹出的动画. */
- (void)addBounceAnnimationToView:(UIView *)view
{
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    bounceAnimation.values = @[@(0.05), @(1.1), @(0.9), @(1)];
    bounceAnimation.duration = 0.6;
    
    NSMutableArray *timingFunctions = [[NSMutableArray alloc] initWithCapacity:bounceAnimation.values.count];
    for (NSUInteger i = 0; i < bounceAnimation.values.count; i++)
    {
        [timingFunctions addObject:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    }
    [bounceAnimation setTimingFunctions:timingFunctions.copy];
    
    bounceAnimation.removedOnCompletion = NO;
    
    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

#pragma mark - Life Cycle

- (id)init
{
    if (self = [super init])
    {
        self.coordinateQuadTree = [[CoordinateQuadTree alloc] init];
        self.coordinateQuadTree.delegate = self;
        
        [self setTitle:@"Cluster Annotations"];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self searchPoi];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [self.coordinateQuadTree clean];
}

@end
