import UIKit

final class CrypticPasswordViewController: UIViewController, UITextFieldDelegate {
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let pinField = UITextField()
    private let algorithmControl = UISegmentedControl(items: CrypticPasswordAlgorithm.algorithmLabels)
    private let patternLabel = UILabel()
    private let statusLabel = UILabel()
    private let outputField = UITextField()
    private let gridStack = UIStackView()
    private var buttons: [UIButton] = []
    private var selected = Array(repeating: false, count: CrypticPasswordAlgorithm.totalCells)
    private var shuffled = ""
    private var finalPassword = ""
    private var currentMatrix = 0
    private var generated = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "CrypticPassword"
        view.backgroundColor = .systemBackground
        buildInterface()
        resetSelectionOnly()
        showCurrentMatrix()
    }

    private func buildInterface() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.alignment = .fill
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        let titleLabel = UILabel()
        titleLabel.text = "CrypticPassword (Secure Password Generation Tool)"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0
        contentStack.addArrangedSubview(titleLabel)

        let pinRow = UIStackView()
        pinRow.axis = .horizontal
        pinRow.spacing = 8
        pinRow.alignment = .center
        let pinLabel = UILabel()
        pinLabel.text = "PIN"
        pinField.text = "2023"
        pinField.keyboardType = .numberPad
        pinField.borderStyle = .roundedRect
        pinField.delegate = self
        pinField.widthAnchor.constraint(equalToConstant: 110).isActive = true
        let generateButton = UIButton(type: .system)
        generateButton.setTitle("Generate", for: .normal)
        generateButton.addTarget(self, action: #selector(generateMatrix), for: .touchUpInside)
        let resetButton = UIButton(type: .system)
        resetButton.setTitle("Reset", for: .normal)
        resetButton.addTarget(self, action: #selector(resetAll), for: .touchUpInside)
        pinRow.addArrangedSubview(pinLabel)
        pinRow.addArrangedSubview(pinField)
        pinRow.addArrangedSubview(generateButton)
        pinRow.addArrangedSubview(resetButton)
        contentStack.addArrangedSubview(pinRow)

        algorithmControl.selectedSegmentIndex = 0
        algorithmControl.addTarget(self, action: #selector(algorithmChanged), for: .valueChanged)
        if #available(iOS 13.0, *) {
            algorithmControl.selectedSegmentTintColor = .systemGray5
        }
        contentStack.addArrangedSubview(algorithmControl)

        patternLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        patternLabel.textAlignment = .center
        contentStack.addArrangedSubview(patternLabel)

        gridStack.axis = .vertical
        gridStack.spacing = 8
        gridStack.alignment = .fill
        gridStack.distribution = .fillEqually
        contentStack.addArrangedSubview(gridStack)
        gridStack.heightAnchor.constraint(equalToConstant: 330).isActive = true

        for row in 0..<CrypticPasswordAlgorithm.matrixRows {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 8
            rowStack.alignment = .fill
            rowStack.distribution = .fillEqually
            gridStack.addArrangedSubview(rowStack)
            for column in 0..<CrypticPasswordAlgorithm.matrixColumns {
                let button = UIButton(type: .system)
                button.tag = row * CrypticPasswordAlgorithm.matrixColumns + column
                button.setTitle("", for: .normal)
                button.layer.cornerRadius = 8
                button.layer.masksToBounds = true
                button.addTarget(self, action: #selector(cellClicked(_:)), for: .touchUpInside)
                buttons.append(button)
                rowStack.addArrangedSubview(button)
            }
        }

        let navigationRow = UIStackView()
        navigationRow.axis = .horizontal
        navigationRow.spacing = 12
        navigationRow.distribution = .fillEqually
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back <", for: .normal)
        backButton.addTarget(self, action: #selector(previousMatrix), for: .touchUpInside)
        let nextButton = UIButton(type: .system)
        nextButton.setTitle("Next >", for: .normal)
        nextButton.addTarget(self, action: #selector(nextMatrix), for: .touchUpInside)
        let finishButton = UIButton(type: .system)
        finishButton.setTitle("Finish", for: .normal)
        finishButton.addTarget(self, action: #selector(finishPassword), for: .touchUpInside)
        navigationRow.addArrangedSubview(backButton)
        navigationRow.addArrangedSubview(nextButton)
        navigationRow.addArrangedSubview(finishButton)
        contentStack.addArrangedSubview(navigationRow)

        outputField.borderStyle = .roundedRect
        outputField.isUserInteractionEnabled = true
        outputField.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        outputField.placeholder = "Generated password"
        contentStack.addArrangedSubview(outputField)

        statusLabel.text = "Enter a PIN and tap Generate."
        statusLabel.textColor = .secondaryLabel
        statusLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        statusLabel.numberOfLines = 0
        contentStack.addArrangedSubview(statusLabel)
    }

    private func effectivePin() -> Int {
        let raw = Int(pinField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 2023
        let normalized = CrypticPasswordAlgorithm.normalize(pin: raw)
        pinField.text = String(normalized)
        return normalized
    }

    private func selectedVersion() -> CrypticPasswordAlgorithm.Version {
        return CrypticPasswordAlgorithm.normalized(version: algorithmControl.selectedSegmentIndex)
    }

    @objc private func generateMatrix() {
        view.endEditing(true)
        let pin = effectivePin()
        let version = selectedVersion()
        shuffled = CrypticPasswordAlgorithm.shuffle(version: version, pin: pin)
        generated = true
        resetSelectionOnly()
        statusLabel.text = "Generated 3 matrices using PIN \(pin), \(CrypticPasswordAlgorithm.algorithmLabels[version.rawValue])."
    }

    @objc private func resetAll() {
        pinField.text = "2023"
        algorithmControl.selectedSegmentIndex = 0
        shuffled = ""
        generated = false
        currentMatrix = 0
        resetSelectionOnly()
        showCurrentMatrix()
        statusLabel.text = "Enter a PIN and tap Generate."
    }

    @objc private func algorithmChanged() {
        shuffled = ""
        generated = false
        resetSelectionOnly()
        statusLabel.text = "Algorithm changed. Tap Generate."
    }

    private func resetSelectionOnly() {
        selected = Array(repeating: false, count: CrypticPasswordAlgorithm.totalCells)
        finalPassword = ""
        outputField.text = ""
        for index in 0..<buttons.count {
            applyButtonState(visibleIndex: index)
        }
    }

    private func absoluteIndex(for visibleIndex: Int) -> Int {
        return currentMatrix * CrypticPasswordAlgorithm.matrixSize + visibleIndex
    }

    private func matrixColor(for matrix: Int) -> UIColor {
        switch matrix {
        case 0: return UIColor(red: 1.0, green: 42.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)
        case 1: return UIColor(red: 85.0 / 255.0, green: 212.0 / 255.0, blue: 0.0, alpha: 1.0)
        default: return UIColor(red: 55.0 / 255.0, green: 171.0 / 255.0, blue: 200.0 / 255.0, alpha: 1.0)
        }
    }

    private func applyButtonState(visibleIndex: Int) {
        guard visibleIndex >= 0 && visibleIndex < buttons.count else { return }
        let absolute = absoluteIndex(for: visibleIndex)
        let button = buttons[visibleIndex]
        button.setTitle("", for: .normal)
        if selected[absolute] {
            button.backgroundColor = .systemBackground
            button.layer.borderWidth = 1.0
            button.layer.borderColor = UIColor.separator.cgColor
        } else {
            button.backgroundColor = matrixColor(for: currentMatrix)
            button.layer.borderWidth = 0.0
            button.layer.borderColor = nil
        }
    }

    private func showCurrentMatrix() {
        patternLabel.text = "Pattern \(currentMatrix + 1) of 3"
        for index in 0..<buttons.count {
            applyButtonState(visibleIndex: index)
        }
    }

    @objc private func cellClicked(_ sender: UIButton) {
        if !generated {
            generateMatrix()
        }
        let visible = sender.tag
        let absolute = absoluteIndex(for: visible)
        guard absolute >= 0,
              absolute < CrypticPasswordAlgorithm.totalCells,
              !selected[absolute] else { return }

        if shuffled.count == CrypticPasswordAlgorithm.totalCells {
            let characterIndex = shuffled.index(shuffled.startIndex, offsetBy: absolute)
            finalPassword.append(shuffled[characterIndex])
        }

        selected[absolute] = true
        applyButtonState(visibleIndex: visible)
        outputField.text = finalPassword
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
        outputField.text = finalPassword
    }
}
