// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------


// Project includes
#import "MagnifyingViewController.h"
#import "MagnifyingView.h"
#import "MagnifyingViewModel.h"
#import "UiUtilities.h"
#import "../utility/ExceptionUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for MagnifyingViewController.
// -----------------------------------------------------------------------------
@interface MagnifyingViewController()
@property(nonatomic, assign) MagnifyingViewModel* magnifyingViewModel;
@property(nonatomic, assign) CGSize magnifyingViewSize;
@property(nonatomic, assign) MagnifyingView* magnifyingView;
@property(nonatomic, assign) CGPoint currentMagnificationCenter;
@property(nonatomic, assign) UIView* currentMagnificationCenterView;
@end


@implementation MagnifyingViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes an MagnifyingViewController object.
///
/// @note This is the designated initializer of MagnifyingViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;
  self.magnifyingViewControllerDelegate = nil;
  self.magnifyingViewModel = nil;
  self.magnifyingViewSize = CGSizeZero;
  self.magnifyingView = nil;
  self.currentMagnificationCenter = CGPointZero;
  self.currentMagnificationCenterView = nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this MagnifyingViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.magnifyingViewControllerDelegate = nil;
  self.magnifyingViewModel = nil;
  self.magnifyingView = nil;
  self.currentMagnificationCenterView = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  self.magnifyingViewModel = [self.magnifyingViewControllerDelegate magnifyingViewControllerModel:self];
  self.magnifyingViewSize = CGSizeMake(self.magnifyingViewModel.magnifyingGlassDimension, self.magnifyingViewModel.magnifyingGlassDimension);
  CGRect magnifyingViewFrame = CGRectZero;
  magnifyingViewFrame.size = self.magnifyingViewSize;
  self.magnifyingView = [[[MagnifyingView alloc] initWithFrame:magnifyingViewFrame] autorelease];
  self.view = self.magnifyingView;
  self.view.opaque = NO;
}

#pragma mark - Public API

// -----------------------------------------------------------------------------
/// @brief Grabs the screen content at and around @a magnificationCenter and
/// magnifies it. Also places the magnifying view at a position that is relative
/// to @a magnificationCenter, according to the rules specified in the class
/// documentation. @a view is the view with @a magnificationCenter in its
/// coordinate system.
// -----------------------------------------------------------------------------
- (void) updateMagnificationCenter:(CGPoint)magnificationCenter inView:(UIView*)magnificationCenterView
{
  // floor-ing prevents potential rounding errors and anti-aliasing. Combined
  // with the following check, floor-ing also prevents updates if the
  // magnification center only changed by a fraction.
  CGPoint flooredMagnificationCenter = CGPointMake(floorf(magnificationCenter.x), floorf(magnificationCenter.y));
  // Prevent unnecessary updates
  if (CGPointEqualToPoint(self.currentMagnificationCenter, flooredMagnificationCenter) &&
      self.currentMagnificationCenterView == magnificationCenterView)
  {
    return;
  }
  self.currentMagnificationCenter = flooredMagnificationCenter;
  self.currentMagnificationCenterView = magnificationCenterView;

  // Hide the magnifying view because we don't want to capture the magnifying
  // glass itself
  self.magnifyingView.hidden = YES;

  UIView* superviewOfMagnifyingView = self.view.superview;
  UIView* viewWithContentToMagnify = superviewOfMagnifyingView;
  CGPoint convertedMagnificationCenter = [viewWithContentToMagnify convertPoint:self.currentMagnificationCenter fromView:self.currentMagnificationCenterView];
  // floor-ing prevents potential rounding errors and anti-aliasing
  convertedMagnificationCenter = CGPointMake(floorf(convertedMagnificationCenter.x), floorf(convertedMagnificationCenter.y));
  CGSize sizeToCapture = CGSizeMake(self.magnifyingViewSize.width / self.magnifyingViewModel.magnification,
                                    self.magnifyingViewSize.height / self.magnifyingViewModel.magnification);
  CGRect frameToCapture = CGRectMake(convertedMagnificationCenter.x - (sizeToCapture.width / 2.0f),
                                     convertedMagnificationCenter.y - (sizeToCapture.height / 2.0f),
                                     sizeToCapture.width,
                                     sizeToCapture.height);
  UIImage* capturedImage = [UiUtilities captureFrame:frameToCapture
                                              inView:viewWithContentToMagnify];
  self.magnifyingView.magnifiedImage = capturedImage;

  // Place the magnifying glass above the intersection identified by the
  // specified GoPoint
  CGRect magnifyingViewFrame = self.magnifyingView.frame;
  magnifyingViewFrame.origin.x = convertedMagnificationCenter.x - (magnifyingViewFrame.size.width / 2.0f);
  magnifyingViewFrame.origin.y = convertedMagnificationCenter.y - (magnifyingViewFrame.size.height / 2.0f);
  magnifyingViewFrame.origin.y -= self.magnifyingViewModel.distanceFromMagnificationCenter;
  magnifyingViewFrame = [self magnifyingViewFrameByVeeringAwayFromFrame:magnifyingViewFrame
                                                      inSuperviewBounds:superviewOfMagnifyingView.bounds];
  self.magnifyingView.frame = magnifyingViewFrame;

  // Show the magnifying view again after all updates were made
  self.magnifyingView.hidden = NO;
}

// -----------------------------------------------------------------------------
/// @brief Examines @a magnifyingViewFrame in the context of @a superviewBounds
/// to see whether any veering is required. If no veering is required, returns
/// @a magnifyingViewFrame unchanged. If veering is required, returns a copy of
/// @a magnifyingViewFrame that is modified according to the veering rules
/// specified in the class documentation.
// -----------------------------------------------------------------------------
- (CGRect) magnifyingViewFrameByVeeringAwayFromFrame:(CGRect)magnifyingViewFrame
                                   inSuperviewBounds:(CGRect)superviewBounds
{
  if (magnifyingViewFrame.origin.y >= 0.0f)
    return magnifyingViewFrame;

  CGFloat horizontalVeeringDistance = -magnifyingViewFrame.origin.y;
  magnifyingViewFrame.origin.y = 0.0f;
  switch (self.magnifyingViewModel.veerDirection)
  {
    case MagnifyingGlassVeerDirectionLeft:
    {
      magnifyingViewFrame.origin.x -= horizontalVeeringDistance;
      if (magnifyingViewFrame.origin.x < 0.0f)
      {
        CGFloat verticalVeeringDistance = -magnifyingViewFrame.origin.x;
        magnifyingViewFrame.origin.x = 0.0f;
        magnifyingViewFrame.origin.y += verticalVeeringDistance;
      }
      break;
    }
    case MagnifyingGlassVeerDirectionRight:
    {
      magnifyingViewFrame.origin.x += horizontalVeeringDistance;
      if (CGRectGetMaxX(magnifyingViewFrame) > CGRectGetMaxX(superviewBounds))
      {
        CGFloat verticalVeeringDistance = CGRectGetMaxX(magnifyingViewFrame) - CGRectGetMaxX(superviewBounds);
        magnifyingViewFrame.origin.x -= verticalVeeringDistance;
        magnifyingViewFrame.origin.y += verticalVeeringDistance;
      }
      break;
    }
    default:
    {
      [ExceptionUtility throwNotImplementedException];
      break;
    }
  }
  return magnifyingViewFrame;
}

@end
