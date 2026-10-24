package dev.edulabrador.sushiscore

import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // FLAG_KEEP_SCREEN_ON only affects this window and needs no permission.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dev.edulabrador.sushiscore/screen",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setKeepScreenOn" -> {
                    val flag = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
                    if (call.arguments == true) {
                        window.addFlags(flag)
                    } else {
                        window.clearFlags(flag)
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
