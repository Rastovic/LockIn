package com.rastovic.lockin

import android.app.Activity
import android.content.Context
import android.content.res.ColorStateList
import android.graphics.PorterDuff
import android.os.Bundle
import android.view.KeyEvent
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast

/**
 * The capture box, opened from the home screen.
 *
 * **A plain Android activity with no Flutter in it.** That is the entire
 * point: it opens instantly over whatever was on screen, takes one line and
 * closes. Routing this through the app would mean a cold start to save six
 * words, and the widget exists precisely because opening the app is the part
 * there is no time for.
 *
 * What is captured is a line of text and nothing else. Which kind of task it
 * is, which project it belongs to and how long it takes is exactly the work
 * being deferred - it waits in the inbox until there is time for it.
 */
class CaptureActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_capture)

        val input = findViewById<EditText>(R.id.capture_input)
        applyPalette(input)
        // The keyboard comes up with the box: one tap from home screen to
        // typing, or the widget has saved nobody anything. A translucent
        // floating window does not always honour the soft-input flag on its
        // own, so the field asks for the keyboard once it is laid out too.
        input.requestFocus()
        window.setSoftInputMode(
            WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_VISIBLE or
                WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE,
        )
        input.post {
            val keyboard = getSystemService(Context.INPUT_METHOD_SERVICE)
                as InputMethodManager
            keyboard.showSoftInput(input, InputMethodManager.SHOW_IMPLICIT)
        }

        // The field asks the keyboard for a Done key; without this the key is
        // drawn, closes the keyboard, and leaves the line sitting there
        // unsaved. Enter is the same gesture from a hardware keyboard.
        input.setOnEditorActionListener { _, actionId, event ->
            val submitted = actionId == EditorInfo.IME_ACTION_DONE ||
                actionId == EditorInfo.IME_ACTION_GO ||
                actionId == EditorInfo.IME_ACTION_SEND ||
                (
                    event != null &&
                        event.keyCode == KeyEvent.KEYCODE_ENTER &&
                        event.action == KeyEvent.ACTION_DOWN
                    )
            if (submitted) save(input.text.toString())
            submitted
        }

        findViewById<Button>(R.id.capture_save).setOnClickListener {
            save(input.text.toString())
        }
        findViewById<Button>(R.id.capture_cancel).setOnClickListener { finish() }
    }

    /** The picked app theme, the same palette the widget that opened this draws. */
    private fun applyPalette(input: EditText) {
        val palette = WidgetTheme(applicationContext).palette()
        findViewById<android.view.View>(R.id.capture_card).background
            ?.mutate()?.setColorFilter(palette.bg, PorterDuff.Mode.SRC_IN)
        input.background?.mutate()?.setColorFilter(palette.field, PorterDuff.Mode.SRC_IN)
        findViewById<TextView>(R.id.capture_title).setTextColor(palette.ink)
        input.setTextColor(palette.ink)
        input.setHintTextColor(ColorStateList.valueOf(palette.inkFaint))
        findViewById<Button>(R.id.capture_cancel).setTextColor(palette.inkMuted)
        findViewById<Button>(R.id.capture_save).setTextColor(palette.solvent)
    }

    private fun save(text: String) {
        val trimmed = text.trim()
        if (trimmed.isEmpty()) {
            finish()
            return
        }
        CaptureQueue(applicationContext).add(trimmed)
        CaptureWidgetProvider.refresh(applicationContext)
        // Said out loud, because nothing else on screen changes and the app is
        // not open to show the new row.
        Toast.makeText(this, R.string.capture_saved, Toast.LENGTH_SHORT).show()
        finish()
    }
}
