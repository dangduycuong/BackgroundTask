//
//  EventBus.swift
//  BackgroundTask
//
//  Created by Boss on 19/06/2021.
//

import UIKit

class EventBus: NSObject {
    enum Event: String {
        case locationOff = "locationOff"
        case locationOn = "locationOn"
        case sessionInvalid = "sessionInvalid"
        case newActiveTrip =  "NEW_ACTIVE_TRIP"
        case newScheduleTrip = "NEW_SCHEDULE_TRIP"
        case updateLocation = "updateLocation"
        case reloadTrip = "reloadtrip"
        case reloadActiveStop = "reloadActiveStop"
        case updateSpeed = "updateSpeed"
        case newTrip = "newTrip"
        case removeTrip = "removeTrip"
        case updateTrip = "updateTrip"
        case reloadLoad = "reloadLoad"
    }
    
    static func post(_ key: Event) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: key.rawValue), object: nil, userInfo: nil)
    }
    
    static func post(_ key: Event, userInfo: [ AnyHashable: Any]) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: key.rawValue), object: nil, userInfo: userInfo)
    }
    
    static func post(forKey key: String) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: key), object: nil, userInfo: nil)
    }
    
    static func post(forKey key: String, userInfo: [ AnyHashable: Any]) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: key), object: nil, userInfo: userInfo)
    }
    
    static func addListener(about: Event, didReceive:@escaping (Notification) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: about.rawValue),
            object: nil,
            queue: OperationQueue.main,
            using: didReceive)
    }
    
    static func removeListener(observer: Any, about: Event) {
        NotificationCenter.default.removeObserver(observer, name: NSNotification.Name(rawValue: about.rawValue), object: nil)
    }
    
    static func addListener(for key: String, didReceive:@escaping (Notification) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: key),
            object: nil,
            queue: OperationQueue.main,
            using: didReceive)
    }
    
    
}

