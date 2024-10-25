package ru.cbsctf.neat

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.dialog.MaterialAlertDialogBuilder

@ExperimentalStdlibApi
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        if (!hasAppWidgets()) {
            val dialog = MaterialAlertDialogBuilder(this)
                .setIcon(R.drawable.baseline_widgets_24)
                .setTitle("Welcome to Neat")
                .setMessage("All you need to Play the Game is your home screen. This is just a dummy popup!")
                .setOnDismissListener {
                    finish()
                }
                .create()
            dialog.show()
        } else {
            Intent(this, GameUpdateService::class.java)
                .apply { startService(this) }
            val dialog = MaterialAlertDialogBuilder(this)
                .setIcon(R.drawable.baseline_auto_awesome_24)
                .setTitle("Updating...")
                .setMessage("Indicators should be working again now")
                .setOnDismissListener {
                    finish()
                }
                .create()
            dialog.show()
        }
    }

    private fun hasAppWidgets() =
        AppWidgetManager.getInstance(this)
            .getAppWidgetIds(ComponentName(this, GameWidgetProvider::class.java))
            .isNotEmpty()
}

