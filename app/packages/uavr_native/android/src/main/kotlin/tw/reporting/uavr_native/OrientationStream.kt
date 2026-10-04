package tw.reporting.uavr_native

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel
import kotlin.math.asin
import kotlin.math.atan2
import kotlin.math.sqrt

/**
 * Back-camera pointing direction from TYPE_ROTATION_VECTOR.
 *
 * getRotationMatrixFromVector gives R (row-major) mapping device coordinates
 * to world coordinates (x = East, y = North, z = Up). The back camera looks
 * along device −z, so its world direction is w = R·(0,0,−1) = (−R[2], −R[5], −R[8]).
 * Azimuth = atan2(w.x, w.y) (clockwise from magnetic north), elevation = asin(w.z).
 * This is independent of screen rotation.
 */
internal class OrientationStream(context: Context) : EventChannel.StreamHandler, SensorEventListener {
    private val sensors = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private var sink: EventChannel.EventSink? = null
    private var intervalNs = 100_000_000L
    private var lastEmitNs = 0L
    private var accuracy = SensorManager.SENSOR_STATUS_UNRELIABLE
    private val r = FloatArray(9)
    private var smoothed: DoubleArray? = null

    /** Set from the last known location via setLocation; 0 when unknown. */
    @Volatile
    var declinationDeg = 0f

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        val sensor = sensors.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        if (sensor == null) {
            events.error("unavailable", "No rotation vector sensor", null)
            return
        }
        val ms = ((arguments as? Map<*, *>)?.get("intervalMs") as? Number)?.toLong() ?: 100L
        intervalNs = ms.coerceAtLeast(0) * 1_000_000
        lastEmitNs = 0
        smoothed = null
        sink = events
        sensors.registerListener(this, sensor, SensorManager.SENSOR_DELAY_GAME)
    }

    override fun onCancel(arguments: Any?) {
        sensors.unregisterListener(this)
        sink = null
    }

    override fun onAccuracyChanged(sensor: Sensor, accuracy: Int) {
        this.accuracy = accuracy
    }

    override fun onSensorChanged(event: SensorEvent) {
        val out = sink ?: return
        // Some older devices throw on rotation vectors longer than 4 values.
        val v = if (event.values.size > 4) event.values.copyOf(4) else event.values
        SensorManager.getRotationMatrixFromVector(r, v)
        accuracy = event.accuracy

        // Low-pass the unit vector (not the angles) so 359° → 0° cannot jump.
        val w = doubleArrayOf(-r[2].toDouble(), -r[5].toDouble(), -r[8].toDouble())
        val s = smoothed?.also { for (i in 0..2) it[i] += SMOOTHING * (w[i] - it[i]) } ?: w.also { smoothed = it }

        if (lastEmitNs != 0L && event.timestamp - lastEmitNs < intervalNs) return
        lastEmitNs = event.timestamp

        val n = sqrt(s[0] * s[0] + s[1] * s[1] + s[2] * s[2])
        if (n == 0.0) return
        val magnetic = normalize(Math.toDegrees(atan2(s[0], s[1])))
        val elevation = Math.toDegrees(asin((s[2] / n).coerceIn(-1.0, 1.0)))
        val declination = declinationDeg.toDouble()
        out.success(
            mapOf(
                "azimuth" to normalize(magnetic + declination),
                "magneticAzimuth" to magnetic,
                "elevation" to elevation,
                "declination" to declination,
                "accuracy" to accuracy,
                "ts" to System.currentTimeMillis(),
            ),
        )
    }

    private fun normalize(deg: Double) = ((deg % 360) + 360) % 360

    private companion object {
        /** Per-sample weight at SENSOR_DELAY_GAME (~50 Hz): ~0.1 s time constant. */
        const val SMOOTHING = 0.2
    }
}
