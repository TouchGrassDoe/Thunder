//
//  Achievement.swift
//  Thunder
//
//  Created by Aaron Doe on 13/10/2024.
//

import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    var description: String
    var icon: String
    let time: Date
}
