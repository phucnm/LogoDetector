////////
// This sample is published as part of the blog article at www.toptal.com/blog 
// Visit www.toptal.com/blog and subscribe to our newsletter to read great posts
////////

//
//  CameraViewController.m
//  LogoDetector
//
//  Created by altaibayar tseveenbayar on 13/05/15.
//  Copyright (c) 2015 altaibayar tseveenbayar. All rights reserved.
//

#import "CameraViewController.h"
#import <opencv2/highgui/ios.h>

#import "MSERManager.h"
#import "MLManager.h"
#import "ImageUtils.h"
#import "GeometryUtil.h"

#ifdef DEBUG
#import "FPS.h"
#endif

//this two values are dependant on defaultAVCaptureSessionPreset
#define W (480)
#define H (640)

@interface CameraViewController()
{
    CvVideoCamera *camera;
    BOOL started;
}

@end

@implementation CameraViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    //UI
    [_btn setTitle: @" " forState: UIControlStateNormal];
    
    //Camera
    camera = [[CvVideoCamera alloc] initWithParentView: _img];
    camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    camera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    camera.defaultFPS = 30;
    camera.grayscaleMode = NO;
    camera.delegate = self;
    
    started = NO;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear: animated];
    
    //[self test];
    [camera start];
    
}

- (void) test
{
    UIImage *logo = [UIImage imageNamed: @"toptal logo"];    
    cv::Mat image = [ImageUtils cvMatFromUIImage: logo];

    //get gray image
    cv::Mat gray;
    cvtColor(image, gray, CV_BGRA2GRAY);
    
    //mser with maximum area is
    std::vector<cv::Point> mser = [ImageUtils maxMser: &gray];
    
    //get 4 vertices of the maxMSER minrect
    cv::RotatedRect rect = cv::minAreaRect(mser);    
    cv::Point2f points[4];
    rect.points(points);
    
    //normalize image
    cv::Mat M = [GeometryUtil getPerspectiveMatrix: points toSize: rect.size];
    cv::Mat normalizedImage = [GeometryUtil normalizeImage: &gray withTranformationMatrix: &M withSize: rect.size.width];

    //get maxMser from normalized image
    std::vector<cv::Point> normalizedMser = [ImageUtils maxMser: &normalizedImage];
    
    _img.backgroundColor = [UIColor greenColor];
    _img.contentMode = UIViewContentModeCenter;
    _img.image = [ImageUtils UIImageFromCVMat: normalizedImage];
}

- (IBAction)btn_TouchUp:(id)sender 
{
    started = !started;
}

- (void)processImage:(cv::Mat &)image {
    if (!started) { [FPS draw: image]; return; }
    
    cv::Mat threshedImage;
    cv::cvtColor(image, threshedImage, CV_BGR2GRAY);
    threshImage(image, threshedImage, 0);
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.threshImageView.image = [ImageUtils UIImageFromCVMat:threshedImage];
//    });
    
}

void threshImage( cv::Mat input, cv::Mat output, int serial ) {
    
    
    cv::GaussianBlur(output, output, cv::Size(9, 9), 2);
    std::vector<cv::Vec3f> circles;
    cv::HoughCircles(output, circles, CV_HOUGH_GRADIENT, 1, output.rows / 8);
    
    if (circles.size()) {
        for (size_t i = 0; i < circles.size(); i++)
        {
            std::cout << "Circle position x = " << (int)circles[i][0] << ", y = " << (int)circles[i][1] << ", radius = " << (int)circles[i][2] << "\n";
            
            cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
            
            int radius = cvRound(circles[i][2]);
            
            circle(input, center, 3, cv::Scalar(0, 255, 0), -1, 8, 0);
            circle(input, center, radius, cv::Scalar(0, 0, 255), 3, 8, 0);
        }

    }
//    cv::HoughCircles(output, circles, CV_HOUGH_GRADIENT, 1.2, 100);
//    for (size_t i = 0; i < circles.size(); i++) {
//        std::cout << "Circle position x = " << (int)circles[i][0] << ", y = " << (int)circles[i][1] << ", radius = " << (int)circles[i][2] << "\n";
//        
//        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
//        
//        int radius = cvRound(circles[i][2]);
//        cv::circle(input, center, radius, cv::Scalar(0, 255, 0));
////        circle(input, center, 3, cv::Scalar(0, 255, 0), -1, 8, 0);
////        circle(input, center, radius, cv::Scalar(0, 0, 255), 3, 8, 0);
//    }

//    cv::Mat hsvImg = cv::Mat::zeros( input.size(), output.type() );
//    std::vector<cv::Vec3f> circles;
////    cv::blur( input, hsvImg, cv::Size( 9, 9 ) );
////    cvtColor( hsvImg, hsvImg, CV_BGR2HSV );
////    cv::inRange( hsvImg, cv::Scalar( 29, 86, 6 ), cv::Scalar( 64, 255, 255 ), output );
//    cv::HoughCircles( output, circles, CV_HOUGH_GRADIENT, 2, output.rows/4, 150, 75, 10, 150);
//    for (size_t i = 0; i < circles.size(); i++)
//    {
//        std::cout << "Circle position x = " << (int)circles[i][0] << ", y = " << (int)circles[i][1] << ", radius = " << (int)circles[i][2] << "\n";
//        
//        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
//        
//        int radius = cvRound(circles[i][2]);
//        
//        circle(input, center, 3, cv::Scalar(0, 255, 0), -1, 8, 0);
//        circle(input, center, radius, cv::Scalar(0, 0, 255), 3, 8, 0);
//    }
//
//    cv::Size imgSize = input.size();
//    cv::Point imgCenter( imgSize.width/2, imgSize.height/2 );
//    for( size_t i = 0; i < circles.size() && i < 1; i++ ) {
//        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
//        int radius = cvRound(circles[i][2]);
//        int xDiff = imgCenter.x - center.x;
//        int yDiff = imgCenter.y - center.y;
//        char sendBuf;
//        if( abs( yDiff ) > radius ) {
//            yDiff = yDiff > 0 ? 30 : 10;
//        } else {
//            yDiff = 20;
//        }
//        if( abs( xDiff ) > radius ) {
//            xDiff = xDiff > 0 ? 3 : 1;
//        } else {
//            xDiff = 2;
//        }
//        if( xDiff != 2 || yDiff != 20 ) {
//            sendBuf = xDiff + yDiff;
//            write( serial, &sendBuf, 1 );
//        }
//        cv::rectangle(
//                  input,
//                  cv::Point(
//                        circles[i][0] - radius,
//                        circles[i][1] - radius
//                        ),
//                  cv::Point(
//                        circles[i][0] + radius,
//                        circles[i][1] + radius
//                        ),
//                  cv::Scalar( 0, 255, 0 ),
//                  3,
//                  8,
//                  0
//                  );
//        cv::line( input, imgCenter, center, cv::Scalar( 255, 0, 0 ), 3, 8, 0 );
//        
//    }
}

//-(void)processImage:(cv::Mat &)image
//{    
//    if (!started) { [FPS draw: image]; return; }
//    
//    cv::Mat gray;
//    cvtColor(image, gray, CV_BGRA2GRAY);
//    
//    std::vector<std::vector<cv::Point>> msers;
//    [[MSERManager sharedInstance] detectRegions: gray intoVector: msers];
//    if (msers.size() == 0) { return; };
//    
//    std::vector<cv::Point> *bestMser = nil;
//    double bestPoint = 10.0;
//    
//    std::for_each(msers.begin(), msers.end(), [&] (std::vector<cv::Point> &mser) 
//    {
//        MSERFeature *feature = [[MSERManager sharedInstance] extractFeature: &mser];
//    
//        if(feature != nil)            
//        {
//            if([[MLManager sharedInstance] isToptalLogo: feature] )
//            {
//                double tmp = [[MLManager sharedInstance] distance: feature ];
//                if ( bestPoint > tmp ) {
//                    bestPoint = tmp;
//                    bestMser = &mser;
//                }
//                
////                [ImageUtils drawMser: &mser intoImage: &image withColor: RED];
//            }
//            else 
//            {
//                //NSLog(@"%@", [feature toString]);
//                //[ImageUtils drawMser: &mser intoImage: &image withColor: RED];
//            }
//        }
//        else 
//        {
//            //[ImageUtils drawMser: &mser intoImage: &image withColor: BLUE];
//        }
//    });
//
//    if (bestMser)
//    {
//        NSLog(@"minDist: %f", bestPoint);
//                
//        cv::Rect bound = cv::boundingRect(*bestMser);
//        cv::rectangle(image, bound, GREEN, 3);
//    }
//    else 
//    {
//        cv::rectangle(image, cv::Rect(0, 0, W, H), RED, 3);
//    }
//
//#if DEBUG    
//    const char* str_fps = [[NSString stringWithFormat: @"MSER: %ld", msers.size()] cStringUsingEncoding: NSUTF8StringEncoding];
//    cv::putText(image, str_fps, cv::Point(10, H - 10), CV_FONT_HERSHEY_PLAIN, 1.0, RED);
//#endif
//    
//    [FPS draw: image]; 
//}

@end
