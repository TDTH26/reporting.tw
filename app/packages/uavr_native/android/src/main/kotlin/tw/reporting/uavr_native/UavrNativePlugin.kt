package tw.reporting.uavr_native

import android.hardware.GeomagneticField
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Channels:
 * - MethodChannel `uavr_native`: remoteIdCapabilities, setLocation, integrityToken
 * - EventChannel `uavr_native/remote_id`: Remote ID frames (see [RemoteIdScanner])
 * - EventChannel `uavr_native/orientation`: back-camera orientation (see [OrientationStream])
 */
class UavrNativePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var methods: MethodChannel
    private lateinit var remoteIdEvents: EventChannel
    private lateinit var orientationEvents: EventChannel
    private lateinit var scanner: RemoteIdScanner
    private lateinit var orientation: OrientationStream
    private lateinit var integrity: PlayIntegrity

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val context = binding.applicationContext
        scanner = RemoteIdScanner(context)
        orientation = OrientationStream(context)
        integrity = PlayIntegrity(context)

        methods = MethodChannel(binding.binaryMessenger, "uavr_native").also { it.setMethodCallHandler(this) }
        remoteIdEvents = EventChannel(binding.binaryMessenger, "uavr_native/remote_id").also {
            it.setStreamHandler(scanner)
        }
        orientationEvents = EventChannel(binding.binaryMessenger, "uavr_native/orientation").also {
            it.setStreamHandler(orientation)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "remoteIdCapabilities" -> result.success(scanner.capabilities())
            "setLocation" -> {
                val lat = call.argument<Number>("lat")?.toFloat()
                val lon = call.argument<Number>("lon")?.toFloat()
                val alt = call.argument<Number>("alt")?.toFloat() ?: 0f
                if (lat == null || lon == null) {
                    result.error("args", "lat and lon are required", null)
                    return
                }
                orientation.declinationDeg =
                    GeomagneticField(lat, lon, alt, System.currentTimeMillis()).declination
                result.success(null)
            }
            "integrityToken" -> {
                val hash = call.argument<String>("requestHash")
                val project = call.argument<Number>("cloudProjectNumber")?.toLong()
                if (hash == null || project == null) {
                    result.success(null)
                    return
                }
                integrity.token(hash, project) { result.success(it) }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methods.setMethodCallHandler(null)
        remoteIdEvents.setStreamHandler(null)
        orientationEvents.setStreamHandler(null)
        scanner.onCancel(null)
        orientation.onCancel(null)
    }
}
