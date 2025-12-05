//
//  MovieAssessment.swift
//  SafetyFMChallenge
//
//  Created by Gilberto Magno on 05/12/25.
//

import FoundationModels
import Foundation

@Generable
struct MovieAssessment {
    var normalizedTitle: String
    var isMovie: Bool
    // Age-based content rating in years (e.g., 7, 10, 12, 13, 16, 18)
    var ageRating: Int?
    // If not a movie, explain briefly what it likely is (optional, short)
    var notMovieExplanation: String?
    // A single safe paragraph with a fact and a couple curiosities
    var safeFactAndCuriosities: String
}
