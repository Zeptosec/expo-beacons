package expo.modules.beacons

import android.Manifest
import android.os.Build
import android.util.Log
import expo.modules.kotlin.Promise
import expo.modules.kotlin.AppContext
import expo.modules.interfaces.permissions.Permissions
import expo.modules.interfaces.permissions.PermissionsResponse
import expo.modules.interfaces.permissions.PermissionsStatus
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class PermissionManager(private val appContext: AppContext, private val onPermissionChange: (Map<String, Any>) -> Unit) {

    private val _permissionsState = MutableStateFlow<Map<String, Any>>(emptyMap())
    val permissionsState: StateFlow<Map<String, Any>> = _permissionsState.asStateFlow()

    private fun getPermissionsService(): Permissions {
        return appContext.permissions ?: throw Exception("Permissions service is unavailable")
    }

    private fun getRequiredPermissions(): Array<String> {
        val permissions = mutableListOf<String>()
        
        // Location is required for beacon scanning on all Android versions
        permissions.add(Manifest.permission.ACCESS_FINE_LOCATION)
        permissions.add(Manifest.permission.ACCESS_COARSE_LOCATION)

        // Android 12+ (API 31+) requires BLUETOOTH_SCAN
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.add(Manifest.permission.BLUETOOTH_SCAN)
            permissions.add(Manifest.permission.BLUETOOTH_CONNECT)
        }

        return permissions.toTypedArray()
    }

    fun syncUpdatePermissions() {
        try {
            val permissionsService = getPermissionsService()
            val required = getRequiredPermissions()
            
            permissionsService.getPermissions(
                { permissionsMap ->
                    val response = formatPermissionsResponse(permissionsMap)
                    val oldState = _permissionsState.value
                    if (oldState != response) {
                        _permissionsState.value = response
                        onPermissionChange(response)
                    }
                },
                *required
            )
        } catch (e: Exception) {
            // Silently fail for sync update/initialization or log it
            Log.e(MODULE_LOG_ID, e.toString())
        }
    }

    fun requestPermissions(promise: Promise) {
        try {
            val permissionsService = getPermissionsService()
            val required = getRequiredPermissions()

            permissionsService.askForPermissions(
                { permissionsMap ->
                    val response = formatPermissionsResponse(permissionsMap)
                    _permissionsState.value = response
                    onPermissionChange(response)
                    promise.resolve(response)
                },
                *required
            )
        } catch (e: Exception) {
            promise.reject("ERR_PERMISSIONS_REQUEST", e.message, e)
        }
    }

    private fun formatPermissionsResponse(permissionsMap: Map<String, PermissionsResponse>): Map<String, Any> {
        val fineLocationPermission = permissionsMap[Manifest.permission.ACCESS_FINE_LOCATION]
        val isLocationGranted = fineLocationPermission?.status == PermissionsStatus.GRANTED
        val canAskAgainLocation = fineLocationPermission?.canAskAgain ?: true

        val isBluetoothGranted: Boolean
        val canAskAgainBluetooth: Boolean

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val scanPermission = permissionsMap[Manifest.permission.BLUETOOTH_SCAN]
            isBluetoothGranted = scanPermission?.status == PermissionsStatus.GRANTED
            canAskAgainBluetooth = scanPermission?.canAskAgain ?: true
        } else {
            // On older Android, if location is granted, BT scanning is generally allowed
            isBluetoothGranted = true
            canAskAgainBluetooth = true
        }

        val locationStatus = if(isLocationGranted) "granted" else "denied"
        val bluetoothStatus = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if(isBluetoothGranted) "granted" else "denied"
        } else {
            "granted"
        }

        return mapOf(
            "granted" to (isLocationGranted && isBluetoothGranted),
            "permissions" to mapOf(
                "location" to mapOf(
                    "granted" to isLocationGranted,
                    "status" to locationStatus,
                    "canAskAgain" to canAskAgainLocation
                ),
                "bluetooth" to mapOf(
                    "granted" to isBluetoothGranted,
                    "status" to bluetoothStatus,
                    "canAskAgain" to canAskAgainBluetooth
                )
            )
        )
    }
}