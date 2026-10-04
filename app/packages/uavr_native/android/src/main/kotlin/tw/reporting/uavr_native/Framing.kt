package tw.reporting.uavr_native

/**
 * Strips the OpenDroneID transport framing so only ASTM F3411 bytes (one
 * 25-byte message or a 0xF message pack) reach Dart.
 */
internal object Framing {
    const val MESSAGE_SIZE = 25

    /** BLE service data UUID 0xFFFA (ASTM International). */
    const val BLE_SERVICE_UUID = "0000fffa-0000-1000-8000-00805f9b34fb"

    /** BLE service data: [0x0D app code][message counter][message or pack]. */
    private const val BLE_APP_CODE: Byte = 0x0D

    /** Wi-Fi vendor-specific IE (id 221): [OUI FA:0B:BC][type 0x0D][counter][pack]. */
    const val VENDOR_IE_ID = 221
    private val ODID_OUI = byteArrayOf(0xFA.toByte(), 0x0B, 0xBC.toByte())
    private const val ODID_VENDOR_TYPE: Byte = 0x0D

    /** Wi-Fi Aware service name; service-specific info is [counter][pack]. */
    const val NAN_SERVICE_NAME = "org.opendroneid.remoteid"

    fun fromBleServiceData(data: ByteArray?): ByteArray? {
        if (data == null || data.size < 2 + MESSAGE_SIZE || data[0] != BLE_APP_CODE) return null
        return data.copyOfRange(2, data.size)
    }

    /** [ie] is the IE body without the id/length header. */
    fun fromVendorIe(ie: ByteArray): ByteArray? {
        if (ie.size < 5 + MESSAGE_SIZE) return null
        for (i in ODID_OUI.indices) if (ie[i] != ODID_OUI[i]) return null
        if (ie[3] != ODID_VENDOR_TYPE) return null
        return ie.copyOfRange(5, ie.size)
    }

    fun fromNanServiceInfo(info: ByteArray?): ByteArray? {
        if (info == null || info.size < 1 + MESSAGE_SIZE) return null
        return info.copyOfRange(1, info.size)
    }
}
