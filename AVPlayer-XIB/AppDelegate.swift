//
//  AppDelegate.swift
//  AVPlayer-XIB
//
//  Created by 홍승표 on 11/5/25.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // A를 rootViewController로 설정
        let aVC = PasscodeLockViewController(nibName: "PasscodeLockViewController", bundle: nil)
        // 윈도우 생성
        window = UIWindow(frame: UIScreen.main.bounds)
        // 윈도우 rootViewController 설정
        window?.rootViewController = aVC         
        // 윈도우 표시
        window?.makeKeyAndVisible()
        return true
    }
    
}
