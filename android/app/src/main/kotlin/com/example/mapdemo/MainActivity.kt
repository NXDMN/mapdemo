package com.example.mapdemo

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity(){
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        flutterEngine
                .platformViewsController
                .registry
                .registerViewFactory("flutter-street-view", FlutterStreetViewFactory(flutterEngine.dartExecutor.binaryMessenger, lifecycle))

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "flutter_compass").setStreamHandler(FlutterCompass(applicationContext))
    }
}