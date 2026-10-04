package tw.reporting.uavr_native

import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertNull

internal class FramingTest {
    private val message = ByteArray(25) { (0x10 + it).toByte() }

    @Test
    fun bleStripsAppCodeAndCounter() {
        assertContentEquals(message, Framing.fromBleServiceData(byteArrayOf(0x0D, 7) + message))
        assertNull(Framing.fromBleServiceData(byteArrayOf(0x0C, 7) + message))
        assertNull(Framing.fromBleServiceData(byteArrayOf(0x0D, 7) + message.copyOf(10)))
        assertNull(Framing.fromBleServiceData(null))
    }

    @Test
    fun vendorIeRequiresOdidOuiAndType() {
        val header = byteArrayOf(0xFA.toByte(), 0x0B, 0xBC.toByte(), 0x0D, 3)
        assertContentEquals(message, Framing.fromVendorIe(header + message))
        assertNull(Framing.fromVendorIe(byteArrayOf(0x00, 0x50, 0xF2.toByte(), 0x0D, 3) + message))
        assertNull(Framing.fromVendorIe(byteArrayOf(0xFA.toByte(), 0x0B, 0xBC.toByte(), 0x0E, 3) + message))
    }

    @Test
    fun nanStripsCounter() {
        assertContentEquals(message, Framing.fromNanServiceInfo(byteArrayOf(1) + message))
        assertNull(Framing.fromNanServiceInfo(message.copyOf(20)))
    }
}
