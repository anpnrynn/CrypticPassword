import Foundation

@main
struct CrypticPasswordAlgorithmSmoke {
    static func main() {
        let pins = [1, 2, 2023, 99999]
        for version in CrypticPasswordAlgorithm.Version.allCases {
            for pin in pins {
                let shuffled = CrypticPasswordAlgorithm.shuffle(version: version, pin: pin)
                if shuffled.count != CrypticPasswordAlgorithm.totalCells {
                    fatalError("Invalid shuffled length for \(version) pin \(pin): \(shuffled.count)")
                }
            }
        }
        print("IOS_SWIFT_CORE_PASS_ALL_ALGORITHMS")
    }
}
