enum CrypticVersion: Int {
    case version1_0 = 0
    case version1_1 = 1
    case version2_0 = 2
    case version2_1 = 3
}

struct CrypticPasswordAlgorithmForTest {
    static let totalCells = 108
    static let pinMinimum = 1
    static let pinMaximum = 99_999
    static let seed1 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!$'*+,-./:;<=>?^_`~$'*+,-./:;<=>?^_`"
    static let seed2Full = #"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-={}|[]\\:\";'<>?,./^&*()_+-={}|[]";"#

    static func normalize(pin: Int) -> Int {
        return min(max(pin, pinMinimum), pinMaximum)
    }

    static func seed(for version: CrypticVersion) -> String {
        switch version {
        case .version1_0, .version1_1: return seed1
        case .version2_0, .version2_1: return seed2Full
        }
    }

    static func rotate(_ data: inout [Character], start: Int, count: Int, length: Int) {
        guard length > 0 else { return }
        let shift = count % length
        guard shift > 0 else { return }
        let segment = Array(data[start..<(start + length)])
        let rotated = Array(segment[shift..<length]) + Array(segment[0..<shift])
        for i in 0..<length { data[start + i] = rotated[i] }
    }

    static func swap(_ data: inout [Character], base: Int, i: Int, j: Int) {
        data.swapAt(base + i, base + j)
    }

    static func shuffleSimple(_ data: inout [Character], pin: Int) {
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

    static func shuffleEnhanced(_ data: inout [Character], pin: Int) {
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

    static func shuffle(version: CrypticVersion, pin rawPin: Int) -> String {
        var data = Array(seed(for: version).prefix(totalCells))
        let pin = normalize(pin: rawPin)
        switch version {
        case .version1_0, .version2_0: shuffleSimple(&data, pin: pin)
        case .version1_1, .version2_1: shuffleEnhanced(&data, pin: pin)
        }
        return String(data.prefix(totalCells))
    }
}

func check(_ version: CrypticVersion, _ pin: Int, _ expected: String) {
    let result = CrypticPasswordAlgorithmForTest.shuffle(version: version, pin: pin)
    if result != expected {
        fatalError("version \(version.rawValue) pin \(pin) mismatch:\nexpected: \(expected)\nactual:   \(result)")
    }
    if result.count != 108 {
        fatalError("version \(version.rawValue) pin \(pin) length \(result.count), expected 108")
    }
}

check(CrypticVersion(rawValue: 0)!, 1, ##"H1F3D5B7997b5d3f1hg0e2c4a6886A4y_!?'=+;-/:.<,>*^$`z$x*v,t.r:p<n>l^j`_i?k=m;o/q-s+u'w~C2E0GYIWKUMSOQRPTNVLXJZ"##)
check(CrypticVersion(rawValue: 0)!, 2023, ##"HCFMDOB/9S7'5h3f1:`UQ+PeN/`.=<?*_$~sb220Yw6y8cIaK4xJzAvRt!rLpqnolmj;8;?W_-0-9+^d53i$':^G>E7,gZ6.k,4*>1<X=VuT"##)
check(CrypticVersion(rawValue: 1)!, 1, ##"7c9ebgdKLMNOP_`_$x*v,t.-/+;'=~?yiwkumsoqr:p<QR4T20BfChDEFGHIJ0Y1ZA183U3456V6X7n>l^j`z!$'*+,-./W92S85a:;<=>?^"##)
check(CrypticVersion(rawValue: 1)!, 2023, ##"+`zT0<>8:3?kt=>_lWno77$GD!IdXy9,a4i'JUv?*23CF1OB-M<9^.r2/f.pNex:4Z;sb-hKA8^j5~$c*+Eu'L6gq;=PH,S_R61m`Q5/w0YV"##)
check(CrypticVersion(rawValue: 2)!, 1, ##"HbFdDfBh9j7l5n3p1rq0o2m4k6i8gAe&;(\_\-]{|[}\=:+")'*>^,$/@&~(z_x-v{t|}s=u+w)y*`^!.#?%<CcEaGYIWKUMSOQRPTNVLXJZ"##)
check(CrypticVersion(rawValue: 2)!, 2023, ##"HCFMDOB|9S7?5r3p1(|UQ.PoN*'&\\\+;><!lc2aY%6&8mIkKe^J*A$R@(~Lz`xyvwt]i)=W}^0{j-{nfds)_["G:Eh/qZg}u=4,-b_X+V#T"##)
check(CrypticVersion(rawValue: 3)!, 1, ##"hmjolqnKLMNOP;'}>^,$/@&^*.)?+<=&s%u#w!y`~(z_QR4T2aBpCrDEFGHIJ0Y1ZAb8dU3e56VgX7x-v{t|*()_+-={}|W9cSifk[]\\:\""##)
check(CrypticVersion(rawValue: 3)!, 2023, ##"-|*T0_-i(3\u@+:;vWxy7h)GD(InX&j/kes_JU$=+cdCF1OB^M\9{&~2|p}zNo^[4Z)!l{rKA8"t5<>m,.E#?Lgq`]\PH=S}R6bw'Qf*%aYV"##)
print("SWIFT_CORE_PASS_ALL_ALGORITHMS")
