// SceneDelegate.m
#import "SceneDelegate.h"
#import "ProbeViewController.h"

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
  if (!scene) return;

  UIWindowScene *windowScene = (UIWindowScene *)scene;
  self.window = [[UIWindow alloc] initWithWindowScene:windowScene];

  ProbeViewController *vc = [[ProbeViewController alloc] init];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];

  self.window.rootViewController = nav;
  [self.window makeKeyAndVisible];
}

@end
