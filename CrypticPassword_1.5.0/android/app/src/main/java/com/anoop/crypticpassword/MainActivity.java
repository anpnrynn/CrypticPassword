package com.anoop.crypticpassword;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.text.InputFilter;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.GridLayout;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

public final class MainActivity extends Activity {
    private static final int RED = Color.rgb(255, 42, 42);
    private static final int GREEN = Color.rgb(85, 212, 0);
    private static final int BLUE = Color.rgb(55, 171, 200);

    private EditText pinEdit;
    private EditText passwordEdit;
    private TextView statusText;
    private TextView patternText;
    private Spinner versionSpinner;
    private GridLayout matrixGrid;
    private final Button[] matrixButtons = new Button[CrypticPasswordAlgorithm.MATRIX_SIZE];
    private final boolean[] activeButtons = new boolean[CrypticPasswordAlgorithm.TOTAL_CELLS];
    private Drawable defaultButtonBackground;
    private String shuffledData = "";
    private int pattern = 1;
    private CrypticPasswordAlgorithm.Version selectedVersion = CrypticPasswordAlgorithm.Version.VERSION_1_0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setTitle("CrypticPassword");
        buildUi();
        resetBoard();
    }

    private void buildUi() {
        ScrollView scrollView = new ScrollView(this);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(16), dp(16), dp(16), dp(16));
        scrollView.addView(root);

        TextView title = new TextView(this);
        title.setText("CrypticPassword");
        title.setTextSize(22);
        title.setTypeface(Typeface.DEFAULT_BOLD);
        root.addView(title, matchWrap());

        TextView subtitle = new TextView(this);
        subtitle.setText("Secure Password Generation Tool");
        subtitle.setTextSize(14);
        root.addView(subtitle, matchWrap());

        versionSpinner = new Spinner(this);
        String[] labels = new String[CrypticPasswordAlgorithm.Version.values().length];
        for (int i = 0; i < labels.length; i++) labels[i] = CrypticPasswordAlgorithm.Version.values()[i].label;
        ArrayAdapter<String> adapter = new ArrayAdapter<>(this, android.R.layout.simple_spinner_dropdown_item, labels);
        versionSpinner.setAdapter(adapter);
        versionSpinner.setOnItemSelectedListener(new AdapterView.OnItemSelectedListener() {
            @Override public void onItemSelected(AdapterView<?> parent, View view, int position, long id) {
                selectedVersion = CrypticPasswordAlgorithm.Version.values()[position];
            }
            @Override public void onNothingSelected(AdapterView<?> parent) { }
        });
        root.addView(versionSpinner, matchWrap());

        TextView pinLabel = new TextView(this);
        pinLabel.setText("PIN (1-5 digits):");
        root.addView(pinLabel, matchWrap());

        pinEdit = new EditText(this);
        pinEdit.setInputType(InputType.TYPE_CLASS_NUMBER);
        pinEdit.setFilters(new InputFilter[]{new InputFilter.LengthFilter(5)});
        pinEdit.setText("2023");
        root.addView(pinEdit, matchWrap());

        LinearLayout actions = new LinearLayout(this);
        actions.setOrientation(LinearLayout.HORIZONTAL);
        actions.setGravity(Gravity.CENTER_HORIZONTAL);
        root.addView(actions, matchWrap());

        Button generate = new Button(this);
        generate.setText("Generate");
        generate.setOnClickListener(v -> generateShuffle());
        actions.addView(generate, weightedButton());

        Button reset = new Button(this);
        reset.setText("Reset");
        reset.setOnClickListener(v -> resetBoard());
        actions.addView(reset, weightedButton());

        patternText = new TextView(this);
        patternText.setTextSize(18);
        patternText.setTypeface(Typeface.DEFAULT_BOLD);
        patternText.setGravity(Gravity.CENTER_HORIZONTAL);
        root.addView(patternText, matchWrap());

        matrixGrid = new GridLayout(this);
        matrixGrid.setColumnCount(CrypticPasswordAlgorithm.MATRIX_COLUMNS);
        matrixGrid.setRowCount(CrypticPasswordAlgorithm.MATRIX_ROWS);
        matrixGrid.setPadding(0, dp(12), 0, dp(12));
        root.addView(matrixGrid, matchWrap());

        for (int i = 0; i < matrixButtons.length; i++) {
            final int cell = i;
            Button b = new Button(this);
            b.setText("");
            b.setMinHeight(dp(44));
            b.setMinimumHeight(dp(44));
            b.setOnClickListener(v -> matrixClicked(cell));
            if (defaultButtonBackground == null) defaultButtonBackground = b.getBackground().getConstantState().newDrawable();
            GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
            lp.width = dp(44);
            lp.height = dp(44);
            lp.setMargins(dp(3), dp(3), dp(3), dp(3));
            matrixGrid.addView(b, lp);
            matrixButtons[i] = b;
        }

        LinearLayout nav = new LinearLayout(this);
        nav.setOrientation(LinearLayout.HORIZONTAL);
        nav.setGravity(Gravity.CENTER_HORIZONTAL);
        root.addView(nav, matchWrap());

        Button back = new Button(this);
        back.setText("Back <");
        back.setOnClickListener(v -> { if (pattern > 1) { pattern--; loadButtons(); } });
        nav.addView(back, weightedButton());

        Button next = new Button(this);
        next.setText("Next >");
        next.setOnClickListener(v -> { if (pattern < CrypticPasswordAlgorithm.MATRIX_COUNT) { pattern++; loadButtons(); } });
        nav.addView(next, weightedButton());

        passwordEdit = new EditText(this);
        passwordEdit.setInputType(InputType.TYPE_CLASS_TEXT | InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD);
        passwordEdit.setSingleLine(false);
        passwordEdit.setMinLines(2);
        passwordEdit.setTypeface(Typeface.MONOSPACE);
        root.addView(passwordEdit, matchWrap());

        statusText = new TextView(this);
        statusText.setTextSize(14);
        root.addView(statusText, matchWrap());

        setContentView(scrollView);
    }

    private void generateShuffle() {
        String raw = pinEdit.getText().toString().trim();
        if (raw.length() == 0) {
            Toast.makeText(this, "Please enter a PIN.", Toast.LENGTH_SHORT).show();
            return;
        }
        int pin;
        try { pin = Integer.parseInt(raw); }
        catch (NumberFormatException ex) { pin = 0; }
        if (pin <= 0) {
            Toast.makeText(this, "PIN must be a positive integer.", Toast.LENGTH_SHORT).show();
            return;
        }
        shuffledData = CrypticPasswordAlgorithm.shuffle(selectedVersion, pin);
        for (int i = 0; i < activeButtons.length; i++) activeButtons[i] = false;
        passwordEdit.setText("");
        pattern = 1;
        loadButtons();
        statusText.setText("Shuffled string generated, now set pattern.");
    }

    private void matrixClicked(int cellInPattern) {
        if (shuffledData.length() < CrypticPasswordAlgorithm.TOTAL_CELLS) return;
        int index = (pattern - 1) * CrypticPasswordAlgorithm.MATRIX_SIZE + cellInPattern;
        activeButtons[index] = true;
        matrixButtons[cellInPattern].setBackground(defaultButtonBackground.getConstantState().newDrawable());
        passwordEdit.append(String.valueOf(shuffledData.charAt(index)));
    }

    private void resetBoard() {
        shuffledData = "";
        for (int i = 0; i < activeButtons.length; i++) activeButtons[i] = false;
        pattern = 1;
        pinEdit.setText("2023");
        passwordEdit.setText("");
        statusText.setText("Set PIN and click Generate.");
        loadButtons();
    }

    private void loadButtons() {
        int color = currentPatternColor();
        for (int i = 0; i < matrixButtons.length; i++) {
            int index = (pattern - 1) * CrypticPasswordAlgorithm.MATRIX_SIZE + i;
            Button button = matrixButtons[i];
            button.setText("");
            if (activeButtons[index]) {
                button.setBackground(defaultButtonBackground.getConstantState().newDrawable());
            } else {
                button.setBackgroundColor(color);
            }
        }
        patternText.setText("Pattern: " + pattern + "/3");
    }

    private int currentPatternColor() {
        if (pattern == 2) return GREEN;
        if (pattern == 3) return BLUE;
        return RED;
    }

    private LinearLayout.LayoutParams matchWrap() {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
        lp.setMargins(0, dp(4), 0, dp(4));
        return lp;
    }

    private LinearLayout.LayoutParams weightedButton() {
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f);
        lp.setMargins(dp(3), dp(3), dp(3), dp(3));
        return lp;
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }
}
