package com.example.wifi_connect

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.ScanResult
import android.net.wifi.WifiConfiguration
import android.net.wifi.WifiManager
import android.util.Log

class ConnectionManager(val ctx: Context, val wifi: WifiManager) {
    fun scanAndConnect(
        ssid: String,
        password: String,
        hidden: Boolean,
        capabilities: String,
        onDone: (WifiConnectStatus) -> Unit
    ) {
        if (hidden) {
            onDone(connect(ssid, password, capabilities, hidden = true))
            return
        }

        scan { results ->
            Log.d(TAG, "Scan results: ${results.map { it.SSID }}")

            for (it in results) {
                if (ssid == it.SSID) {
                    onDone(connect(ssid, password, it.capabilities))
                    return@scan
                }
            }

            onDone(WifiConnectStatus.NOT_FOUND)
        }
    }

    fun scan(onDone: (List<ScanResult>) -> Unit) {
        ctx.registerReceiver(
            object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent) {
                    ctx.unregisterReceiver(this)
                    onDone(wifi.scanResults)
                }
            },
            IntentFilter().apply {
                addAction(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION)
            }
        )
        wifi.startScan()
    }

    fun connect(
        ssid: String,
        password: String,
        capabilities: String,
        hidden: Boolean = false
    ): WifiConnectStatus {
        //Make new configuration
        var conf = WifiConfiguration()

        //clear alloweds
        conf.allowedAuthAlgorithms.clear()
        conf.allowedGroupCiphers.clear()
        conf.allowedKeyManagement.clear()
        conf.allowedPairwiseCiphers.clear()
        conf.allowedProtocols.clear()

        // Quote ssid and password
        conf.SSID = String.format("\"%s\"", ssid)
        conf.hiddenSSID = hidden

        getExistingWifiConfig(conf.SSID)?.let {
            wifi.removeNetwork(it.networkId)
        }

        // appropriate ciper is need to set according to security type used
        if (
            capabilities.contains("WPA")
            || capabilities.contains("WPA2")
            || capabilities.contains("WPA/WPA2 PSK")
        ) {
            // This is needed for WPA/WPA2
            // Reference - https://android.googlesource.com/platform/frameworks/base/+/refs/heads/master/wifi/java/android/net/wifi/WifiConfiguration.java#149
            conf.allowedAuthAlgorithms.set(WifiConfiguration.AuthAlgorithm.OPEN)

            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.CCMP)
            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.TKIP)

            conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.WPA_PSK)

            conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.CCMP)
            conf.allowedPairwiseCiphers.set(WifiConfiguration.PairwiseCipher.TKIP)

            conf.allowedProtocols.set(WifiConfiguration.Protocol.RSN)
            conf.allowedProtocols.set(WifiConfiguration.Protocol.WPA)
            conf.status = WifiConfiguration.Status.ENABLED
            conf.preSharedKey = String.format("\"%s\"", password)
        } else if (capabilities.contains("WEP")) {
            // This is needed for WEP
            // Reference - https://android.googlesource.com/platform/frameworks/base/+/refs/heads/master/wifi/java/android/net/wifi/WifiConfiguration.java#149
            conf.wepKeys[0] = "\"" + password + "\""
            conf.wepTxKeyIndex = 0
            conf.allowedAuthAlgorithms.set(WifiConfiguration.AuthAlgorithm.OPEN)
            conf.allowedAuthAlgorithms.set(WifiConfiguration.AuthAlgorithm.SHARED)
            conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
            conf.allowedGroupCiphers.set(WifiConfiguration.GroupCipher.WEP40)
        } else {
            conf.allowedKeyManagement.set(WifiConfiguration.KeyMgmt.NONE)
        }

        var newNetwork = -1

        // Use the existing network config if exists
        for (wifiConfig in wifi.configuredNetworks) {
            if (wifiConfig.SSID == conf.SSID) {
                conf = wifiConfig
                newNetwork = conf.networkId
            }
        }

        // If network not already in configured networks add new network
        if (newNetwork == -1) {
            newNetwork = wifi.addNetwork(conf)
            wifi.saveConfiguration()
        }

        // if network not added return false
        if (newNetwork == -1) {
            return WifiConnectStatus.FAILED
        }

        // disconnect current network
        val disconnect = wifi.disconnect()
        if (!disconnect) {
            return WifiConnectStatus.FAILED
        }

        // enable new network
        val success = wifi.enableNetwork(newNetwork, true)

        return if (success) {
            WifiConnectStatus.OK
        } else {
            WifiConnectStatus.FAILED
        }
    }

    fun getExistingWifiConfig(ssid: String): WifiConfiguration? {
        for (config in wifi.configuredNetworks) {
            if (config.SSID == "\"" + ssid + "\"") {
                return config
            }
        }
        return null
    }
}