package com.allvideoplayer.mxplayer.videoplayer

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val factorySmall = NativeAdFactorySmall(layoutInflater)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "small", factorySmall)

        val factoryMedium = NativeAdFactoryMedium(layoutInflater)
        GoogleMobileAdsPlugin.registerNativeAdFactory(flutterEngine, "medium", factoryMedium)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "small")
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "medium")
    }
}

class NativeAdFactorySmall(val layoutInflater: LayoutInflater) :
    GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.native_ad_small, null) as NativeAdView

        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)

        (adView.headlineView as TextView).text = nativeAd.headline
        nativeAd.body?.let {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = it
        } ?: run {
            adView.bodyView?.visibility = View.GONE
        }

        nativeAd.callToAction?.let {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = "OPEN"
        } ?: run {
            adView.callToActionView?.visibility = View.GONE
        }

        nativeAd.icon?.let {
            adView.iconView?.visibility = View.VISIBLE
            (adView.iconView as ImageView).setImageDrawable(it.drawable)
        } ?: run {
            adView.iconView?.visibility = View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}

class NativeAdFactoryMedium(val layoutInflater: LayoutInflater) :
    GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(R.layout.native_ad_medium, null) as NativeAdView

        adView.headlineView = adView.findViewById(R.id.ad_headline)
        adView.bodyView = adView.findViewById(R.id.ad_body)
        adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
        adView.iconView = adView.findViewById(R.id.ad_app_icon)
        adView.mediaView = adView.findViewById(R.id.ad_media)

        (adView.headlineView as TextView).text = nativeAd.headline
        nativeAd.body?.let {
            adView.bodyView?.visibility = View.VISIBLE
            (adView.bodyView as TextView).text = it
        } ?: run {
            adView.bodyView?.visibility = View.GONE
        }

        nativeAd.callToAction?.let {
            adView.callToActionView?.visibility = View.VISIBLE
            (adView.callToActionView as Button).text = "OPEN"
        } ?: run {
            adView.callToActionView?.visibility = View.GONE
        }

        nativeAd.icon?.let {
            adView.iconView?.visibility = View.VISIBLE
            (adView.iconView as ImageView).setImageDrawable(it.drawable)
        } ?: run {
            adView.iconView?.visibility = View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
