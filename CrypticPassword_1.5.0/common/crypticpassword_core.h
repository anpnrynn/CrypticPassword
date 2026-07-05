#ifndef CRYPTICPASSWORD_CORE_H
#define CRYPTICPASSWORD_CORE_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CRYPTIC_MATRIX_COUNT 3
#define CRYPTIC_MATRIX_ROWS 6
#define CRYPTIC_MATRIX_COLS 6
#define CRYPTIC_MATRIX_SIZE 36
#define CRYPTIC_TOTAL_CELLS 108
#define CRYPTIC_PIN_MIN 1
#define CRYPTIC_PIN_MAX 99999

/* Seed 1: original Generation Two initdata string from CrypticPassword.html. */
#define CRYPTIC_PASSWORD_SEED1 "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!$'*+,-./:;<=>?^_`~$'*+,-./:;<=>?^_`"

/* Backwards-compatible name used by older package revisions. */
#define CRYPTIC_PASSWORD_SEED CRYPTIC_PASSWORD_SEED1

/* Seed 2: second initdata string copied from CrypticPasswordDlg.cpp.
   The desktop matrix has 108 cells, so algorithm versions 2.0 and 2.1 use
   the first 108 characters for matrix output, matching the uploaded MFC code's
   108-cell indexing. */
#define CRYPTIC_PASSWORD_SEED2_FULL "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-={}|[]\\\\:\\\";'<>?,./^&*()_+-={}|[]\";"
#define CRYPTIC_PASSWORD_SEED2_USED_LENGTH CRYPTIC_TOTAL_CELLS

typedef enum CrypticAlgorithmVersion {
    CRYPTIC_ALGO_VERSION_1_0 = 0,
    CRYPTIC_ALGO_VERSION_1_1 = 1,
    CRYPTIC_ALGO_VERSION_2_0 = 2,
    CRYPTIC_ALGO_VERSION_2_1 = 3
} CrypticAlgorithmVersion;

#define CRYPTIC_ALGO_DEFAULT CRYPTIC_ALGO_VERSION_1_0

int cryptic_pin_normalize(int pin);
CrypticAlgorithmVersion cryptic_algorithm_normalize(int version);
const char *cryptic_algorithm_display_name(CrypticAlgorithmVersion version);
const char *cryptic_seed_for_version(CrypticAlgorithmVersion version);
size_t cryptic_seed_length_for_version(CrypticAlgorithmVersion version);

void cryptic_shuffle_with_pin(int pin, char output[CRYPTIC_TOTAL_CELLS + 1]);
void cryptic_shuffle_with_pin_version(int pin, CrypticAlgorithmVersion version, char output[CRYPTIC_TOTAL_CELLS + 1]);
char cryptic_character_at(const char shuffled[CRYPTIC_TOTAL_CELLS + 1], int zero_based_cell_index);

#ifdef __cplusplus
}
#endif

#endif /* CRYPTICPASSWORD_CORE_H */
