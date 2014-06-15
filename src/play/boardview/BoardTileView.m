// -----------------------------------------------------------------------------
// Copyright 2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "BoardTileView.h"
#import "layer/CoordinatesLayerDelegate.h"
#import "layer/CrossHairLinesLayerDelegate.h"
#import "layer/CrossHairStoneLayerDelegate.h"
#import "layer/GridLayerDelegate.h"
#import "layer/InfluenceLayerDelegate.h"
#import "layer/StarPointsLayerDelegate.h"
#import "layer/StonesLayerDelegate.h"
#import "layer/StoneGroupStateLayerDelegate.h"
#import "layer/SymbolsLayerDelegate.h"
#import "layer/TerritoryLayerDelegate.h"
#import "../model/PlayViewMetrics.h"
#import "../../go/GoGame.h"
#import "../../go/GoScore.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/LongRunningActionCounter.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for BoardTileView.
// -----------------------------------------------------------------------------
@interface BoardTileView()
@property(nonatomic, assign) bool drawLayersWasDelayed;
@property(nonatomic, retain) NSMutableArray* layerDelegates;
//@}
@end


@implementation BoardTileView

// -----------------------------------------------------------------------------
/// @brief Initializes a BoardView object with frame rectangle @a rect.
///
/// @note This is the designated initializer of BoardView.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)rect
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:rect];
  if (! self)
    return nil;

  self.row = -1;
  self.column = -1;
  self.layerDelegates = [[[NSMutableArray alloc] initWithCapacity:0] autorelease];

  self.drawLayersWasDelayed = false;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  PlayViewMetrics* metrics = appDelegate.playViewMetrics;
  PlayViewModel* playViewModel = appDelegate.playViewModel;
  BoardPositionModel* boardPositionModel = appDelegate.boardPositionModel;
  ScoringModel* scoringModel = appDelegate.scoringModel;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameDidCreate:) name:goGameDidCreate object:nil];
  [center addObserver:self selector:@selector(goScoreScoringEnabled:) name:goScoreScoringEnabled object:nil];
  [center addObserver:self selector:@selector(goScoreScoringDisabled:) name:goScoreScoringDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  [center addObserver:self selector:@selector(territoryStatisticsChanged:) name:territoryStatisticsChanged object:nil];
  [center addObserver:self selector:@selector(longRunningActionEnds:) name:longRunningActionEnds object:nil];
  // KVO observing
  [boardPositionModel addObserver:self forKeyPath:@"markNextMove" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"rect" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"boardSize" options:0 context:NULL];
  [metrics addObserver:self forKeyPath:@"displayCoordinates" options:0 context:NULL];
  [playViewModel addObserver:self forKeyPath:@"markLastMove" options:0 context:NULL];
  [playViewModel addObserver:self forKeyPath:@"moveNumbersPercentage" options:0 context:NULL];
  [playViewModel addObserver:self forKeyPath:@"stoneDistanceFromFingertip" options:0 context:NULL];
  [scoringModel addObserver:self forKeyPath:@"inconsistentTerritoryMarkupType" options:0 context:NULL];
  GoGame* game = [GoGame sharedGame];
  if (game)
  {
    GoBoardPosition* boardPosition = game.boardPosition;
    [boardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
    [boardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
  }

  id<BoardViewLayerDelegate> layerDelegate;
  layerDelegate = [[[BVGridLayerDelegate alloc] initWithTileView:self
                                                         metrics:metrics] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVStarPointsLayerDelegate alloc] initWithTileView:self
                                                               metrics:metrics] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVCrossHairLinesLayerDelegate alloc] initWithTileView:self
                                                                   metrics:metrics] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVStonesLayerDelegate alloc] initWithTileView:self
                                                           metrics:metrics] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVCrossHairStoneLayerDelegate alloc] initWithTileView:self
                                                                   metrics:metrics] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVInfluenceLayerDelegate alloc] initWithTileView:self
                                                              metrics:metrics
                                                        playViewModel:playViewModel] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVSymbolsLayerDelegate alloc] initWithTileView:self
                                                            metrics:metrics
                                                      playViewModel:playViewModel
                                                 boardPositionModel:boardPositionModel] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVTerritoryLayerDelegate alloc] initWithTileView:self
                                                              metrics:metrics
                                                         scoringModel:scoringModel] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVStoneGroupStateLayerDelegate alloc] initWithTileView:self
                                                                    metrics:metrics
                                                               scoringModel:scoringModel] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVCoordinatesLayerDelegate alloc] initWithTileView:self
                                                                metrics:metrics
                                                                   axis:CoordinateLabelAxisLetter] autorelease];
  [self.layerDelegates addObject:layerDelegate];
  layerDelegate = [[[BVCoordinatesLayerDelegate alloc] initWithTileView:self
                                                                metrics:metrics
                                                                   axis:CoordinateLabelAxisNumber] autorelease];
  [self.layerDelegates addObject:layerDelegate];

  return self;
}


- (void) dealloc
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  PlayViewMetrics* metrics = appDelegate.playViewMetrics;
  PlayViewModel* playViewModel = appDelegate.playViewModel;
  BoardPositionModel* boardPositionModel = appDelegate.boardPositionModel;
  ScoringModel* scoringModel = appDelegate.scoringModel;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center removeObserver:self];
  [boardPositionModel removeObserver:self forKeyPath:@"markNextMove"];
  [metrics removeObserver:self forKeyPath:@"rect"];
  [metrics removeObserver:self forKeyPath:@"boardSize"];
  [metrics removeObserver:self forKeyPath:@"displayCoordinates"];
  [playViewModel removeObserver:self forKeyPath:@"markLastMove"];
  [playViewModel removeObserver:self forKeyPath:@"moveNumbersPercentage"];
  [playViewModel removeObserver:self forKeyPath:@"stoneDistanceFromFingertip"];
  [scoringModel removeObserver:self forKeyPath:@"inconsistentTerritoryMarkupType"];
  GoBoardPosition* boardPosition = [GoGame sharedGame].boardPosition;
  [boardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [boardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];

  self.layerDelegates = nil;
  [super dealloc];
}

- (void) setRow:(int)row
{
  _row = row;

}

- (void) delayedDrawLayers
{
  if ([LongRunningActionCounter sharedCounter].counter > 0)
    self.drawLayersWasDelayed = true;
  else
    [self drawLayers];
}


- (void) drawLayers
{
  // No game -> no board -> no drawing. This situation exists right after the
  // application has launched and the initial game is created only after a
  // small delay.
  if (! [GoGame sharedGame])
    return;
  self.drawLayersWasDelayed = false;

  // Draw layers in the order in which they appear in the layerDelegates array
  for (id<BoardViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate drawLayer];
}

- (void) notifyLayerDelegates:(enum BoardViewLayerDelegateEvent)event eventInfo:(id)eventInfo
{
  for (id<BoardViewLayerDelegate> layerDelegate in self.layerDelegates)
    [layerDelegate notify:event eventInfo:eventInfo];
}

- (void) goGameWillCreate:(NSNotification*)notification
{
  GoGame* oldGame = [notification object];
  GoBoardPosition* oldBoardPosition = oldGame.boardPosition;
  [oldBoardPosition removeObserver:self forKeyPath:@"currentBoardPosition"];
  [oldBoardPosition removeObserver:self forKeyPath:@"numberOfBoardPositions"];
}

- (void) goGameDidCreate:(NSNotification*)notification
{
  GoGame* newGame = [notification object];
  GoBoardPosition* newBoardPosition = newGame.boardPosition;
  [newBoardPosition addObserver:self forKeyPath:@"currentBoardPosition" options:0 context:NULL];
  [newBoardPosition addObserver:self forKeyPath:@"numberOfBoardPositions" options:0 context:NULL];
  [self notifyLayerDelegates:BVLDEventGoGameStarted eventInfo:nil];
  // todo xxx we should not need that, but layer delegates still rely on it
  [self notifyLayerDelegates:BVLDEventRectangleChanged eventInfo:nil];
  [self delayedDrawLayers];
}

- (void) goScoreScoringEnabled:(NSNotification*)notification
{
  [self notifyLayerDelegates:BVLDEventScoringModeEnabled eventInfo:nil];
  [self delayedDrawLayers];
}

- (void) goScoreScoringDisabled:(NSNotification*)notification
{
  [self notifyLayerDelegates:BVLDEventScoringModeDisabled eventInfo:nil];
  [self delayedDrawLayers];
}

- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  [self notifyLayerDelegates:BVLDEventScoreCalculationEnds eventInfo:nil];
  [self delayedDrawLayers];
}

- (void) territoryStatisticsChanged:(NSNotification*)notification
{
  [self notifyLayerDelegates:BVLDEventTerritoryStatisticsChanged eventInfo:nil];
  [self delayedDrawLayers];
}

- (void) longRunningActionEnds:(NSNotification*)notification
{
  if (self.drawLayersWasDelayed)
    [self drawLayers];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  PlayViewMetrics* metrics = appDelegate.playViewMetrics;
  PlayViewModel* playViewModel = appDelegate.playViewModel;
  BoardPositionModel* boardPositionModel = appDelegate.boardPositionModel;
  ScoringModel* scoringModel = appDelegate.scoringModel;

  if (object == scoringModel)
  {
    if ([keyPath isEqualToString:@"inconsistentTerritoryMarkupType"])
    {
      if ([GoGame sharedGame].score.scoringEnabled)
      {
        [self notifyLayerDelegates:BVLDEventInconsistentTerritoryMarkupTypeChanged eventInfo:nil];
        [self delayedDrawLayers];
      }
    }
  }
  else if (object == boardPositionModel)
  {
    if ([keyPath isEqualToString:@"markNextMove"])
    {
      [self notifyLayerDelegates:BVLDEventMarkNextMoveChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
  }
  else if (object == metrics)
  {
    if ([keyPath isEqualToString:@"rect"])
    {
      // Notify Auto Layout that our intrinsic size changed. This provokes a
      // frame change.
      [self invalidateIntrinsicContentSize];
      [self notifyLayerDelegates:BVLDEventRectangleChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
    else if ([keyPath isEqualToString:@"boardSize"])
    {
      [self notifyLayerDelegates:BVLDEventBoardSizeChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
    else if ([keyPath isEqualToString:@"displayCoordinates"])
    {
      [self notifyLayerDelegates:BVLDEventDisplayCoordinatesChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
  }
  else if (object == playViewModel)
  {
    if ([keyPath isEqualToString:@"markLastMove"])
    {
      [self notifyLayerDelegates:BVLDEventMarkLastMoveChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
    else if ([keyPath isEqualToString:@"moveNumbersPercentage"])
    {
      [self notifyLayerDelegates:BVLDEventMoveNumbersPercentageChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
/*xxx
    else if ([keyPath isEqualToString:@"stoneDistanceFromFingertip"])
      [self updateCrossHairPointDistanceFromFinger];
*/ 
  }
  else if (object == [GoGame sharedGame].boardPosition)
  {
    if ([keyPath isEqualToString:@"currentBoardPosition"])
    {
      [self notifyLayerDelegates:BVLDEventBoardPositionChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
    else if ([keyPath isEqualToString:@"numberOfBoardPositions"])
    {
      [self notifyLayerDelegates:BVLDEventNumberOfBoardPositionsChanged eventInfo:nil];
      [self delayedDrawLayers];
    }
  }
}

- (void) redraw
{
  [self notifyLayerDelegates:BVLDEventRectangleChanged eventInfo:nil];
  [self delayedDrawLayers];
}

@end
