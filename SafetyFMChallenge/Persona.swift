//
//  Persona.swift
//  SafetyFMChallenge
//
//  Created by Gilberto Magno on 05/12/25.
//

enum Persona: String, CaseIterable, Identifiable {
    case child = "Child"
    case teen = "Teenager"
    case adult = "Adult"
    var id: String { rawValue }

    // Define max allowed age rating per persona (inclusive)
    // You can tune these thresholds to your policy.
    var maxAllowedAge: Int {
        switch self {
        case .child: return 12   // block 13+
        case .teen:  return 17   // block 18+
        case .adult: return 99   // effectively no block
        }
    }
}
