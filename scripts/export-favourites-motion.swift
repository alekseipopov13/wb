import Foundation
import SwiftUI

/// Values are read from the same live timelines as the UI; milliseconds, not frames.
@main
enum ExportFavouritesMotion {
    static func rows(duration: Double, pose: (Double) -> [String: Double]) -> [[String: Double]] {
        (0...Int(ceil(duration * 60))).map { frame in
            let time = min(duration, Double(frame) / 60)
            var values = pose(time)
            values["time_ms"] = (time * 1000 * 1000).rounded() / 1000
            return values.mapValues { ($0 * 1_000_000).rounded() / 1_000_000 }
        }
    }

    static func main() throws {
        let reference: [String: Any] = [
            "schema_version": 1,
            "units": ["time": "milliseconds after each track begins", "size": "logical UI units", "scale": "1 = normal size", "aspect": "scale_x = scale * aspect; scale_y = scale / aspect", "progress": "0 = measured source position; 1 = measured destination position", "rotation_delta_deg": "degrees added to the resting rotation"],
            "sample_rate_hz": 60,
            "source": "WBSandbox/Design/SandboxMotion.swift; Model/FavouritesInsertion.swift; Model/FavouritesReminderGeometry.swift; Model/FavouritesDeckInteraction.swift",
            "reminder": [
                "delay_ms": 100,
                "duration_ms": SandboxMotion.TailMessage.timeline.duration * 1000,
                "resting_rotation_deg": FavouritesReminderGeometry.restingRotation,
                "size": ["width": FavouritesReminderGeometry.size.width, "height": FavouritesReminderGeometry.size.height],
                "samples": rows(duration: SandboxMotion.TailMessage.timeline.duration) {
                    let p = SandboxMotion.TailMessage.timeline.value(time: $0)
                    return ["scale": p.scale, "aspect": p.aspect, "scale_x": p.scale * p.aspect, "scale_y": p.scale / p.aspect, "rotation_delta_deg": p.rotation]
                }
            ],
            "grid_insertion": [
                "appearance_delay_ms": 270,
                "cascade_step_ms": FavouritesInsertionOrder.cascadeStep * 1000,
                "maximum_delay_ms": FavouritesInsertionOrder.maximumDelay * 1000,
                "samples": rows(duration: SandboxMotion.CardInsertion.timeline.duration) {
                    let p = SandboxMotion.CardInsertion.timeline.value(time: $0)
                    return ["scale": p.scale, "aspect": p.aspect, "light_opacity": p.light]
                }
            ],
            "neighbour_travel": [
                "duration_ms": SandboxMotion.CardInsertion.travel.duration * 1000,
                "samples": rows(duration: SandboxMotion.CardInsertion.travel.duration) {
                    ["progress": SandboxMotion.CardInsertion.travel.value(time: $0).progress]
                }
            ],
            "removal": [
                "vacancy_delay_ms": FavouritesRemovalOrder.vacancyDelay * 1000,
                "maximum_delay_ms": (FavouritesRemovalOrder.vacancyDelay + FavouritesInsertionOrder.maximumDelay) * 1000,
                "samples": rows(duration: SandboxMotion.CardRemoval.timeline.duration) {
                    let progress = SandboxMotion.CardRemoval.timeline.value(time: $0).progress
                    return ["progress": progress, "visibility": 1-progress, "scale": max(0.04, 1-progress)]
                }
            ],
            "promotion": [
                "appearance_delay_ms": 340,
                "samples": rows(duration: SandboxMotion.CardInsertion.promotion.duration) {
                    let p = SandboxMotion.CardInsertion.promotion.value(time: $0)
                    return ["scale": p.scale, "aspect": p.aspect, "light_opacity": p.light]
                }
            ],
            "deck_gesture": ["arm_distance": FavouritesDeckInteraction.triggerDistance, "disarm_distance": FavouritesDeckInteraction.disarmDistance],
            "collection_geometry": ["feed_width": FavouritesCollectionArrangement.row.cardWidth(in: 390), "feed_height": FavouritesCollectionArrangement.row.cardHeight, "feed_gap": FavouritesCollectionArrangement.row.spacing, "grid_height": FavouritesCollectionArrangement.grid.cardHeight, "grid_gap": FavouritesCollectionArrangement.grid.spacing]
        ]
        let data = try JSONSerialization.data(withJSONObject: reference, options: [.prettyPrinted, .sortedKeys])
        let destination = CommandLine.arguments.dropFirst().first ?? "docs/favourites/motion-reference.json"
        try (data + Data([10])).write(to: URL(fileURLWithPath: destination))
        print("Exported live motion reference: \(destination)")
    }
}
