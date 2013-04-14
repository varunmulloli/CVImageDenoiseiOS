//
//  ViewController.m
//  CVImageDenoise
//
//  Created by Varun Mulloli on 14/04/13.
//  Copyright (c) 2013 Varun Mulloli. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController
{
    UIImagePickerController *imgPicker;
    UIBarButtonItem *editButton;
    UIBarButtonItem *saveButton;
    UIBarButtonItem *photoLibrary;
    
    Mat img;
}

@synthesize popOver;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeToolbar];
}

-(void) initializeToolbar
{
    editButton = [[UIBarButtonItem alloc] initWithTitle:@"Denoise" style:UIBarButtonItemStyleBordered target:self action:@selector(denoiseImage)];
    saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(savePhoto)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    photoLibrary = [[UIBarButtonItem alloc] initWithTitle:@"Library" style:UIBarButtonItemStyleBordered target:self action:@selector(openPhotoLibrary)];
    photoLibrary.style = UIBarButtonItemStyleBordered;
    UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(startCamera)];
    cameraButton.style = UIBarButtonItemStyleBordered;
    
    NSArray *array = [NSArray arrayWithObjects: editButton, saveButton, flexibleSpace, photoLibrary, cameraButton, nil];
    [toolbar setItems:array animated:YES];
    
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        cameraButton.enabled = NO;
    
    if (img.empty())
    {
        editButton.enabled = NO;
        saveButton.enabled = NO;
    }
}

- (void) savePhoto
{
    UIImageWriteToSavedPhotosAlbum([self UIImageFromCVMat:img], nil, nil, nil);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Image has been successfully saved to the Photos Library." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil, nil];
    [alert show];
}

- (void)openPhotoLibrary
{
    imgPicker = [[UIImagePickerController alloc] init];
    imgPicker.allowsEditing = NO;
    imgPicker.delegate = self;
    imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        if(![popOver isPopoverVisible])
        {
            popOver = [[UIPopoverController alloc] initWithContentViewController:imgPicker];
            [popOver presentPopoverFromBarButtonItem:photoLibrary permittedArrowDirections:UIPopoverArrowDirectionDown animated:YES];
        }
    }
    else
    {
        [self presentViewController:imgPicker animated:YES completion:nil];
    }
}

- (void)startCamera
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        imgPicker = [[UIImagePickerController alloc] init];
        imgPicker.allowsEditing = NO;
        imgPicker.delegate = self;
        imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imgPicker.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:imgPicker animated:YES completion:nil];
    }
}

- (void) denoiseImage
{
    Mat temp;
    cvtColor(img, temp, CV_BGRA2BGR);
    fastNlMeansDenoising(temp, img);
    [imageView setImage:[self UIImageFromCVMat:img]];
}

- (Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat cvMat(rows, cols, CV_8UC4);
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data, cols, rows, 8, cvMat.step[0], colorSpace,kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}

-(UIImage *)UIImageFromCVMat:(Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols, cvMat.rows, 8,  8 * cvMat.elemSize(), cvMat.step[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false,kCGRenderingIntentDefault);
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}


- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo: (NSDictionary *)info
{
    UIImage *picture = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    [imageView setImage:picture];
    img = [self cvMatFromUIImage:picture];
    if (!img.empty())
    {
        editButton.enabled = YES;
        saveButton.enabled = YES;
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        [popOver dismissPopoverAnimated:YES];
    else
        [imgPicker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        [popOver dismissPopoverAnimated:YES];
    else
        [imgPicker dismissViewControllerAnimated:YES completion:nil];
}

@end
