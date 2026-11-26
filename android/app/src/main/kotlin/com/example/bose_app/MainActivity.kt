package com.example.bose_app

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hosts the "bose_eq/device_audio" channel: picks audio files through the
 * system document picker and keeps read access to them across restarts.
 *
 * Nothing is copied. The app stores only each file's content:// URI and
 * plays the original in place, so picked tracks take no extra storage.
 * Access survives restarts because the URI permission is made persistable.
 */
class MainActivity : FlutterActivity() {
    private var pendingPick: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Copies left behind by the earlier file_picker-based picker.
        File(cacheDir, "file_picker").deleteRecursively()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pick" -> pick(result)
                    "granted" -> result.success(
                        contentResolver.persistedUriPermissions
                            .filter { it.isReadPermission }
                            .map { it.uri.toString() },
                    )
                    "release" -> {
                        call.argument<String>("uri")?.let { release(Uri.parse(it)) }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun pick(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "The picker is already open", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "audio/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        pendingPick = result
        try {
            startActivityForResult(intent, PICK_REQUEST)
        } catch (e: Exception) {
            pendingPick = null
            result.error("unavailable", e.message, null)
        }
    }

    @Deprecated("Uses the platform callback that FlutterActivity exposes")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_REQUEST) return
        val result = pendingPick ?: return
        pendingPick = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(emptyList<Map<String, String>>()) // cancelled
            return
        }
        val uris = mutableListOf<Uri>()
        val clip = data.clipData
        if (clip != null) {
            for (i in 0 until clip.itemCount) uris.add(clip.getItemAt(i).uri)
        } else {
            data.data?.let { uris.add(it) }
        }

        result.success(
            uris.mapNotNull { uri ->
                try {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION,
                    )
                    mapOf("uri" to uri.toString(), "name" to displayName(uri))
                } catch (e: SecurityException) {
                    null // provider does not allow lasting access; skip it
                }
            },
        )
    }

    private fun release(uri: Uri) {
        try {
            contentResolver.releasePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        } catch (e: SecurityException) {
            // Already released.
        }
    }

    private fun displayName(uri: Uri): String {
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(0)?.let { return it }
                }
            }
        return uri.lastPathSegment ?: "Unknown track"
    }

    private companion object {
        const val CHANNEL = "bose_eq/device_audio"
        const val PICK_REQUEST = 4207
    }
}
