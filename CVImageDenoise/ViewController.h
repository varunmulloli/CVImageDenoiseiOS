//
//  ViewController.h
//  CVImageDenoise
//
//  Created by Varun Mulloli on 14/04/13.
//  Copyright (c) 2013 Varun Mulloli. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/opencv.hpp>
#include <vector>

using namespace cv;

@interface ViewController : UIViewController
<UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    IBOutlet UIImageView *imageView;
    IBOutlet UIToolbar *toolbar;
}

@property (nonatomic, strong) UIPopoverController *popOver;

@end
