// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardViewMetrics.h"
#import "../model/BoardViewModel.h"
#import "../../go/GoBoard.h"
#import "../../go/GoGame.h"
#import "../../go/GoPoint.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/FontRange.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardViewMetrics.
// -----------------------------------------------------------------------------
@interface BoardViewMetrics()
@property(nonatomic, retain) FontRange* moveNumberFontRange;
@property(nonatomic, retain) FontRange* coordinateLabelFontRange;
@property(nonatomic, retain) FontRange* nextMoveLabelFontRange;
@end


@implementation BoardViewMetrics

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardViewMetrics object.
///
/// @note This is the designated initializer of BoardViewMetrics.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;
  [self setupStaticProperties];
  [self setupFontRanges];
  [self setupMainProperties];
  [self setupNotificationResponders];
  // Remaining properties are initialized by this updater
  [self updateWithRect:self.rect boardSize:self.boardSize displayCoordinates:self.displayCoordinates];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this BoardViewMetrics object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [self removeNotificationResponders];
  self.lineRectangles = nil;
  self.lineColor = nil;
  self.starPointColor = nil;
  self.crossHairColor = nil;
  self.moveNumberFontRange = nil;
  self.coordinateLabelFontRange = nil;
  self.nextMoveLabelFontRange = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupStaticProperties
{
  self.contentsScale = [UIScreen mainScreen].scale;
  self.lineColor = [UIColor blackColor];
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    self.boundingLineWidth = 2;
  else
    self.boundingLineWidth = 3;
  self.normalLineWidth = 1;
  self.starPointColor = [UIColor blackColor];
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    self.starPointRadius = 3;
  else
    self.starPointRadius = 5;
  self.stoneRadiusPercentage = 0.9;
  self.crossHairColor = [UIColor blueColor];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupFontRanges
{
  // The minimum should not be smaller: There is no point in displaying text
  // that is so small that nobody can read it. Especially for coordinate labels,
  // it is much better to not display the labels and give the unused space to
  // the grid (on the iPhone and on a 19x19 board, every pixel counts!).
  int minimumFontSize = 8;
  // The maximum could be larger
  int maximumFontSize = 20;

  NSString* widestMoveNumber = @"388";
  self.moveNumberFontRange = [[[FontRange alloc] initWithText:widestMoveNumber
                                              minimumFontSize:minimumFontSize
                                              maximumFontSize:maximumFontSize] autorelease];
  NSString* widestCoordinateLabel = @"18";
  self.coordinateLabelFontRange = [[[FontRange alloc] initWithText:widestCoordinateLabel
                                                   minimumFontSize:minimumFontSize
                                                   maximumFontSize:maximumFontSize] autorelease];
  NSString* widestNextMoveLabel = @"A";
  self.nextMoveLabelFontRange = [[[FontRange alloc] initWithText:widestNextMoveLabel
                                                 minimumFontSize:minimumFontSize
                                                 maximumFontSize:maximumFontSize] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupMainProperties
{
  self.zoomScale = 1.0f;
  self.tileSize = CGSizeMake(128, 128);
  self.rect = CGRectZero;
  self.boardSize = GoBoardSizeUndefined;
  self.displayCoordinates = [ApplicationDelegate sharedDelegate].boardViewModel.displayCoordinates;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupNotificationResponders
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [[ApplicationDelegate sharedDelegate].boardViewModel addObserver:self forKeyPath:@"displayCoordinates" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Private helper.
// -----------------------------------------------------------------------------
- (void) removeNotificationResponders
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [[ApplicationDelegate sharedDelegate].boardViewModel removeObserver:self forKeyPath:@"displayCoordinates"];
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this BoardViewMetrics object based on
/// @a newRect.
// -----------------------------------------------------------------------------
- (void) updateWithRect:(CGRect)newRect
{
  if (CGRectEqualToRect(newRect, self.rect))
    return;
  [self updateWithRect:newRect boardSize:self.boardSize displayCoordinates:self.displayCoordinates];
  // Update properties only after everything has been re-calculated so that KVO
  // observers get the new values
  self.rect = newRect;
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this BoardViewMetrics object based on
/// @a newBoardSize.
// -----------------------------------------------------------------------------
- (void) updateWithBoardSize:(enum GoBoardSize)newBoardSize
{
  if (self.boardSize == newBoardSize)
    return;
  [self updateWithRect:self.rect boardSize:newBoardSize displayCoordinates:self.displayCoordinates];
  // Update properties only after everything has been re-calculated so that KVO
  // observers get the new values
  self.boardSize = newBoardSize;
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this BoardViewMetrics object based on
/// @a newDisplayCoordinates.
// -----------------------------------------------------------------------------
- (void) updateWithDisplayCoordinates:(bool)newDisplayCoordinates
{
  if (self.displayCoordinates == newDisplayCoordinates)
    return;
  [self updateWithRect:self.rect boardSize:self.boardSize displayCoordinates:newDisplayCoordinates];
  // Update properties only after everything has been re-calculated so that KVO
  // observers get the new values
  self.displayCoordinates = newDisplayCoordinates;
}

// todo xxx document
- (void) updateWithZoomScale:(CGFloat)newZoomScale
{
  if (1.0f == newZoomScale)
    return;
  CGRect newRect = self.rect;
  newRect.size.width *= newZoomScale;
  newRect.size.height *= newZoomScale;
  [self updateWithRect:newRect boardSize:self.boardSize displayCoordinates:self.displayCoordinates];
  // Update properties only after everything has been re-calculated so that KVO
  // observers get the new values
  self.rect = newRect;
  // todo xxx also document that self.zoomScale is the absolute zoom scale,
  // while newZoomScale is a relative zoomscale
  self.zoomScale *= newZoomScale;

}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this BoardViewMetrics object based on
/// @a newRect, @a newBoardSize and @a newDisplayCoordinates.
///
/// This is the internal backend for updateWithRect:(), updateWithBoardSize:()
/// and updateWithDisplayCoordinates:().
// -----------------------------------------------------------------------------
- (void) updateWithRect:(CGRect)newRect boardSize:(enum GoBoardSize)newBoardSize displayCoordinates:(bool)newDisplayCoordinates
{
  // ----------------------------------------------------------------------
  // All calculations in this method must use newRect, newBoardSize and
  // newDisplayCoordinates. The corresponding properties self.rect,
  // self.boardSize and self.displayCoordinates must not be used because, due
  // to the way how this update method is invoked, at least one of these
  // properties is guaranteed to be not up-to-date.
  // ----------------------------------------------------------------------

  // The rect is rectangular, but the Go board is square. Examine the rect
  // orientation and use the smaller dimension of the rect as the base for
  // the Go board's side length.
  self.portrait = newRect.size.height >= newRect.size.width;
  int offsetForCenteringX = 0;
  int offsetForCenteringY = 0;
  if (self.portrait)
  {
    self.boardSideLength = floor(newRect.size.width);
    offsetForCenteringY += floor((newRect.size.height - self.boardSideLength) / 2);
  }
  else
  {
    self.boardSideLength = floor(newRect.size.height);
    offsetForCenteringX += floor((newRect.size.width - self.boardSideLength) / 2);
  }

  if (GoBoardSizeUndefined == newBoardSize)
  {
    // Assign hard-coded values and don't rely on calculations that might
    // produce insane results. This also removes the risk of division by zero
    // errors.
    self.boardSideLength = 0;
    self.topLeftBoardCornerX = offsetForCenteringX;
    self.topLeftBoardCornerY = offsetForCenteringY;
    self.coordinateLabelStripWidth = 0;
    self.coordinateLabelInset = 0;
    self.coordinateLabelFont = nil;
    self.coordinateLabelMaximumSize = CGSizeZero;
    self.nextMoveLabelFont = nil;
    self.nextMoveLabelMaximumSize = CGSizeZero;
    self.numberOfCells = 0;
    self.cellWidth = 0;
    self.pointDistance = 0;
    self.stoneRadius = 0;
    self.lineLength = 0;
    self.topLeftPointX = self.topLeftBoardCornerX;
    self.topLeftPointY = self.topLeftBoardCornerY;
    self.bottomRightPointX = self.topLeftPointX;
    self.bottomRightPointY = self.topLeftPointY;
  }
  else
  {
    // When the board is zoomed, the rect usually has a size with fractions.
    // We need the fraction part so that we can make corrections to coordinates
    // that prevent anti-aliasing.
    CGFloat rectWidthFraction = newRect.size.width - floor(newRect.size.width);
    CGFloat rectHeightFraction = newRect.size.height - floor(newRect.size.height);
    // All coordinate calculations are based on topLeftBoardCorner, so if we
    // correct this coordinate, the correction will propagate appropriately.
    // TODO Find out why exactly the fractions need to be added and not
    // subtracted. It has something to do with the origin of the Core Graphics
    // coordinate system (lower-left corner), but I have not thought this
    // through.
    self.topLeftBoardCornerX = offsetForCenteringX + rectWidthFraction;
    self.topLeftBoardCornerY = offsetForCenteringY + rectHeightFraction;

    if (newDisplayCoordinates)
    {
      // The coordinate labels' font size will be selected so that labels fit
      // into the width of the strip that we calculate here. The following
      // simple calculation assumes that to look good, the width of the strip
      // should be about (self.cellWidth / 2). Because we do not yet have
      // self.cellWidth we need to approximate.
      // TODO: The current calculation is too simple and gives us a strip that
      // is wider than necessary, i.e. it will take away more space from
      // self.cellWidth than necessary. A more intelligent approach should find
      // out if a few pixels can be gained for self.cellWidth by choosing a
      // smaller coordinate label font. In the balance, the font size sacrifice
      // must not become too great, for instance the sacrifice would be too
      // great if no font could be found anymore and thus no coordinate labels
      // would be drawn. An algorithm that achieves such a balance would
      // probably need to find its solution in multiple iterations.
      self.coordinateLabelStripWidth = floor(self.boardSideLength / newBoardSize / 2);

      // We want coordinate labels to be drawn with an inset: It just doesn't
      // look good if a coordinate label is drawn right at the screen edge or
      // touches a stone at the board edge.
      static const int coordinateLabelInsetMinimum = 1;
      // If there is sufficient space the inset can grow beyond the minimum.
      // We use a percentage so that the inset grows with the available drawing
      // area. The percentage chosen here is an arbitrary value.
      static const CGFloat coordinateLabelInsetPercentage = 0.05;
      self.coordinateLabelInset = floor(self.coordinateLabelStripWidth * coordinateLabelInsetPercentage);
      if (self.coordinateLabelInset < coordinateLabelInsetMinimum)
        self.coordinateLabelInset = coordinateLabelInsetMinimum;

      // Finally we are able to select a font. We use the largest possible font,
      // but if there isn't one we sacrifice 1 inset point and try again. The
      // idea is that it is better to display coordinate labels and use an inset
      // that is not the desired optimum, than to not display labels at all.
      // coordinateLabelInsetMinimum is still the hard limit, though.
      bool didFindCoordinateLabelFont = false;
      while (! didFindCoordinateLabelFont
             && self.coordinateLabelInset >= coordinateLabelInsetMinimum)
      {
        int coordinateLabelAvailableWidth = (self.coordinateLabelStripWidth
                                             - 2 * self.coordinateLabelInset);
        didFindCoordinateLabelFont = [self.coordinateLabelFontRange queryForWidth:coordinateLabelAvailableWidth
                                                                             font:&_coordinateLabelFont
                                                                         textSize:&_coordinateLabelMaximumSize];
        if (! didFindCoordinateLabelFont)
          self.coordinateLabelInset--;
      }
      if (! didFindCoordinateLabelFont)
      {
        self.coordinateLabelStripWidth = 0;
        self.coordinateLabelInset = 0;
        self.coordinateLabelFont = nil;
        self.coordinateLabelMaximumSize = CGSizeZero;
      }
    }
    else
    {
      self.coordinateLabelStripWidth = 0;
      self.coordinateLabelInset = 0;
      self.coordinateLabelFont = nil;
      self.coordinateLabelMaximumSize = CGSizeZero;
    }

    // Valid values for this constant:
    // 1 = A single coordinate label strip is displayed for each of the axis.
    //     The strips are drawn above and on the left hand side of the board
    // 2 = Two coordinate label strips are displayed for each of the axis. The
    //     strips are drawn on all edges of the board.
    // Note that this constant cannot be set to 0 to disable coordinate labels.
    // The calculations above already achieve this by setting
    // self.coordinateLabelStripWidth to 0.
    //
    // TODO: Currently only one strip is drawn even if this constant is set to
    // the value 2. The only effect that value 2 has is that drawing space is
    // reserved for the second strip.
    static const int numberOfCoordinateLabelStripsPerAxis = 1;

    // For the purpose of calculating the cell width, we assume that all lines
    // have the same thickness. The difference between normal and bounding line
    // width is added to the *OUTSIDE* of the board (see GridLayerDelegate).
    int numberOfPointsAvailableForCells = (self.boardSideLength
                                           - (numberOfCoordinateLabelStripsPerAxis * self.coordinateLabelStripWidth)
                                           - newBoardSize * self.normalLineWidth);
    assert(numberOfPointsAvailableForCells >= 0);
    if (numberOfPointsAvailableForCells < 0)
      DDLogError(@"%@: Negative value %d for numberOfPointsAvailableForCells", self, numberOfPointsAvailableForCells);
    self.numberOfCells = newBoardSize - 1;
    // +1 to self.numberOfCells because we need one-half of a cell on both sides
    // of the board (top/bottom or left/right) to draw, for instance, a stone
    self.cellWidth = floor(numberOfPointsAvailableForCells / (self.numberOfCells + 1));

    self.pointDistance = self.cellWidth + self.normalLineWidth;
    self.stoneRadius = floor(self.cellWidth / 2 * self.stoneRadiusPercentage);
    int pointsUsedForGridLines = ((newBoardSize - 2) * self.normalLineWidth
                                  + 2 * self.boundingLineWidth);
    self.lineLength = pointsUsedForGridLines + self.cellWidth * self.numberOfCells;

    
    // Calculate topLeftPointOffset so that the grid is centered. -1 to
    // newBoardSize because our goal is to get the coordinates of the top-left
    // point, which sits in the middle of a normal line. Because the centering
    // calculation divides by 2 we must subtract a full line width here, not
    // just half a line width.
    int widthForCentering = self.cellWidth * self.numberOfCells + (newBoardSize - 1) * self.normalLineWidth;
    int topLeftPointOffset = floor((self.boardSideLength
                                    - (numberOfCoordinateLabelStripsPerAxis * self.coordinateLabelStripWidth)
                                    - widthForCentering) / 2);
    topLeftPointOffset += self.coordinateLabelStripWidth;
    if (topLeftPointOffset < self.cellWidth / 2.0)
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Insufficient space to draw stones: topLeftPointOffset %d is below half-cell width", topLeftPointOffset];
      DDLogError(@"%@: %@", self, errorMessage);
    }
    self.topLeftPointX = self.topLeftBoardCornerX + topLeftPointOffset;
    self.topLeftPointY = self.topLeftBoardCornerY + topLeftPointOffset;
    self.bottomRightPointX = self.topLeftPointX + (newBoardSize - 1) * self.pointDistance;
    self.bottomRightPointY = self.topLeftPointY + (newBoardSize - 1) * self.pointDistance;

    // Calculate self.pointCellSize. See property documentation for details
    // what we calculate here.
    int pointCellSideLength = self.cellWidth + self.normalLineWidth;
    self.pointCellSize = CGSizeMake(pointCellSideLength, pointCellSideLength);

    // Geometry tells us that for the square with side length "a":
    //   a = r * sqrt(2)
    int stoneInnerSquareSideLength = floor(self.stoneRadius * sqrt(2));
    // Subtract an additional 1-2 points because we don't want to touch the
    // stone border. The square side length must be an odd number to prevent
    // anti-aliasing when the square is drawn (we assume that drawing occurs
    // with boardViewModel.normalLineWidth and that the line width is an odd
    // number (typically 1 point)).
    --stoneInnerSquareSideLength;
    if (stoneInnerSquareSideLength % 2 == 0)
      --stoneInnerSquareSideLength;
    self.stoneInnerSquareSize = CGSizeMake(stoneInnerSquareSideLength, stoneInnerSquareSideLength);

    // Schema depicting the horizontal bounding line at the top of the board:
    //
    //       +----------->  +------------------------- startB
    //       |              |
    //       |              |
    //       |              |
    // widthB|              | ------------------------ strokeB
    //       |              |
    //       |        +-->  |   +--------------------- startN
    //       |  widthN|     |   | -------------------- strokeN
    //       +----->  +-->  +-- +---------------------
    //
    // widthN = width normal line
    // widthB = width bounding line
    // startN = start coordinate for normal line
    // startB = start coordinate for bounding line
    // strokeN = stroke coordinate for normal line, also self.topLeftPointY
    // strokeB = stroke coordinate for bounding line
    //
    // Notice how the lower edge of the bounding line is flush with the lower
    // edge of the normal line (it were drawn here). The calculation for
    // strokeB goes like this:
    //       strokeB = strokeN + widthN/2 - widthB/2
    //
    // Based on this, the calculation for startB looks like this:
    //       startB = strokeB - widthB / 2
    int normalLineStrokeCoordinate = self.topLeftPointY;
    CGFloat normalLineHalfWidth = self.normalLineWidth / 2.0;
    CGFloat boundingLineHalfWidth = self.boundingLineWidth / 2.0;
    CGFloat boundingLineStrokeCoordinate = normalLineStrokeCoordinate + normalLineHalfWidth - boundingLineHalfWidth;
    self.boundingLineStrokeOffset = normalLineStrokeCoordinate - boundingLineStrokeCoordinate;
    CGFloat boundingLineStartCoordinate = boundingLineStrokeCoordinate - boundingLineHalfWidth;
    self.lineStartOffset = normalLineStrokeCoordinate - boundingLineStartCoordinate;

    bool success = [self.moveNumberFontRange queryForWidth:self.stoneInnerSquareSize.width
                                                      font:&_moveNumberFont
                                                  textSize:&_moveNumberMaximumSize];
    if (! success)
    {
      self.moveNumberFont = nil;
      self.moveNumberMaximumSize = CGSizeZero;
    }

    success = [self.nextMoveLabelFontRange queryForWidth:self.stoneInnerSquareSize.width
                                                    font:&_nextMoveLabelFont
                                                textSize:&_nextMoveLabelMaximumSize];
    if (! success)
    {
      self.nextMoveLabelFont = nil;
      self.nextMoveLabelMaximumSize = CGSizeZero;
    }

    self.lineRectangles = [self calculateLineRectanglesWithBoardSize:newBoardSize];
  }  // else [if (GoBoardSizeUndefined == newBoardSize)]
}

// -----------------------------------------------------------------------------
/// @brief Returns view coordinates that correspond to the intersection
/// @a point.
///
/// The origin of the coordinate system is assumed to be in the top-left corner.
///
/// @overload This overload uses self.boardSize.
// -----------------------------------------------------------------------------
- (CGPoint) coordinatesFromPoint:(GoPoint*)point
{
  return [self coordinatesFromPoint:point withBoardSize:self.boardSize];
}

// -----------------------------------------------------------------------------
/// @brief Returns view coordinates that correspond to the intersection
/// @a point on a board with size @a boardSize.
///
/// The origin of the coordinate system is assumed to be in the top-left corner.
///
/// @overload This overload does not use self.boardSize, so it can be called at
/// those times when the property does not (yet) have its correct value. This
/// is specifically useful while updateWithRect:boardSize:displayCoordinates:()
/// is still running.
// -----------------------------------------------------------------------------
- (CGPoint) coordinatesFromPoint:(GoPoint*)point withBoardSize:(enum GoBoardSize)boardSize
{
  struct GoVertexNumeric numericVertex = point.vertex.numeric;
  return CGPointMake(self.topLeftPointX + (self.pointDistance * (numericVertex.x - 1)),
                     self.topLeftPointY + (self.pointDistance * (boardSize - numericVertex.y)));
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoPoint object for the intersection identified by the view
/// coordinates @a coordinates.
///
/// Returns nil if @a coordinates do not refer to a valid intersection (e.g.
/// because @a coordinates are outside the board's edges).
///
/// The origin of the coordinate system is assumed to be in the top-left corner.
// -----------------------------------------------------------------------------
- (GoPoint*) pointFromCoordinates:(CGPoint)coordinates
{
  struct GoVertexNumeric numericVertex;
  numericVertex.x = 1 + (coordinates.x - self.topLeftPointX) / self.pointDistance;
  numericVertex.y = self.boardSize - (coordinates.y - self.topLeftPointY) / self.pointDistance;
  GoVertex* vertex;
  @try
  {
    vertex = [GoVertex vertexFromNumeric:numericVertex];
  }
  @catch (NSException* exception)
  {
    return nil;
  }
  return [[GoGame sharedGame].board pointAtVertex:vertex.string];
}

// -----------------------------------------------------------------------------
/// @brief Returns a BoardViewIntersection object for the intersection that is
/// closest to the view coordinates @a coordinates. Returns
/// BoardViewIntersectionNull if there is no "closest" intersection.
///
/// Determining "closest" works like this:
/// - The closest intersection is the one whose distance to @a coordinates is
///   less than half the distance between two adjacent intersections
///   - During panning this creates a "snap-to" effect when the user's panning
///     fingertip crosses half the distance between two adjacent intersections.
///   - For a tap this simply makes sure that the fingertip does not have to
///     hit the exact coordinate of the intersection.
/// - If @a coordinates are a sufficient distance away from the Go board edges,
///   there is no "closest" intersection
// -----------------------------------------------------------------------------
- (BoardViewIntersection) intersectionNear:(CGPoint)coordinates
{
  int halfPointDistance = floor(self.pointDistance / 2);
  bool coordinatesOutOfRange = false;

  // Check if coordinates are outside the grid on the x-axis and cannot be
  // mapped to a point. To make the edge lines accessible in the same way as
  // the inner lines, a padding of half a point distance must be added.
  if (coordinates.x < self.topLeftPointX)
  {
    if (coordinates.x < self.topLeftPointX - halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.x = self.topLeftPointX;
  }
  else if (coordinates.x > self.bottomRightPointX)
  {
    if (coordinates.x > self.bottomRightPointX + halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.x = self.bottomRightPointX;
  }
  else
  {
    // Adjust so that the snap-to calculation below switches to the next vertex
    // when the coordinates are half-way through the distance to that vertex
    coordinates.x += halfPointDistance;
  }

  // Unless the x-axis checks have already found the coordinates to be out of
  // range, we now perform the same checks as above on the y-axis
  if (coordinatesOutOfRange)
  {
    // Coordinates are already out of range, no more checks necessary
  }
  else if (coordinates.y < self.topLeftPointY)
  {
    if (coordinates.y < self.topLeftPointY - halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.y = self.topLeftPointY;
  }
  else if (coordinates.y > self.bottomRightPointY)
  {
    if (coordinates.y > self.bottomRightPointY + halfPointDistance)
      coordinatesOutOfRange = true;
    else
      coordinates.y = self.bottomRightPointY;
  }
  else
  {
    coordinates.y += halfPointDistance;
  }

  // Snap to the nearest vertex, unless the coordinates were out of range
  if (coordinatesOutOfRange)
    return BoardViewIntersectionNull;
  else
  {
    coordinates.x = (self.topLeftPointX
                     + self.pointDistance * floor((coordinates.x - self.topLeftPointX) / self.pointDistance));
    coordinates.y = (self.topLeftPointY
                     + self.pointDistance * floor((coordinates.y - self.topLeftPointY) / self.pointDistance));
    GoPoint* pointAtCoordinates = [self pointFromCoordinates:coordinates];
    if (pointAtCoordinates)
    {
      return BoardViewIntersectionMake(pointAtCoordinates, coordinates);
    }
    else
    {
      DDLogError(@"Snap-to calculation failed");
      return BoardViewIntersectionNull;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameDidCreate notification.
// -----------------------------------------------------------------------------
- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  [self updateWithBoardSize:newGame.board.size];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  if ([keyPath isEqualToString:@"displayCoordinates"])
  {
    BoardViewModel* model = (BoardViewModel*)object;
    [self updateWithDisplayCoordinates:model.displayCoordinates];
  }
}

// -----------------------------------------------------------------------------
/// @brief Calculates a list of rectangles that together make up all grid lines
/// on the board.
///
/// This is a private helper for updateWithRect:boardSize:displayCoordinates:().
/// The implementation of this helper must not use any of the main properties
/// (self.rect, self.boardSize or self.displayCoordinates) for its calculations
/// because these properties do not yet have the correct values.
// -----------------------------------------------------------------------------
- (NSArray*) calculateLineRectanglesWithBoardSize:(enum GoBoardSize)newBoardSize
{
  NSMutableArray* lineRectangles = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];
  GoPoint* topLeftPoint = [[GoGame sharedGame].board topLeftPoint];

  for (int lineDirection = 0; lineDirection < 2; ++lineDirection)
  {
    bool isHorizontalLine = (0 == lineDirection) ? true : false;
    GoPoint* previousPoint = nil;
    GoPoint* currentPoint = topLeftPoint;
    while (currentPoint)
    {
      GoPoint* nextPoint;
      if (isHorizontalLine)
        nextPoint = currentPoint.below;
      else
        nextPoint = currentPoint.right;
      CGPoint pointCoordinates = [self coordinatesFromPoint:currentPoint
                                              withBoardSize:newBoardSize];

      int lineWidth;
      bool isBoundingLine = (nil == previousPoint || nil == nextPoint);
      if (isBoundingLine)
        lineWidth = self.boundingLineWidth;
      else
        lineWidth = self.normalLineWidth;
      CGFloat lineHalfWidth = lineWidth / 2.0f;

      struct GoVertexNumeric numericVertex = currentPoint.vertex.numeric;
      int lineIndexCountingFromTopLeft;
      if (isHorizontalLine)
        lineIndexCountingFromTopLeft = newBoardSize - numericVertex.y;
      else
        lineIndexCountingFromTopLeft = numericVertex.x - 1;
      bool isBoundingLineLeftOrTop = (0 == lineIndexCountingFromTopLeft);
      bool isBoundingLineRightOrBottom = ((newBoardSize - 1) == lineIndexCountingFromTopLeft);

      CGRect lineRect;
      if (isHorizontalLine)
      {
        // 1. Determine the rectangle size. Everything below this deals with
        // the rectangle origin.
        lineRect.size = CGSizeMake(self.lineLength, lineWidth);
        // 2. Place line so that its upper-left corner is at the y-position of
        // the specified intersection
        lineRect.origin.x = self.topLeftPointX;
        lineRect.origin.y = pointCoordinates.y;
        // 3. Place line so that it straddles the y-position of the specified
        // intersection
        lineRect.origin.y -= lineHalfWidth;
        // 4. If it's a bounding line, adjust the line position so that its edge
        // is in the same position as if a normal line were drawn. The surplus
        // width lies outside of the board. As a result, all cells inside the
        // board have the same size.
        if (isBoundingLineLeftOrTop)
          lineRect.origin.y -= self.boundingLineStrokeOffset;
        else if (isBoundingLineRightOrBottom)
          lineRect.origin.y += self.boundingLineStrokeOffset;
        // 5. Adjust horizontal line position so that it starts at the left edge
        // of the left bounding line
        lineRect.origin.x -= self.lineStartOffset;
      }
      else
      {
        // The if-branch above that deals with horizontal lines has more
        // detailed comments.

        // 1. Rectangle size
        lineRect.size = CGSizeMake(lineWidth, self.lineLength);
        // 2. Initial rectangle origin
        lineRect.origin.x = pointCoordinates.x;
        lineRect.origin.y = self.topLeftPointY;
        // 3. Straddle intersection
        lineRect.origin.x -= lineHalfWidth;
        // 4. Position bounding lines
        if (isBoundingLineLeftOrTop)
          lineRect.origin.x -= self.boundingLineStrokeOffset;
        else if (isBoundingLineRightOrBottom)
          lineRect.origin.x += self.boundingLineStrokeOffset;
        // 5. Adjust vertical line position
        lineRect.origin.y -= self.lineStartOffset;
        // Shift all vertical lines 1 point to the right. This is what I call
        // "the mystery point" - I couldn't come up with a satisfactory
        // explanation why this is needed even after hours of geometric drawings
        // and manual calculations. Very unsatisfactory :-(
        // TODO xxx It appears that this is no longer necessary. If this is
        // true, then close the corresponding GitHub issue. The reason probably
        // is connected with the CTM rotation that we did in the old drawing
        // mechanism.
        //lineRect.origin.x += 1;
      }

      [lineRectangles addObject:[NSValue valueWithCGRect:lineRect]];

      previousPoint = currentPoint;
      currentPoint = nextPoint;
    }
  }

  return lineRectangles;
}

@end
