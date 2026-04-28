//
//  darkMode.swift
//  ToneDeaf
//
//  Created by Zachary Brunell on 4/26/26.
//

import Foundation
import UIKit

struct darkMode {
    // Stores and retrieves the app-wide dark mode setting using UserDefaults (defaults to true)
    
     static var isDarkMode: Bool {
        get {
            if UserDefaults.standard.object(forKey: "darkMode") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "darkMode")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "darkMode")
        }
    }
}
