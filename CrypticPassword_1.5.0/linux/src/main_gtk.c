#include <gtk/gtk.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../../common/crypticpassword_core.h"

#define MAX_PASSWORD_CHARS CRYPTIC_TOTAL_CELLS

typedef struct AppState {
    GtkWidget *window;
    GtkWidget *pin_spin;
    GtkWidget *algorithm_combo;
    GtkWidget *stack;
    GtkWidget *pattern_label;
    GtkWidget *output_entry;
    GtkWidget *status_label;
    GtkWidget *buttons[CRYPTIC_TOTAL_CELLS];
    gboolean selected[CRYPTIC_TOTAL_CELLS];
    int current_matrix;
    gboolean generated;
    char shuffled[CRYPTIC_TOTAL_CELLS + 1];
    char password[MAX_PASSWORD_CHARS + 1];
    int password_len;
} AppState;

static AppState app;

static const char *k_algorithm_labels[] = {
    "version1_0 / seed1",
    "version1_1 / seed1",
    "version2_0 / seed2",
    "version2_1 / seed2"
};

static void update_output(void)
{
    gtk_entry_set_text(GTK_ENTRY(app.output_entry), app.password);
}

static void update_pattern_label(void)
{
    char text[64];
    snprintf(text, sizeof(text), "Pattern %d of 3", app.current_matrix + 1);
    gtk_label_set_text(GTK_LABEL(app.pattern_label), text);
}

static void apply_button_state(int index)
{
    GtkWidget *button = app.buttons[index];
    GtkStyleContext *ctx = gtk_widget_get_style_context(button);
    int matrix = (index / CRYPTIC_MATRIX_SIZE) + 1;
    char css_class[32];

    gtk_style_context_remove_class(ctx, "matrix-red");
    gtk_style_context_remove_class(ctx, "matrix-green");
    gtk_style_context_remove_class(ctx, "matrix-blue");
    gtk_button_set_label(GTK_BUTTON(button), "");

    if (!app.selected[index]) {
        snprintf(css_class, sizeof(css_class), "matrix-%s",
            matrix == 1 ? "red" : (matrix == 2 ? "green" : "blue"));
        gtk_style_context_add_class(ctx, css_class);
    }
}

static void reset_selection_only(void)
{
    int i;
    memset(app.selected, 0, sizeof(app.selected));
    app.password[0] = '\0';
    app.password_len = 0;
    update_output();
    for (i = 0; i < CRYPTIC_TOTAL_CELLS; ++i) {
        apply_button_state(i);
    }
}

static int current_pin(void)
{
    return cryptic_pin_normalize(gtk_spin_button_get_value_as_int(GTK_SPIN_BUTTON(app.pin_spin)));
}

static CrypticAlgorithmVersion current_algorithm(void)
{
    int active = gtk_combo_box_get_active(GTK_COMBO_BOX(app.algorithm_combo));
    return cryptic_algorithm_normalize(active);
}

static void generate_matrix(void)
{
    int pin = current_pin();
    CrypticAlgorithmVersion version = current_algorithm();
    char status[160];
    cryptic_shuffle_with_pin_version(pin, version, app.shuffled);
    app.generated = TRUE;
    reset_selection_only();
    snprintf(status, sizeof(status), "Generated 3 matrices using PIN %d, %s.", pin, k_algorithm_labels[(int)version]);
    gtk_label_set_text(GTK_LABEL(app.status_label), status);
}

static void generate_clicked(GtkButton *button, gpointer user_data)
{
    (void)button;
    (void)user_data;
    generate_matrix();
}

static void reset_all(GtkButton *button, gpointer user_data)
{
    (void)button;
    (void)user_data;
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(app.pin_spin), 2023.0);
    gtk_combo_box_set_active(GTK_COMBO_BOX(app.algorithm_combo), 0);
    memset(app.shuffled, 0, sizeof(app.shuffled));
    app.generated = FALSE;
    app.current_matrix = 0;
    reset_selection_only();
    gtk_stack_set_visible_child_name(GTK_STACK(app.stack), "matrix1");
    update_pattern_label();
    gtk_label_set_text(GTK_LABEL(app.status_label), "Enter a PIN and click Generate.");
}

static void algorithm_changed(GtkComboBox *combo, gpointer user_data)
{
    (void)combo;
    (void)user_data;
    memset(app.shuffled, 0, sizeof(app.shuffled));
    app.generated = FALSE;
    reset_selection_only();
    gtk_label_set_text(GTK_LABEL(app.status_label), "Algorithm changed. Click Generate.");
}

static void cell_clicked(GtkButton *button, gpointer user_data)
{
    int index = GPOINTER_TO_INT(user_data);
    char c;
    (void)button;

    if (!app.generated) {
        generate_matrix();
    }

    if (index < 0 || index >= CRYPTIC_TOTAL_CELLS || app.selected[index]) {
        return;
    }

    c = cryptic_character_at(app.shuffled, index);
    if (c != '\0' && app.password_len < MAX_PASSWORD_CHARS) {
        app.password[app.password_len++] = c;
        app.password[app.password_len] = '\0';
    }

    app.selected[index] = TRUE;
    apply_button_state(index);
    update_output();
}

static void next_matrix(GtkButton *button, gpointer user_data)
{
    char name[16];
    (void)button;
    (void)user_data;
    if (app.current_matrix < CRYPTIC_MATRIX_COUNT - 1) {
        ++app.current_matrix;
    }
    snprintf(name, sizeof(name), "matrix%d", app.current_matrix + 1);
    gtk_stack_set_visible_child_name(GTK_STACK(app.stack), name);
    update_pattern_label();
}

static void previous_matrix(GtkButton *button, gpointer user_data)
{
    char name[16];
    (void)button;
    (void)user_data;
    if (app.current_matrix > 0) {
        --app.current_matrix;
    }
    snprintf(name, sizeof(name), "matrix%d", app.current_matrix + 1);
    gtk_stack_set_visible_child_name(GTK_STACK(app.stack), name);
    update_pattern_label();
}

static void finish_clicked(GtkButton *button, gpointer user_data)
{
    (void)button;
    (void)user_data;
    update_output();
}

static GtkWidget *create_matrix_grid(int matrix)
{
    GtkWidget *grid = gtk_grid_new();
    int row;
    int col;

    gtk_grid_set_row_spacing(GTK_GRID(grid), 8);
    gtk_grid_set_column_spacing(GTK_GRID(grid), 8);
    gtk_widget_set_margin_top(grid, 8);
    gtk_widget_set_margin_bottom(grid, 8);

    for (row = 0; row < CRYPTIC_MATRIX_ROWS; ++row) {
        for (col = 0; col < CRYPTIC_MATRIX_COLS; ++col) {
            int index = matrix * CRYPTIC_MATRIX_SIZE + row * CRYPTIC_MATRIX_COLS + col;
            GtkWidget *button = gtk_button_new_with_label("");
            gtk_widget_set_size_request(button, 56, 42);
            app.buttons[index] = button;
            g_signal_connect(button, "clicked", G_CALLBACK(cell_clicked), GINT_TO_POINTER(index));
            gtk_grid_attach(GTK_GRID(grid), button, col, row, 1, 1);
        }
    }

    return grid;
}

static void install_css(void)
{
    GtkCssProvider *provider = gtk_css_provider_new();
    const char *css =
        "button.matrix-red { background: #FF2A2A; background-image: none; }"
        "button.matrix-green { background: #55D400; background-image: none; }"
        "button.matrix-blue { background: #37abc8; background-image: none; }";
    gtk_css_provider_load_from_data(provider, css, -1, NULL);
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(),
        GTK_STYLE_PROVIDER(provider), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(provider);
}

static void activate(GtkApplication *gtk_app, gpointer user_data)
{
    GtkWidget *main_box;
    GtkWidget *pin_box;
    GtkWidget *nav_box;
    GtkWidget *output_box;
    GtkWidget *generate_button;
    GtkWidget *reset_button;
    GtkWidget *back_button;
    GtkWidget *next_button;
    GtkWidget *finish_button;
    GtkWidget *grid;
    int i;

    (void)user_data;

    install_css();

    app.window = gtk_application_window_new(gtk_app);
    gtk_window_set_title(GTK_WINDOW(app.window), "CrypticPassword - GTK+");
    gtk_window_set_default_size(GTK_WINDOW(app.window), 620, 590);
    gtk_container_set_border_width(GTK_CONTAINER(app.window), 16);

    main_box = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    gtk_container_add(GTK_CONTAINER(app.window), main_box);

    gtk_box_pack_start(GTK_BOX(main_box), gtk_label_new("CrypticPassword (Secure Password Generation Tool)"), FALSE, FALSE, 0);

    pin_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    gtk_box_pack_start(GTK_BOX(main_box), pin_box, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(pin_box), gtk_label_new("PIN (1-99999):"), FALSE, FALSE, 0);

    app.pin_spin = gtk_spin_button_new_with_range(CRYPTIC_PIN_MIN, CRYPTIC_PIN_MAX, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(app.pin_spin), 2023.0);
    gtk_box_pack_start(GTK_BOX(pin_box), app.pin_spin, FALSE, FALSE, 0);

    gtk_box_pack_start(GTK_BOX(pin_box), gtk_label_new("Algorithm:"), FALSE, FALSE, 0);
    app.algorithm_combo = gtk_combo_box_text_new();
    for (i = 0; i < 4; ++i) {
        gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(app.algorithm_combo), k_algorithm_labels[i]);
    }
    gtk_combo_box_set_active(GTK_COMBO_BOX(app.algorithm_combo), 0);
    g_signal_connect(app.algorithm_combo, "changed", G_CALLBACK(algorithm_changed), NULL);
    gtk_box_pack_start(GTK_BOX(pin_box), app.algorithm_combo, FALSE, FALSE, 0);

    generate_button = gtk_button_new_with_label("Generate");
    g_signal_connect(generate_button, "clicked", G_CALLBACK(generate_clicked), NULL);
    gtk_box_pack_start(GTK_BOX(pin_box), generate_button, FALSE, FALSE, 0);

    reset_button = gtk_button_new_with_label("Reset");
    g_signal_connect(reset_button, "clicked", G_CALLBACK(reset_all), NULL);
    gtk_box_pack_start(GTK_BOX(pin_box), reset_button, FALSE, FALSE, 0);

    app.pattern_label = gtk_label_new("Pattern 1 of 3");
    gtk_box_pack_start(GTK_BOX(main_box), app.pattern_label, FALSE, FALSE, 0);

    app.stack = gtk_stack_new();
    gtk_stack_set_transition_type(GTK_STACK(app.stack), GTK_STACK_TRANSITION_TYPE_SLIDE_LEFT_RIGHT);
    for (i = 0; i < CRYPTIC_MATRIX_COUNT; ++i) {
        char name[16];
        char title[32];
        grid = create_matrix_grid(i);
        snprintf(name, sizeof(name), "matrix%d", i + 1);
        snprintf(title, sizeof(title), "Pattern %d", i + 1);
        gtk_stack_add_titled(GTK_STACK(app.stack), grid, name, title);
    }
    gtk_box_pack_start(GTK_BOX(main_box), app.stack, TRUE, TRUE, 0);

    nav_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    gtk_box_pack_start(GTK_BOX(main_box), nav_box, FALSE, FALSE, 0);
    back_button = gtk_button_new_with_label("Back <");
    g_signal_connect(back_button, "clicked", G_CALLBACK(previous_matrix), NULL);
    gtk_box_pack_start(GTK_BOX(nav_box), back_button, FALSE, FALSE, 0);
    next_button = gtk_button_new_with_label("Next >");
    g_signal_connect(next_button, "clicked", G_CALLBACK(next_matrix), NULL);
    gtk_box_pack_start(GTK_BOX(nav_box), next_button, FALSE, FALSE, 0);
    finish_button = gtk_button_new_with_label("Finish");
    g_signal_connect(finish_button, "clicked", G_CALLBACK(finish_clicked), NULL);
    gtk_box_pack_start(GTK_BOX(nav_box), finish_button, FALSE, FALSE, 0);

    output_box = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    gtk_box_pack_start(GTK_BOX(main_box), output_box, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(output_box), gtk_label_new("Password:"), FALSE, FALSE, 0);
    app.output_entry = gtk_entry_new();
    gtk_entry_set_width_chars(GTK_ENTRY(app.output_entry), 42);
    gtk_box_pack_start(GTK_BOX(output_box), app.output_entry, TRUE, TRUE, 0);

    app.status_label = gtk_label_new("Enter a PIN and click Generate.");
    gtk_box_pack_start(GTK_BOX(main_box), app.status_label, FALSE, FALSE, 0);

    reset_selection_only();
    gtk_widget_show_all(app.window);
}

int main(int argc, char **argv)
{
    GtkApplication *gtk_app;
    int status;

    gtk_app = gtk_application_new("org.cryptic.password", G_APPLICATION_FLAGS_NONE);
    g_signal_connect(gtk_app, "activate", G_CALLBACK(activate), NULL);
    status = g_application_run(G_APPLICATION(gtk_app), argc, argv);
    g_object_unref(gtk_app);
    return status;
}
