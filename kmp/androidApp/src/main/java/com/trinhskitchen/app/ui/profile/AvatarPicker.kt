package com.trinhskitchen.app.ui.profile

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.media.ExifInterface
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.core.content.FileProvider
import androidx.compose.ui.platform.LocalContext
import java.io.ByteArrayOutputStream
import java.io.File
import kotlin.math.max

/** The two ways a profile photo can be chosen, as the profile screen offers them. */
class AvatarPicker(
    val pickFromLibrary: () -> Unit,
    val takePhoto: () -> Unit
)

/**
 * A photo picker and a camera, both handing back a JPEG ready to upload.
 * Mirrors what iOS gets from PhotosPicker and UIImagePickerController.
 *
 * The library picker needs no permission on any supported version, and the camera writes to
 * the app's own cache through a FileProvider, so neither path asks the customer for access to
 * anything wider than the photo they picked.
 *
 * @param onPicked called with the encoded photo; not called when the customer backs out or the
 *                 file turns out to be unreadable
 * @param onError called with a message worth showing
 */
@Composable
fun rememberAvatarPicker(
    onPicked: (ByteArray) -> Unit,
    onError: (String) -> Unit
): AvatarPicker {
    val context = LocalContext.current
    val cameraTarget = remember { mutableStateOf<Uri?>(null) }

    fun deliver(uri: Uri?) {
        val jpeg = uri?.let { encodeJpeg(context, it) }
        if (jpeg == null) onError("We couldn't read that photo.") else onPicked(jpeg)
    }

    val library = rememberLauncherForActivityResult(ActivityResultContracts.PickVisualMedia()) { uri ->
        uri?.let { deliver(it) }
    }

    val camera = rememberLauncherForActivityResult(ActivityResultContracts.TakePicture()) { taken ->
        if (taken) deliver(cameraTarget.value)
    }

    return remember {
        AvatarPicker(
            pickFromLibrary = {
                library.launch(
                    PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                )
            },
            takePhoto = {
                try {
                    val file = File.createTempFile("avatar", ".jpg", context.cacheDir)
                    val uri = FileProvider.getUriForFile(
                        context,
                        "${context.packageName}.files",
                        file
                    )
                    cameraTarget.value = uri
                    camera.launch(uri)
                } catch (e: Exception) {
                    onError(e.message ?: "The camera isn't available on this device.")
                }
            }
        )
    }
}

/**
 * Reads an image and re-encodes it as a JPEG small enough to upload.
 *
 * Sampled down while decoding rather than after: a full-resolution phone photo is tens of
 * megabytes as a bitmap, and this is going into a 60dp circle.
 *
 * ponytail: sampling lands within 2x of the target edge rather than exactly on it — fine for an
 * avatar, scale the bitmap afterwards if a larger use appears.
 */
private fun encodeJpeg(context: Context, uri: Uri): ByteArray? = try {
    val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
    context.contentResolver.openInputStream(uri)?.use {
        BitmapFactory.decodeStream(it, null, bounds)
    }

    val options = BitmapFactory.Options().apply {
        var sample = 1
        while (max(bounds.outWidth, bounds.outHeight) / sample > MAX_EDGE * 2) sample *= 2
        inSampleSize = sample
    }
    val decoded = context.contentResolver.openInputStream(uri)?.use {
        BitmapFactory.decodeStream(it, null, options)
    }

    decoded?.let { bitmap ->
        ByteArrayOutputStream().use { out ->
            uprightOf(context, uri, bitmap).compress(Bitmap.CompressFormat.JPEG, QUALITY, out)
            out.toByteArray()
        }
    }
} catch (e: Exception) {
    println("📷 Avatar encode failed: ${e.message}")
    null
}

/**
 * Applies the photo's own EXIF rotation.
 *
 * A camera writes the orientation as a tag and leaves the pixels as the sensor read them, so
 * without this a portrait selfie arrives at the server on its side.
 */
private fun uprightOf(context: Context, uri: Uri, bitmap: Bitmap): Bitmap {
    val orientation = context.contentResolver.openInputStream(uri)?.use {
        ExifInterface(it).getAttributeInt(
            ExifInterface.TAG_ORIENTATION,
            ExifInterface.ORIENTATION_NORMAL
        )
    } ?: return bitmap

    val degrees = when (orientation) {
        ExifInterface.ORIENTATION_ROTATE_90 -> 90f
        ExifInterface.ORIENTATION_ROTATE_180 -> 180f
        ExifInterface.ORIENTATION_ROTATE_270 -> 270f
        else -> return bitmap
    }

    val rotated = Matrix().apply { postRotate(degrees) }
    return Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, rotated, true)
}

private const val MAX_EDGE = 1024
private const val QUALITY = 85
