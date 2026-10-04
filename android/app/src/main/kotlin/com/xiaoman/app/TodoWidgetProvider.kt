package com.xiaoman.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
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
                TodoWidgetData.toggle(context, id)
                TodoWidgetData.refreshAll(context)
            }
        } else {
            super.onReceive(context, intent)
        }
    }

    /// 打开 App（+ 按钮带 todo_add，整块点击带 todo）
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

    /// 点条目 = 勾选切换（requestCode 加偏移避开其他 PendingIntent）
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

/// 4x2：标题行（待办 + 未完成数 + 添加）+ 最多 3 条列表，点条目勾选完成。
class TodoWidgetProvider4x2 : TodoWidgetBase() {

    override fun onUpdate(
        context: Context, manager: AppWidgetManager, appWidgetIds: IntArray,
    ) {
        val todos = TodoWidgetData.openTodos(context, 3)
        val count = TodoWidgetData.openCount(context)
        val addPi = openAppPi(context, "todo_add", 10001)
        val openPi = openAppPi(context, "todo", 10002)

        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_todo_4x2)
            v.setTextViewText(R.id.widget_count, "$count")
            v.setOnClickPendingIntent(R.id.widget_add, addPi)

            // 3 条固定行：有数据填充并绑定勾选，无数据隐藏
            val rowIds = intArrayOf(R.id.widget_row0, R.id.widget_row1, R.id.widget_row2)
            val titleIds = intArrayOf(R.id.widget_title0, R.id.widget_title1, R.id.widget_title2)
            for (i in rowIds.indices) {
                if (i < todos.size) {
                    val t = todos[i]
                    v.setViewVisibility(rowIds[i], android.view.View.VISIBLE)
                    v.setTextViewText(titleIds[i], t.title)
                    v.setOnClickPendingIntent(
                        rowIds[i], togglePi(context, TodoWidgetProvider4x2::class.java, t.id),
                    )
                } else {
                    v.setViewVisibility(rowIds[i], android.view.View.GONE)
                }
            }
            // 空态：一条都没有时显示一句宽慰话
            v.setViewVisibility(
                R.id.widget_empty, if (todos.isEmpty()) android.view.View.VISIBLE else android.view.View.GONE,
            )
            v.setOnClickPendingIntent(R.id.widget_root, openPi)
            manager.updateAppWidget(id, v)
        }
    }
}

/// 2x2：大数字未完成数 + 最多 2 条列表。
class TodoWidgetProvider2x2 : TodoWidgetBase() {

    override fun onUpdate(
        context: Context, manager: AppWidgetManager, appWidgetIds: IntArray,
    ) {
        val todos = TodoWidgetData.openTodos(context, 2)
        val count = TodoWidgetData.openCount(context)
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
                    v.setViewVisibility(rowIds[i], android.view.View.VISIBLE)
                    v.setTextViewText(titleIds[i], t.title)
                    v.setOnClickPendingIntent(
                        rowIds[i], togglePi(context, TodoWidgetProvider2x2::class.java, t.id),
                    )
                } else {
                    v.setViewVisibility(rowIds[i], android.view.View.GONE)
                }
            }
            v.setOnClickPendingIntent(R.id.widget_root, openPi)
            manager.updateAppWidget(id, v)
        }
    }
}
