package dev.edulabrador.sushiscore

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val pendingLaunchActions = mutableListOf<String>()
    private var launchChannel: MethodChannel? = null
    private var pendingFileResult: MethodChannel.Result? = null
    private var pendingExport: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Read before super.onCreate, which attaches the Flutter engine.
        queueLaunchAction(intent, isRestoring = savedInstanceState != null)
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (queueLaunchAction(intent, isRestoring = false)) {
            // Dart drains the queue; if it is not listening yet it drains on start.
            launchChannel?.invokeMethod("actionAvailable", null)
        }
    }

    private fun queueLaunchAction(intent: Intent?, isRestoring: Boolean): Boolean {
        val action = LaunchActions.actionFor(intent?.action, intent?.flags ?: 0, isRestoring)
            ?: return false
        pendingLaunchActions.add(action)
        return true
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // FLAG_KEEP_SCREEN_ON only affects this window and needs no permission.
        MethodChannel(messenger, "dev.edulabrador.sushiscore/screen")
            .setMethodCallHandler { call, result ->
                val flag = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                when (call.method) {
                    "setKeepScreenOn" -> {
                        if (call.arguments == true) window.addFlags(flag) else window.clearFlags(flag)
                        result.success(null)
                    }
                    "isKeepScreenOn" -> result.success(window.attributes.flags and flag != 0)
                    else -> result.notImplemented()
                }
            }

        launchChannel = MethodChannel(messenger, "dev.edulabrador.sushiscore/launch").apply {
            setMethodCallHandler { call, result ->
                if (call.method == "takePendingActions") {
                    val actions = pendingLaunchActions.toList()
                    pendingLaunchActions.clear()
                    result.success(actions)
                } else {
                    result.notImplemented()
                }
            }
        }

        MethodChannel(messenger, "dev.edulabrador.sushiscore/files")
            .setMethodCallHandler { call, result -> handleFileCall(call, result) }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        launchChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun handleFileCall(call: MethodCall, result: MethodChannel.Result) {
        val intent = when (call.method) {
            "exportFile" -> Intent(Intent.ACTION_CREATE_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType("application/json")
                .putExtra(Intent.EXTRA_TITLE, TextFiles.exportFileName(call.argument<String>("name")))
            "importFile" -> Intent(Intent.ACTION_OPEN_DOCUMENT)
                .addCategory(Intent.CATEGORY_OPENABLE)
                .setType("*/*")
                .putExtra(
                    Intent.EXTRA_MIME_TYPES,
                    arrayOf("application/json", "text/plain", "application/octet-stream"),
                )
            else -> return result.notImplemented()
        }
        if (pendingFileResult != null) {
            return result.error("busy", "Another file request is open", null)
        }
        try {
            pendingFileResult = result
            pendingExport = call.argument<String>("content")
            startActivityForResult(
                intent,
                if (call.method == "exportFile") EXPORT_REQUEST else IMPORT_REQUEST,
            )
        } catch (e: ActivityNotFoundException) {
            pendingFileResult = null
            pendingExport = null
            result.error("unavailable", "No document picker on this device", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != EXPORT_REQUEST && requestCode != IMPORT_REQUEST) return
        val result = pendingFileResult ?: return
        val content = pendingExport
        pendingFileResult = null
        pendingExport = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null) // The user cancelled.
            return
        }
        // Content providers may be slow (cloud storage), so stay off the UI thread.
        Thread {
            try {
                val value: Any = if (requestCode == EXPORT_REQUEST) {
                    write(uri, content.orEmpty())
                    true
                } else {
                    read(uri)
                }
                runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                runOnUiThread { result.error("io", e.message, null) }
            }
        }.start()
    }

    private fun write(uri: Uri, content: String) {
        val output = contentResolver.openOutputStream(uri) ?: throw IOException("Cannot write file")
        output.use { it.write(content.toByteArray(Charsets.UTF_8)) }
    }

    private fun read(uri: Uri): String {
        val input = contentResolver.openInputStream(uri) ?: throw IOException("Cannot read file")
        return input.use { TextFiles.readUtf8(it) }
    }

    private companion object {
        const val EXPORT_REQUEST = 4101
        const val IMPORT_REQUEST = 4102
    }
}
