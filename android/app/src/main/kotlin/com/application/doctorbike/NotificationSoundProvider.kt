package com.application.doctorbike

import android.content.ContentProvider
import android.content.ContentValues
import android.database.Cursor
import android.net.Uri
import android.os.ParcelFileDescriptor
import java.io.File

/** Read-only provider used by Android's notification service for admin-uploaded sounds. */
class NotificationSoundProvider : ContentProvider() {
    override fun onCreate(): Boolean = true

    override fun openFile(uri: Uri, mode: String): ParcelFileDescriptor {
        if (mode != "r") throw SecurityException("Notification sounds are read-only")
        val name = uri.lastPathSegment?.takeIf {
            it.matches(Regex("[a-zA-Z0-9._-]+"))
        } ?: throw IllegalArgumentException("Invalid sound path")
        val directory = File(requireNotNull(context).filesDir, "notification_sounds")
        val file = File(directory, name).canonicalFile
        if (file.parentFile != directory.canonicalFile || !file.isFile) {
            throw IllegalArgumentException("Sound not found")
        }
        return ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
    }

    override fun getType(uri: Uri): String = when (uri.lastPathSegment?.substringAfterLast('.')?.lowercase()) {
        "wav" -> "audio/wav"
        "mp3" -> "audio/mpeg"
        "caf" -> "audio/x-caf"
        else -> "application/octet-stream"
    }

    override fun query(uri: Uri, projection: Array<out String>?, selection: String?, selectionArgs: Array<out String>?, sortOrder: String?): Cursor? = null
    override fun insert(uri: Uri, values: ContentValues?): Uri? = throw UnsupportedOperationException()
    override fun delete(uri: Uri, selection: String?, selectionArgs: Array<out String>?): Int = throw UnsupportedOperationException()
    override fun update(uri: Uri, values: ContentValues?, selection: String?, selectionArgs: Array<out String>?): Int = throw UnsupportedOperationException()
}
