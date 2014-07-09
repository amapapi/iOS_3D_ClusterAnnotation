//
//  CoordinateQuadTree.h
//  officialDemo2D
//
//  Created by yi chen on 14-5-15.
//  Copyright (c) 2014年 AutoNavi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MAMapKit/MAMapKit.h>
#import "QuadTree.h"

@protocol CoordinateQuadTreeDelegate <NSObject>

- (void)coordinateQuadTreeDidBuild:(QuadTreeNode *)root;

@end


@interface CoordinateQuadTree : NSObject

@property (nonatomic, assign) QuadTreeNode * root;
@property (nonatomic, strong) id<CoordinateQuadTreeDelegate> delegate;

- (void)buildTreeWithPOIs:(NSArray *)pois;
- (void)clean;

- (NSArray *)clusteredAnnotationsWithinMapRect:(MAMapRect)rect withZoomScale:(double)zoomScale andZoomLevel:(double)zoomLevel;

@end
