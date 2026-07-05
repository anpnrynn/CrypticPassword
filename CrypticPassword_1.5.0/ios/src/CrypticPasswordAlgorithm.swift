import Foundation

final class CrypticPasswordAlgorithm {
    enum Version: Int, CaseIterable {
        case version1_0 = 0
        case version1_1 = 1
        case version2_0 = 2
        case version2_1 = 3
    }

    static let matrixCount = 3
    static let matrixRows = 6
    static let matrixColumns = 6
    static let matrixSize = 36
    static let totalCells = 108
    static let pinMinimum = 1
    static let pinMaximum = 99_999

    static let algorithmLabels = [
        "version1_0 / seed1",
        "version1_1 / seed1",
        "version2_0 / seed2",
        "version2_1 / seed2"
    ]

    static let seed1 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!$'*+,-./:;<=>?^_`~$'*+,-./:;<=>?^_`"
    static let seed2Full = #"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-={}|[]\\:\";'<>?,./^&*()_+-={}|[]\";"#

    static func normalize(pin: Int) -> Int {
        return min(max(pin, pinMinimum), pinMaximum)
    }

    static func normalized(version rawValue: Int) -> Version {
        return Version(rawValue: rawValue) ?? .version1_0
    }

    private static func seed(for version: Version) -> String {
        switch version {
        case .version1_0, .version1_1:
            return seed1
        case .version2_0, .version2_1:
            return seed2Full
        }
    }

    private static func rotate(_ data: inout [Character], start: Int, count: Int, length: Int) {
        guard length > 0 else { return }
        let shift = count % length
        guard shift > 0 else { return }
        let segment = Array(data[start..<(start + length)])
        let rotated = Array(segment[shift..<length]) + Array(segment[0..<shift])
        for i in 0..<length {
            data[start + i] = rotated[i]
        }
    }

    private static func swap(_ data: inout [Character], base: Int, i: Int, j: Int) {
        data.swapAt(base + i, base + j)
    }

    private static func shuffleSimple(_ data: inout [Character], pin: Int) {
        let n = totalCells
        let half = n / 2
        var k = 1

        for _ in 0..<pin {
            for i in 0..<(n / 4) {
                if k % 2 == 0 {
                    swap(&data, base: 0, i: i, j: half - i - 1)
                    swap(&data, base: half, i: i, j: half - i - 1)
                } else {
                    swap(&data, base: 0, i: i, j: half - i - 2)
                    swap(&data, base: half, i: i, j: half - i - 2)
                }
                k += 1
            }

            rotate(&data, start: 0, count: 13, length: half)
            rotate(&data, start: half, count: 17, length: half)
            rotate(&data, start: 0, count: 23, length: n)
        }
    }

    private static func shuffleEnhanced(_ data: inout [Character], pin: Int) {
        let n = totalCells
        let half = n / 2
        let random = [23, 13, 17, 7, 11]
        var k = 1

        for _ in 0..<pin {
            for i in 0..<(n / 4) {
                if k % 2 == 0 {
                    swap(&data, base: 0, i: i, j: half - i - 1)
                    swap(&data, base: random[3], i: i, j: half - i - 1 - random[2])
                    swap(&data, base: half, i: i, j: half - i - 1)
                    swap(&data, base: random[4], i: i, j: half - i - 1 - random[4])
                } else {
                    swap(&data, base: 0, i: i, j: half - i - 2)
                    swap(&data, base: random[3], i: i, j: half - i - 2 - random[3])
                    swap(&data, base: half, i: i, j: half - i - 2)
                    swap(&data, base: random[4], i: i, j: half - i - 2 - random[4])
                }
                swap(&data, base: 0, i: i, j: random[1] + i)
                swap(&data, base: half, i: i, j: random[2] + i)
                k += 1
            }

            rotate(&data, start: 0, count: random[1], length: half)
            rotate(&data, start: half, count: random[2], length: half)
            rotate(&data, start: 0, count: random[0], length: n - random[0])
            rotate(&data, start: 0, count: random[3], length: n - random[3])
            rotate(&data, start: random[3], count: random[4], length: half)
        }
    }

    static func shuffle(version: Version, pin rawPin: Int) -> String {
        let pin = normalize(pin: rawPin)
        var data = Array(seed(for: version).prefix(totalCells))

        switch version {
        case .version1_0, .version2_0:
            shuffleSimple(&data, pin: pin)
        case .version1_1, .version2_1:
            shuffleEnhanced(&data, pin: pin)
        }

        return String(data.prefix(totalCells))
    }
}
