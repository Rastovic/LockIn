package com.rastovic.lockin

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView

/**
 * The screen a watched app is covered with.
 *
 * **A plain Android activity with no Flutter in it**, like the capture box: it
 * has to appear the instant the app does, and a Flutter cold start would leave
 * a second or two of the feed showing underneath.
 *
 * It offers the way forward the app believes in - open LockIn and earn some
 * time - and a way out. In block mode there is no "just five more minutes":
 * a block with a bypass one tap away is a nag, not a block. Remind mode is
 * that nag on purpose, chosen by the user, with "Continue anyway"; the time
 * after it is counted as usual and lands as debt.
 */
class BlockActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_block)

        val palette = WidgetTheme(applicationContext).palette()
        val store = BlockStore(applicationContext)
        val remaining = store.remainingSeconds(
            UsageReader(applicationContext),
            System.currentTimeMillis(),
        )

        findViewById<android.view.View>(R.id.block_root).setBackgroundColor(palette.bg)
        findViewById<TextView>(R.id.block_title).setTextColor(palette.ink)

        findViewById<TextView>(R.id.block_balance).apply {
            text = formatMinutes(remaining)
            setTextColor(palette.balanceColor(remaining.toInt()))
        }

        findViewById<TextView>(R.id.block_body).apply {
            // Past the day boundary the figure may be missing a fresh
            // allowance only the app can work out, so say how to get it.
            setText(
                when {
                    intent.getBooleanExtra(EXTRA_STALE, false) ->
                        R.string.block_body_stale
                    store.hard -> R.string.block_body
                    else -> R.string.block_body_remind
                },
            )
            setTextColor(palette.inkMuted)
        }

        findViewById<Button>(R.id.block_open).apply {
            setTextColor(palette.bg)
            background?.mutate()?.setTint(palette.solvent)
            setOnClickListener {
                startActivity(
                    Intent(this@BlockActivity, MainActivity::class.java).addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP,
                    ),
                )
                finish()
            }
        }

        findViewById<Button>(R.id.block_close).apply {
            setTextColor(palette.inkMuted)
            setOnClickListener { goHome() }
        }

        val pkg = intent.getStringExtra(EXTRA_PACKAGE)
        findViewById<Button>(R.id.block_continue).apply {
            if (store.hard || pkg == null) {
                visibility = android.view.View.GONE
            } else {
                setTextColor(palette.inkMuted)
                setOnClickListener {
                    // Before the relaunch, or the service sees the app come
                    // back with nothing to spend and reminds again at once.
                    store.passPackage = pkg
                    packageManager.getLaunchIntentForPackage(pkg)?.let {
                        startActivity(it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
                    }
                    finish()
                }
            }
        }
    }

    /**
     * Close goes to the launcher, not back. In remind mode the covered app is
     * still underneath, and a plain finish would drop the user into it.
     */
    override fun onBackPressed() = goHome()

    private fun goHome() {
        startActivity(
            Intent(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_HOME)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
        finish()
    }

    /** Whole minutes, floored, with a real minus sign. Mirrors Dart. */
    private fun formatMinutes(seconds: Long): String {
        val minutes = Math.floorDiv(seconds, 60L)
        return if (minutes < 0) "−${-minutes} min" else "$minutes min"
    }

    companion object {
        const val EXTRA_STALE = "stale"
        const val EXTRA_PACKAGE = "package"
    }
}
