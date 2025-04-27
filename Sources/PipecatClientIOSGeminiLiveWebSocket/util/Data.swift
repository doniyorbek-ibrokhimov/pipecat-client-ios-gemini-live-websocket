//
//  Data.swift
//  VisionFit
//
//  Created by Doniyorbek Ibrokhimov on 27/04/25.
//

import Foundation

public extension Data {
    func printPrettyJSON() {
        do {
            if let json = try JSONSerialization.jsonObject(with: self, options: []) as? [String: Any] {
                let prettyData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                if let prettyString = String(data: prettyData, encoding: .utf8) {
                    print("Received JSON: \(prettyString)")
                }
            }
        } catch {
            print("Failed to parse JSON: \(error.localizedDescription)")
        }
    }
}
