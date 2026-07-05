# Analysis of CrypticPassword inputs

The original `CrypticPassword.html` is an HTML/JavaScript password-generation page. It declares a Generation Two `initdata` string and uses JavaScript functions named `rotate`, `swapchars`, and `shuffle` to generate a shuffled 108-character mapping from a numeric PIN.

The uploaded `CrypticPasswordDlg.cpp` adds a second seed string and four MFC radio-button selectable behaviors:

- `version1_0 / seed1`: simple shuffle using seed 1.
- `version1_1 / seed1`: enhanced shuffle using seed 1.
- `version2_0 / seed2`: simple shuffle using seed 2.
- `version2_1 / seed2`: enhanced shuffle using seed 2.

## Shared matrix model

The application maintains exactly three matrices:

- Matrix 1: cells 1-36, shuffled indices 0-35.
- Matrix 2: cells 37-72, shuffled indices 36-71.
- Matrix 3: cells 73-108, shuffled indices 72-107.

All desktop front ends use the same 108-cell matrix contract.

## Seed strings

Seed 1 is the original 108-character string:

```text
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!$'*+,-./:;<=>?^_`~$'*+,-./:;<=>?^_`
```

Seed 2 is copied from the uploaded MFC source. Its source string has 112 printable characters:

```text
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`~!@#$%^&*()_+-={}|[]\\:";'<>?,./^&*()_+-={}|[]";
```

Because the UI has 108 cells, the version2_0 and version2_1 matrix output uses the first 108 characters for the shuffled cell mapping.

## Simple shuffle used by version1_0 and version2_0

1. Start from the selected seed prefix.
2. For each PIN iteration:
   1. Split the 108-character string into two 54-character halves.
   2. For 27 positions, swap characters in both halves.
      - When the persistent counter `k` is even, swap index `i` with `54 - i - 1`.
      - When `k` is odd, swap index `i` with `54 - i - 2`.
   3. Rotate the first half by 13.
   4. Rotate the second half by 17.
   5. Rotate the complete 108-character string by 23.
3. Split the final string into three 36-character ranges.

## Enhanced shuffle used by version1_1 and version2_1

The enhanced shuffle uses the same 108-cell base, but adds extra swaps and rotations based on the uploaded MFC `random` values `{23, 13, 17, 7, 11}`.

Per PIN iteration:

1. Use the two 54-character halves.
2. For each of 27 positions:
   - Perform the standard half swap.
   - Perform additional offset swaps at bases 7 and 11 against the first half.
   - Perform the standard second-half swap.
   - Swap `s1[i]` with `s1[13 + i]`.
   - Swap `s2[i]` with `s2[17 + i]`.
3. Rotate first half by 13.
4. Rotate second half by 17.
5. Rotate the first 85 characters by 23.
6. Rotate the first 101 characters by 7.
7. Rotate the 54-character range starting at offset 7 by 11.

The uploaded MFC code also computes an alternate rotated buffer for certain shift-key divisibility cases, but then overwrites the visible shuffled data with the main data buffer. The shared implementation keeps the user-visible behavior.

## Matrix colors

All matrix buttons are colored by matrix at all times:

- Matrix 1: red `#FF2A2A`.
- Matrix 2: green `#55D400`.
- Matrix 3: blue `#37abc8`.

The clicked state is represented by returning the clicked matrix button to the default system button appearance; no OFF/ON labels are used.

## Test vectors

The C and Swift validation targets check PIN 1 and PIN 2023 for every algorithm version. Example PIN 2023 outputs:

### version1_0 / seed1

```text
HCFMDOB/9S7'5h3f1:`UQ+PeN/`.=<?*_$~sb220Yw6y8cIaK4xJzAvRt!rLpqnolmj;8;?W_-0-9+^d53i$':^G>E7,gZ6.k,4*>1<X=VuT
```

### version1_1 / seed1

```text
+`zT0<>8:3?kt=>_lWno77$GD!IdXy9,a4i'JUv?*23CF1OB-M<9^.r2/f.pNex:4Z;sb-hKA8^j5~$c*+Eu'L6gq;=PH,S_R61m`Q5/w0YV
```

### version2_0 / seed2

```text
HCFMDOB|9S7?5r3p1(|UQ.PoN*'&\\\+;><!lc2aY%6&8mIkKe^J*A$R@(~Lz`xyvwt]i)=W}^0{j-{nfds)_["G:Eh/qZg}u=4,-b_X+V#T
```

### version2_1 / seed2

```text
-|*T0_-i(3\u@+:;vWxy7h)GD(InX&j/kes_JU$=+cdCF1OB^M\9{&~2|p}zNo^[4Z)!l{rKA8"t5<>m,.E#?Lgq`]\PH=S}R6bw'Qf*%aYV
```


## Android 12+ port

The Android port is implemented as a native Android SDK application using Java Activity/UI widgets. It mirrors the desktop/iOS algorithm set, both seed strings, the three 6x6 matrix workflow, red/green/blue matrix colors, and selected-cell return to system-default button appearance.
