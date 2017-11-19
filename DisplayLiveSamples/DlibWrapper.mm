//
//  DlibWrapper.m
//  DisplayLiveSamples
//
//  Created by Luis Reisewitz on 16.05.16.
//  Copyright © 2016 ZweiGraf. All rights reserved.
//

#import "DlibWrapper.h"
#import <UIKit/UIKit.h>

#include <dlib/image_processing.h>
#include <dlib/image_io.h>
#include <string>
#include <iostream>
#include <sstream>
#include <stdio.h>

@interface DlibWrapper ()

@property (assign) BOOL prepared;

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects;

@end
@implementation DlibWrapper {
    dlib::shape_predictor sp;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _prepared = NO;
    }
    return self;
}

- (void)prepare {
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"shape_predictor_68_face_landmarks" ofType:@"dat"];
    std::string modelFileNameCString = [modelFileName UTF8String];
    
    dlib::deserialize(modelFileNameCString) >> sp;
    
    // FIXME: test this stuff for memory leaks (cpp object destruction)
    self.prepared = YES;
}

- (void)doWorkOnSampleBuffer:(CMSampleBufferRef)sampleBuffer inRects:(NSArray<NSValue *> *)rects long1:(long *)pnt1 long2:(long *) pnt2 long3:(long *)pnt3 long4:(long *)pnt4 long5:(long *)pnt5  long6:(long *)pnt6 long7:(long *)pnt7 long8:(long *)pnt8 {
    
    if (!self.prepared) {
        [self prepare];
    }
    
    dlib::array2d<dlib::bgr_pixel> img;
    
    // MARK: magic
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);

    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    char *baseBuffer = (char *)CVPixelBufferGetBaseAddress(imageBuffer);
    
    long px1;
    long px2;
    long px3;
    long px4;
    
    // set_size expects rows, cols format
    img.set_size(height, width);
    
    // copy samplebuffer image data into dlib image format
    img.reset();
    long position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();

        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        char b = baseBuffer[bufferLocation];
        char g = baseBuffer[bufferLocation + 1];
        char r = baseBuffer[bufferLocation + 2];
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        dlib::bgr_pixel newpixel(b, g, r);
        pixel = newpixel;
        
        position++;
    }
    
    // unlock buffer again until we need it again
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    // convert the face bounds list to dlib format
    std::vector<dlib::rectangle> convertedRectangles = [DlibWrapper convertCGRectValueArray:rects];
    
    // for every detected face
    for (unsigned long j = 0; j < convertedRectangles.size(); ++j)
    {
        dlib::rectangle oneFaceRect = convertedRectangles[j];
        
        // detect all landmarks
        dlib::full_object_detection shape = sp(img, oneFaceRect);
        
        // and draw them into the image (samplebuffer)
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
        //for (unsigned long k = 0; k < 10; k++) {
            if (k == 62) {
                dlib::point p = shape.part(k);
                draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 255, 0));
                px1 = p.x();
                //px2 = p.y();
                *pnt1 = px1;
                //*pnt1 = px1;
            }else if (k == 66) {
                dlib::point p = shape.part(k);
                draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 0, 255));
                //px3 = p.x();
                px2 = p.y();
                *pnt2 = px2;
                //*pnt4 = px4;
            
                //dlib::point p = shape.part(k);
                //draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 255, 255));
            }
            
        }
        
        for (unsigned long k = 0; k < shape.num_parts(); k++) {
        //for (unsigned long k = 0; k < 10; k++) {
            if (k > 45 && k < 48) {
                dlib::point p = shape.part(k);
                draw_solid_circle(img, p, 3, dlib::rgb_pixel(255, 0, 0));
            }else if (k > 42 && k < 45) {
                dlib::point p = shape.part(k);
                draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 255, 0));
            }else if (k > 36 && k < 39) {
                dlib::point p = shape.part(k);
                draw_solid_circle(img, p, 3, dlib::rgb_pixel(0, 0, 255));
            }else if (k > 39 && k < 42) {
                dlib::point p = shape.part(k);
                draw_solid_circle(img, p, 3, dlib::rgb_pixel(255, 255, 255));
            }else if (k > 26 && k < 28) {
                dlib::point p = shape.part(k);
                draw_solid_circle(img, p, 3, dlib::rgb_pixel(255, 0, 255));
            }else if (k > 7 && k < 9) {
                dlib::point p = shape.part(k);
                draw_solid_circle(img, p, 3, dlib::rgb_pixel(255, 0, 255));
            }
            
        }
        //unsigned long s = shape.num_parts();
        //printf("%ld\n", s);

    }
    
    // lets put everything back where it belongs
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    // copy dlib image data back into samplebuffer
    img.reset();
    position = 0;
    while (img.move_next()) {
        dlib::bgr_pixel& pixel = img.element();
        
        // assuming bgra format here
        long bufferLocation = position * 4; //(row * width + column) * 4;
        baseBuffer[bufferLocation] = pixel.blue;
        baseBuffer[bufferLocation + 1] = pixel.green;
        baseBuffer[bufferLocation + 2] = pixel.red;
        //        we do not need this
        //        char a = baseBuffer[bufferLocation + 3];
        
        position++;
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

+ (std::vector<dlib::rectangle>)convertCGRectValueArray:(NSArray<NSValue *> *)rects {
    std::vector<dlib::rectangle> myConvertedRects;
    for (NSValue *rectValue in rects) {
        CGRect rect = [rectValue CGRectValue];
        long left = rect.origin.x;
        long top = rect.origin.y;
        long right = left + rect.size.width;
        long bottom = top + rect.size.height;
        dlib::rectangle dlibRect(left, top, right, bottom);

        myConvertedRects.push_back(dlibRect);
    }
    return myConvertedRects;
}

@end
