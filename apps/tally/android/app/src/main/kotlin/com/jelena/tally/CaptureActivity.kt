package com.jelena.tally

import android.app.Activity
import android.os.Bundle
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
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
        // The keyboard comes up with the box: one tap from home screen to
        // typing, or the widget has saved nobody anything.
        input.requestFocus()
        window.setSoftInputMode(
            WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_VISIBLE,
        )

        findViewById<Button>(R.id.capture_save).setOnClickListener {
            save(input.text.toString())
        }
        findViewById<Button>(R.id.capture_cancel).setOnClickListener { finish() }
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
