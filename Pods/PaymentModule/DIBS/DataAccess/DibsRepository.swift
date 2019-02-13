//
//  DibsRepository.swift
//  Mobilbillet
//
//  Created by Linar Chabibulin on 28/08/2017.
//  Copyright © 2017 Kofoed & Co. All rights reserved.
//

import Foundation

class DibsRepository {

    // MARK: - user default keys
    static let hasEnterCVCPromptShownKey = "hasEnterCVCPromptShown"
    
    // Specifies whether "Enter CVC number" prompt has been shown on the top of the DIBS payment window
    static var hasEnterCVCPromptShown: Bool {
        get {
            return UserDefaults.standard.bool(forKey: hasEnterCVCPromptShownKey)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: hasEnterCVCPromptShownKey)
            UserDefaults.standard.synchronize();
        }
    }
}
