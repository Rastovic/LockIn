package com.rastovic.lockin

import android.content.Context
import android.content.res.Configuration
import org.json.JSONObject

/**
 * The palette every home screen surface draws with, written by Dart.
 *
 * The widgets used to carry a fixed Blush palette of their own, so on the
 * default Aurora theme a pink card sat on the home screen of a near-black,
 * mint app. Dart now sends the picked theme's light and dark token sets plus
 * the picked mode, and Kotlin only decides which of the two applies right now.
 * The colours in `values/widget_colors.xml` stay as the fallback for a widget
 * placed before the app has ever run.
 */
class WidgetTheme(private val context: Context) {

    private val prefs =
        context.getSharedPreferences("tally.widget.theme", Context.MODE_PRIVATE)

    data class Palette(
        val bg: Int,
        val ink: Int,
        val inkMuted: Int,
        val inkFaint: Int,
        val field: Int,
        val solvent: Int,
        val low: Int,
        val borrowing: Int,
    ) {
        /** Mirrors `BalanceState.forSeconds` in Dart. */
        fun balanceColor(seconds: Int): Int = when {
            seconds < 0 -> borrowing
            seconds < 10 * 60 -> low
            else -> solvent
        }
    }

    fun write(mode: String, lightJson: String, darkJson: String) {
        prefs.edit()
            .putString(KEY_MODE, mode)
            .putString(KEY_LIGHT, lightJson)
            .putString(KEY_DARK, darkJson)
            .apply()
    }

    /**
     * The palette for this instant.
     *
     * "system" follows the phone's night mode, which a widget re-reads on
     * every render, so the home screen flips with the system the same way the
     * app does. A forced light or dark in the app holds on the home screen too.
     */
    fun palette(): Palette {
        val dark = when (prefs.getString(KEY_MODE, MODE_SYSTEM)) {
            MODE_LIGHT -> false
            MODE_DARK -> true
            else -> (context.resources.configuration.uiMode and
                Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        }
        val raw = prefs.getString(if (dark) KEY_DARK else KEY_LIGHT, null)
        return raw?.let(::parse) ?: fallback()
    }

    private fun parse(raw: String): Palette? = try {
        val json = JSONObject(raw)
        // Colours arrive as unsigned 32-bit ARGB, past Int's range; reading a
        // Long and truncating keeps the alpha byte.
        fun color(key: String) = json.getLong(key).toInt()
        Palette(
            bg = color("bg"),
            ink = color("ink"),
            inkMuted = color("inkMuted"),
            inkFaint = color("inkFaint"),
            field = color("field"),
            solvent = color("solvent"),
            low = color("low"),
            borrowing = color("borrowing"),
        )
    } catch (e: Exception) {
        // A malformed palette costs the theme, never a crash on the home
        // screen.
        null
    }

    private fun fallback() = Palette(
        bg = context.getColor(R.color.widget_bg),
        ink = context.getColor(R.color.widget_ink),
        inkMuted = context.getColor(R.color.widget_ink_muted),
        inkFaint = context.getColor(R.color.widget_ink_faint),
        field = context.getColor(R.color.widget_field),
        solvent = context.getColor(R.color.widget_accent),
        low = context.getColor(R.color.widget_accent),
        borrowing = context.getColor(R.color.widget_accent),
    )

    companion object {
        /**
         * How opaque a widget card is, out of 255.
         *
         * Tinted rather than solid: a widget sits on the user's wallpaper, and
         * a fully opaque card reads as a hole punched in it. Enough pigment to
         * carry the theme and keep the text legible, not enough to hide what
         * is behind it. Raise it if a busy wallpaper makes the rows hard to
         * read.
         */
        const val CARD_ALPHA = 150


        private const val KEY_MODE = "mode"
        private const val KEY_LIGHT = "light"
        private const val KEY_DARK = "dark"
        private const val MODE_SYSTEM = "system"
        private const val MODE_LIGHT = "light"
        private const val MODE_DARK = "dark"
    }
}
