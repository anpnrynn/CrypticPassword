#include "../common/crypticpassword_core.h"
#include <stdio.h>
#include <string.h>

static int check_version_pin(CrypticAlgorithmVersion version, int pin, const char *expected)
{
    char out[CRYPTIC_TOTAL_CELLS + 1];
    cryptic_shuffle_with_pin_version(pin, version, out);
    if (strcmp(out, expected) != 0) {
        fprintf(stderr, "version %d pin %d failed\nexpected: %s\nactual  : %s\n", (int)version, pin, expected, out);
        return 1;
    }
    if (strlen(out) != CRYPTIC_TOTAL_CELLS) {
        fprintf(stderr, "version %d pin %d produced length %zu\n", (int)version, pin, strlen(out));
        return 1;
    }
    return 0;
}

static int check_pin(int pin, const char *expected)
{
    char out[CRYPTIC_TOTAL_CELLS + 1];
    cryptic_shuffle_with_pin(pin, out);
    if (strcmp(out, expected) != 0) {
        fprintf(stderr, "default pin %d failed\nexpected: %s\nactual  : %s\n", pin, expected, out);
        return 1;
    }
    return 0;
}

int main(void)
{
    int failed = 0;

    failed += check_version_pin((CrypticAlgorithmVersion)0, 1,
        "H1F3D5B7997b5d3f1hg0e2c4a6886A4y_!?'=+;-/:.<,>*^$`z$x*v,t.r:p<n>l^j`_i?k=m;o/q-s+u'w~C2E0GYIWKUMSOQRPTNVLXJZ");

    failed += check_version_pin((CrypticAlgorithmVersion)0, 2023,
        "HCFMDOB/9S7'5h3f1:`UQ+PeN/`.=<?*_$~sb220Yw6y8cIaK4xJzAvRt!rLpqnolmj;8;?W_-0-9+^d53i$':^G>E7,gZ6.k,4*>1<X=VuT");

    failed += check_version_pin((CrypticAlgorithmVersion)1, 1,
        "7c9ebgdKLMNOP_`_$x*v,t.-/+;'=~?yiwkumsoqr:p<QR4T20BfChDEFGHIJ0Y1ZA183U3456V6X7n>l^j`z!$'*+,-./W92S85a:;<=>?^");

    failed += check_version_pin((CrypticAlgorithmVersion)1, 2023,
        "+`zT0<>8:3?kt=>_lWno77$GD!IdXy9,a4i'JUv?*23CF1OB-M<9^.r2/f.pNex:4Z;sb-hKA8^j5~$c*+Eu'L6gq;=PH,S_R61m`Q5/w0YV");

    failed += check_version_pin((CrypticAlgorithmVersion)2, 1,
        "HbFdDfBh9j7l5n3p1rq0o2m4k6i8gAe&;(\\_\\-]{|[}\\=:+\")'*>^,$/@&~(z_x-v{t|}s=u+w)y*`^!.#?%<CcEaGYIWKUMSOQRPTNVLXJZ");

    failed += check_version_pin((CrypticAlgorithmVersion)2, 2023,
        "HCFMDOB|9S7?5r3p1(|UQ.PoN*'&\\\\\\+;><!lc2aY%6&8mIkKe^J*A$R@(~Lz`xyvwt]i)=W}^0{j-{nfds)_[\"G:Eh/qZg}u=4,-b_X+V#T");

    failed += check_version_pin((CrypticAlgorithmVersion)3, 1,
        "hmjolqnKLMNOP;'}>^,$/@&^*.)?+<=&s%u#w!y`~(z_QR4T2aBpCrDEFGHIJ0Y1ZAb8dU3e56VgX7x-v{t|*()_+-={}|W9cSifk[]\\\\:\\\"");

    failed += check_version_pin((CrypticAlgorithmVersion)3, 2023,
        "-|*T0_-i(3\\u@+:;vWxy7h)GD(InX&j/kes_JU$=+cdCF1OB^M\\9{&~2|p}zNo^[4Z)!l{rKA8\"t5<>m,.E#?Lgq`]\\PH=S}R6bw'Qf*%aYV");

    failed += check_pin(2023,
        "HCFMDOB/9S7'5h3f1:`UQ+PeN/`.=<?*_$~sb220Yw6y8cIaK4xJzAvRt!rLpqnolmj;8;?W_-0-9+^d53i$':^G>E7,gZ6.k,4*>1<X=VuT");

    if (CRYPTIC_TOTAL_CELLS != 108 || CRYPTIC_MATRIX_COUNT != 3 || CRYPTIC_MATRIX_SIZE != 36) {
        fprintf(stderr, "matrix constants failed\n");
        failed += 1;
    }

    if (cryptic_seed_length_for_version(CRYPTIC_ALGO_VERSION_1_0) != 108) {
        fprintf(stderr, "seed1 length check failed\n");
        failed += 1;
    }
    if (cryptic_seed_length_for_version(CRYPTIC_ALGO_VERSION_2_0) != 112) {
        fprintf(stderr, "seed2 full length check failed\n");
        failed += 1;
    }

    if (failed == 0) {
        puts("CrypticPassword core tests passed for version1_0, version1_1, version2_0, and version2_1.");
        return 0;
    }

    return 1;
}
