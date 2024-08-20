package com.example.mapdemo

import android.content.Context
import android.os.Bundle
import android.view.View
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.google.android.gms.maps.StreetViewPanorama
import com.google.android.gms.maps.StreetViewPanoramaOptions
import com.google.android.gms.maps.StreetViewPanoramaView
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.StreetViewPanoramaCamera
import com.google.android.gms.maps.model.StreetViewPanoramaLocation
import com.google.android.gms.maps.model.StreetViewPanoramaOrientation
import com.google.android.gms.maps.model.StreetViewSource
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding.OnSaveInstanceStateListener
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformView

internal class FlutterStreetView(
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?,
    binaryMessenger: BinaryMessenger,
    activityLifecycle: Lifecycle
) : PlatformView, MethodCallHandler, DefaultLifecycleObserver, OnSaveInstanceStateListener, StreetViewListener {
    private var streetViewPanoramaView: StreetViewPanoramaView? =null
    private var streetViewPanorama: StreetViewPanorama? = null
    private val initOptions: StreetViewPanoramaOptions
    private val methodChannel: MethodChannel

    override fun getView(): View? = streetViewPanoramaView

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }

    init {
        initOptions = createInitOption(creationParams)
        streetViewPanoramaView = StreetViewPanoramaView(context, initOptions).apply {
            this.id = id
            getStreetViewPanoramaAsync {
                streetViewPanorama = it
                setupListener(it)
            }
        }

        methodChannel = MethodChannel(binaryMessenger, "flutter_street_view_$id")
        methodChannel.setMethodCallHandler(this)

        activityLifecycle.addObserver(this)
    }

    private fun createInitOption(creationParams: Map<String?, Any?>?): StreetViewPanoramaOptions =
        if (creationParams != null) StreetViewPanoramaOptions().apply {
            if (creationParams.containsKey("initPosition") && creationParams["initPosition"] != null) {
                val data = creationParams["initPosition"] as List<*>
                val initPosition = if (data.size == 2)
                    LatLng((data[0]!! as Double), (data[1]!! as Double))
                else null

                val source = if (creationParams.containsKey("source") && creationParams["source"] != null){
                    if (creationParams["source"] == "outdoor") StreetViewSource.OUTDOOR else StreetViewSource.DEFAULT
                }else null

                if (source != null)
                    position(initPosition, source)
                else
                    position(initPosition)
            }

        } else StreetViewPanoramaOptions()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when(call.method){

        }
    }

    private fun setupListener(streetViewPanorama: StreetViewPanorama) {
        streetViewPanorama.setOnStreetViewPanoramaCameraChangeListener(this)
        streetViewPanorama.setOnStreetViewPanoramaChangeListener(this)
        streetViewPanorama.setOnStreetViewPanoramaClickListener(this)
        streetViewPanorama.setOnStreetViewPanoramaLongClickListener(this)
    }

    override fun onStreetViewPanoramaCameraChange(camera: StreetViewPanoramaCamera) {
        val arguments: MutableMap<String, Any> = hashMapOf(
            "bearing" to camera.bearing,
            "tilt" to camera.tilt,
            "zoom" to camera.zoom
        )

        methodChannel.invokeMethod(
            "camera#onChange",
            arguments
        )
    }

    override fun onStreetViewPanoramaChange(location: StreetViewPanoramaLocation) {
        val arg = if (location.links.isNotEmpty()) location.let {
            hashMapOf(
                "links" to ArrayList<Any>().apply {
                    it.links.forEach { link ->
                        add(arrayListOf(link.panoId, link.bearing))
                    }
                },
                "panoId" to it.panoId,
                "position" to listOf(it.position.latitude, it.position.longitude)
            )

        } else mutableMapOf<String, Any>().apply {
            val errorMsg = "No valid panorama found."
            put("error", errorMsg)
        }

        methodChannel.invokeMethod(
            "panorama#onChange", arg
        )
    }

    override fun onStreetViewPanoramaClick(orientation: StreetViewPanoramaOrientation) {
        val arguments: MutableMap<String, Any> = hashMapOf(
            "bearing" to orientation.bearing,
            "tilt" to orientation.tilt
        )

        methodChannel.invokeMethod(
            "panorama#onClick", arguments.apply {
                streetViewPanorama?.orientationToPoint(orientation)?.let {
                    putAll(hashMapOf(
                        "x" to it.x,
                        "y" to it.y
                    ))
                }
            }
        )
    }

    override fun onStreetViewPanoramaLongClick(orientation: StreetViewPanoramaOrientation) {
        val arguments: MutableMap<String, Any> = hashMapOf(
            "bearing" to orientation.bearing,
            "tilt" to orientation.tilt
        )

        methodChannel.invokeMethod(
            "panorama#onLongClick", arguments.apply {
                streetViewPanorama?.orientationToPoint(orientation)?.let {
                    putAll(hashMapOf(
                        "x" to it.x,
                        "y" to it.y
                    ))
                }
            }
        )
    }

    override fun onCreate(owner: LifecycleOwner) {
        streetViewPanoramaView?.onCreate(null)
    }

    override fun onStart(owner: LifecycleOwner) {
        streetViewPanoramaView?.onStart()
        super.onStart(owner)
    }

    override fun onResume(owner: LifecycleOwner) {
        streetViewPanoramaView?.onResume()
        super.onResume(owner)
    }

    override fun onPause(owner: LifecycleOwner) {
        streetViewPanoramaView?.onPause()
        super.onPause(owner)
    }

    override fun onStop(owner: LifecycleOwner) {
        streetViewPanoramaView?.onStop()
        super.onStop(owner)
    }

    override fun onDestroy(owner: LifecycleOwner) {
        owner.lifecycle.removeObserver(this)
        destroyStreetViewIfNecessary()
        super.onDestroy(owner)
    }

    override fun onSaveInstanceState(bundle: Bundle) {
        streetViewPanoramaView?.onSaveInstanceState(bundle)
    }

    override fun onRestoreInstanceState(bundle: Bundle?) {
        streetViewPanoramaView?.onCreate(bundle)
    }

    private fun destroyStreetViewIfNecessary() {
        if (streetViewPanoramaView == null) {
            return
        }
        streetViewPanoramaView?.onDestroy()
        streetViewPanoramaView = null
    }
}

interface StreetViewListener : StreetViewPanorama.OnStreetViewPanoramaCameraChangeListener,
    StreetViewPanorama.OnStreetViewPanoramaChangeListener,
    StreetViewPanorama.OnStreetViewPanoramaClickListener,
    StreetViewPanorama.OnStreetViewPanoramaLongClickListener