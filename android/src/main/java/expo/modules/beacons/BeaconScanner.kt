package expo.modules.beacons

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.util.Log
import androidx.annotation.RequiresPermission
import expo.modules.beacons.modules.Beacon
import expo.modules.beacons.modules.BeaconParser
import expo.modules.beacons.modules.IBeacon

class BeaconScannerException(message: String, val code: String) : Exception(message)

class BeaconScanner(
    adapter: BluetoothAdapter?,
    val permissionManager: PermissionManager,
    private val onScanStateChanged: (Boolean) -> Unit
) {
    var isScanning = false
        private set(value) {
            field = value
            onScanStateChanged(value)
        }

    private var scanCallback: ScanCallback? = null
    private val scanner = adapter?.bluetoothLeScanner
    private var regionUuids: List<String>? = null

    fun setRegions(uuids: List<String>) {
        // Filter for unique, valid UUID strings and ignore case
        regionUuids = uuids
            .distinctBy { it.lowercase() }
            .filter { isValidUuid(it) }
            .ifEmpty { null }
    }

    private fun isValidUuid(uuid: String): Boolean {
        return try {
            java.util.UUID.fromString(uuid)
            true
        } catch (e: IllegalArgumentException) {
            Log.e(MODULE_LOG_ID, "Invalid UUID: ${e.toString()}")
            false
        }
    }

    @RequiresPermission(Manifest.permission.BLUETOOTH_SCAN)
    fun startScanning(onResult: (Beacon) -> Unit) {
        if (scanner == null) {
            throw BeaconScannerException("Bluetooth LE Scanner is not available", "SCANNER_NOT_AVAILABLE")
        }
        if (isScanning) {
            throw BeaconScannerException("Scanning is already in progress", "ALREADY_SCANNING")
        }

        val permissions = permissionManager.permissionsState.value
        val isGranted = permissions["granted"] as? Boolean ?: false

        if (!isGranted) {
            throw BeaconScannerException("Permissions are not granted for beacon scanning", "MISSING_PERMISSIONS")
        }

        scanCallback = object : ScanCallback() {
            @RequiresPermission(Manifest.permission.BLUETOOTH_CONNECT)
            override fun onScanResult(callbackType: Int, result: ScanResult) {

                val beacon = BeaconParser.parseFromScanResult(result)
                if (beacon != null) {
                    val currentRegions = regionUuids
                    if (currentRegions == null || matchesRegion(beacon, currentRegions)) {
                        onResult(beacon)
                    }
                }
            }

            private fun matchesRegion(beacon: Beacon, uuids: List<String>): Boolean {
                if (beacon is IBeacon) {
                    return uuids.any { it.equals(beacon.uuid, ignoreCase = true) }
                }
                // For other beacon types (Eddystone), you might filter by different fields
                return true
            }

            override fun onScanFailed(errorCode: Int) {
                val errorMsg = when(errorCode) {
                    SCAN_FAILED_ALREADY_STARTED -> "Scan already started"
                    SCAN_FAILED_APPLICATION_REGISTRATION_FAILED -> "App registration failed"
                    SCAN_FAILED_INTERNAL_ERROR -> "Internal error"
                    SCAN_FAILED_FEATURE_UNSUPPORTED -> "Power optimization / Hardware unsupported"
                    SCAN_FAILED_OUT_OF_HARDWARE_RESOURCES -> "Out of hardware resources"
                    else -> "Unknown error: $errorCode"
                }
                isScanning = false
                scanCallback = null
                
                Log.e(MODULE_LOG_ID, "SCAN FAILED: $errorMsg")
            }
        }

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        scanner.startScan(null, settings, scanCallback)

        isScanning = true
    }

    @SuppressLint("MissingPermission") // We suppress because we handle permissions in the Module
    fun stopScanning() {
        if(!isScanning) {
            return
        }
        try {
            scanCallback?.let {
                scanner?.stopScan(it)
                scanCallback = null
            }
            isScanning = false
        } catch (e: SecurityException) {
            Log.e(MODULE_LOG_ID, "Permission lost while trying to stop scan: ${e.message}")
        } catch (e: Exception) {
            Log.e(MODULE_LOG_ID, "Error stopping scan: ${e.message}")
        }
    }
}
