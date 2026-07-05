import java.awt.BorderLayout;
import java.awt.CardLayout;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.GridLayout;
import java.awt.event.ActionEvent;
import java.text.NumberFormat;
import java.util.Arrays;
import javax.swing.BorderFactory;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JFormattedTextField;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.SwingUtilities;
import javax.swing.UIManager;
import javax.swing.WindowConstants;
import javax.swing.text.NumberFormatter;

public final class CrypticPasswordSwing {
    private static final int MATRIX_COUNT = 3;
    private static final int MATRIX_ROWS = 6;
    private static final int MATRIX_COLS = 6;
    private static final int MATRIX_SIZE = 36;
    private static final int TOTAL_CELLS = 108;
    private static final int PIN_MIN = 1;
    private static final int PIN_MAX = 99999;

    private static final int VERSION_1_0 = 0;
    private static final int VERSION_1_1 = 1;
    private static final int VERSION_2_0 = 2;
    private static final int VERSION_2_1 = 3;

    private static final String[] ALGORITHM_LABELS = {
        "version1_0 / seed1",
        "version1_1 / seed1",
        "version2_0 / seed2",
        "version2_1 / seed2"
    };

    private static final String SEED1 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!$'*+,-./:;<=>?^_`~$'*+,-./:;<=>?^_`";
    private static final String SEED2_FULL = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-={}|[]\\\\:\\\";'<>?,./^&*()_+-={}|[]\";";

    private final JFrame frame = new JFrame("CrypticPassword - Swing");
    private final CardLayout cardLayout = new CardLayout();
    private final JPanel matrixCards = new JPanel(cardLayout);
    private final JLabel patternLabel = new JLabel("Pattern 1 of 3");
    private final JLabel statusLabel = new JLabel("Enter a PIN and click Generate.");
    private final JFormattedTextField pinField;
    private final JComboBox<String> algorithmCombo = new JComboBox<>(ALGORITHM_LABELS);
    private final JTextField outputField = new JTextField(52);
    private final JButton[] cells = new JButton[TOTAL_CELLS];
    private final boolean[] selected = new boolean[TOTAL_CELLS];
    private final StringBuilder finalPassword = new StringBuilder(TOTAL_CELLS);
    private String shuffled = "";
    private int currentMatrix = 0;
    private boolean generated = false;

    private CrypticPasswordSwing() {
        NumberFormat integerFormat = NumberFormat.getIntegerInstance();
        integerFormat.setGroupingUsed(false);
        NumberFormatter formatter = new NumberFormatter(integerFormat);
        formatter.setMinimum(PIN_MIN);
        formatter.setMaximum(PIN_MAX);
        formatter.setAllowsInvalid(false);
        pinField = new JFormattedTextField(formatter);
        pinField.setColumns(8);
        pinField.setValue(2023);
    }

    private static int normalizePin(int pin) {
        if (pin < PIN_MIN) {
            return PIN_MIN;
        }
        if (pin > PIN_MAX) {
            return PIN_MAX;
        }
        return pin;
    }

    private static int normalizeVersion(int version) {
        return (version >= VERSION_1_0 && version <= VERSION_2_1) ? version : VERSION_1_0;
    }

    private static String seedForVersion(int version) {
        switch (normalizeVersion(version)) {
            case VERSION_2_0:
            case VERSION_2_1:
                return SEED2_FULL;
            case VERSION_1_0:
            case VERSION_1_1:
            default:
                return SEED1;
        }
    }

    private static void rotate(char[] data, int start, int count, int length) {
        if (length <= 0) {
            return;
        }
        int shift = count % length;
        if (shift == 0) {
            return;
        }
        char[] segment = Arrays.copyOfRange(data, start, start + length);
        System.arraycopy(segment, shift, data, start, length - shift);
        System.arraycopy(segment, 0, data, start + length - shift, shift);
    }

    private static void swap(char[] data, int base, int i, int j) {
        char c = data[base + i];
        data[base + i] = data[base + j];
        data[base + j] = c;
    }

    private static void shuffleSimple(char[] data, int pin) {
        int n = TOTAL_CELLS;
        int half = n / 2;
        int k = 1;
        for (int j = 0; j < pin; ++j) {
            for (int i = 0; i < n / 4; ++i) {
                if (k % 2 == 0) {
                    swap(data, 0, i, half - i - 1);
                    swap(data, half, i, half - i - 1);
                } else {
                    swap(data, 0, i, half - i - 2);
                    swap(data, half, i, half - i - 2);
                }
                ++k;
            }
            rotate(data, 0, 13, half);
            rotate(data, half, 17, half);
            rotate(data, 0, 23, n);
        }
    }

    private static void shuffleEnhanced(char[] data, int pin) {
        int n = TOTAL_CELLS;
        int half = n / 2;
        int[] random = {23, 13, 17, 7, 11};
        int k = 1;
        for (int j = 0; j < pin; ++j) {
            for (int i = 0; i < n / 4; ++i) {
                if (k % 2 == 0) {
                    swap(data, 0, i, half - i - 1);
                    swap(data, random[3], i, half - i - 1 - random[2]);
                    swap(data, half, i, half - i - 1);
                    swap(data, random[4], i, half - i - 1 - random[4]);
                } else {
                    swap(data, 0, i, half - i - 2);
                    swap(data, random[3], i, half - i - 2 - random[3]);
                    swap(data, half, i, half - i - 2);
                    swap(data, random[4], i, half - i - 2 - random[4]);
                }
                swap(data, 0, i, random[1] + i);
                swap(data, half, i, random[2] + i);
                ++k;
            }
            rotate(data, 0, random[1], half);
            rotate(data, half, random[2], half);
            rotate(data, 0, random[0], n - random[0]);
            rotate(data, 0, random[3], n - random[3]);
            rotate(data, random[3], random[4], half);
        }
    }

    private static String shuffle(int version, int pin) {
        pin = normalizePin(pin);
        version = normalizeVersion(version);
        char[] seed = seedForVersion(version).toCharArray();
        char[] data = Arrays.copyOf(seed, TOTAL_CELLS);
        if (version == VERSION_1_1 || version == VERSION_2_1) {
            shuffleEnhanced(data, pin);
        } else {
            shuffleSimple(data, pin);
        }
        return new String(data, 0, TOTAL_CELLS);
    }

    private int getPin() {
        Object value = pinField.getValue();
        if (value instanceof Number) {
            return normalizePin(((Number) value).intValue());
        }
        try {
            return normalizePin(Integer.parseInt(pinField.getText().trim()));
        } catch (NumberFormatException ex) {
            return 2023;
        }
    }

    private int getVersion() {
        return normalizeVersion(algorithmCombo.getSelectedIndex());
    }

    private void generateMatrix() {
        int pin = getPin();
        int version = getVersion();
        shuffled = shuffle(version, pin);
        generated = true;
        resetSelectionOnly();
        statusLabel.setText("Generated 3 matrices using PIN " + pin + ", " + ALGORITHM_LABELS[version] + ".");
    }

    private void algorithmChanged() {
        shuffled = "";
        generated = false;
        resetSelectionOnly();
        statusLabel.setText("Algorithm changed. Click Generate.");
    }

    private void resetSelectionOnly() {
        Arrays.fill(selected, false);
        finalPassword.setLength(0);
        outputField.setText("");
        for (int i = 0; i < TOTAL_CELLS; ++i) {
            applyButtonState(i);
        }
    }

    private void resetAll() {
        pinField.setValue(2023);
        algorithmCombo.setSelectedIndex(0);
        shuffled = "";
        generated = false;
        resetSelectionOnly();
        currentMatrix = 0;
        cardLayout.show(matrixCards, "matrix1");
        updatePatternLabel();
        statusLabel.setText("Enter a PIN and click Generate.");
    }

    private Color matrixBackground(int index) {
        int matrix = index / MATRIX_SIZE;
        if (matrix == 0) {
            return new Color(0xFF2A2A);
        }
        if (matrix == 1) {
            return new Color(0x55D400);
        }
        return new Color(0x37ABC8);
    }

    private Color matrixForeground(int index) {
        return (index / MATRIX_SIZE) == 1 ? Color.BLACK : Color.WHITE;
    }

    private void applyButtonState(int index) {
        JButton button = cells[index];
        if (button == null) {
            return;
        }
        button.setText("");
        button.setContentAreaFilled(true);

        if (selected[index]) {
            Color background = UIManager.getColor("Button.background");
            Color foreground = UIManager.getColor("Button.foreground");
            button.setBackground(background != null ? background : null);
            button.setForeground(foreground != null ? foreground : Color.BLACK);
            button.setOpaque(false);
            button.setBorder(UIManager.getBorder("Button.border"));
        } else {
            button.setBackground(matrixBackground(index));
            button.setForeground(matrixForeground(index));
            button.setOpaque(true);
            button.setBorder(BorderFactory.createLineBorder(Color.DARK_GRAY));
        }
    }

    private void cellClicked(int index) {
        if (!generated) {
            generateMatrix();
        }
        if (index < 0 || index >= TOTAL_CELLS || selected[index]) {
            return;
        }
        if (shuffled.length() == TOTAL_CELLS) {
            finalPassword.append(shuffled.charAt(index));
        }
        selected[index] = true;
        applyButtonState(index);
        outputField.setText(finalPassword.toString());
    }

    private JPanel createMatrix(int matrix) {
        JPanel panel = new JPanel(new GridLayout(MATRIX_ROWS, MATRIX_COLS, 8, 8));
        panel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
        for (int row = 0; row < MATRIX_ROWS; ++row) {
            for (int col = 0; col < MATRIX_COLS; ++col) {
                int index = matrix * MATRIX_SIZE + row * MATRIX_COLS + col;
                JButton button = new JButton("");
                button.setPreferredSize(new Dimension(58, 42));
                button.setFocusPainted(false);
                final int cellIndex = index;
                button.addActionListener((ActionEvent event) -> cellClicked(cellIndex));
                cells[index] = button;
                applyButtonState(index);
                panel.add(button);
            }
        }
        return panel;
    }

    private void updatePatternLabel() {
        patternLabel.setText("Pattern " + (currentMatrix + 1) + " of 3");
    }

    private void nextMatrix() {
        if (currentMatrix < MATRIX_COUNT - 1) {
            ++currentMatrix;
        }
        cardLayout.show(matrixCards, "matrix" + (currentMatrix + 1));
        updatePatternLabel();
    }

    private void previousMatrix() {
        if (currentMatrix > 0) {
            --currentMatrix;
        }
        cardLayout.show(matrixCards, "matrix" + (currentMatrix + 1));
        updatePatternLabel();
    }

    private void buildAndShow() {
        frame.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
        frame.setLayout(new BorderLayout(10, 10));

        JPanel top = new JPanel(new BorderLayout(8, 8));
        JLabel title = new JLabel("CrypticPassword (Secure Password Generation Tool)");
        title.setFont(title.getFont().deriveFont(Font.BOLD, 15.0f));
        top.add(title, BorderLayout.NORTH);

        JPanel controls = new JPanel(new FlowLayout(FlowLayout.LEFT));
        JButton generate = new JButton("Generate");
        JButton reset = new JButton("Reset");
        generate.addActionListener(event -> generateMatrix());
        reset.addActionListener(event -> resetAll());
        algorithmCombo.addActionListener(event -> algorithmChanged());
        controls.add(new JLabel("PIN (1-99999):"));
        controls.add(pinField);
        controls.add(new JLabel("Algorithm:"));
        controls.add(algorithmCombo);
        controls.add(generate);
        controls.add(reset);
        top.add(controls, BorderLayout.CENTER);
        top.add(patternLabel, BorderLayout.SOUTH);
        frame.add(top, BorderLayout.NORTH);

        for (int i = 0; i < MATRIX_COUNT; ++i) {
            matrixCards.add(createMatrix(i), "matrix" + (i + 1));
        }
        frame.add(matrixCards, BorderLayout.CENTER);

        JPanel bottom = new JPanel(new BorderLayout(8, 8));
        JPanel nav = new JPanel(new FlowLayout(FlowLayout.LEFT));
        JButton back = new JButton("Back <");
        JButton next = new JButton("Next >");
        JButton finish = new JButton("Finish");
        back.addActionListener(event -> previousMatrix());
        next.addActionListener(event -> nextMatrix());
        finish.addActionListener(event -> outputField.setText(finalPassword.toString()));
        nav.add(back);
        nav.add(next);
        nav.add(finish);
        bottom.add(nav, BorderLayout.NORTH);

        outputField.setFont(new Font(Font.MONOSPACED, Font.PLAIN, 13));
        JPanel outputPanel = new JPanel(new BorderLayout(8, 8));
        outputPanel.add(new JLabel("Password:"), BorderLayout.WEST);
        outputPanel.add(outputField, BorderLayout.CENTER);
        bottom.add(outputPanel, BorderLayout.CENTER);
        bottom.add(statusLabel, BorderLayout.SOUTH);
        frame.add(bottom, BorderLayout.SOUTH);

        resetSelectionOnly();
        frame.pack();
        frame.setMinimumSize(new Dimension(700, 600));
        frame.setLocationRelativeTo(null);
        frame.setVisible(true);
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new CrypticPasswordSwing().buildAndShow());
    }
}
