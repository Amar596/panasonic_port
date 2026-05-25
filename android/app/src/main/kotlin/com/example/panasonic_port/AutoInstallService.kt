package com.example.panasonic_port

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import android.widget.Toast


class AutoInstallService : AccessibilityService() {
    
    companion object {
        private const val TAG = "AutoInstallService"
        var instance: AutoInstallService? = null
        private var installClicked = false
        private var openClicked = false
        private var retryCount = 0
        private var updateDialogClicked = false
        
        fun autoClickInstall() {
            Log.d(TAG, "autoClickInstall called")
            instance?.performInstallClick()
        }
        
        fun resetFlags() {
            installClicked = false
            openClicked = false
            retryCount = 0
            updateDialogClicked = false
            Log.d(TAG, "Flags reset")
        }

        fun autoClickUpdateButton(buttonText: String) {
            Log.d(TAG, "autoClickUpdateButton called for: $buttonText")
            instance?.clickDialogButton(buttonText)
        }

        fun checkForUpdateDialog(): Boolean {
            return instance?.isUpdateDialogShowing() ?: false
        }
        
        fun forceCheckForDialog() {
            instance?.forceCheckForDialog()
        }
    }

    private fun showToast(message: String) {
    Handler(Looper.getMainLooper()).post {
        android.widget.Toast.makeText(
            this@AutoInstallService,
            message,
            android.widget.Toast.LENGTH_LONG
        ).show()
    }
    }

    // fun forceCheckForDialog() {
    // Log.d(TAG, "Force checking for dialog...")
    // val root = rootInActiveWindow
    // if (root != null) {
    //     Log.d(TAG, "Root window available, searching for dialog...")
    //     findAndClickUpdateDialogButton()
    // } else {
    //     Log.d(TAG, "Root window is null, cannot detect dialog")
    //     // Try to get the active window through another method
    //     try {
    //         val windows = windows
    //         if (windows != null) {
    //             Log.d(TAG, "Found ${windows.size} windows")
    //             for (window in windows) {
    //                 Log.d(TAG, "Window: ${window.root}")
    //                 if (window.root != null) {
    //                     findAndClickUpdateDialogButton()
    //                     break
    //                 }
    //             }
    //         }
    //     } catch (e: Exception) {
    //         Log.e(TAG, "Error getting windows: ${e.message}")
    //     }
    // }
    // }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPES_ALL_MASK
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or
                    AccessibilityServiceInfo.FLAG_REQUEST_TOUCH_EXPLORATION_MODE or
                    AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 100
        }
        setServiceInfo(info)
        
        Log.d(TAG, "✅ Accessibility Service Connected and Configured")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName = event?.packageName?.toString() ?: return
        
        Log.d(TAG, "Event: pkg=$packageName, type=${event.eventType}")
        
        // Handle package installer events
        val isInstallerRelated = packageName.contains("packageinstaller") ||
                                 packageName == "com.android.packageinstaller" ||
                                 packageName == "com.google.android.packageinstaller"
        
        if (isInstallerRelated) {
            Log.d(TAG, "📦 Installer window detected: $packageName")
            
            when (event.eventType) {
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                    Handler(Looper.getMainLooper()).postDelayed({
                        if (!installClicked) {
                            findAndClickInstallButton()
                        } else if (installClicked && !openClicked) {
                            Handler(Looper.getMainLooper()).postDelayed({
                                findAndClickOpenButton()
                            }, 1500)
                        }
                    }, 500)
                }
            }
        }
        
        // Handle installation complete
        if (event?.className?.toString()?.contains("InstallSuccess") == true ||
            event?.className?.toString()?.contains("InstallFinished") == true) {
            Log.d(TAG, "🎉 Installation complete screen detected!")
            Handler(Looper.getMainLooper()).postDelayed({
                if (installClicked && !openClicked) {
                    findAndClickOpenButton()
                }
            }, 1000)
        }
    }

    // NEW METHOD: Handle app's own dialogs
    private fun handleAppDialog(event: AccessibilityEvent?) {
        when (event?.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED,
            AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> {
                Handler(Looper.getMainLooper()).postDelayed({
                    if (!updateDialogClicked) {
                        findAndClickUpdateDialogButton()
                    }
                }, 300)
            }
        }
    }


    // IMPROVED: Better dialog detection and button clicking
        private fun findAndClickUpdateDialogButton() {
        Log.d(TAG, "🔍 Searching for update dialog buttons...")
        
        // Try multiple ways to get the root view
        var root = rootInActiveWindow
        
        // If root is null, try to get from windows
        if (root == null) {
            try {
                val windows = windows
                if (windows != null && windows.isNotEmpty()) {
                    for (window in windows) {
                        if (window.root != null) {
                            root = window.root
                            Log.d(TAG, "Got root from window")
                            break
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error getting windows: ${e.message}")
            }
        }
        
        if (root == null) {
            Log.d(TAG, "Root window is null for update dialog")
            return
        }
        
        // Search for ANY button with "Update" or "Update Now" text
        val allButtons = mutableListOf<AccessibilityNodeInfo>()
        collectAllButtons(root, allButtons)
        
        Log.d(TAG, "Found ${allButtons.size} total buttons")

            for (button in allButtons) {
        val buttonText = button.text?.toString() ?: ""
        
        if (buttonText.contains("Update Now", ignoreCase = true) ||
            buttonText.equals("Update", ignoreCase = true)) {
            
            Log.d(TAG, "✅ Found target button: '$buttonText'")
            val clicked = button.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            if (clicked) {
                updateDialogClicked = true
                
                // ADD THIS LINE - Start downloading the APK
                startApkDownload("YOUR_APK_DOWNLOAD_URL_HERE")
                
                Log.d(TAG, "✅ Successfully clicked: '$buttonText'")
                return
            }
        }
    }
        
        // for (button in allButtons) {
        //     val buttonText = button.text?.toString() ?: ""
        //     val className = button.className?.toString() ?: ""
            
        //     Log.d(TAG, "Button found: text='$buttonText', class='$className', clickable=${button.isClickable}")
            
        //     // Check if this is the "Update Now" button
        //     if (buttonText.contains("Update Now", ignoreCase = true) ||
        //         buttonText.equals("Update", ignoreCase = true) ||
        //         buttonText.equals("UPDATE", ignoreCase = true) ||
        //         buttonText.contains("Install", ignoreCase = true)) {
                
        //         Log.d(TAG, "✅ Found target button: '$buttonText'")
        //         val clicked = button.performAction(AccessibilityNodeInfo.ACTION_CLICK)
        //         if (clicked) {
        //             updateDialogClicked = true
        //             Log.d(TAG, "✅ Successfully clicked: '$buttonText'")
        //             return
        //         }
        //     }
        // }
        
        // If not found, try to find by ID (Flutter dialog buttons often have specific IDs)
        findAndClickByViewId(root)
    }

    private fun collectAllButtons(node: AccessibilityNodeInfo, buttons: MutableList<AccessibilityNodeInfo>) {
    // Check if this node is a button
    val className = node.className?.toString() ?: ""
    if (className.contains("Button", ignoreCase = true) && node.isClickable) {
        buttons.add(node)
    }
    
    // Also check nodes that are clickable even if not Button class
    if (node.isClickable && node.isEnabled && node.text?.isNotEmpty() == true) {
        buttons.add(node)
    }
    
    // Recursively check children
    for (i in 0 until node.childCount) {
        val child = node.getChild(i)
        if (child != null) {
            collectAllButtons(child, buttons)
            child.recycle()
        }
    }
    }

    private fun findAndClickByViewId(root: AccessibilityNodeInfo) {
    // Common Flutter dialog button IDs
    val buttonIds = listOf(
        "android:id/button1",           // Positive button
        "android:id/button2",           // Negative button  
        "android:id/button3",           // Neutral button
        "com.example.philips_tv_flutter:id/button1",
        "com.example.philips_tv_flutter:id/button2"
    )
    
    for (id in buttonIds) {
        val button = findButtonById(root, listOf(id))
        if (button != null && button.isClickable) {
            val buttonText = button.text?.toString() ?: ""
            Log.d(TAG, "Found button by ID: $id, text='$buttonText'")
            val clicked = button.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            if (clicked) {
                updateDialogClicked = true
                Log.d(TAG, "✅ Successfully clicked button with ID: $id")
                return
            }
        }
    }
    }

    // Add this method to search for text anywhere in the hierarchy
    private fun findTextInAnyNode(node: AccessibilityNodeInfo, searchText: String): Boolean {
        val nodeText = node.text?.toString()
        if (nodeText != null && nodeText.contains(searchText, ignoreCase = true)) {
            Log.d(TAG, "Found text '$searchText' in node: $nodeText")
            return true
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                val found = findTextInAnyNode(child, searchText)
                child.recycle()
                if (found) return true
            }
        }
        return false
    }

    // Add this method to force click at coordinates (as fallback)
    private fun forceClickAtCoordinates() {
        // Get screen dimensions and click at typical dialog button position
        // You may need to adjust these coordinates based on your screen
        val displayMetrics = resources.displayMetrics
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels
        
        // Typically dialog buttons are at the bottom center
        val x = (screenWidth / 2).toFloat()
        val y = (screenHeight * 0.85).toFloat()
        
        Log.d(TAG, "Force clicking at coordinates: ($x, $y)")
        
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
            val path = android.graphics.Path()
            path.moveTo(x, y)
            val gesture = android.accessibilityservice.GestureDescription.Builder()
                .addStroke(android.accessibilityservice.GestureDescription.StrokeDescription(path, 0, 100))
                .build()
            
            dispatchGesture(gesture, object : GestureResultCallback() {
                override fun onCompleted(gestureDescription: android.accessibilityservice.GestureDescription?) {
                    Log.d(TAG, "✅ Force click completed")
                    updateDialogClicked = true
                }
                
                override fun onCancelled(gestureDescription: android.accessibilityservice.GestureDescription?) {
                    Log.d(TAG, "❌ Force click cancelled")
                }
            }, null)
        }
    }


    private fun isUpdateDialogShowing(root: AccessibilityNodeInfo? = rootInActiveWindow): Boolean {
        root ?: return false
        
        val hasUpdateText = findTextInNode(root, listOf("Update Available", "New Version", "Update Now", "新版本"))
        
        if (hasUpdateText != null) {
            Log.d(TAG, "Found update dialog text: ${hasUpdateText.text}")
            return true
        }
        
        val dialog = findDialogContainer(root)
        if (dialog != null) {
            Log.d(TAG, "Found dialog container")
            return true
        }
        
        return false
    }

    // private fun showToast(message: String) {
    //     Handler(Looper.getMainLooper()).post {
    //         android.widget.Toast.makeText(
    //             this@AutoInstallService,
    //             message,
    //             android.widget.Toast.LENGTH_LONG
    //         ).show()
    //     }
    // }

    // ADD THIS NEW METHOD HERE
    private fun showProgressToast(progress: Int) {
        if (progress % 25 == 0 || progress == 100) { 
            Handler(Looper.getMainLooper()).post {
                Toast.makeText(
                    this@AutoInstallService, 
                    "Downloading update: $progress%", 
                    Toast.LENGTH_SHORT
                ).show()
            }
        }
    }

    // Add these methods to your AutoInstallService class
    private fun startApkDownload(downloadUrl: String) {
        showToast("Starting download...")
        
        val downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        val request = DownloadManager.Request(Uri.parse(downloadUrl)).apply {
            setTitle("App Update")
            setDescription("Downloading latest version...")
            setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "app_update.apk")
        }
        
        val downloadId = downloadManager.enqueue(request)
        monitorDownloadProgress(downloadId)
    }

    private fun monitorDownloadProgress(downloadId: Long) {
        val handler = Handler(Looper.getMainLooper())
        val downloadManager = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
        
        handler.post(object : Runnable {
            override fun run() {
                val query = DownloadManager.Query().setFilterById(downloadId)
                val cursor = downloadManager.query(query)
                
                if (cursor.moveToFirst()) {
                    val bytesDownloaded = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR))
                    val bytesTotal = cursor.getInt(cursor.getColumnIndex(DownloadManager.COLUMN_TOTAL_SIZE_BYTES))
                    
                    if (bytesTotal > 0) {
                        val progress = (bytesDownloaded * 100 / bytesTotal)
                        showProgressToast(progress) // This shows the toast at 25%, 50%, 75%, 100%
                        
                        if (progress < 100) {
                            handler.postDelayed(this, 1000) // Check again in 1 second
                        } else {
                            showToast("Download complete! Installing update...")
                            // Trigger the installation
                            findAndClickInstallButton()
                        }
                    } else {
                        handler.postDelayed(this, 1000)
                    }
                }
                cursor.close()
            }
        })
    }

    // NEW METHOD: Find text in node hierarchy
    private fun findTextInNode(node: AccessibilityNodeInfo, texts: List<String>): AccessibilityNodeInfo? {
        val nodeText = node.text?.toString()
        if (nodeText != null) {
            for (text in texts) {
                if (nodeText.contains(text, ignoreCase = true)) {
                    return node
                }
            }
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                val found = findTextInNode(child, texts)
                if (found != null) return found
                child.recycle()
            }
        }
        return null
    }

    // NEW METHOD: Find dialog container
    private fun findDialogContainer(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val className = node.className?.toString() ?: ""
        
        if (className.contains("AlertDialog") || 
            className.contains("Dialog") ||
            className.contains("DialogContainer")) {
            return node
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                val found = findDialogContainer(child)
                if (found != null) return found
                child.recycle()
            }
        }
        return null
    }

    private fun clickDialogButton(buttonText: String) {
        val root = rootInActiveWindow
        if (root == null) {
            Log.d(TAG, "Root window is null for dialog button click")
            return
        }
        
        val button = findButtonByText(root, listOf(buttonText))
        
        if (button != null && button.isClickable) {
            Log.d(TAG, "✅ Found button: $buttonText")
            button.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            updateDialogClicked = true
        }
    }

    private fun isUpdateDialogShowing(): Boolean {
        val root = rootInActiveWindow ?: return false
        val updateTexts = listOf("Update Available", "New Version", "Update Now")
        return findButtonByText(root, updateTexts) != null
    }

    private fun forceCheckForDialog() {
        val root = rootInActiveWindow
        if (root != null) {
            Log.d(TAG, "Force checking for dialog...")
            val button = findButtonByText(root, listOf("Update Now", "Update"))
            if (button != null && button.isClickable) {
                button.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                updateDialogClicked = true
            }
        }
    }


    private fun findAndClickInstallButton() {
        val root = rootInActiveWindow
        if (root == null) {
            Log.d(TAG, "Root window is null for INSTALL button")
            return
        }
        
        Log.d(TAG, "🔍 Searching for INSTALL button...")
        
        val installTexts = listOf("INSTALL")
        var installButton = findButtonByText(root, installTexts)
        
        if (installButton == null) {
            val buttonIds = listOf(
                "android:id/button1",
                "com.android.packageinstaller:id/install_button"
            )
            installButton = findButtonById(root, buttonIds)
        }
        
        if (installButton != null && installButton.isClickable) {
            Log.d(TAG, "✅ Found INSTALL button")
            val clicked = installButton.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            if (clicked) {
                installClicked = true
                Log.d(TAG, "✅ INSTALL button clicked successfully!")
            }
        }
    }

    private fun findAndClickOpenButton() {
        val root = rootInActiveWindow
        if (root == null) {
            Log.d(TAG, "Root window is null for OPEN button")
            retryCount++
            if (retryCount < 5) {
                Handler(Looper.getMainLooper()).postDelayed({
                    findAndClickOpenButton()
                }, 1000)
            }
            return
        }
        
        Log.d(TAG, "🔍 Searching for OPEN button...")
        
        val openTexts = listOf("OPEN")
        var openButton = findButtonByText(root, openTexts)
        
        if (openButton == null) {
            val buttonIds = listOf(
                "android:id/button2",
                "com.android.packageinstaller:id/open_button"
            )
            openButton = findButtonById(root, buttonIds)
        }
        
        if (openButton != null && openButton.isClickable) {
            Log.d(TAG, "✅ Found OPEN button")
            val clicked = openButton.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            if (clicked) {
                openClicked = true
                Log.d(TAG, "✅ OPEN button clicked successfully!")
                retryCount = 0
            }
        } else {
            retryCount++
            if (retryCount < 5) {
                Handler(Looper.getMainLooper()).postDelayed({
                    findAndClickOpenButton()
                }, 1000)
            }
        }
    }
    
    private fun debugPrintButtons(node: AccessibilityNodeInfo) {
        try {
            if (node.isClickable && node.text != null) {
                Log.d(TAG, "Clickable button found: text='${node.text}', id='${node.viewIdResourceName}'")
            }
            
            for (i in 0 until node.childCount) {
                val child = node.getChild(i)
                if (child != null) {
                    debugPrintButtons(child)
                    child.recycle()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error printing buttons: ${e.message}")
        }
    }
    

    private fun findButtonByText(node: AccessibilityNodeInfo, texts: List<String>): AccessibilityNodeInfo? {
        val nodeText = node.text?.toString()
        if (nodeText != null) {
            for (text in texts) {
                if (nodeText.equals(text, ignoreCase = true) && node.isClickable) {
                    return node
                }
            }
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                val found = findButtonByText(child, texts)
                if (found != null) return found
                child.recycle()
            }
        }
        return null
    }
    
    private fun findButtonById(node: AccessibilityNodeInfo, ids: List<String>): AccessibilityNodeInfo? {
        val nodeId = node.viewIdResourceName
        if (nodeId != null) {
            for (id in ids) {
                if (nodeId == id && node.isClickable) {
                    return node
                }
            }
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                val found = findButtonById(child, ids)
                if (found != null) return found
                child.recycle()
            }
        }
        return null
    }
    
    private fun findButtonByContentDescription(node: AccessibilityNodeInfo, descriptions: List<String>): AccessibilityNodeInfo? {
        val contentDesc = node.contentDescription?.toString()
        if (contentDesc != null) {
            for (desc in descriptions) {
                if (contentDesc.equals(desc, ignoreCase = true) && node.isClickable) {
                    Log.d(TAG, "Found button by content description: '$contentDesc'")
                    return node
                }
            }
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                val found = findButtonByContentDescription(child, descriptions)
                if (found != null) return found
            }
        }
        return null
    }
    
    private fun performInstallClick() {
        Log.d(TAG, "Manual install click triggered")
        installClicked = false
        openClicked = false
        retryCount = 0
        findAndClickInstallButton()
    }
    
    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service Interrupted")
        instance = null
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
        Log.d(TAG, "Accessibility Service Destroyed")
    }


    private fun isWebViewDialog(root: AccessibilityNodeInfo): Boolean {
        // Check if any WebView is present
        var hasWebView = false
        
        fun checkForWebView(node: AccessibilityNodeInfo) {
            val className = node.className?.toString() ?: ""
            if (className.contains("WebView", ignoreCase = true)) {
                hasWebView = true
                Log.d(TAG, "Found WebView: $className")
                return
            }
            
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                checkForWebView(child)
                child.recycle()
                if (hasWebView) return
            }
        }
        
        checkForWebView(root)
        return hasWebView
    }

    private fun handleWebViewDialog(root: AccessibilityNodeInfo) {
    // Find the WebView node
    var webViewNode: AccessibilityNodeInfo? = null
    
    fun findWebView(node: AccessibilityNodeInfo) {
        val className = node.className?.toString() ?: ""
        if (className.contains("WebView", ignoreCase = true)) {
            webViewNode = node
            return
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            findWebView(child)
            child.recycle()
            if (webViewNode != null) return
        }
    }
    
    findWebView(root)
    
    // Store in a local variable to avoid smart cast issues
    val webView = webViewNode
    if (webView != null) {
        // Try to perform click on the WebView (this might not work directly)
        // Alternative: We need to inject JavaScript
        Log.d(TAG, "Attempting to click via WebView node")
        
        // Method 1: Try ACTION_CLICK on WebView
        if (webView.isClickable) {
            val clicked = webView.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            if (clicked) {
                updateDialogClicked = true
                Log.d(TAG, "✅ Clicked on WebView")
                return
            }
        }
        
        // Method 2: Send a broadcast to Flutter to execute JavaScript
        sendWebViewClickBroadcast()
    }
    }

    private fun sendWebViewClickBroadcast() {
        try {
            val intent = android.content.Intent("CLICK_UPDATE_BUTTON")
            intent.setPackage("com.example.philips_tv_flutter")
            sendBroadcast(intent)
            Log.d(TAG, "📡 Sent broadcast to click update button in WebView")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to send broadcast: ${e.message}")
        }
    }

    private fun clickNativeDialogButton(root: AccessibilityNodeInfo): Boolean {
        val allButtons = mutableListOf<AccessibilityNodeInfo>()
        collectClickableButtons(root, allButtons)
        
        Log.d(TAG, "Found ${allButtons.size} clickable buttons")
        
        for (button in allButtons) {
            val buttonText = button.text?.toString() ?: ""
            val viewId = button.viewIdResourceName ?: ""
            
            Log.d(TAG, "Button: text='$buttonText', id='$viewId'")
            
            if (buttonText.contains("Update Now", ignoreCase = true) ||
                buttonText.contains("Update", ignoreCase = true) ||
                buttonText.contains("Install", ignoreCase = true) ||
                viewId.contains("button1") ||
                viewId.contains("positive")) {
                
                val clicked = button.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                if (clicked) {
                    Log.d(TAG, "✅ Clicked button: '$buttonText'")
                    return true
                }
            }
        }
        
        return false
    }

    private fun collectClickableButtons(node: AccessibilityNodeInfo, buttons: MutableList<AccessibilityNodeInfo>) {
        if (node.isClickable && node.isEnabled) {
            buttons.add(node)
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i) ?: continue
            collectClickableButtons(child, buttons)
            child.recycle()
        }
    }

    private fun debugPrintAllText(node: AccessibilityNodeInfo) {
        try {
            if (node.text?.isNotEmpty() == true) {
                Log.d(TAG, "Text: '${node.text}', class='${node.className}', clickable=${node.isClickable}")
            }
            if (node.contentDescription?.isNotEmpty() == true) {
                Log.d(TAG, "ContentDesc: '${node.contentDescription}'")
            }
            
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                debugPrintAllText(child)
                child.recycle()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error: ${e.message}")
        }
    }
}