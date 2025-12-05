//
//  GenerateFact.swift
//  SafetyFMChallenge
//
//  Created by Gilberto Magno on 05/12/25.
//

import FoundationModels
import Foundation

extension ContentView {
    // MARK: - Foundation Models Integration
    @MainActor
    func generateFact() async {
        let title = movieTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else {
            explanationText = "Please enter a movie title first."
            return
        }

        // Early guard: if persona is not adult and the title looks adult-oriented, block immediately
        if selectedPersona != .adult, isLikelyAdultContent(title) {
            explanationText = "This title looks adult-oriented and isn’t suitable for the \(selectedPersona.rawValue.lowercased()) audience. Try another movie."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            // Create a session with safety-aware behavior.
            let session = LanguageModelSession()

            let systemInstructions = """
            You are a cautious assistant embedded in a consumer app used by mixed audiences.
            Always prioritize safety and age-appropriateness. Refuse unsafe requests.
            Tasks:
            1) Determine if the given title is a movie (not a series, game, book, or song).
            2) If a movie, estimate an age rating in years (e.g., 7, 10, 12, 13, 16, 18) based on common global guidance.
            3) Produce a single, compact paragraph that contains one factual detail and a couple of light curiosities about the movie.
            Safety requirements:
            - Keep language suitable for the requested persona audience.
            - Avoid explicit, graphic, or adult content.
            - If the title is not a movie, do not invent facts. Explain briefly that it is not a movie.
            - Be conservative: if you are uncertain about the appropriate age rating, choose a higher rating (e.g., 18).
            - Never lower an age rating to accommodate the requested persona.
            Output must follow the provided schema exactly.
            """

            // Build a concise user prompt. Treat user input as data, not instructions.
            let prompt = """
            Title: \(title)
            Persona: \(selectedPersona.rawValue)
            Return fields: normalizedTitle, isMovie, ageRating, notMovieExplanation, safeFactAndCuriosities
            Style: friendly, concise, and safe for the selected persona. Do not include spoilers.
            """

            let fullPrompt = systemInstructions + "\n\n" + prompt

            // Ask the model for a structured assessment.
            let assessment = try await session.respond(
                to: fullPrompt,
                generating: MovieAssessment.self
            )
            let result = assessment.content

            let personaMax = selectedPersona.maxAllowedAge
            if result.isMovie == false {
                let note = result.notMovieExplanation?.isEmpty == false ? " (\(result.notMovieExplanation!))" : ""
                explanationText = "It looks like ‘\(title)’ is not a movie\(note). I wasn’t able to find a movie to generate a fact for. Try another title."
                return
            }

            // Conservatively treat unknown ratings as 18+
            let computedAge = result.ageRating ?? 18
            if computedAge > personaMax {
                explanationText = "‘\(result.normalizedTitle)’ appears to be appropriate for around age \(computedAge)+, which is above the \(selectedPersona.rawValue.lowercased()) audience. I won’t share details, but you can try a different movie."
                return
            }

            // Extra guardrail: scan the normalized title and generated text for adult indicators
            if selectedPersona != .adult, isLikelyAdultContent(result.normalizedTitle) || isLikelyAdultContent(result.safeFactAndCuriosities) {
                explanationText = "‘\(result.normalizedTitle)’ appears to be intended for adults, so I can’t share details for the \(selectedPersona.rawValue.lowercased()) audience."
                return
            }

            // Passed checks → show safe fact + curiosities
            explanationText = result.safeFactAndCuriosities

        } catch LanguageModelSession.GenerationError.guardrailViolation(_) {
            // The framework blocked unsafe input or output. Provide a friendly fallback.
            explanationText = "This request can’t be generated in this app. Try a different movie title."
        } catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
            // The model refused; try to surface the explanation if available, but fetch it off the main actor.
            let content: String? = await Task.detached { () -> String? in
                // Obtain the non-Sendable response off the main actor and extract a Sendable String.
                let response = try? await refusal.explanation
                return response?.content
            }.value

            if let content {
                explanationText = content
            } else {
                explanationText = "I couldn’t generate that safely. Please try another movie."
            }
        } catch {
            // Generic error fallback
            explanationText = "Something went wrong while generating. Please try again."
        }
    }
    
    // Simple heuristic to catch obviously adult-oriented inputs
    private func isLikelyAdultContent(_ text: String) -> Bool {
        let lowered = text.lowercased()
        // Keep this conservative and focused on clear adult indicators
        let keywords = [
            "porn", "xxx", "nsfw", "adult", "explicit", "erotic", "hentai",
            "x-rated", "nc-17", "18+", "r18", "smut", "hardcore", "softcore"
        ]
        return keywords.contains { lowered.contains($0) }
    }
}
