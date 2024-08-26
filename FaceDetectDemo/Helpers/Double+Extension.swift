//
//  Double+Extension.swift
//  FaceDetectDemo
//
//  Created by netzwelt on 20/08/24.
//

import Foundation

extension Float {
    func formatDecimal() -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.roundingMode = .down

        let numberOfDigits = floor(log10(abs(self))) + 1
        if numberOfDigits < 3 {
            formatter.maximumFractionDigits = 1
        } else {
            formatter.maximumFractionDigits = 0
        }

        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
