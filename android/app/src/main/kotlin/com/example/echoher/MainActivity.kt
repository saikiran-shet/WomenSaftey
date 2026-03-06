package com.example.echoher

import android.telephony.SmsManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.echoher.app/sms"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendDirectSms") {
                val num = call.argument<String>("phone")
                val msg = call.argument<String>("message")
                
                if (num != null && msg != null) {
                    try {
                        val smsManager: SmsManager = this.getSystemService(SmsManager::class.java)
                        smsManager.sendTextMessage(num, null, msg, null, null)
                        result.success("SMS Sent")
                    } catch (e: Exception) {
                        result.error("SMS_FAILED", e.message, null)
                    }
                } else {
                    result.error("INVALID_ARGS", "Phone or message was null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}