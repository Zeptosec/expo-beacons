package expo.modules.beacons

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.util.Log
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

class MyBluetoothManager(private val context: Context) {
  private val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager?
  val bluetoothAdapter: BluetoothAdapter? = bluetoothManager?.adapter

  private val _bluetoothState = MutableStateFlow(bluetoothAdapter?.state ?: BluetoothAdapter.ERROR)
  val bluetoothState: StateFlow<Int> = _bluetoothState

  val isBluetoothEnabled: Boolean
    get() = bluetoothAdapter?.isEnabled == true && _bluetoothState.value == BluetoothAdapter.STATE_ON

  private val bluetoothStateReceiver = object : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
      if (intent.action == BluetoothAdapter.ACTION_STATE_CHANGED) {
        val state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR)
        _bluetoothState.value = state
      }
    }
  }

  fun start() {
    val bluetoothChangeFilter = IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED)
    context.registerReceiver(bluetoothStateReceiver, bluetoothChangeFilter)
    _bluetoothState.value = bluetoothAdapter?.state ?: BluetoothAdapter.ERROR
  }

  fun stop() {
    try {
      context.unregisterReceiver(bluetoothStateReceiver)
    } catch (e: Exception) {
      Log.e("MyBluetoothManager", e.toString())
    }
  }

  fun mapBluetoothState(state: Int): String {
    return when (state) {
      BluetoothAdapter.STATE_ON -> "on"
      BluetoothAdapter.STATE_OFF -> "off"
      BluetoothAdapter.STATE_TURNING_ON -> "off"
      BluetoothAdapter.STATE_TURNING_OFF -> "off"
      else -> "unknown"
    }
  }
}