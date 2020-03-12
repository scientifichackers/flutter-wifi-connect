package com.example.wifi_connect

import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.provider.Settings
import com.pycampers.plugin_scaffold.createPluginScaffold
import com.pycampers.plugin_scaffold.trySend
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.Random
import java.util.Timer
import kotlin.concurrent.timer

const val TAG = "WifiConnectPlugin"
const val POLL_INTERVAL_MS = 500.toLong()

enum class WifiConnectStatus {
    OK,
    FAILED,
    NOT_FOUND,
    WIFI_DISABLED,
}

class WifiConnectPlugin(registrar: Registrar) : ActivityResultListener {
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            createPluginScaffold(
                registrar.messenger(),
                "wifi_connect",
                WifiConnectPlugin(registrar)
            )
        }
    }

    val ctx = registrar.context()
    val activity = registrar.activity()
    val wifi = ctx.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    val conn = ConnectionManager(ctx, wifi)

    val enableSettingsResultCode = randomResultCode()
    var openEnableSettingsCallback: (() -> Unit)? = null

    init {
        registrar.addActivityResultListener(this)
    }

    fun openWifiSettings(call: MethodCall, result: Result) {
        activity.startActivityForResult(
            Intent(Settings.ACTION_WIFI_SETTINGS),
            enableSettingsResultCode
        )

        openEnableSettingsCallback = {
            connect(call, result)
            openEnableSettingsCallback = null
        }
    }

    var timers = mutableMapOf<Int, Timer>()

    fun connectedSSIDOnListen(id: Int, args: Any?, sink: EventSink) {
        timers[id] = timer(
            period = (args as Int).toLong(),
            action = { sink.success(getConnectedSSID()) }
        )
    }

    fun connectedSSIDOnCancel(id: Int, args: Any?) {
        timers.remove(id)?.cancel()
    }

    fun getConnectedSSID(call: MethodCall, result: Result) {
        result.success(getConnectedSSID())
    }

    fun getConnectedSSID(): String {
        val info = wifi.connectionInfo
        val ssid = info.ssid
        if (info.networkId == -1 || ssid == "<unknown ssid>") {
            return ""
        }
        return ssid.substring(1, ssid.length - 1)
    }

    fun connect(call: MethodCall, result: Result) {
        val ssid = call.argument<String>("ssid")!!
        val password = call.argument<String>("password")!!
        val hidden = call.argument<Boolean>("hidden")!!
        val capabilities = call.argument<String>("capabilities")!!
        val timeLimitMillis = call.argument<Long>("timeLimitMillis")!!

        if (!wifi.isWifiEnabled) {
            wifi.isWifiEnabled = true
            if (!waitForWifiEnable(timeLimitMillis)) {
                result.success(WifiConnectStatus.WIFI_DISABLED.ordinal)
                return
            }
        }

        conn.scanAndConnect(ssid, password, hidden, capabilities) { status ->
            val connectStatus =
                if (status == WifiConnectStatus.OK) {
                    val connected = waitForWifiConnect(timeLimitMillis, ssid)
                    if (connected) {
                        status
                    } else {
                        WifiConnectStatus.FAILED
                    }
                } else {
                    status
                }

            trySend(result) { connectStatus.ordinal }
        }
    }

    fun waitForWifiConnect(timeLimitMillis: Long, ssid: String): Boolean {
        while (System.currentTimeMillis() < timeLimitMillis) {
            val connectedSSID = getConnectedSSID()
            if (connectedSSID == ssid) {
                return true
            }
            Thread.sleep(POLL_INTERVAL_MS)
        }
        return false
    }

    fun waitForWifiEnable(timeLimitMillis: Long): Boolean {
        while (System.currentTimeMillis() < timeLimitMillis) {
            if (wifi.isWifiEnabled) {
                return true
            }
            Thread.sleep(POLL_INTERVAL_MS)
        }
        return false
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != enableSettingsResultCode) {
            return false
        }
        openEnableSettingsCallback?.invoke()
        return true
    }
}

val rand = Random()

fun randomResultCode(): Int {
    return rand.nextInt(65534) + 1
}