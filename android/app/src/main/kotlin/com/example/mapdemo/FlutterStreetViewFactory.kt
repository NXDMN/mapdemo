package com.example.mapdemo

import android.content.Context
import androidx.lifecycle.Lifecycle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FlutterStreetViewFactory(
    private val binaryMessenger: BinaryMessenger,
    private val activityLifecycle: Lifecycle
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        return FlutterStreetView(context!!, viewId, creationParams, binaryMessenger, activityLifecycle)
    }
}