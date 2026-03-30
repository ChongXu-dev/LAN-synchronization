package com.example.lan_clipboard

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.lan_clipboard/sync_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "startService") {
                startSyncService()
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun startSyncService() {
        val intent = Intent(this, SyncService::class.java)
        startForegroundService(intent)
    }
}
