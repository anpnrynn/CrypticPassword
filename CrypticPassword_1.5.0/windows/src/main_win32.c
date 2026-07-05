#include <windows.h>
#include <commctrl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <wchar.h>

#include "../../common/crypticpassword_core.h"
#include "resource.h"

#pragma comment(lib, "comctl32.lib")

#define APP_CLASS_NAME L"CrypticPasswordWin32Window"
#define MAX_PASSWORD_CHARS CRYPTIC_TOTAL_CELLS

typedef struct AppState {
    HWND hwnd;
    HWND pinEdit;
    HWND algoCombo;
    HWND outputEdit;
    HWND statusLabel;
    HWND patternLabel;
    HWND cells[CRYPTIC_TOTAL_CELLS];
    int selected[CRYPTIC_TOTAL_CELLS];
    int currentMatrix;
    int generated;
    char shuffled[CRYPTIC_TOTAL_CELLS + 1];
    char password[MAX_PASSWORD_CHARS + 1];
    int passwordLength;
    HFONT uiFont;
} AppState;

static const wchar_t *kAlgorithmLabels[] = {
    L"version1_0 / seed1",
    L"version1_1 / seed1",
    L"version2_0 / seed2",
    L"version2_1 / seed2"
};

static AppState g_app;

static void set_status(const wchar_t *text)
{
    SetWindowTextW(g_app.statusLabel, text);
}

static int parse_pin(void)
{
    wchar_t text[32];
    int pin;
    GetWindowTextW(g_app.pinEdit, text, 32);
    pin = _wtoi(text);
    return cryptic_pin_normalize(pin);
}

static CrypticAlgorithmVersion current_algorithm(void)
{
    LRESULT index = SendMessageW(g_app.algoCombo, CB_GETCURSEL, 0, 0);
    if (index == CB_ERR) {
        return CRYPTIC_ALGO_DEFAULT;
    }
    return cryptic_algorithm_normalize((int)index);
}

static void set_output_from_ascii(const char *text)
{
    wchar_t wbuf[MAX_PASSWORD_CHARS + 1];
    int i;
    for (i = 0; text[i] != '\0' && i < MAX_PASSWORD_CHARS; ++i) {
        wbuf[i] = (wchar_t)(unsigned char)text[i];
    }
    wbuf[i] = L'\0';
    SetWindowTextW(g_app.outputEdit, wbuf);
}

static void update_pattern_label(void)
{
    wchar_t label[64];
    swprintf(label, 64, L"Pattern %d of 3", g_app.currentMatrix + 1);
    SetWindowTextW(g_app.patternLabel, label);
}

static void update_visible_matrix(void)
{
    int i;
    for (i = 0; i < CRYPTIC_TOTAL_CELLS; ++i) {
        int matrix = i / CRYPTIC_MATRIX_SIZE;
        ShowWindow(g_app.cells[i], matrix == g_app.currentMatrix ? SW_SHOW : SW_HIDE);
    }
    update_pattern_label();
}

static void reset_selection_only(void)
{
    int i;
    memset(g_app.selected, 0, sizeof(g_app.selected));
    for (i = 0; i < CRYPTIC_TOTAL_CELLS; ++i) {
        InvalidateRect(g_app.cells[i], NULL, TRUE);
    }
    g_app.password[0] = '\0';
    g_app.passwordLength = 0;
    set_output_from_ascii(g_app.password);
}

static void generate_password_matrix(void)
{
    int pin = parse_pin();
    wchar_t status[128];
    CrypticAlgorithmVersion version = current_algorithm();
    cryptic_shuffle_with_pin_version(pin, version, g_app.shuffled);
    g_app.generated = 1;
    reset_selection_only();
    swprintf(status, 128, L"Generated 3 matrices using PIN %d, %s.", pin, kAlgorithmLabels[(int)version]);
    set_status(status);
}

static void reset_all(void)
{
    SetWindowTextW(g_app.pinEdit, L"2023");
    SendMessageW(g_app.algoCombo, CB_SETCURSEL, 0, 0);
    g_app.generated = 0;
    memset(g_app.shuffled, 0, sizeof(g_app.shuffled));
    reset_selection_only();
    g_app.currentMatrix = 0;
    update_visible_matrix();
    set_status(L"Enter a PIN and click Generate.");
}

static void finish_password(void)
{
    set_output_from_ascii(g_app.password);
}

static void cell_clicked(int index)
{
    if (!g_app.generated) {
        generate_password_matrix();
    }

    if (index < 0 || index >= CRYPTIC_TOTAL_CELLS || g_app.selected[index]) {
        return;
    }

    if (g_app.passwordLength < MAX_PASSWORD_CHARS) {
        char c = cryptic_character_at(g_app.shuffled, index);
        if (c != '\0') {
            g_app.password[g_app.passwordLength++] = c;
            g_app.password[g_app.passwordLength] = '\0';
        }
    }

    g_app.selected[index] = 1;
    InvalidateRect(g_app.cells[index], NULL, TRUE);
    finish_password();
}

static COLORREF matrix_color(int matrix)
{
    switch (matrix) {
        case 0: return RGB(255, 42, 42);
        case 1: return RGB(85, 212, 0);
        case 2: return RGB(55, 171, 200);
        default: return RGB(80, 80, 80);
    }
}

static void draw_cell_button(const DRAWITEMSTRUCT *dis)
{
    int index = (int)dis->CtlID - IDC_CELL_BASE;
    int matrix = index / CRYPTIC_MATRIX_SIZE;
    int selected = (index >= 0 && index < CRYPTIC_TOTAL_CELLS) ? g_app.selected[index] : 0;
    HDC hdc = dis->hDC;
    RECT rc = dis->rcItem;
    HPEN pen;
    HPEN oldPen;
    HBRUSH bg;
    HBRUSH oldBrush;

    if (selected) {
        FillRect(hdc, &rc, (HBRUSH)(COLOR_BTNFACE + 1));
        DrawFrameControl(hdc, &rc, DFC_BUTTON, DFCS_BUTTONPUSH);
        return;
    }

    bg = CreateSolidBrush(matrix_color(matrix));
    pen = CreatePen(PS_SOLID, 1, RGB(100, 100, 100));

    FillRect(hdc, &rc, (HBRUSH)(COLOR_BTNFACE + 1));
    InflateRect(&rc, -3, -3);

    oldPen = (HPEN)SelectObject(hdc, pen);
    oldBrush = (HBRUSH)SelectObject(hdc, bg);
    RoundRect(hdc, rc.left, rc.top, rc.right, rc.bottom, 10, 10);

    SelectObject(hdc, oldBrush);
    SelectObject(hdc, oldPen);
    DeleteObject(bg);
    DeleteObject(pen);
}

static BOOL CALLBACK set_child_font_proc(HWND child, LPARAM font)
{
    SendMessageW(child, WM_SETFONT, (WPARAM)font, TRUE);
    return TRUE;
}

static void create_controls(HWND hwnd)
{
    int matrix, row, col;
    int startX = 24;
    int startY = 128;
    int step = 48;
    int i;

    g_app.uiFont = (HFONT)GetStockObject(DEFAULT_GUI_FONT);

    CreateWindowW(L"STATIC", L"CrypticPassword (Secure Password Generation Tool)",
        WS_CHILD | WS_VISIBLE, 24, 18, 620, 22, hwnd, NULL, NULL, NULL);

    CreateWindowW(L"STATIC", L"PIN (1-99999):", WS_CHILD | WS_VISIBLE,
        24, 56, 100, 24, hwnd, NULL, NULL, NULL);

    g_app.pinEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"2023",
        WS_CHILD | WS_VISIBLE | ES_NUMBER | ES_AUTOHSCROLL,
        130, 54, 90, 26, hwnd, (HMENU)IDC_PIN, NULL, NULL);

    CreateWindowW(L"STATIC", L"Algorithm:", WS_CHILD | WS_VISIBLE,
        236, 56, 76, 24, hwnd, NULL, NULL, NULL);

    g_app.algoCombo = CreateWindowW(L"COMBOBOX", L"",
        WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST | WS_VSCROLL | WS_TABSTOP,
        316, 52, 210, 150, hwnd, (HMENU)IDC_ALGORITHM, NULL, NULL);
    for (i = 0; i < 4; ++i) {
        SendMessageW(g_app.algoCombo, CB_ADDSTRING, 0, (LPARAM)kAlgorithmLabels[i]);
    }
    SendMessageW(g_app.algoCombo, CB_SETCURSEL, 0, 0);

    CreateWindowW(L"BUTTON", L"Generate", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        542, 52, 88, 30, hwnd, (HMENU)IDC_GENERATE, NULL, NULL);

    CreateWindowW(L"BUTTON", L"Reset", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        640, 52, 72, 30, hwnd, (HMENU)IDC_RESET, NULL, NULL);

    g_app.patternLabel = CreateWindowW(L"STATIC", L"Pattern 1 of 3", WS_CHILD | WS_VISIBLE,
        24, 96, 240, 22, hwnd, (HMENU)IDC_PATTERN_LABEL, NULL, NULL);

    for (matrix = 0; matrix < CRYPTIC_MATRIX_COUNT; ++matrix) {
        for (row = 0; row < CRYPTIC_MATRIX_ROWS; ++row) {
            for (col = 0; col < CRYPTIC_MATRIX_COLS; ++col) {
                int index = matrix * CRYPTIC_MATRIX_SIZE + row * CRYPTIC_MATRIX_COLS + col;
                g_app.cells[index] = CreateWindowW(L"BUTTON", L"",
                    WS_CHILD | BS_OWNERDRAW | BS_PUSHBUTTON,
                    startX + col * step, startY + row * step, 40, 40,
                    hwnd, (HMENU)(IDC_CELL_BASE + index), NULL, NULL);
                SendMessageW(g_app.cells[index], WM_SETFONT, (WPARAM)g_app.uiFont, TRUE);
            }
        }
    }

    CreateWindowW(L"BUTTON", L"Back <", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        24, 436, 80, 30, hwnd, (HMENU)IDC_BACK, NULL, NULL);
    CreateWindowW(L"BUTTON", L"Next >", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        114, 436, 80, 30, hwnd, (HMENU)IDC_NEXT, NULL, NULL);
    CreateWindowW(L"BUTTON", L"Finish", WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        204, 436, 80, 30, hwnd, (HMENU)IDC_FINISH, NULL, NULL);

    CreateWindowW(L"STATIC", L"Password:", WS_CHILD | WS_VISIBLE,
        24, 484, 80, 24, hwnd, NULL, NULL, NULL);
    g_app.outputEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"",
        WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL,
        108, 480, 600, 26, hwnd, (HMENU)IDC_OUTPUT, NULL, NULL);

    g_app.statusLabel = CreateWindowW(L"STATIC", L"Enter a PIN and click Generate.",
        WS_CHILD | WS_VISIBLE, 24, 522, 690, 24, hwnd, (HMENU)IDC_STATUS, NULL, NULL);

    EnumChildWindows(hwnd, set_child_font_proc, (LPARAM)g_app.uiFont);

    update_visible_matrix();
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    switch (msg) {
    case WM_CREATE:
        g_app.hwnd = hwnd;
        g_app.currentMatrix = 0;
        create_controls(hwnd);
        return 0;

    case WM_COMMAND: {
        int id = LOWORD(wParam);
        if (id == IDC_GENERATE) {
            generate_password_matrix();
        } else if (id == IDC_RESET) {
            reset_all();
        } else if (id == IDC_BACK) {
            if (g_app.currentMatrix > 0) {
                --g_app.currentMatrix;
                update_visible_matrix();
            }
        } else if (id == IDC_NEXT) {
            if (g_app.currentMatrix < CRYPTIC_MATRIX_COUNT - 1) {
                ++g_app.currentMatrix;
                update_visible_matrix();
            }
        } else if (id == IDC_FINISH) {
            finish_password();
        } else if (id == IDC_ALGORITHM) {
            g_app.generated = 0;
            memset(g_app.shuffled, 0, sizeof(g_app.shuffled));
            reset_selection_only();
            set_status(L"Algorithm changed. Click Generate.");
        } else if (id >= IDC_CELL_BASE && id < IDC_CELL_BASE + CRYPTIC_TOTAL_CELLS) {
            cell_clicked(id - IDC_CELL_BASE);
        }
        return 0;
    }

    case WM_DRAWITEM:
        if (wParam >= IDC_CELL_BASE && wParam < IDC_CELL_BASE + CRYPTIC_TOTAL_CELLS) {
            draw_cell_button((const DRAWITEMSTRUCT *)lParam);
            return TRUE;
        }
        break;

    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR lpCmdLine, int nCmdShow)
{
    INITCOMMONCONTROLSEX icc;
    WNDCLASSEXW wc;
    HWND hwnd;
    MSG msg;

    (void)hPrevInstance;
    (void)lpCmdLine;

    icc.dwSize = sizeof(icc);
    icc.dwICC = ICC_STANDARD_CLASSES;
    InitCommonControlsEx(&icc);

    ZeroMemory(&wc, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = APP_CLASS_NAME;
    wc.hIcon = LoadIcon(NULL, IDI_APPLICATION);
    wc.hIconSm = LoadIcon(NULL, IDI_APPLICATION);

    if (!RegisterClassExW(&wc)) {
        MessageBoxW(NULL, L"Could not register CrypticPassword window class.", L"CrypticPassword", MB_ICONERROR);
        return 1;
    }

    hwnd = CreateWindowExW(0, APP_CLASS_NAME, L"CrypticPassword - Native Win32",
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
        CW_USEDEFAULT, CW_USEDEFAULT, 760, 620,
        NULL, NULL, hInstance, NULL);

    if (!hwnd) {
        MessageBoxW(NULL, L"Could not create CrypticPassword window.", L"CrypticPassword", MB_ICONERROR);
        return 1;
    }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    while (GetMessageW(&msg, NULL, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    return (int)msg.wParam;
}
