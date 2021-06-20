//
//  DetailVCViewController.swift
//  BackgroundTask
//
//  Created by Boss on 19/06/2021.
//

import UIKit

class DetailVCViewController: UIViewController {
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    var viewModel: DetailVCViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerNotificationCenter()
    }
    
    fileprivate func registerNotificationCenter() {
        
        EventBus.addListener(about: .reloadActiveStop) { [weak self] (notification) in
//            self?.viewModel?.fetchActiveTripIfNeed()
        }
        
        let notiCenter = NotificationCenter.default
        notiCenter
            .addObserver(self,
                         selector: #selector(locationUpdate(notification:)),
                         name: Notification.Name(EventBus.Event.updateLocation.rawValue),
                         object: nil)
        
        notiCenter
            .addObserver(self,
                         selector: #selector(registerBackgroundTask),
                         name: UIApplication.didBecomeActiveNotification,
                         object: nil)
    }
    
    @objc func registerBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        assert(backgroundTask != .invalid)
    }
    
    func endBackgroundTask() {
        print("Background task ended.")
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
    
    @objc fileprivate func locationUpdate(notification: NSNotification) {
    }
    
}
