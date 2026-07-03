// DistractionJudgeTests.swift — the universal (no-AI) lexical relevance tier must work on any
// Mac and in any language: mission tokens found in the screen text mean the user is ON mission.

import XCTest
@testable import Hyperfocus

final class DistractionJudgeTests: XCTestCase {

    func test_lexical_missionWordsOnScreen_isOnMission() {
        // RU mission, RU screen text — no embeddings/LLM involved.
        let onMission = DistractionJudge.lexicalOnMission(
            mission: "смонтировать ролик про горы",
            screenLines: ["монтаж — final cut pro", "проект: ролик горы v2", "youtube"])
        XCTAssertTrue(onMission)
    }

    func test_lexical_unrelatedFeed_isDistraction() {
        let onMission = DistractionJudge.lexicalOnMission(
            mission: "написать отчёт по продажам",
            screenLines: ["mrbeast", "shorts", "for you", "recommended", "youtube"])
        XCTAssertFalse(onMission)
    }

    func test_lexical_inflectedRussianTokens_matchByPrefix() {
        // "отчёта"/"продажах" are inflected forms — prefix matching must still connect them.
        let onMission = DistractionJudge.lexicalOnMission(
            mission: "написать отчёт по продажам",
            screenLines: ["черновик отчёта", "данные о продажах за июнь", "youtube tab"])
        XCTAssertTrue(onMission)
    }

    func test_lexical_shortAndEmptyMissions_neverCrash_andSideWithDistraction() {
        XCTAssertFalse(DistractionJudge.lexicalOnMission(mission: "", screenLines: ["youtube"]))
        XCTAssertFalse(DistractionJudge.lexicalOnMission(mission: "go", screenLines: ["youtube"]))
    }

    func test_lexical_englishMission_matches() {
        let onMission = DistractionJudge.lexicalOnMission(
            mission: "Edit the launch video script",
            screenLines: ["script draft — google docs", "video timeline", "youtube"])
        XCTAssertTrue(onMission)
    }
}
