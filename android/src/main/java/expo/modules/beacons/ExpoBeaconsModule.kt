package expo.modules.beacons

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.content.ContextCompat
import expo.modules.kotlin.Promise
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

const val MODULE_LOG_ID = "ExpoBeaconsModule"

class ExpoBeaconsModule : Module() {
  // Each module class must implement the definition function. The definition consists of components
  // that describes the module's functionality and behavior.
  // See https://docs.expo.dev/modules/module-api for more details about available components.

  private val requestEnableBt = 1001
  private lateinit var beaconManager: BeaconScanner
  private lateinit var myBluetoothManager: MyBluetoothManager
  private lateinit var permissionManager: PermissionManager
  private val scope = CoroutineScope(Dispatchers.Main)

  override fun definition() = ModuleDefinition {
    // Sets the name of the module that JavaScript code will use to refer to the module. Takes a string as an argument.
    // Can be inferred from module's class name, but it's recommended to set it explicitly for clarity.
    // The module will be accessible from `requireNativeModule('ExpoBeacons')` in JavaScript.
    Name("ExpoBeacons")

    OnCreate {
      val context = appContext.reactContext

      if (context == null) {
        Log.e(MODULE_LOG_ID, "Missing react context in OnCreate")
        return@OnCreate
      }

      permissionManager = PermissionManager(appContext) { permissions ->
        sendEvent("onPermissionsChange", permissions)
      }
      permissionManager.syncUpdatePermissions()

      myBluetoothManager = MyBluetoothManager(context)
      myBluetoothManager.start()

      val adapter = myBluetoothManager.bluetoothAdapter
      if (adapter != null) {
        beaconManager = BeaconScanner(adapter, permissionManager) { isScanning ->
          sendEvent("onScanStateChange", mapOf("isScanning" to isScanning))
        }
      } else {
        Log.e(MODULE_LOG_ID, "Missing bluetoothAdapter in OnCreate")
      }

      scope.launch {
        myBluetoothManager.bluetoothState.collectLatest { state ->
          if (state == BluetoothAdapter.STATE_OFF || state == BluetoothAdapter.STATE_TURNING_OFF) {
            beaconManager.stopScanning()
          }
          sendEvent("onBluetoothStateChange", mapOf(
            "state" to myBluetoothManager.mapBluetoothState(state)
          ))
        }
      }
    }

    OnDestroy {
      myBluetoothManager.stop()
      scope.cancel()
    }

    OnActivityEntersForeground {
      permissionManager.syncUpdatePermissions()
    }

    AsyncFunction("requestPermissionsAsync") { promise: Promise ->
      permissionManager.requestPermissions(promise)
    }

    Property("bluetoothState") {
      return@Property myBluetoothManager.mapBluetoothState(myBluetoothManager.bluetoothState.value)
    }

    Property("permissions") {
      return@Property permissionManager.permissionsState.value
    }

    Property("isScanning") {
      return@Property beaconManager.isScanning
    }

    @SuppressLint("MissingPermission")
    Function("startScan") {
      if (!myBluetoothManager.isBluetoothEnabled) {
        throw Exception("Bluetooth is not enabled")
      }
      beaconManager.startScanning { beacon ->
        sendEvent("onBeaconDetected", beacon.toMap())
      }
    }
    
    Function("stopScan") {
      beaconManager.stopScanning()
    }

    // Roughly match the logic in iOS
    Function("setRegions") { uuids: List<String> ->
      beaconManager.setRegions(uuids)
    }

    AsyncFunction("requestBluetoothEnable") {
      val context = appContext.reactContext ?: throw Exception("Context is not defined")

      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val permissionCheck = ContextCompat.checkSelfPermission(
          context,
          Manifest.permission.BLUETOOTH_CONNECT
        )

        if (permissionCheck != PackageManager.PERMISSION_GRANTED) {
          throw Exception("Missing BLUETOOTH_CONNECT permission. Request permission first.")
        }
      }

      val intent = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
      val activity = appContext.currentActivity ?: throw Exception("Foreground activity not found")
      activity.startActivityForResult(intent, requestEnableBt)
    }

    // Defines event names that the module can send to JavaScript.
    Events("onBluetoothStateChange", "onBeaconDetected", "onScanStateChange", "onPermissionsChange")
  }
}
