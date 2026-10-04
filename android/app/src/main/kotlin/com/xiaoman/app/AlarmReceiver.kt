package com.xiaoman.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/// 闹钟触发：原生发通知（重启后接管 flutter_local_notifications 失效的闹钟）。
class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "trinity_schedule"
        const val EXTRA_ID = "alarm_id"
        const val EXTRA_TITLE = "alarm_title"
        const val EXTRA_BODY = "alarm_body"
        const val EXTRA_PAYLOAD = "alarm_payload"
        // v5.0：待办提醒走 trinity_todo 渠道；缺省沿用 trinity_schedule（渠道 id 红线不动）
        const val EXTRA_CHANNEL = "alarm_channel"
        const val TODO_CHANNEL_ID = "trinity_todo"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_ID, 0)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "日程提醒"
        val body = intent.getStringExtra(EXTRA_BODY) ?: ""
        val channel = intent.getStringExtra(EXTRA_CHANNEL)?.takeIf { it.isNotEmpty() }
            ?: CHANNEL_ID

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(
            NotificationChannel(
                channel,
                if (channel == TODO_CHANNEL_ID) "待办提醒" else "日程提醒",
                NotificationManager.IMPORTANCE_HIGH,
            ),
        )

        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pi = PendingIntent.getActivity(
            context, id, launch ?: Intent(),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder: Notification.Builder = Notification.Builder(context, channel)
        // v5.0：大图标（提醒更醒目）；自适应图标不能直接 decodeResource，画到画布
        largeIcon(context)?.let { builder.setLargeIcon(it) }
        val n = builder
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(context.applicationInfo.icon)
            .setContentIntent(pi)
            .setAutoCancel(true)
            .build()
        nm.notify(id, n)
    }

    /// 应用图标转 Bitmap（AdaptiveIconDrawable 需手动绘制）
    private fun largeIcon(context: Context): android.graphics.Bitmap? {
        return try {
            val d = context.packageManager.getApplicationIcon(context.packageName)
            when (d) {
                is android.graphics.drawable.AdaptiveIconDrawable -> {
                    val size = 128
                    val b = android.graphics.Bitmap.createBitmap(
                        size, size, android.graphics.Bitmap.Config.ARGB_8888,
                    )
                    val c = android.graphics.Canvas(b)
                    d.setBounds(0, 0, size, size)
                    d.draw(c)
                    b
                }
                is android.graphics.drawable.BitmapDrawable -> d.bitmap
                else -> null
            }
        } catch (e: Exception) {
            null
        }
    }
}
