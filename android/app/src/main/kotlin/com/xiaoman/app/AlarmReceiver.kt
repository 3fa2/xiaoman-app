package com.xiaoman.app

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/// 闹钟触发：原生发通知（重启后接管 flutter_local_notifications 失效的闹钟）。
class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val CHANNEL_ID = "trinity_schedule"
        const val EXTRA_ID = "alarm_id"
        const val EXTRA_TITLE = "alarm_title"
        const val EXTRA_BODY = "alarm_body"
        const val EXTRA_PAYLOAD = "alarm_payload"
        const val EXTRA_EPOCH = "alarm_epoch"
        // v5.0：待办提醒走 trinity_todo 渠道；缺省沿用 trinity_schedule（渠道 id 红线不动）
        const val EXTRA_CHANNEL = "alarm_channel"
        const val TODO_CHANNEL_ID = "trinity_todo"
        // v5.3：每日写日记提醒（触发后自滚下一天；点通知直达日记编辑器）
        const val EXTRA_REPEAT_DAILY = "alarm_repeat_daily"
        const val DIARY_CHANNEL_ID = "trinity_diary"
        private const val DAY_MS = 24 * 60 * 60 * 1000L
    }

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_ID, 0)
        val title = intent.getStringExtra(EXTRA_TITLE) ?: "日程提醒"
        val body = intent.getStringExtra(EXTRA_BODY) ?: ""
        val channel = intent.getStringExtra(EXTRA_CHANNEL)?.takeIf { it.isNotEmpty() }
            ?: CHANNEL_ID
        val repeatDaily = intent.getBooleanExtra(EXTRA_REPEAT_DAILY, false)

        // 每日提醒：排下一天 + 更新持久列表（否则重启重建后不再响）。
        // epoch 守卫：缺失（0）时不自滚，否则会用过去时间反复排闹钟形成即时循环。
        val prevEpoch = intent.getLongExtra(EXTRA_EPOCH, 0L)
        if (repeatDaily && id != 0 && prevEpoch > 0) {
            val next = prevEpoch + DAY_MS
            val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val i = Intent(context, AlarmReceiver::class.java).apply {
                putExtra(AlarmReceiver.EXTRA_ID, id)
                putExtra(AlarmReceiver.EXTRA_TITLE, title)
                putExtra(AlarmReceiver.EXTRA_BODY, body)
                putExtra(AlarmReceiver.EXTRA_PAYLOAD, intent.getStringExtra(EXTRA_PAYLOAD))
                putExtra(AlarmReceiver.EXTRA_CHANNEL, channel)
                putExtra(AlarmReceiver.EXTRA_EPOCH, next)
                putExtra(AlarmReceiver.EXTRA_REPEAT_DAILY, true)
            }
            val pi = PendingIntent.getBroadcast(
                context, id, i,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val exactOk = if (Build.VERSION.SDK_INT >= 31) am.canScheduleExactAlarms() else true
            if (exactOk) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pi)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next, pi)
            }
            AlarmPersistence.rollDaily(context, id, next)
        }

        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        nm.createNotificationChannel(
            NotificationChannel(
                channel,
                when (channel) {
                    TODO_CHANNEL_ID -> "待办提醒"
                    DIARY_CHANNEL_ID -> "写日记提醒"
                    else -> "日程提醒"
                },
                NotificationManager.IMPORTANCE_HIGH,
            ),
        )

        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        // 写日记提醒：点通知直达日记编辑器（锁屏由 App 内 LockGate 处理）
        if (channel == DIARY_CHANNEL_ID) {
            launch?.putExtra(TodoWidgetData.EXTRA_OPEN_ACTION, "diary")
        }
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
