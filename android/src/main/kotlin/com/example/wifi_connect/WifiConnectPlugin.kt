package com.example.wifi_connect

import android.content.Context
import android.content.Intent
import android.net.wifi.WifiManager
import android.provider.Settings
import com.pycampers.plugin_scaffold.createPluginScaffold
import com.pycampers.plugin_scaffold.trySend
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import io.flutter.plugin.common.PluginRegistry.Registrar
import java.util.Random

const val TAG = "WifiConnectPlugin"

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

    fun getConnectedSSID(call: MethodCall, result: Result) {
        val conn = wifi.connectionInfo
        if (conn.networkId == -1 || conn.ssid == "<unknown ssid>") {
            result.success(null)
        } else {
            val ssid = conn.ssid
            result.success(ssid.substring(1, ssid.length - 1))
        }
    }

    fun connect(call: MethodCall, result: Result) {
        val ssid = call.argument<String>("ssid")!!
        val password = call.argument<String>("password")!!
        val wifiEnableTimeoutMillis = call.argument<Int>("wifiEnableTimeoutMillis")!!.toLong()

        if (!wifi.isWifiEnabled) {
            wifi.isWifiEnabled = true

            val timeLimit = System.currentTimeMillis() + wifiEnableTimeoutMillis
            val sleepInterval = wifiEnableTimeoutMillis / 10
            while (!wifi.isWifiEnabled && System.currentTimeMillis() < timeLimit) {
                Thread.sleep(sleepInterval)
            }

            if (!wifi.isWifiEnabled) {
                result.success(WifiConnectStatus.WIFI_DISABLED.ordinal)
                return
            }
        }

        conn.scanAndConnect(ssid, password) { status ->
            trySend(result) { status.ordinal }
        }
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