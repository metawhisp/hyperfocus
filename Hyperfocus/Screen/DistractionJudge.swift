// DistractionJudge.swift — on-device context judge for the Distraction Radar (canon #35).
//
// The keyword prefilter is literal: a "youtube" hit says nothing about WHY it is on screen.
// When Apple Intelligence is available (macOS 26+, enabled by the user), the built-in
// on-device model gets the mission and an excerpt of the recognized screen text and decides
// whether the user is actually off-mission. Nothing leaves the Mac; on any error or when the
// model is unavailable the judge sides with the prefilter (nudge fires — current behavior).

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

final class DistractionJudge {
    /// True when the built-in model can actually answer (framework + Apple Intelligence on).
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    /// Calls back on the main thread: true = genuinely distracted, false = the screen serves
    /// the mission. Tiered by what THIS Mac can do (the app must serve every Mac, not just
    /// Apple Intelligence ones): built-in LLM when available, otherwise a language-agnostic
    /// lexical relevance check that runs everywhere down to Intel + macOS 15.
    func isDistracted(mission: String, matchedTerm: String, screenLines: [String],
                      completion: @escaping (Bool) -> Void) {
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *),
           case .available = SystemLanguageModel.default.availability {
            Task {
                let verdict = await Self.ask(mission: mission, matchedTerm: matchedTerm,
                                             screenLines: screenLines)
                await MainActor.run { completion(verdict) }
            }
            return
        }
        #endif
        let onMission = Self.lexicalOnMission(mission: mission, screenLines: screenLines)
        NSLog("HFJUDGE(lexical) term=%@ verdict=%@", matchedTerm,
              onMission ? "ON-MISSION" : "DISTRACTED")
        DispatchQueue.main.async { completion(!onMission) }
    }

    /// Universal tier: do the mission's own words appear in the recognized screen text?
    /// Prefix matching (first 5 chars of tokens ≥4 chars) absorbs RU/EN inflections without
    /// any ML — "отчёт" connects to "отчёта", "video" to "videos". Two hits (or every mission
    /// token for short missions) reads as on-mission; anything less sides with the keyword hit.
    static func lexicalOnMission(mission: String, screenLines: [String]) -> Bool {
        let separators = CharacterSet.alphanumerics.inverted
        let tokens = mission.lowercased()
            .components(separatedBy: separators)
            .filter { $0.count >= 4 }
        guard !tokens.isEmpty else { return false }
        let screen = screenLines.joined(separator: " ").lowercased()
        let hits = tokens.filter { screen.contains($0.prefix(5)) }.count
        return hits >= min(2, tokens.count)
    }

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private static func ask(mission: String, matchedTerm: String,
                            screenLines: [String]) async -> Bool {
        let excerpt = String(screenLines.prefix(40).joined(separator: " | ").prefix(1200))
        let session = LanguageModelSession(instructions: """
            You judge whether a computer user drifted away from their stated work mission, \
            based on text visible on their screen. The mission may be in any language. \
            Watching/browsing content unrelated to the mission is drifting; using a site or \
            app as part of the mission is not. Answer with exactly one word: YES if they \
            drifted, NO if the screen serves the mission.
            """)
        let prompt = """
            Mission: "\(mission)"
            Flagged keyword on screen: \(matchedTerm)
            Screen text excerpt: \(excerpt)
            Did the user drift away from the mission?
            """
        do {
            let response = try await session.respond(to: prompt)
            let verdict = !response.content.uppercased().contains("NO")
            NSLog("HFJUDGE term=%@ verdict=%@", matchedTerm, verdict ? "DISTRACTED" : "ON-MISSION")
            return verdict
        } catch {
            NSLog("HFJUDGE error: %@ — siding with the keyword hit", error.localizedDescription)
            return true
        }
    }
    #endif
}
