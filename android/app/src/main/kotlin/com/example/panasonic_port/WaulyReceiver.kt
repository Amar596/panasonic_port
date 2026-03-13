package com.example.panasonic_port

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.content.SharedPreferences
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.EventChannel

class WaulyReceiver : BroadcastReceiver() {
    
    companion object {
        const val ACTION = "com.signalr.TESTCRASH_CRASH_EVENT"
        const val PREFS_NAME = "WaulyMonitorPrefs"
        const val KEY_LAST_MESSAGE = "wauly_last_message"
        const val KEY_LAST_MESSAGE_TIME = "wauly_last_message_time"
        const val KEY_LAST_ACTIVE_TIME = "wauly_last_active_time"
        const val KEY_APP_STATUS = "wauly_app_status"
        
        var eventSink: EventChannel.EventSink? = null

                // Add duplicate prevention
        private var lastMessageHash = 0
        private var lastMessageTime: Long = 0
        // Store recent message hashes to prevent duplicates
        private val recentMessages = LinkedHashMap<String, Long>()
        private val DEDUP_WINDOW_MS = 2000L // 2 seconds window        
    }

    override fun onReceive(context: Context, intent: Intent) {
        val broadcastId = intent.getStringExtra("broadcast_id") ?: "no-id"
        Log.d("WaulyReceiver", "Broadcast received - ID: $broadcastId")
        Log.d("WaulyReceiver", "Broadcast received: ${intent.action}")
        Log.d("MonitorApp-RECEIVER2", "🟢 RECEIVER 2 (WaulyReceiver) triggered")
        
        if (intent.action != ACTION) return
        
        val message = intent.getStringExtra("crash_text") ?: "No message"
        val currentTime = System.currentTimeMillis()
        val messageHash = message.hashCode()
        
        
        // Check for duplicate within 1 second
        if (messageHash == Companion.lastMessageHash && currentTime - Companion.lastMessageTime < 1000) {
            Log.d("WaulyReceiver", "⏭️ Duplicate message ignored: $message")
            return
        }
        
        // Update last message info
        Companion.lastMessageHash = messageHash
        Companion.lastMessageTime = currentTime
        
        Log.d("MonitorApp-RECEIVER2", "Message: $message")
        
        val timestamp = getCurrentTimestamp()
        
        Log.d("WaulyReceiver", "Wauly Message: $message")
        Log.d("WaulyReceiver", "Received at: $timestamp")
        
        // Save to SharedPreferences
        val sharedPref = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        with(sharedPref.edit()) {
            putString(KEY_LAST_MESSAGE, message)
            putString(KEY_LAST_MESSAGE_TIME, timestamp)

            // Update last active time based on message content
        when {
            // When app is STOPPED, set last active time to the stop time
            message.contains("STOPPED") -> {
                putString(KEY_LAST_ACTIVE_TIME, timestamp)
                Log.d("WaulyReceiver", "⏱️ App stopped at: $timestamp")
            }
            // For running/active messages, update last active time
            message.contains("RUNNING") || 
            message.contains("STARTED") ||
            message.contains("USER INTERACTION") -> {
                putString(KEY_LAST_ACTIVE_TIME, timestamp)
            }
        }
            
            // Update app status
            when {
                message.contains("STARTED") -> putString(KEY_APP_STATUS, "RUNNING")
                message.contains("STOPPED") -> putString(KEY_APP_STATUS, "STOPPED")
                message.contains("BACKGROUNDED") -> putString(KEY_APP_STATUS, "BACKGROUND")
                message.contains("ALIVE") -> putString(KEY_APP_STATUS, "RUNNING")
                message.contains("HEARTBEAT") -> putString(KEY_APP_STATUS, "RUNNING")
            }
            
            apply()
        }

        if (message.contains("ALIVE") || 
        message.contains("BACKGROUNDED") ||  // Block BACKGROUNDED
        message.contains("HEARTBEAT")) {     // Block HEARTBEAT if needed
        Log.d("WaulyReceiver", "🚫 Message filtered out: $message")
        return  // Exit immediately - no logs, no processing, no UI
        }
        
        // Send to Flutter UI via EventChannel if available
        val data = hashMapOf<String, Any>(
            "message" to message,
            "timestamp" to timestamp,
            "type" to getMessageType(message)
        )
        
        if (eventSink != null) {
            try {
                eventSink?.success(data)
                Log.d("WaulyReceiver", "✅ Data sent successfully to Flutter")
            } catch (e: Exception) {
                Log.e("WaulyReceiver", "❌ Error sending to eventSink: ${e.message}")
            }
        } else {
            Log.w("WaulyReceiver", "⚠️ eventSink is null - Flutter not listening")
        }
    }

    private fun getMessageType(message: String): String {
    val upperMsg = message.uppercase()
    return when {
        upperMsg.contains("STARTED") -> "started"
        upperMsg.contains("STOPPED") -> "stopped"
        upperMsg.contains("BACKGROUND") -> "background"
        upperMsg.contains("ALIVE") -> "alive"
        upperMsg.contains("RUNNING") -> "running"
        upperMsg.contains("HEARTBEAT") -> "heartbeat"
        upperMsg.contains("TEST") -> "test"
        upperMsg.contains("CRASH") -> "crash"
        else -> "info"
    }
}
    
    private fun getCurrentTimestamp(): String {
        return SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.getDefault())
            .format(Date())
    }
}

