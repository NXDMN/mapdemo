package com.example.mapdemo

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.display.DisplayManager
import android.os.SystemClock
import android.view.Display
import android.view.Surface
import io.flutter.Log
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs


class FlutterCompass(private val context: Context) : EventChannel.StreamHandler {
    // The rate sensor events will be delivered at. As the Android documentation
    // states, this is only a hint to the system and the events might actually be
    // received faster or slower than this specified rate. Since the minimum
    // Android API levels about 9, we are able to set this value ourselves rather
    // than using one of the provided constants which deliver updates too quickly
    // for our use case. The default is set to 100ms
    val SENSOR_DELAY_MICROS: Int = 30 * 1000

    // Filtering coefficient 0 < ALPHA < 1
    val ALPHA: Float = 0.45f

    // Controls the compass update rate in milliseconds
    val COMPASS_UPDATE_RATE_MS: Int = 32

    private lateinit var sensorEventListener: SensorEventListener
    private var display: Display? = null
    private var sensorManager: SensorManager? = null
    private var compassSensor: Sensor? = null
    private var gravitySensor: Sensor? = null
    private var magneticFieldSensor: Sensor? = null

    private val truncatedRotationVectorValue = FloatArray(4)
    private val rotationMatrix = FloatArray(9)
    private var rotationVectorValue: FloatArray? = null
    private var lastHeading: Float = 0f
    private var lastAccuracySensorStatus: Int = 0

    private var compassUpdateNextTimestamp: Long = 0
    private var gravityValues = FloatArray(3)
    private var magneticValues = FloatArray(3)

    private fun getSensors(context: Context){
        display = (context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager)
            .getDisplay(Display.DEFAULT_DISPLAY)
        sensorManager = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
        compassSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        if (compassSensor == null) {
            Log.d(
                "FlutterCompass", "Rotation vector sensor not supported on device, "
                        + "falling back to accelerometer and magnetic field."
            )
        }

        gravitySensor = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        magneticFieldSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
    }

    private fun cleanSensors() {
        display = null
        sensorManager = null
        compassSensor = null
        gravitySensor = null
        magneticFieldSensor = null
    }

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        getSensors(context);

        eventSink = events
        sensorEventListener = createSensorEventListener()
        registerListener()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        unregisterListener()

        cleanSensors()
    }

    private fun isCompassSensorAvailable(): Boolean = compassSensor != null

    private fun registerListener() {
        if (sensorManager == null) return
        if (isCompassSensorAvailable()) {
            // Does nothing if the sensors already registered.
            sensorManager!!.registerListener(
                sensorEventListener,
                compassSensor,
                SENSOR_DELAY_MICROS
            )
        }

        sensorManager!!.registerListener(sensorEventListener, gravitySensor, SENSOR_DELAY_MICROS)
        sensorManager!!.registerListener(
            sensorEventListener,
            magneticFieldSensor,
            SENSOR_DELAY_MICROS
        )
    }

    private fun unregisterListener() {
        if (sensorManager == null) return
        if (isCompassSensorAvailable()) {
            sensorManager!!.unregisterListener(sensorEventListener, compassSensor)
        }

        sensorManager!!.unregisterListener(sensorEventListener, gravitySensor)
        sensorManager!!.unregisterListener(sensorEventListener, magneticFieldSensor)
    }

    private fun createSensorEventListener(): SensorEventListener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                if (lastAccuracySensorStatus == SensorManager.SENSOR_STATUS_UNRELIABLE) {
                    Log.d("FlutterCompass", "Compass sensor is unreliable, device calibration is needed.")
                    // Update the heading, even if the sensor is unreliable.
                    // This makes it possible to use a different indicator for the unreliable case,
                    // instead of just changing the RenderMode to NORMAL.
                }
                if (event.sensor.type == Sensor.TYPE_ROTATION_VECTOR) {
                    rotationVectorValue = getRotationVectorFromSensorEvent(event)
                    updateOrientation()
                } else if (event.sensor.type == Sensor.TYPE_ACCELEROMETER && !isCompassSensorAvailable()) {
                    gravityValues =
                        lowPassFilter(getRotationVectorFromSensorEvent(event), gravityValues)
                    updateOrientation()
                } else if (event.sensor.type == Sensor.TYPE_MAGNETIC_FIELD && !isCompassSensorAvailable()) {
                    magneticValues =
                        lowPassFilter(getRotationVectorFromSensorEvent(event), magneticValues)
                    updateOrientation()
                }
            }

            override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
                if (lastAccuracySensorStatus != accuracy) {
                    lastAccuracySensorStatus = accuracy
                }
            }

            private fun updateOrientation() {
                // check when the last time the compass was updated, return if too soon.
                val currentTime = SystemClock.elapsedRealtime()
                if (currentTime < compassUpdateNextTimestamp) {
                    return
                }

                if (rotationVectorValue != null) {
                    SensorManager.getRotationMatrixFromVector(rotationMatrix, rotationVectorValue)
                } else {
                    // Get rotation matrix given the gravity and geomagnetic matrices
                    SensorManager.getRotationMatrix(
                        rotationMatrix,
                        null,
                        gravityValues,
                        magneticValues
                    )
                }

                var worldAxisForDeviceAxisX: Int
                var worldAxisForDeviceAxisY: Int

                when (display!!.rotation) {
                    Surface.ROTATION_90 -> {
                        worldAxisForDeviceAxisX = SensorManager.AXIS_Y
                        worldAxisForDeviceAxisY = SensorManager.AXIS_MINUS_X
                    }

                    Surface.ROTATION_180 -> {
                        worldAxisForDeviceAxisX = SensorManager.AXIS_MINUS_X
                        worldAxisForDeviceAxisY = SensorManager.AXIS_MINUS_Y
                    }

                    Surface.ROTATION_270 -> {
                        worldAxisForDeviceAxisX = SensorManager.AXIS_MINUS_Y
                        worldAxisForDeviceAxisY = SensorManager.AXIS_X
                    }

                    Surface.ROTATION_0 -> {
                        worldAxisForDeviceAxisX = SensorManager.AXIS_X
                        worldAxisForDeviceAxisY = SensorManager.AXIS_Y
                    }

                    else -> {
                        worldAxisForDeviceAxisX = SensorManager.AXIS_X
                        worldAxisForDeviceAxisY = SensorManager.AXIS_Y
                    }
                }
                val adjustedRotationMatrix = FloatArray(9)
                SensorManager.remapCoordinateSystem(
                    rotationMatrix, worldAxisForDeviceAxisX, worldAxisForDeviceAxisY,
                    adjustedRotationMatrix
                )

                // Transform rotation matrix into azimuth/pitch/roll
                val orientation = FloatArray(3)
                SensorManager.getOrientation(adjustedRotationMatrix, orientation)

                if (orientation[1] < -Math.PI / 4) {
                    // The pitch is less than -45 degrees.
                    // Remap the axes as if the device screen was the instrument panel.
                    when (display!!.rotation) {
                        Surface.ROTATION_90 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_Z
                            worldAxisForDeviceAxisY = SensorManager.AXIS_MINUS_X
                        }

                        Surface.ROTATION_180 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_MINUS_X
                            worldAxisForDeviceAxisY = SensorManager.AXIS_MINUS_Z
                        }

                        Surface.ROTATION_270 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_MINUS_Z
                            worldAxisForDeviceAxisY = SensorManager.AXIS_X
                        }

                        Surface.ROTATION_0 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_X
                            worldAxisForDeviceAxisY = SensorManager.AXIS_Z
                        }

                        else -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_X
                            worldAxisForDeviceAxisY = SensorManager.AXIS_Z
                        }
                    }
                } else if (orientation[1] > Math.PI / 4) {
                    // The pitch is larger than 45 degrees.
                    // Remap the axes as if the device screen was upside down and facing back.
                    when (display!!.rotation) {
                        Surface.ROTATION_90 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_MINUS_Z
                            worldAxisForDeviceAxisY = SensorManager.AXIS_MINUS_X
                        }

                        Surface.ROTATION_180 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_MINUS_X
                            worldAxisForDeviceAxisY = SensorManager.AXIS_Z
                        }

                        Surface.ROTATION_270 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_Z
                            worldAxisForDeviceAxisY = SensorManager.AXIS_X
                        }

                        Surface.ROTATION_0 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_X
                            worldAxisForDeviceAxisY = SensorManager.AXIS_MINUS_Z
                        }

                        else -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_X
                            worldAxisForDeviceAxisY = SensorManager.AXIS_MINUS_Z
                        }
                    }
                } else if (abs(orientation[2].toDouble()) > Math.PI / 2) {
                    // The roll is less than -90 degrees, or is larger than 90 degrees.
                    // Remap the axes as if the device screen was face down.
                    when (display!!.rotation) {
                        Surface.ROTATION_90 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_MINUS_Y
                            worldAxisForDeviceAxisY = SensorManager.AXIS_MINUS_X
                        }

                        Surface.ROTATION_180 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_MINUS_X
                            worldAxisForDeviceAxisY = SensorManager.AXIS_Y
                        }

                        Surface.ROTATION_270 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_Y
                            worldAxisForDeviceAxisY = SensorManager.AXIS_X
                        }

                        Surface.ROTATION_0 -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_X
                            worldAxisForDeviceAxisY = SensorManager.AXIS_MINUS_Y
                        }

                        else -> {
                            worldAxisForDeviceAxisX = SensorManager.AXIS_X
                            worldAxisForDeviceAxisY = SensorManager.AXIS_MINUS_Y
                        }
                    }
                }

                SensorManager.remapCoordinateSystem(
                    rotationMatrix, worldAxisForDeviceAxisX, worldAxisForDeviceAxisY,
                    adjustedRotationMatrix
                )

                // Transform rotation matrix into azimuth/pitch/roll
                SensorManager.getOrientation(adjustedRotationMatrix, orientation)

                val v = DoubleArray(3)
                v[0] = Math.toDegrees(orientation[0].toDouble())
                v[2] = accuracy
                // The x-axis is all we care about here.
                notifyCompassChangeListeners(v)

                // Update the compassUpdateNextTimestamp
                compassUpdateNextTimestamp = currentTime + COMPASS_UPDATE_RATE_MS
            }

            private fun notifyCompassChangeListeners(heading: DoubleArray) {
                eventSink?.success(heading)
                lastHeading = heading[0].toFloat()
            }

            private val accuracy: Double
                get() = if (lastAccuracySensorStatus == SensorManager.SENSOR_STATUS_ACCURACY_HIGH) {
                    15.0
                } else if (lastAccuracySensorStatus == SensorManager.SENSOR_STATUS_ACCURACY_MEDIUM) {
                    30.0
                } else if (lastAccuracySensorStatus == SensorManager.SENSOR_STATUS_ACCURACY_LOW) {
                    45.0
                } else {
                    -1.0 // unknown
                }

            /**
             * Helper function, that filters newValues, considering previous values
             *
             * @param newValues      array of float, that contains new data
             * @param smoothedValues array of float, that contains previous state
             * @return float filtered array of float
             */
            private fun lowPassFilter(
                newValues: FloatArray,
                smoothedValues: FloatArray?
            ): FloatArray {
                if (smoothedValues == null) {
                    return newValues
                }
                for (i in newValues.indices) {
                    smoothedValues[i] =
                        smoothedValues[i] + ALPHA * (newValues[i] - smoothedValues[i])
                }
                return smoothedValues
            }

            /**
             * Pulls out the rotation vector from a SensorEvent, with a maximum length
             * vector of four elements to avoid potential compatibility issues.
             *
             * @param event the sensor event
             * @return the events rotation vector, potentially truncated
             */
            private fun getRotationVectorFromSensorEvent(event: SensorEvent): FloatArray {
                if (event.values.size > 4) {
                    // On some Samsung devices SensorManager.getRotationMatrixFromVector
                    // appears to throw an exception if rotation vector has length > 4.
                    // For the purposes of this class the first 4 values of the
                    // rotation vector are sufficient (see crbug.com/335298 for details).
                    // Only affects Android 4.3
                    System.arraycopy(event.values, 0, truncatedRotationVectorValue, 0, 4)
                    return truncatedRotationVectorValue
                } else {
                    return event.values
                }
            }
        }
}