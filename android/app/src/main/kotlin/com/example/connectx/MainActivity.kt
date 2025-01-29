/*package com.example.connectx

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    private val PERMISSION_REQUEST_CODE = 101

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Check if ACCESS_FINE_LOCATION permission is granted
        val locationPermissionCheck = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        )

        // Check if NEARBY_WIFI_DEVICES permission is granted
        val wifiPermissionCheck = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.NEARBY_WIFI_DEVICES
        )

        // Check if READ_MEDIA_IMAGES permission is granted
//        val imagesPermissionCheck = ContextCompat.checkSelfPermission(
//            this,
//            Manifest.permission.READ_MEDIA_IMAGES
//        )

        // Check if READ_MEDIA_VIDEO permission is granted
//        val videoPermissionCheck = ContextCompat.checkSelfPermission(
//            this,
//            Manifest.permission.READ_MEDIA_VIDEO
//        )
//
//        // Check if READ_MEDIA_AUDIO permission is granted
//        val audioPermissionCheck = ContextCompat.checkSelfPermission(
//            this,
//            Manifest.permission.READ_MEDIA_AUDIO
//        )

        // Request permissions if not granted
        val permissionsToRequest = mutableListOf<String>()

        if (locationPermissionCheck != PackageManager.PERMISSION_GRANTED) {
            permissionsToRequest.add(Manifest.permission.ACCESS_FINE_LOCATION)
        }
        if (wifiPermissionCheck != PackageManager.PERMISSION_GRANTED) {
            permissionsToRequest.add(Manifest.permission.NEARBY_WIFI_DEVICES)
        }
//        if (imagesPermissionCheck != PackageManager.PERMISSION_GRANTED) {
//            permissionsToRequest.add(Manifest.permission.READ_MEDIA_IMAGES)
//        }
//        if (videoPermissionCheck != PackageManager.PERMISSION_GRANTED) {
//            permissionsToRequest.add(Manifest.permission.READ_MEDIA_VIDEO)
//        }
//        if (audioPermissionCheck != PackageManager.PERMISSION_GRANTED) {
//            permissionsToRequest.add(Manifest.permission.READ_MEDIA_AUDIO)
//        }

        // Request all permissions if any are not granted
        if (permissionsToRequest.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                permissionsToRequest.toTypedArray(),
                PERMISSION_REQUEST_CODE
            )
        }
        // No action if all permissions are already granted
    }

    // Handle permission result
    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            var allPermissionsGranted = true
            // Check if all requested permissions were granted
            for (result in grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allPermissionsGranted = false
                    break
                }
            }
            if (allPermissionsGranted) {
                // All permissions granted, proceed with the functionality
                Toast.makeText(this, "Permissions Granted", Toast.LENGTH_SHORT).show()
            } else {
                // One or more permissions denied
                Toast.makeText(this, "Permissions Denied", Toast.LENGTH_SHORT).show()
            }
        }
    }
}*/

package com.example.connectx

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    private val PERMISSION_REQUEST_CODE = 101

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val permission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S_V2)
            Manifest.permission.NEARBY_WIFI_DEVICES
        else
            Manifest.permission.ACCESS_FINE_LOCATION

        if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(permission), PERMISSION_REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == PERMISSION_REQUEST_CODE) {
            val resultMessage = if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                "Permission granted!"
            } else {
                "Permission denied!"
            }
            Toast.makeText(this, resultMessage, Toast.LENGTH_SHORT).show()
        }
    }
}

