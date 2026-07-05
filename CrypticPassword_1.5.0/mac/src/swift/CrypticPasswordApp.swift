import Cocoa

final class CrypticPasswordAlgorithm {
    enum Version: Int {
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
    static let seed2Full = #"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-={}|[]\\:\";'<>?,./^&*()_+-={}|[]";"#

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

final class CrypticPasswordController: NSObject {
    private let window: NSWindow
    private let pinField = NSTextField(string: "2023")
    private let algorithmPopup = NSPopUpButton(frame: .zero, pullsDown: false)
    private let patternLabel = NSTextField(labelWithString: "Pattern 1 of 3")
    private let statusLabel = NSTextField(labelWithString: "Enter a PIN and click Generate.")
    private let outputField = NSTextField(string: "")
    private let matrixContainer = NSView()
    private var matrixViews: [NSView] = []
    private var buttons: [NSButton] = []
    private var selected = Array(repeating: false, count: CrypticPasswordAlgorithm.totalCells)
    private var shuffled = ""
    private var finalPassword = ""
    private var currentMatrix = 0
    private var generated = false

    override init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 710),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        super.init()
        buildInterface()
    }

    func show() {
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    private func buildInterface() {
        window.title = "CrypticPassword - Swift"
        window.minSize = NSSize(width: 700, height: 650)

        guard let contentView = window.contentView else { return }

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 12
        root.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        root.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(root)

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            root.topAnchor.constraint(equalTo: contentView.topAnchor),
            root.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        let title = NSTextField(labelWithString: "CrypticPassword (Secure Password Generation Tool)")
        title.font = NSFont.boldSystemFont(ofSize: 16)
        root.addArrangedSubview(title)

        let controls = NSStackView()
        controls.orientation = .horizontal
        controls.alignment = .centerY
        controls.spacing = 8

        controls.addArrangedSubview(NSTextField(labelWithString: "PIN (1-99999):"))
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        formatter.minimum = NSNumber(value: CrypticPasswordAlgorithm.pinMinimum)
        formatter.maximum = NSNumber(value: CrypticPasswordAlgorithm.pinMaximum)
        pinField.formatter = formatter
        pinField.translatesAutoresizingMaskIntoConstraints = false
        pinField.widthAnchor.constraint(equalToConstant: 90).isActive = true
        controls.addArrangedSubview(pinField)

        controls.addArrangedSubview(NSTextField(labelWithString: "Algorithm:"))
        algorithmPopup.addItems(withTitles: CrypticPasswordAlgorithm.algorithmLabels)
        algorithmPopup.selectItem(at: 0)
        algorithmPopup.target = self
        algorithmPopup.action = #selector(algorithmChanged)
        controls.addArrangedSubview(algorithmPopup)

        let generateButton = NSButton(title: "Generate", target: self, action: #selector(generateMatrix))
        generateButton.bezelStyle = .rounded
        controls.addArrangedSubview(generateButton)

        let resetButton = NSButton(title: "Reset", target: self, action: #selector(resetAll))
        resetButton.bezelStyle = .rounded
        controls.addArrangedSubview(resetButton)
        root.addArrangedSubview(controls)

        patternLabel.font = NSFont.boldSystemFont(ofSize: 13)
        root.addArrangedSubview(patternLabel)

        matrixContainer.translatesAutoresizingMaskIntoConstraints = false
        root.addArrangedSubview(matrixContainer)
        NSLayoutConstraint.activate([
            matrixContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 620),
            matrixContainer.heightAnchor.constraint(equalToConstant: 390)
        ])

        for matrixIndex in 0..<CrypticPasswordAlgorithm.matrixCount {
            let matrix = createMatrixView(matrixIndex: matrixIndex)
            matrix.translatesAutoresizingMaskIntoConstraints = false
            matrixContainer.addSubview(matrix)
            NSLayoutConstraint.activate([
                matrix.leadingAnchor.constraint(equalTo: matrixContainer.leadingAnchor),
                matrix.trailingAnchor.constraint(equalTo: matrixContainer.trailingAnchor),
                matrix.topAnchor.constraint(equalTo: matrixContainer.topAnchor),
                matrix.bottomAnchor.constraint(equalTo: matrixContainer.bottomAnchor)
            ])
            matrixViews.append(matrix)
        }
        showCurrentMatrix()

        let navigation = NSStackView()
        navigation.orientation = .horizontal
        navigation.spacing = 8
        navigation.alignment = .centerY
        navigation.addArrangedSubview(NSButton(title: "Back <", target: self, action: #selector(previousMatrix)))
        navigation.addArrangedSubview(NSButton(title: "Next >", target: self, action: #selector(nextMatrix)))
        navigation.addArrangedSubview(NSButton(title: "Finish", target: self, action: #selector(finishPassword)))
        root.addArrangedSubview(navigation)

        let outputRow = NSStackView()
        outputRow.orientation = .horizontal
        outputRow.alignment = .centerY
        outputRow.spacing = 8
        outputRow.addArrangedSubview(NSTextField(labelWithString: "Password:"))
        outputField.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        outputField.isEditable = false
        outputField.translatesAutoresizingMaskIntoConstraints = false
        outputField.widthAnchor.constraint(greaterThanOrEqualToConstant: 560).isActive = true
        outputRow.addArrangedSubview(outputField)
        root.addArrangedSubview(outputRow)

        statusLabel.textColor = .secondaryLabelColor
        root.addArrangedSubview(statusLabel)

        resetSelectionOnly()
    }

    private func createMatrixView(matrixIndex: Int) -> NSView {
        let outer = NSView()
        let grid = NSStackView()
        grid.orientation = .vertical
        grid.alignment = .centerX
        grid.distribution = .fillEqually
        grid.spacing = 10
        grid.translatesAutoresizingMaskIntoConstraints = false
        outer.addSubview(grid)

        NSLayoutConstraint.activate([
            grid.centerXAnchor.constraint(equalTo: outer.centerXAnchor),
            grid.centerYAnchor.constraint(equalTo: outer.centerYAnchor),
            grid.widthAnchor.constraint(lessThanOrEqualTo: outer.widthAnchor),
            grid.heightAnchor.constraint(lessThanOrEqualTo: outer.heightAnchor)
        ])

        for row in 0..<CrypticPasswordAlgorithm.matrixRows {
            let rowStack = NSStackView()
            rowStack.orientation = .horizontal
            rowStack.alignment = .centerY
            rowStack.distribution = .fillEqually
            rowStack.spacing = 10
            grid.addArrangedSubview(rowStack)

            for column in 0..<CrypticPasswordAlgorithm.matrixColumns {
                let index = matrixIndex * CrypticPasswordAlgorithm.matrixSize + row * CrypticPasswordAlgorithm.matrixColumns + column
                let button = NSButton(title: "", target: self, action: #selector(cellClicked(_:)))
                button.tag = index
                button.bezelStyle = .regularSquare
                button.isBordered = false
                button.setButtonType(.momentaryPushIn)
                button.wantsLayer = true
                button.layer?.cornerRadius = 8
                button.translatesAutoresizingMaskIntoConstraints = false
                button.widthAnchor.constraint(equalToConstant: 64).isActive = true
                button.heightAnchor.constraint(equalToConstant: 42).isActive = true
                buttons.append(button)
                rowStack.addArrangedSubview(button)
            }
        }

        return outer
    }

    private func effectivePin() -> Int {
        let parsed = Int(pinField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 2023
        let normalized = CrypticPasswordAlgorithm.normalize(pin: parsed)
        pinField.stringValue = String(normalized)
        return normalized
    }

    private func selectedVersion() -> CrypticPasswordAlgorithm.Version {
        return CrypticPasswordAlgorithm.normalized(version: algorithmPopup.indexOfSelectedItem)
    }

    @objc private func generateMatrix() {
        let pin = effectivePin()
        let version = selectedVersion()
        shuffled = CrypticPasswordAlgorithm.shuffle(version: version, pin: pin)
        generated = true
        resetSelectionOnly()
        statusLabel.stringValue = "Generated 3 matrices using PIN \(pin), \(CrypticPasswordAlgorithm.algorithmLabels[version.rawValue])."
    }

    @objc private func resetAll() {
        pinField.stringValue = "2023"
        algorithmPopup.selectItem(at: 0)
        shuffled = ""
        generated = false
        currentMatrix = 0
        resetSelectionOnly()
        showCurrentMatrix()
        statusLabel.stringValue = "Enter a PIN and click Generate."
    }

    @objc private func algorithmChanged() {
        shuffled = ""
        generated = false
        resetSelectionOnly()
        statusLabel.stringValue = "Algorithm changed. Click Generate."
    }

    private func resetSelectionOnly() {
        selected = Array(repeating: false, count: CrypticPasswordAlgorithm.totalCells)
        finalPassword = ""
        outputField.stringValue = ""
        for index in 0..<buttons.count {
            applyButtonState(index: index)
        }
    }

    private func matrixBackground(for index: Int) -> NSColor {
        let matrix = index / CrypticPasswordAlgorithm.matrixSize
        switch matrix {
        case 0: return NSColor(calibratedRed: 1.0, green: 42.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)
        case 1: return NSColor(calibratedRed: 85.0 / 255.0, green: 212.0 / 255.0, blue: 0.0, alpha: 1.0)
        default: return NSColor(calibratedRed: 55.0 / 255.0, green: 171.0 / 255.0, blue: 200.0 / 255.0, alpha: 1.0)
        }
    }

    private func applyButtonState(index: Int) {
        guard index >= 0 && index < buttons.count else { return }
        let button = buttons[index]
        button.title = ""
        button.attributedTitle = NSAttributedString(string: "")

        if selected[index] {
            button.bezelStyle = .rounded
            button.isBordered = true
            button.wantsLayer = false
            button.contentTintColor = nil
        } else {
            button.bezelStyle = .regularSquare
            button.isBordered = false
            button.wantsLayer = true
            button.layer?.cornerRadius = 8
            button.layer?.backgroundColor = matrixBackground(for: index).cgColor
        }
    }

    @objc private func cellClicked(_ sender: NSButton) {
        if !generated {
            generateMatrix()
        }

        let index = sender.tag
        guard index >= 0,
              index < CrypticPasswordAlgorithm.totalCells,
              index < buttons.count,
              !selected[index] else { return }

        if shuffled.count == CrypticPasswordAlgorithm.totalCells {
            let characterIndex = shuffled.index(shuffled.startIndex, offsetBy: index)
            finalPassword.append(shuffled[characterIndex])
        }

        selected[index] = true
        applyButtonState(index: index)
        outputField.stringValue = finalPassword
    }

    @objc private func nextMatrix() {
        if currentMatrix < CrypticPasswordAlgorithm.matrixCount - 1 {
            currentMatrix += 1
        }
        showCurrentMatrix()
    }

    @objc private func previousMatrix() {
        if currentMatrix > 0 {
            currentMatrix -= 1
        }
        showCurrentMatrix()
    }

    @objc private func finishPassword() {
        outputField.stringValue = finalPassword
    }

    private func showCurrentMatrix() {
        for (index, view) in matrixViews.enumerated() {
            view.isHidden = index != currentMatrix
        }
        patternLabel.stringValue = "Pattern \(currentMatrix + 1) of 3"
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: CrypticPasswordController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        controller = CrypticPasswordController()
        controller?.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
