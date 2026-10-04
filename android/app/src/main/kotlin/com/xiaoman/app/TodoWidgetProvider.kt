package com.xiaoman.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/// 待办小组件基类：处理勾选广播 + 公共 PendingIntent 构造。
abstract class TodoWidgetBase : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == TodoWidgetData.ACTION_TOGGLE) {
            val id = intent.getIntExtra(TodoWidgetData.EXTRA_TODO_ID, -1)
            if (id > 0) {
                // 在 SharedPreferences 缓存中翻转 done（即时反馈）
                TodoWidgetStore.toggle(context, id)
                // 尝试通知 Flutter 侧执行真正的 toggle（App 在运行时生效）
                WidgetChannelBridge.toggleTodo(id)
                // 刷新全部小组件
                TodoWidgetData.refreshAll(context)
            }
        } else {
            super.onReceive(context, intent)
        }
    }

    protected fun openAppPi(
        context: Context, action: String, requestCode: Int,
    ): PendingIntent {
        val launch = context.packageManager
            .getLaunchIntentForPackage(context.packageName) ?: Intent()
        launch.putExtra(TodoWidgetData.EXTRA_OPEN_ACTION, action)
        return PendingIntent.getActivity(
            context, requestCode, launch,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    protected fun togglePi(
        context: Context, provider: Class<*>, todoId: Int,
    ): PendingIntent {
        val i = Intent(context, provider)
            .setAction(TodoWidgetData.ACTION_TOGGLE)
            .putExtra(TodoWidgetData.EXTRA_TODO_ID, todoId)
        return PendingIntent.getBroadcast(
            context, 20000 + todoId, i,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}

/// 刷新全部小组件实例
fun refreshAllWidgets(context: Context) {
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

/// 4x2：大数字头部 + 圆形[+] + 最多 3 条装饰条卡。
class TodoWidgetProvider4x2 : TodoWidgetBase() {

    override fun onUpdate(
        context: Context, manager: AppWidgetManager, appWidgetIds: IntArray,
    ) {
        val todos = TodoWidgetStore.openTodos(context, 3)
        val count = TodoWidgetStore.openCount(context)
        val addPi = openAppPi(context, "todo_add", 10001)
        val openPi = openAppPi(context, "todo", 10002)

        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_todo_4x2)
            v.setTextViewText(R.id.widget_count, "$count")
            v.setOnClickPendingIntent(R.id.widget_add, addPi)

            val rowIds = intArrayOf(R.id.widget_row0, R.id.widget_row1, R.id.widget_row2)
            val titleIds = intArrayOf(R.id.widget_title0, R.id.widget_title1, R.id.widget_title2)
            for (i in rowIds.indices) {
                if (i < todos.size) {
                    val t = todos[i]
                    v.setViewVisibility(rowIds[i], View.VISIBLE)
                    v.setTextViewText(titleIds[i], t.title)
                    v.setOnClickPendingIntent(
                        rowIds[i], togglePi(context, TodoWidgetProvider4x2::class.java, t.id),
                    )
                } else {
                    v.setViewVisibility(rowIds[i], View.GONE)
                }
            }
            v.setViewVisibility(
                R.id.widget_empty, if (todos.isEmpty()) View.VISIBLE else View.GONE,
            )
            v.setOnClickPendingIntent(R.id.widget_root, openPi)
            manager.updateAppWidget(id, v)
        }
    }
}

/// 2x2：大数字头部 + 圆形[+] + 最多 2 条装饰条卡。
class TodoWidgetProvider2x2 : TodoWidgetBase() {

    override fun onUpdate(
        context: Context, manager: AppWidgetManager, appWidgetIds: IntArray,
    ) {
        val todos = TodoWidgetStore.openTodos(context, 2)
        val count = TodoWidgetStore.openCount(context)
        val addPi = openAppPi(context, "todo_add", 10011)
        val openPi = openAppPi(context, "todo", 10012)

        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_todo_2x2)
            v.setTextViewText(R.id.widget_count, "$count")
            v.setOnClickPendingIntent(R.id.widget_add, addPi)

            val rowIds = intArrayOf(R.id.widget_row0, R.id.widget_row1)
            val titleIds = intArrayOf(R.id.widget_title0, R.id.widget_title1)
            for (i in rowIds.indices) {
                if (i < todos.size) {
                    val t = todos[i]
                    v.setViewVisibility(rowIds[i], View.VISIBLE)
                    v.setTextViewText(titleIds[i], t.title)
                    v.setOnClickPendingIntent(
                        rowIds[i], togglePi(context, TodoWidgetProvider2x2::class.java, t.id),
                    )
                } else {
                    v.setViewVisibility(rowIds[i], View.GONE)
                }
            }
            v.setOnClickPendingIntent(R.id.widget_root, openPi)
            manager.updateAppWidget(id, v)
        }
    }
}
