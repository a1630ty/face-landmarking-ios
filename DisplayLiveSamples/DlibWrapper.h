//
//  DlibWrapper.h
//  DisplayLiveSamples
//
//  Created by Luis Reisewitz on 16.05.16.
//  Copyright © 2016 ZweiGraf. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface DlibWrapper : NSObject

- (instancetype)init;
//- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects;
- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects slong1:(long *)pnt1 slong2:(long *)pnt2 slong3:(long *)pnt3 slong4:(long *)pnt4 slong5:(long *)pnt5 slong6:(long *)pnt6 slong7:(long *)pnt7 slong8:(long *)pnt8;
- (void)prepare;

@end
