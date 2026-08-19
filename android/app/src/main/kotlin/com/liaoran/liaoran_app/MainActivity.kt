package com.liaoran.liaoran_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "liaoran/upload"
    private val backupChannelName = "liaoran/backup"
    private var pendingResult: MethodChannel.Result? = null
    private var inFlight = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerUploadChannel(flutterEngine)
        registerBackupChannel(flutterEngine)
    }

    private fun registerUploadChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            if (call.method == "pickImage") {
                if (inFlight) {
                    result.success(null)
                    return@setMethodCallHandler
                }
                inFlight = true
                pendingResult = result
                val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "image/*"
                }
                startActivityForResult(intent, PICK_IMAGE_REQUEST)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun registerBackupChannel(flutterEngine: FlutterEngine) {
        val backupDir = File(filesDir, "backups").apply { mkdirs() }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            backupChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "writeFile" -> {
                    val name = call.argument<String>("name")
                    val content = call.argument<String>("content")
                    if (name == null || content == null) {
                        result.error("bad_args", "name or content missing", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(backupDir, name)
                        file.writeText(content)
                        result.success(file.absolutePath)
                    } catch (e: Exception) {
                        result.error("write_failed", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_IMAGE_REQUEST) return

        val result = pendingResult
        pendingResult = null
        inFlight = false

        val uri = if (resultCode == Activity.RESULT_OK) data?.data else null
        if (uri == null || result == null) {
            result?.success(null)
            return
        }
        try {
            val input = contentResolver.openInputStream(uri)
            if (input == null) {
                result.success(null)
                return
            }
            val outFile =
                File(cacheDir, "upload_${System.currentTimeMillis()}.jpg")
            input.use { ins ->
                outFile.outputStream().use { outs -> ins.copyTo(outs) }
            }
            result.success(outFile.absolutePath)
        } catch (_: Exception) {
            result.success(null)
        }
    }

    companion object {
        private const val PICK_IMAGE_REQUEST = 0x1A01
    }
}
