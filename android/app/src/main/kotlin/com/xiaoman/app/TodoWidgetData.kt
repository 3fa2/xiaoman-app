package com.xiaoman.app

import android.content.Context
import android.appwidget.AppWidgetManager
import android.content.ComponentName

/// 小组件数据/刷新辅助（v5.0.3）。
/// 数据读取已迁移到 TodoWidgetStore（SharedPreferences 缓存）；
/// 本对象只保留 action 常量 + 刷新入口。
object TodoWidgetData {
    const val ACTION_TOGGLE = "com.xiaoman.app.widget.TODO_TOGGLE"
    const val EXTRA_TODO_ID = "widget_todo_id"
    const val EXTRA_OPEN_ACTION = "open_action"

    /// 刷新全部小组件实例（数据变化 / 勾选 / 开机重建后调用）
    fun refreshAll(context: Context) {
        try {
            val m = AppWidgetManager.getInstance(context)
            val ids4 = m.getAppWidgetIds(
                ComponentName(context, TodoWidgetProvider4x2::class.java),
            )
            if (ids4.isNotEmpty()) {
                TodoWidgetProvider4x2().onUpdate(context, m, ids4)
            }
            val ids2 = m.getAppWidgetIds(
                ComponentName(context, TodoWidgetProvider2x2::class.java),
            )
            if (ids2.isNotEmpty()) {
                TodoWidgetProvider2x2().onUpdate(context, m, ids2)
            }
        } catch (e: Exception) {
            // 刷新失败不影响主流程
        }
    }
}
