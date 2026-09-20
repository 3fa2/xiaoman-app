package com.xiaoman.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/// 开机/更新/时间变更/时区变更/日期变更后重建全部提醒。
/// 数据来源：Flutter 侧同步到 AlarmPersistence 的计划（未来 14 天滚动窗口）。
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_DATE_CHANGED,
            -> rescheduleAll(context)
        }
    }

    fun rescheduleAll(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        for (e in AlarmPersistence.getAll(context)) {
            if (e.epochMs <= now) continue
            val i = Intent(context, AlarmReceiver::class.java).apply {
                putExtra(AlarmReceiver.EXTRA_ID, e.id)
                putExtra(AlarmReceiver.EXTRA_TITLE, e.title)
                putExtra(AlarmReceiver.EXTRA_BODY, e.body)
                putExtra(AlarmReceiver.EXTRA_PAYLOAD, e.payload)
            }
            val pi = PendingIntent.getBroadcast(
                context, e.id, i,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val exactOk = if (Build.VERSION.SDK_INT >= 31) am.canScheduleExactAlarms() else true
            if (exactOk) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, e.epochMs, pi)
            } else {
                // 权限不可用：降级非精确，宁可延迟不可丢失
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, e.epochMs, pi)
            }
        }
    }
}
