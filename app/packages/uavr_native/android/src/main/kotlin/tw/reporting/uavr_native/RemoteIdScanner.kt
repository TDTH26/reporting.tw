package tw.reporting.uavr_native

import android.Manifest
import android.annotation.SuppressLint
import android.annotation.TargetApi
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanFilter
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.WifiManager
import android.net.wifi.aware.AttachCallback
import android.net.wifi.aware.DiscoverySessionCallback
import android.net.wifi.aware.PeerHandle
import android.net.wifi.aware.SubscribeConfig
import android.net.wifi.aware.SubscribeDiscoverySession
import android.net.wifi.aware.WifiAwareManager
import android.net.wifi.aware.WifiAwareSession
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.os.SystemClock
import android.util.Log
import io.flutter.plugin.common.EventChannel

/**
 * Receives OpenDroneID broadcasts on every transport the device supports and
 * emits `{transport, address, rssi, ts, payload}` maps while listened to.
 *
 * Transports whose runtime permissions are missing are skipped and reported
 * once as a `permission` error event; the others keep scanning.
 */
internal class RemoteIdScanner(context: Context) : EventChannel.StreamHandler {
    private val context = context.applicationContext
    private val main = Handler(Looper.getMainLooper())
    private val pm = context.packageManager
    private var sink: EventChannel.EventSink? = null

    /** Bumped on every listen/cancel so late async callbacks can tell they are stale. */
    private var generation = 0

    private var bleCallback: ScanCallback? = null
    private var wifiReceiver: BroadcastReceiver? = null
    private var wifiTick: Runnable? = null
    private val lastBeaconTs = HashMap<String, Long>()
    private var nanSession: WifiAwareSession? = null
    private var nanSubscribe: SubscribeDiscoverySession? = null

    private val bluetoothAdapter: BluetoothAdapter?
        get() = (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter

    fun capabilities(): Map<String, Boolean> {
        val adapter = bluetoothAdapter
        val legacy = adapter != null && pm.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)
        val longRange = legacy && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            runCatching { adapter!!.isLeCodedPhySupported && adapter.isLeExtendedAdvertisingSupported }
                .getOrDefault(false)
        val beacon = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            pm.hasSystemFeature(PackageManager.FEATURE_WIFI)
        return mapOf(
            "bluetoothLegacy" to legacy,
            "bluetoothLongRange" to longRange,
            "wifiBeacon" to beacon,
            "wifiNan" to nanAvailable(),
        )
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        stop()
        sink = events
        generation++
        val missing = linkedSetOf<String>()
        startBle(missing)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) startWifiBeacon(missing)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startNan(missing)
        if (missing.isNotEmpty()) {
            events.error("permission", "Missing permissions: ${missing.joinToString()}", missing.toList())
        }
    }

    override fun onCancel(arguments: Any?) {
        stop()
        sink = null
    }

    private fun stop() {
        generation++
        bleCallback?.let { cb ->
            runCatching { bluetoothAdapter?.bluetoothLeScanner?.stopScan(cb) }
                .onFailure { Log.w(TAG, "BLE stopScan failed", it) }
        }
        bleCallback = null
        wifiReceiver?.let { runCatching { context.unregisterReceiver(it) } }
        wifiReceiver = null
        wifiTick?.let { main.removeCallbacks(it) }
        wifiTick = null
        lastBeaconTs.clear()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            nanSubscribe?.close()
            nanSession?.close()
        }
        nanSubscribe = null
        nanSession = null
    }

    private fun emit(transport: String, address: String, rssi: Int?, ts: Long, payload: ByteArray) {
        val event = mapOf(
            "transport" to transport,
            "address" to address,
            "rssi" to rssi,
            "ts" to ts,
            "payload" to payload,
        )
        if (Looper.myLooper() == Looper.getMainLooper()) sink?.success(event)
        else main.post { sink?.success(event) }
    }

    private fun granted(permission: String) =
        context.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    /** Adds the missing ones of [permissions] to [missing]; true if all are granted. */
    private fun require(missing: MutableSet<String>, vararg permissions: String): Boolean {
        val lacking = permissions.filterNot(::granted)
        missing += lacking
        return lacking.isEmpty()
    }

    // --- Bluetooth (legacy + BT5 extended / Coded PHY) ---

    @SuppressLint("MissingPermission")
    private fun startBle(missing: MutableSet<String>) {
        val adapter = bluetoothAdapter ?: return
        if (!pm.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) return
        val ok = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            require(missing, Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.ACCESS_FINE_LOCATION)
        } else {
            require(missing, Manifest.permission.ACCESS_FINE_LOCATION)
        }
        if (!ok || !adapter.isEnabled) return
        val scanner = adapter.bluetoothLeScanner ?: return

        val uuid = ParcelUuid.fromString(Framing.BLE_SERVICE_UUID)
        val filters = listOf(ScanFilter.Builder().setServiceData(uuid, ByteArray(0)).build())
        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            adapter.isLeCodedPhySupported && adapter.isLeExtendedAdvertisingSupported
        ) {
            settings.setLegacy(false).setPhy(ScanSettings.PHY_LE_ALL_SUPPORTED)
        }

        val callback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) = handleBle(result, uuid)
            override fun onBatchScanResults(results: MutableList<ScanResult>) =
                results.forEach { handleBle(it, uuid) }
            override fun onScanFailed(errorCode: Int) {
                Log.w(TAG, "BLE scan failed: $errorCode")
            }
        }
        try {
            scanner.startScan(filters, settings.build(), callback)
            bleCallback = callback
        } catch (e: SecurityException) {
            missing += Manifest.permission.BLUETOOTH_SCAN
        }
    }

    private fun handleBle(result: ScanResult, uuid: ParcelUuid) {
        val payload = Framing.fromBleServiceData(result.scanRecord?.getServiceData(uuid)) ?: return
        val bt5 = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            (!result.isLegacy || result.primaryPhy == BluetoothDevice.PHY_LE_CODED)
        val ts = System.currentTimeMillis() -
            (SystemClock.elapsedRealtimeNanos() - result.timestampNanos) / 1_000_000
        emit(if (bt5) "bt5" else "bt4", result.device.address, result.rssi, ts, payload)
    }

    // --- Wi-Fi Beacon (vendor IEs in scan results, API 30+) ---

    @TargetApi(Build.VERSION_CODES.R)
    private fun startWifiBeacon(missing: MutableSet<String>) {
        if (!pm.hasSystemFeature(PackageManager.FEATURE_WIFI)) return
        val wifi = context.getSystemService(WifiManager::class.java) ?: return
        if (!require(missing, Manifest.permission.ACCESS_FINE_LOCATION)) return

        val receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) = readBeacons(wifi)
        }
        val filter = IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(receiver, filter)
        }
        wifiReceiver = receiver

        // Android throttles startScan (4 scans / 2 min in the foreground), so
        // ask every 30 s and also pick up scans triggered by anyone else.
        val tick = object : Runnable {
            override fun run() {
                @Suppress("DEPRECATION")
                runCatching { wifi.startScan() }
                readBeacons(wifi)
                main.postDelayed(this, WIFI_SCAN_INTERVAL_MS)
            }
        }
        wifiTick = tick
        main.post(tick)
    }

    @TargetApi(Build.VERSION_CODES.R)
    @SuppressLint("MissingPermission")
    private fun readBeacons(wifi: WifiManager) {
        val results = try {
            wifi.scanResults
        } catch (e: SecurityException) {
            sink?.error("permission", "Wi-Fi scan results not permitted", null)
            return
        }
        for (r in results) {
            val bssid = r.BSSID ?: continue
            // getScanResults() returns cached entries; only forward new sightings.
            if (lastBeaconTs[bssid] == r.timestamp) continue
            for (ie in r.informationElements) {
                if (ie.id != Framing.VENDOR_IE_ID) continue
                val buf = ie.bytes.duplicate()
                val body = ByteArray(buf.remaining()).also { buf.get(it) }
                val payload = Framing.fromVendorIe(body) ?: continue
                lastBeaconTs[bssid] = r.timestamp
                // ScanResult.timestamp is microseconds since boot.
                val ts = System.currentTimeMillis() - (SystemClock.elapsedRealtime() - r.timestamp / 1000)
                emit("wifi_beacon", bssid, r.level, ts, payload)
            }
        }
    }

    // --- Wi-Fi Aware / NAN (API 26+) ---

    private fun nanAvailable(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        if (!pm.hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE)) return false
        val aware = context.getSystemService(Context.WIFI_AWARE_SERVICE) as? WifiAwareManager
        return aware?.isAvailable == true
    }

    @TargetApi(Build.VERSION_CODES.O)
    @SuppressLint("MissingPermission")
    private fun startNan(missing: MutableSet<String>) {
        if (!pm.hasSystemFeature(PackageManager.FEATURE_WIFI_AWARE)) return
        val aware = context.getSystemService(Context.WIFI_AWARE_SERVICE) as? WifiAwareManager ?: return
        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            Manifest.permission.NEARBY_WIFI_DEVICES
        } else {
            Manifest.permission.ACCESS_FINE_LOCATION
        }
        if (!require(missing, permission) || !aware.isAvailable) return

        val gen = generation
        val discovery = object : DiscoverySessionCallback() {
            override fun onSubscribeStarted(session: SubscribeDiscoverySession) {
                if (gen != generation) session.close() else nanSubscribe = session
            }

            override fun onServiceDiscovered(
                peerHandle: PeerHandle,
                serviceSpecificInfo: ByteArray?,
                matchFilter: List<ByteArray>?,
            ) = handleNan(peerHandle, serviceSpecificInfo)

            override fun onMessageReceived(peerHandle: PeerHandle, message: ByteArray?) =
                handleNan(peerHandle, message)
        }
        val attach = object : AttachCallback() {
            override fun onAttached(session: WifiAwareSession) {
                if (gen != generation) {
                    session.close()
                    return
                }
                nanSession = session
                try {
                    val config = SubscribeConfig.Builder().setServiceName(Framing.NAN_SERVICE_NAME).build()
                    session.subscribe(config, discovery, main)
                } catch (e: SecurityException) {
                    sink?.error("permission", "Wi-Fi Aware subscribe not permitted", listOf(permission))
                }
            }

            override fun onAttachFailed() {
                Log.w(TAG, "Wi-Fi Aware attach failed")
            }
        }
        try {
            aware.attach(attach, main)
        } catch (e: SecurityException) {
            missing += permission
        }
    }

    private fun handleNan(peer: PeerHandle, info: ByteArray?) {
        val payload = Framing.fromNanServiceInfo(info) ?: return
        // PeerHandle.hashCode() is its peer id, stable for the discovery session.
        emit("wifi_nan", "nan:${peer.hashCode()}", null, System.currentTimeMillis(), payload)
    }

    private companion object {
        const val TAG = "UavrRemoteId"
        const val WIFI_SCAN_INTERVAL_MS = 30_000L
    }
}
