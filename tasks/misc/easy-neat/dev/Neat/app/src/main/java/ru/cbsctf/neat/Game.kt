package ru.cbsctf.neat

import android.app.PendingIntent
import android.app.Service
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.View
import android.widget.RemoteViews
import java.security.MessageDigest
import java.util.zip.ZipFile
import kotlin.experimental.xor

@ExperimentalStdlibApi
class GameWidgetProvider : AppWidgetProvider() {
    private lateinit var gameState: GameState

    companion object {
        private const val TAG = "GameWidgetProvider"
        private const val ACTION_UPDATE_WIDGETS = "com.example.ACTION_UPDATE_WIDGETS"
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        gameState = GameState(context)
        super.onReceive(context, intent)

        if (intent.action == ACTION_UPDATE_WIDGETS) {
            val epochTime = intent.getIntExtra("epochTime", 0)
            updateAllWidgets(context, epochTime)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)

        // Log.d(TAG, "Widgets ${appWidgetIds.joinToString()} deleted")
        appWidgetIds.forEach {
            val index = gameState.getWidgetIndex(it)
            if (index in GameState.FLAG.indices) {
                gameState.addAvailableLetter(index)
            }
            gameState.setWidgetIndex(it, -1)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val availableLetters = gameState.getAvailableLetters()

        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        if (availableLetters.isNotEmpty()) {
            val index = availableLetters.random()
            setupLetterWidget(views, index)
            gameState.setWidgetIndex(appWidgetId, index)
            gameState.removeAvailableLetter(index)
        } else {
            setupQuestionMarkWidget(views)
        }

        views.setOnClickPendingIntent(R.id.widget_container, getMainActivityIntent(context))
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun setupLetterWidget(views: RemoteViews, index: Int) {
        views.setViewVisibility(R.id.letter_layout, View.VISIBLE)
        views.setViewVisibility(R.id.question_mark, View.GONE)

        val letter = GameState.FLAG[index].toString()
        views.setTextViewText(R.id.letter_text, letter)
    }

    private fun setupQuestionMarkWidget(views: RemoteViews) {
        views.setViewVisibility(R.id.letter_layout, View.GONE)
        views.setViewVisibility(R.id.question_mark, View.VISIBLE)
    }

    private fun updateAllWidgets(context: Context, epochTime: Int) {
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, GameWidgetProvider::class.java)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
        // Log.d(TAG, "updateAllWidgets(): ${appWidgetIds.joinToString()}")

        val activeIndex = epochTime % GameState.FLAG.length

        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            val widgetIndex = gameState.getWidgetIndex(appWidgetId)
            if (widgetIndex in GameState.FLAG.indices) {
                views.setViewVisibility(R.id.widget_indicator,
                    if (widgetIndex == activeIndex) View.VISIBLE else View.INVISIBLE)
                appWidgetManager.partiallyUpdateAppWidget(appWidgetId, views)
            }
        }
    }

    private fun getMainActivityIntent(context: Context) =
        Intent(context, MainActivity::class.java).let {
            it.flags = Intent.FLAG_ACTIVITY_NO_HISTORY or Intent.FLAG_ACTIVITY_NEW_TASK
            PendingIntent.getActivity(context, 1337, it,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT)
        }
}

@ExperimentalStdlibApi
class GameState(context: Context) {
    private val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

    init {
        val key = HorribleCrypto().deriveObfuscatedKey(context)
        // key = 3a470f3ae2e85e71374ac58058ea6e7e
        val flag = byteArrayOf(89, 51, 105, 89, -105, -104, 37, 63, 88, 61, -100, -17, 45, -104, 38, 17, 87, 34, 92, 89, -112, -37, 59, 31, 6, 57, -102, -42, 107, -72, 23, 33, 116, 34, 110, 78, -97)
        FLAG = flag.mapIndexed { i, a -> a xor key[i % 16]}.map { Char(it.toInt()) }.joinToString("")
        // FLAG = ctfcup{NowYourHomeScr3en1s_V3Ry_Neat}
    }

    companion object {
        private const val TAG = "GameState"
        var FLAG = "Just play the game"
        private const val PREF_NAME = "GameWidgetsState"
        private const val PREF_AVAILABLE_LETTERS = "available_letters"
    }

    fun getAvailableLetters(): Set<Int> =
        prefs.getStringSet(PREF_AVAILABLE_LETTERS, null)?.map { it.toInt() }?.toSet()
            ?: FLAG.indices.toSet()

    private fun setAvailableLetters(availableLetters: Set<Int>) =
        prefs.edit().putStringSet(PREF_AVAILABLE_LETTERS, availableLetters.map { it.toString() }.toSet()).apply()

    fun removeAvailableLetter(index: Int) {
        val availableLetters = getAvailableLetters().toMutableSet()
        availableLetters.remove(index)
        setAvailableLetters(availableLetters)
    }

    fun addAvailableLetter(index: Int) {
        val availableLetters = getAvailableLetters().toMutableSet()
        availableLetters.add(index)
        setAvailableLetters(availableLetters)
    }

    fun getWidgetIndex(appWidgetId: Int): Int = prefs.getInt("widget_index_$appWidgetId", -1)

    fun setWidgetIndex(appWidgetId: Int, index: Int) =
        prefs.edit().putInt("widget_index_$appWidgetId", index).apply()
}

class GameUpdateService : Service() {
    private lateinit var handler: Handler
    private lateinit var updateRunnable: Runnable
    private var running = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        handler = Handler(Looper.getMainLooper())
        updateRunnable = object : Runnable {
            override fun run() {
                sendUpdateBroadcast()
                handler.postDelayed(this, 1000)
            }
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (!running) {
            running = true
            handler.post(updateRunnable)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        handler.removeCallbacks(updateRunnable)
        running = false
    }

    @OptIn(ExperimentalStdlibApi::class)
    private fun sendUpdateBroadcast() {
        val intent = Intent(this, GameWidgetProvider::class.java)
        intent.action = "com.example.ACTION_UPDATE_WIDGETS"
        val epochTime = (System.currentTimeMillis() / 1000 - 1728675200 /* </sh1yo> */).toInt()
        intent.putExtra("epochTime", epochTime)
        sendBroadcast(intent)
    }
}


class HorribleCrypto {
    fun deriveObfuscatedKey(context: Context): ByteArray {
        val resourcesBytes = getResourcesArscBytes(context)
        val signatureBytes = getAppSignatureBytes(context)

        val mixedBytes = ByteArray(32)
        for (i in 0 until 32) {
            mixedBytes[i] = (resourcesBytes[i % resourcesBytes.size]
                .toInt() xor signatureBytes[i % signatureBytes.size].toInt()
                    xor (i * 23 + 17)).toByte()
        }

        val md = MessageDigest.getInstance("SHA-256")
        val intermediateHash = md.digest(mixedBytes)

        val finalKey = ByteArray(16)
        for (i in 0 until 16) {
            finalKey[i] = (intermediateHash[i] xor intermediateHash[31 - i]
                    xor (intermediateHash[(i * 11 + 5) % 32])
                    xor ((i * 29 + 13).toByte())).toByte()
        }

        return finalKey.reversedArray()
    }

    private inline fun getResourcesArscBytes(context: Context): ByteArray {
        val apkPath = context.applicationInfo.sourceDir
        val zipFile = ZipFile(apkPath)
        val resourcesEntry = zipFile.getEntry("resources.arsc")
        val inputStream = zipFile.getInputStream(resourcesEntry)

        val bytes = inputStream.readBytes()
        inputStream.close()
        zipFile.close()

        // Extract specific bytes based on a convoluted algorithm
        val extractedBytes = ByteArray(32)
        val resourcesSize = bytes.size
        for (i in 0 until 32) {
            val index = (i * 1337 + 42) % resourcesSize
            extractedBytes[i] = bytes[index]
        }

        // Apply a series of bitwise operations
        for (i in 0 until 32) {
            extractedBytes[i] = extractedBytes[i].rotateLeft(3)
                .xor((i * 59 + 31).toByte())
                .rotateRight(2)
        }

        return MessageDigest.getInstance("SHA-256").digest(extractedBytes)
    }

    private inline fun getAppSignatureBytes(context: Context): ByteArray {
        val packageManager = context.packageManager
        val packageName = context.packageName
        val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
        val signatures = packageInfo.signatures
        val signatureBytes = signatures[0].toByteArray()

        // Apply additional obfuscation to signature bytes
        val obfuscatedSignature = ByteArray(signatureBytes.size)
        for (i in signatureBytes.indices) {
            obfuscatedSignature[i] = (signatureBytes[i]
                .rotateLeft(4)
                .xor((i * 73 + 19).toByte())
                .rotateRight(3))
        }

        return MessageDigest.getInstance("SHA-512").digest(obfuscatedSignature)
    }

    private fun Byte.rotateLeft(n: Int): Byte = ((this.toInt() shl n) or (this.toInt() ushr (8 - n))).toByte()
    private fun Byte.rotateRight(n: Int): Byte = ((this.toInt() ushr n) or (this.toInt() shl (8 - n))).toByte()
}
