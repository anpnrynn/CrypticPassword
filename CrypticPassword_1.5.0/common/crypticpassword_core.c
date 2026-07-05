#include "crypticpassword_core.h"

#include <string.h>

static void swapchars(char *s, int m, int n)
{
    char c = s[m];
    s[m] = s[n];
    s[n] = c;
}

/* JavaScript/MFC rotate(s, n): s.substr(n) + s.substr(0, n). */
static void rotate_left(char *s, int count, int n)
{
    char temp[CRYPTIC_TOTAL_CELLS + 8];

    if (s == 0 || n <= 0 || count <= 0) {
        return;
    }

    count %= n;
    if (count == 0) {
        return;
    }

    memcpy(temp, s, (size_t)count);
    memmove(s, s + count, (size_t)(n - count));
    memcpy(s + (n - count), temp, (size_t)count);
}

static void copy_seed_prefix(char output[CRYPTIC_TOTAL_CELLS + 1], const char *seed)
{
    memcpy(output, seed, CRYPTIC_TOTAL_CELLS);
    output[CRYPTIC_TOTAL_CELLS] = '\0';
}

static void shuffle_simple(char data[CRYPTIC_TOTAL_CELLS + 1], int pin)
{
    const int n = CRYPTIC_TOTAL_CELLS;
    int k = 1;
    int j;

    for (j = 0; j < pin; ++j) {
        char *s1 = &data[0];
        char *s2 = &data[n / 2];
        int i;

        for (i = 0; i < n / 4; ++i) {
            if ((k % 2) == 0) {
                swapchars(s1, i, (n / 2) - i - 1);
                swapchars(s2, i, (n / 2) - i - 1);
            } else {
                swapchars(s1, i, (n / 2) - i - 2);
                swapchars(s2, i, (n / 2) - i - 2);
            }
            ++k;
        }

        rotate_left(s1, 13, n / 2);
        rotate_left(s2, 17, n / 2);
        rotate_left(data, 23, n);
        data[CRYPTIC_TOTAL_CELLS] = '\0';
    }
}

static int rotatevalue(int pin, const unsigned int *shiftkeys)
{
    static const int rotatevalues[] = {
        3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
        13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
        23, 24, 25, 26, 27, 28, 29, 30, 31, 32,
        33, 34, 35, 36, 37, 0
    };
    int i = 0;

    while (shiftkeys[i] != 0) {
        if ((unsigned int)pin < shiftkeys[i]) {
            return 0;
        }
        if (((unsigned int)pin % shiftkeys[i]) == 0) {
            return rotatevalues[i];
        }
        ++i;
    }
    return 0;
}

static void shuffle_enhanced(char data[CRYPTIC_TOTAL_CELLS + 1], int pin)
{
    static const unsigned int shiftkeys[] = { 3500U, 301390U, 0U };
    const int random_values[] = { 23, 13, 17, 7, 11 };
    const int n = CRYPTIC_TOTAL_CELLS;
    int k = 1;
    int j;
    char rotated[CRYPTIC_TOTAL_CELLS + 1];

    (void)rotated;

    for (j = 0; j < pin; ++j) {
        char *s1 = &data[0];
        char *s2 = &data[n / 2];
        int i;

        for (i = 0; i < n / 4; ++i) {
            if ((k % 2) == 0) {
                swapchars(s1, i, (n / 2) - i - 1);
                swapchars(s1 + random_values[3], i, (n / 2) - i - 1 - random_values[2]);
                swapchars(s2, i, (n / 2) - i - 1);
                swapchars(s1 + random_values[4], i, (n / 2) - i - 1 - random_values[4]);
            } else {
                swapchars(s1, i, (n / 2) - i - 2);
                swapchars(s1 + random_values[3], i, (n / 2) - i - 2 - random_values[3]);
                swapchars(s2, i, (n / 2) - i - 2);
                swapchars(s1 + random_values[4], i, (n / 2) - i - 2 - random_values[4]);
            }
            swapchars(s1, i, random_values[1] + i);
            swapchars(s2, i, random_values[2] + i);
            ++k;
        }

        rotate_left(s1, random_values[1], n / 2);
        rotate_left(s2, random_values[2], n / 2);
        rotate_left(data, random_values[0], n - random_values[0]);
        rotate_left(s1, random_values[3], n - random_values[3]);
        rotate_left(&s1[random_values[3]], random_values[4], n / 2);
        data[CRYPTIC_TOTAL_CELLS] = '\0';

        /* The uploaded MFC code computes an alternate rotated buffer for some
           pins, then overwrites the user-visible shuffled buffer with the main
           data buffer. Keep this calculation side-effect-free for compatibility
           documentation while returning the user-visible 108-cell data. */
        if (rotatevalue(pin, shiftkeys) != 0) {
            memcpy(rotated, data, CRYPTIC_TOTAL_CELLS + 1);
            rotate_left(rotated, rotatevalue(pin, shiftkeys), n - rotatevalue(pin, shiftkeys));
            rotated[CRYPTIC_TOTAL_CELLS] = '\0';
        }
    }
}

int cryptic_pin_normalize(int pin)
{
    if (pin < CRYPTIC_PIN_MIN) {
        return CRYPTIC_PIN_MIN;
    }
    if (pin > CRYPTIC_PIN_MAX) {
        return CRYPTIC_PIN_MAX;
    }
    return pin;
}

CrypticAlgorithmVersion cryptic_algorithm_normalize(int version)
{
    switch (version) {
        case CRYPTIC_ALGO_VERSION_1_0:
        case CRYPTIC_ALGO_VERSION_1_1:
        case CRYPTIC_ALGO_VERSION_2_0:
        case CRYPTIC_ALGO_VERSION_2_1:
            return (CrypticAlgorithmVersion)version;
        default:
            return CRYPTIC_ALGO_DEFAULT;
    }
}

const char *cryptic_algorithm_display_name(CrypticAlgorithmVersion version)
{
    switch (cryptic_algorithm_normalize((int)version)) {
        case CRYPTIC_ALGO_VERSION_1_0: return "version1_0 / seed1";
        case CRYPTIC_ALGO_VERSION_1_1: return "version1_1 / seed1";
        case CRYPTIC_ALGO_VERSION_2_0: return "version2_0 / seed2";
        case CRYPTIC_ALGO_VERSION_2_1: return "version2_1 / seed2";
        default: return "version1_0 / seed1";
    }
}

const char *cryptic_seed_for_version(CrypticAlgorithmVersion version)
{
    switch (cryptic_algorithm_normalize((int)version)) {
        case CRYPTIC_ALGO_VERSION_2_0:
        case CRYPTIC_ALGO_VERSION_2_1:
            return CRYPTIC_PASSWORD_SEED2_FULL;
        case CRYPTIC_ALGO_VERSION_1_0:
        case CRYPTIC_ALGO_VERSION_1_1:
        default:
            return CRYPTIC_PASSWORD_SEED1;
    }
}

size_t cryptic_seed_length_for_version(CrypticAlgorithmVersion version)
{
    const char *seed = cryptic_seed_for_version(version);
    return strlen(seed);
}

void cryptic_shuffle_with_pin_version(int pin, CrypticAlgorithmVersion version, char output[CRYPTIC_TOTAL_CELLS + 1])
{
    CrypticAlgorithmVersion normalized_version = cryptic_algorithm_normalize((int)version);

    pin = cryptic_pin_normalize(pin);
    copy_seed_prefix(output, cryptic_seed_for_version(normalized_version));

    switch (normalized_version) {
        case CRYPTIC_ALGO_VERSION_1_1:
        case CRYPTIC_ALGO_VERSION_2_1:
            shuffle_enhanced(output, pin);
            break;
        case CRYPTIC_ALGO_VERSION_1_0:
        case CRYPTIC_ALGO_VERSION_2_0:
        default:
            shuffle_simple(output, pin);
            break;
    }

    output[CRYPTIC_TOTAL_CELLS] = '\0';
}

void cryptic_shuffle_with_pin(int pin, char output[CRYPTIC_TOTAL_CELLS + 1])
{
    cryptic_shuffle_with_pin_version(pin, CRYPTIC_ALGO_DEFAULT, output);
}

char cryptic_character_at(const char shuffled[CRYPTIC_TOTAL_CELLS + 1], int zero_based_cell_index)
{
    if (!shuffled || zero_based_cell_index < 0 || zero_based_cell_index >= CRYPTIC_TOTAL_CELLS) {
        return '\0';
    }
    return shuffled[zero_based_cell_index];
}
