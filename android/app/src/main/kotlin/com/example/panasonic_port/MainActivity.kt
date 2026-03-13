package com.example.panasonic_port

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.mk.service.ifpd.midware.manager.app.imp.AppSystem
import com.mk.service.ifpd.midware.manager.app.imp.AppSettings
import com.mk.service.ifpd.app.midware.DisplayOrientation
import android.os.RemoteException
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import io.flutter.plugin.common.EventChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {

    private val CHANNEL = "port_control"
    private val MONITORING_EVENT_CHANNEL = "com.example.panasonic_port/monitoring_events"

    private lateinit var appSystem: AppSystem
    private lateinit var appSettings: AppSettings
    private lateinit var sharedPref: SharedPreferences

    companion object {
        private const val WAULY_BROADCAST_ACTION = "com.signalr.TESTCRASH_CRASH_EVENT"
        private const val PREFS_NAME = "WaulyMonitorPrefs"
        private const val KEY_LAST_MESSAGE = "wauly_last_message"
        private const val KEY_LAST_MESSAGE_TIME = "wauly_last_message_time"
        private const val KEY_LAST_ACTIVE_TIME = "wauly_last_active_time"
        private const val KEY_APP_STATUS = "wauly_app_status"
        private const val KEY_MESSAGE_HISTORY = "wauly_message_history" 
    private const val MAX_HISTORY_ITEMS = 50 
    }

    // EventChannel stream handler
    private var eventSink: EventChannel.EventSink? = null
    //private var waulyBroadcastReceiver: BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize SharedPreferences - FIXED: Use PREFS_NAME instead of WaulyReceiver.PREFS_NAME
        sharedPref = applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        
        Log.d("MonitorApp", "MainActivity created")
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        appSystem = AppSystem.getInstance(applicationContext)
        appSettings = AppSettings.getInstance(applicationContext)   
        appSystem.connectService()
        appSettings.connectService()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shutdownSystem" -> {
                    appSystem.shutdown()
                    result.success("Shutdown command sent")
                }

                "openHDMI" -> {
                    val index = call.argument<Int>("index") ?: 0
                    appSystem.openHDMI(index)
                    result.success("HDMI opened for index $index")
                }

                "closeHDMI" -> {
                    appSystem.closeHDMI()
                    result.success("HDMI closed")
                }

                "getHDMIStatus" -> {
                    val index = call.argument<Int>("index") ?: 0
                    val status = appSystem.getHDMIConnectedStatus(index)
                    result.success(status) 
                }

                "getHDMIMode" -> {
                    val mode = appSettings.getHDMIMode()
                    result.success(mode)
                }
   
                "setHdmiMode" -> {
                    try {
                        val status = call.argument<Boolean>("status") ?: false
                        appSettings.setHdmiMode(status)
                        result.success(true)
                    } catch (e: RemoteException) {
                        result.error("REMOTE_ERROR", "Service communication failed", null)
                    } catch (e: Exception) {
                        result.error("GENERIC_ERROR", e.message, null)
                    }
                }

                "setDelayPowerOn" -> {
                    var mins = call.argument<Int>("mins") ?: 0
                    appSystem.setDelayPowerOn(mins)
                    result.success("Delay power on set")
                }

                "turnOff" -> {
                    appSystem.turnOff()
                    result.success("System turned off")
                }

                "isInteractive" -> {
                    val interactive = appSystem.isInteractive()
                    result.success(interactive) 
                }

                "setBackLight" -> {
                    val value = call.argument<Int>("value") ?: 0
                    appSettings.setBackLight(value)
                    result.success("Backlight set")
                }

                "startScreenCap" -> {
                    val fileName = call.argument<String>("fileName") ?: ""
                    val file = java.io.File(fileName)

                    if (file.parentFile?.exists() == false) {
                        file.parentFile?.mkdirs()
                    }
                    val resultCode = appSystem.startScreenCap(fileName)
                    result.success("Screen capture started")
                }

                "setDisplayOrientation" -> {
                    val angle = call.argument<Int>("angle") ?: 0
                    val orientation = when (angle) {
                        0 -> DisplayOrientation.ROTATION_0
                        90 -> DisplayOrientation.ROTATION_90
                        180 -> DisplayOrientation.ROTATION_180
                        270 -> DisplayOrientation.ROTATION_270
                        else -> DisplayOrientation.ROTATION_0 
                    }
                    appSystem.setDisplayOrientation(orientation)
                    result.success("Orientation set")
                }

                "getSystemVoice" -> {
                    val volume = appSystem.getSystemVoice()
                    result.success(volume)
                }
                
                "setSystemVoice" -> {
                    val voice = call.argument<Int>("voice") ?: 50
                    if (voice in 0..100) {
                        appSystem.setSystemVoice(voice)
                        result.success("Volume set to $voice")
                    } else {
                        result.error("INVALID_VOLUME", "Volume must be 0-100", null)
                    }
                }
                
                "mute" -> {
                    appSystem.mute()
                    result.success("Device muted")
                }
                
                "unMute" -> {
                    appSystem.unMute()
                    result.success("Device unmuted")
                }

                "reboot" -> {
                    appSystem.reboot()
                    result.success("Reboot command sent")
                }

                "getMacAddress" -> {
                    try {
                        val macAddress = appSystem.macAddress
                        result.success(macAddress)
                    } catch (e: Exception) {
                        result.error("MAC_ADDRESS_ERROR", "Failed to get MAC address", null)
                    }
                }

                "getDeviceId" -> {
                    try {
                        val deviceId = appSystem.deviceId
                        result.success(deviceId)
                    } catch (e: Exception) {
                        result.error("DEVICE_ID_ERROR", "Failed to get device ID", null)
                    }
                }
                
                "getSN" -> {
                    try {
                        Log.d("MainActivity", "Attempting to get SN...")
                        val sn = appSystem.getSN()
                        Log.d("MainActivity", "Got SN: $sn")
                        if (sn.isNullOrEmpty()) {
                            Log.w("MainActivity", "Received empty SN")
                            result.error("EMPTY_SN", "Serial number is empty", null)
                        } else {
                            result.success(sn)
                        }
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error getting SN", e)
                        result.error("SN_ERROR", "Failed to get serial number: ${e.message}", e.toString())
                    }
                }

                "getClientType" -> {
                    try {
                        val clientType = appSystem.clientType
                        result.success(clientType)
                    } catch (e: Exception) {
                        result.error("CLIENT_TYPE_ERROR", "Failed to get client type", null)
                    }
                }

                "getAppId" -> {
                    try {
                        val appId = appSystem.appId
                        result.success(appId)
                    } catch (e: Exception) {
                        result.error("APP_ID_ERROR", "Failed to get app ID", null)
                    }
                }

                "getWaulyStatus" -> {
                    val lastMessage = sharedPref.getString(KEY_LAST_MESSAGE, "No messages received yet")
                    val lastMessageTime = sharedPref.getString(KEY_LAST_MESSAGE_TIME, "N/A")
                    val lastActiveTime = sharedPref.getString(KEY_LAST_ACTIVE_TIME, "N/A")
                    val appStatus = sharedPref.getString(KEY_APP_STATUS, "UNKNOWN")
                    
                    val statusData = hashMapOf<String, Any>(
                        "lastMessage" to (lastMessage ?: ""),
                        "lastMessageTime" to (lastMessageTime ?: ""),
                        "lastActiveTime" to (lastActiveTime ?: ""),
                        "appStatus" to (appStatus ?: "")
                    )
                    
                    result.success(statusData)
                }

                "saveMessageHistory" -> {
                    val historyJson = call.argument<String>("history") ?: "[]"
                    sharedPref.edit().putString(KEY_MESSAGE_HISTORY, historyJson).apply()
                    result.success(true)
                }

                "loadMessageHistory" -> {
                    val historyJson = sharedPref.getString(KEY_MESSAGE_HISTORY, "[]")
                    result.success(historyJson)
                }

                "clearMessageHistory" -> {
                    sharedPref.edit().remove(KEY_MESSAGE_HISTORY).apply()
                    result.success(true)
                }
                
                "clearWaulyData" -> {
                    sharedPref.edit().clear().apply()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }

        // EventChannel for real-time updates
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, MONITORING_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    WaulyReceiver.eventSink = events
                    Log.d("MonitorApp", "EventChannel listener attached")
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    WaulyReceiver.eventSink = null
                    Log.d("MonitorApp", "EventChannel listener detached")
                }
            })
    }


    override fun onResume() {
        super.onResume()
        // DO NOT register any receiver here - WaulyReceiver is in manifest
        Log.d("MainActivity", "Activity resumed - WaulyReceiver handles broadcasts")
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