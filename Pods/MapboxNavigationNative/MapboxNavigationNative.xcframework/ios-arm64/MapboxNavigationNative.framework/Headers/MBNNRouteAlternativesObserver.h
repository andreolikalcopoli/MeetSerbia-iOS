// This file is generated and will be overwritten automatically.

#import <Foundation/Foundation.h>

@class MBNNRouteAlternative;
@protocol MBNNRouteInterface;

NS_SWIFT_NAME(RouteAlternativesObserver)
@protocol MBNNRouteAlternativesObserver
/**
 * This callback is invoked when controller get alternatives from router that changed from alternatives from last callback
 *  or if we pass some route and fork point became behind us.
 *  Discarded routes are not considered by comparison (see @return)
 *  This callback will be invoked after setting new routes to the navigator.
 *  Callback will be invoked with empty array if a single route has been passed to the navigator.
 *  If no alternatives (All alternatives have been passed or router has returned only main route) callback will be invoked with empty array.
 *  @param  routeAlternatives new list of alternative routes. This is a full list with all alternatives except the manually deleted ones, using the returned array.
 *  @param  removed list of removed alternatives. These can be alternatives that have passed or alternatives that are no longer provided by the router.
 */
- (void)onRouteAlternativesChangedForRouteAlternatives:(nonnull NSArray<MBNNRouteAlternative *> *)routeAlternatives
                                               removed:(nonnull NSArray<MBNNRouteAlternative *> *)removed;
/**
 *  This callback is invoked when current primary route has `Onboard` origin, and some incoming route is a sub-route of the primary route and it has `Online` origin.
 *  @param onlinePrimaryRoute  new incoming route, that has `Online` origin and is a sub-route of primary route.
 */
- (void)onOnlinePrimaryRouteAvailableForOnlinePrimaryRoute:(nonnull id<MBNNRouteInterface>)onlinePrimaryRoute;
/** This callback is invoked when an error occurs. */
- (void)onErrorForMessage:(nonnull NSString *)message;
@end
