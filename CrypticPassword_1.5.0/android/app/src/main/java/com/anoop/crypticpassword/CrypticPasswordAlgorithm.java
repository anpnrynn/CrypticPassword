package com.anoop.crypticpassword;

public final class CrypticPasswordAlgorithm {
    public enum Version {
        VERSION_1_0("version1_0 / seed1"),
        VERSION_1_1("version1_1 / seed1"),
        VERSION_2_0("version2_0 / seed2"),
        VERSION_2_1("version2_1 / seed2");

        public final String label;
        Version(String label) { this.label = label; }
    }

    public static final int MATRIX_COUNT = 3;
    public static final int MATRIX_ROWS = 6;
    public static final int MATRIX_COLUMNS = 6;
    public static final int MATRIX_SIZE = 36;
    public static final int TOTAL_CELLS = 108;
    public static final int PIN_MINIMUM = 1;
    public static final int PIN_MAXIMUM = 99999;

    public static final String SEED1 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!$'*+,-./:;<=>?^_`~$'*+,-./:;<=>?^_`";
    public static final String SEED2 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-={}|[]\\\\:\\\";'<>?,./^&*()_+-={}|[]\\\";";

    private CrypticPasswordAlgorithm() {}

    public static int normalizePin(int pin) {
        if (pin < PIN_MINIMUM) return PIN_MINIMUM;
        if (pin > PIN_MAXIMUM) return PIN_MAXIMUM;
        return pin;
    }

    private static String seedFor(Version version) {
        switch (version) {
            case VERSION_2_0:
            case VERSION_2_1:
                return SEED2;
            case VERSION_1_0:
            case VERSION_1_1:
            default:
                return SEED1;
        }
    }

    private static void rotate(char[] data, int start, int count, int length) {
        if (length <= 0) return;
        int shift = count % length;
        if (shift <= 0) return;
        char[] temp = new char[length];
        System.arraycopy(data, start + shift, temp, 0, length - shift);
        System.arraycopy(data, start, temp, length - shift, shift);
        System.arraycopy(temp, 0, data, start, length);
    }

    private static void swap(char[] data, int base, int i, int j) {
        char tmp = data[base + i];
        data[base + i] = data[base + j];
        data[base + j] = tmp;
    }

    private static void shuffleSimple(char[] data, int pin) {
        final int n = TOTAL_CELLS;
        final int half = n / 2;
        int k = 1;
        for (int j = 0; j < pin; j++) {
            for (int i = 0; i < n / 4; i++) {
                if (k % 2 == 0) {
                    swap(data, 0, i, half - i - 1);
                    swap(data, half, i, half - i - 1);
                } else {
                    swap(data, 0, i, half - i - 2);
                    swap(data, half, i, half - i - 2);
                }
                k++;
            }
            rotate(data, 0, 13, half);
            rotate(data, half, 17, half);
            rotate(data, 0, 23, n);
        }
    }

    private static void shuffleEnhanced(char[] data, int pin) {
        final int n = TOTAL_CELLS;
        final int half = n / 2;
        final int[] random = {23, 13, 17, 7, 11};
        int k = 1;
        for (int j = 0; j < pin; j++) {
            for (int i = 0; i < n / 4; i++) {
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
                k++;
            }
            rotate(data, 0, random[1], half);
            rotate(data, half, random[2], half);
            rotate(data, 0, random[0], n - random[0]);
            rotate(data, 0, random[3], n - random[3]);
            rotate(data, random[3], random[4], half);
        }
    }

    public static String shuffle(Version version, int rawPin) {
        int pin = normalizePin(rawPin);
        String seed = seedFor(version);
        char[] data = seed.substring(0, TOTAL_CELLS).toCharArray();
        switch (version) {
            case VERSION_1_1:
            case VERSION_2_1:
                shuffleEnhanced(data, pin);
                break;
            case VERSION_1_0:
            case VERSION_2_0:
            default:
                shuffleSimple(data, pin);
                break;
        }
        return new String(data, 0, TOTAL_CELLS);
    }
}
