package expo.modules.beacons

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import kotlin.math.pow

class BeaconScanner2(private val context: Context, private val listener: BeaconListener) {
    private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager

    private val bluetoothAdapter: BluetoothAdapter = bluetoothManager.adapter
    private val bluetoothLeScanner: BluetoothLeScanner? = bluetoothAdapter.bluetoothLeScanner

    interface BeaconListener {
        fun onIBeaconDetected(beaconData: Map<String, Any>)
        fun onEddystoneDetected(eddystoneData: Map<String, Any>)
    }

    fun startScan() {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED) {
            bluetoothLeScanner?.startScan(scanCallback)
        } else {
            // Handle missing permissions (request them if necessary)
        }
    }

    fun stopScan() {
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_SCAN
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            // TODO: Consider calling
            //    ActivityCompat#requestPermissions
            // here to request the missing permissions, and then overriding
            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
            //                                          int[] grantResults)
            // to handle the case where the user grants the permission. See the documentation
            // for ActivityCompat#requestPermissions for more details.
            return
        }
        bluetoothLeScanner?.stopScan(scanCallback)
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult?) {
            result?.let { scanResult ->
//                val device = scanResult.device
                val advertisementData = scanResult.scanRecord?.bytes
                if(scanResult.rssi > -45){
                    Log.d("ExpoBeacons", "found tag!")
                }
                advertisementData?.let {
                    // Detect iBeacon or Eddystone based on the advertisement data
                    if (isIBeacon(it)) {
                        val beaconData = mapOf(
                            "rssi" to scanResult.rssi,
                            "uuid" to getIBeaconUUID(it),
                            "accuracy" to calculateAccuracy(scanResult.rssi),
                            "major" to getIBeaconMajor(it),
                            "minor" to getIBeaconMinor(it),
                            "proximity" to calculateProximity(scanResult.rssi)
                        )
                        listener.onIBeaconDetected(beaconData)
                    } else if (isEddystone(it)) {
                        val eddystoneData = mapOf(
                            "rssi" to scanResult.rssi,
                            "uuid" to getEddystoneUUID(it),
                            "namespace" to getEddystoneNamespace(it),
                            "instance" to getEddystoneInstance(it)
                        )
                        listener.onEddystoneDetected(eddystoneData)
                    }
                }
            }
        }
    }

    private fun isIBeacon(advertisementData: ByteArray): Boolean {
        // Simple check for iBeacon pattern in advertisement data (e.g., 0x0215 prefix)
        return advertisementData.size > 4 && advertisementData[0] == 0x02.toByte() && advertisementData[1] == 0x15.toByte()
    }

    private fun isEddystone(advertisementData: ByteArray): Boolean {
        // Check for Eddystone UID pattern (0x00E0 prefix)
        return advertisementData.size > 4 && advertisementData[0] == 0x00.toByte() && advertisementData[1] == 0xE0.toByte()
    }

    private fun getIBeaconUUID(advertisementData: ByteArray): String {
        return advertisementData.slice(4..19).joinToString(separator = "") { String.format("%02X", it) }
    }

    private fun getIBeaconMajor(advertisementData: ByteArray): Int {
        return ((advertisementData[20].toInt() shl 8) or advertisementData[21].toInt())
    }

    private fun getIBeaconMinor(advertisementData: ByteArray): Int {
        return ((advertisementData[22].toInt() shl 8) or advertisementData[23].toInt())
    }

    private fun calculateAccuracy(rssi: Int): Double {
        // Simplified formula to calculate the accuracy based on RSSI
        return 10.0.pow((27.0 - rssi) / 20.0)
    }

    private fun calculateProximity(rssi: Int): Int {
        return when {
            rssi > -50 -> 1 // Immediate
            rssi > -70 -> 2 // Near
            else -> 3 // Far
        }
    }

    private fun getEddystoneUUID(advertisementData: ByteArray): String {
        return advertisementData.slice(4..19).joinToString(separator = "") { String.format("%02X", it) }
    }

    private fun getEddystoneNamespace(advertisementData: ByteArray): String {
        return advertisementData.slice(4..19).joinToString(separator = "") { String.format("%02X", it) }
    }

    private fun getEddystoneInstance(advertisementData: ByteArray): String {
        return advertisementData.slice(20..29).joinToString(separator = "") { String.format("%02X", it) }
    }
}
