package com.xiaoman.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import java.util.Calendar

/// 截止日标签（v5.8）：小组件行尾的 due 文案 + 颜色资源 + 可见性。
data class DueLabel(val text: String, val colorRes: Int, val visible: Boolean)

/// 待办小组件基类：处理勾选广播 + 公共 PendingIntent 构造 + 截止日文案。
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

    /// 截止日文案规则：
    /// null → 不显示；今天 → 「今天」（雾蓝强调）；明天 → 「明天」（次级灰）；
    /// 早于今天 → 「M月d日」（低饱和红，过期）；晚于明天 → 「M月d日」（次级灰）。
    protected fun dueLabel(dueDay: Int?, todayDay: Int): DueLabel {
        if (dueDay == null || dueDay <= 0) {
            return DueLabel("", R.color.widget_ink_soft, false)
        }
        return when {
            dueDay == todayDay -> DueLabel("今天", R.color.widget_today_fg, true)
            dueDay == todayDay + 1 -> DueLabel("明天", R.color.widget_ink_soft, true)
            dueDay < todayDay -> DueLabel(
                "${dueDay / 100 % 100}月${dueDay % 100}日", R.color.widget_danger, true,
            )
            else -> DueLabel(
                "${dueDay / 100 % 100}月${dueDay % 100}日", R.color.widget_ink_soft, true,
            )
        }
    }

    /// 今天 yyyymmdd（与 ScheduleWidgetStore.isToday 同一套算法）
    protected fun todayDay(): Int {
        val n = Calendar.getInstance()
        return n.get(Calendar.YEAR) * 10000 +
            (n.get(Calendar.MONTH) + 1) * 100 + n.get(Calendar.DAY_OF_MONTH)
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

/// 4x2（v5.8）：大数字头部 + 圆形[+] + ViewFlipper 轮播（最多 9 条 = 3 页 × 3 条）。
class TodoWidgetProvider4x2 : TodoWidgetBase() {

    override fun onUpdate(
        context: Context, manager: AppWidgetManager, appWidgetIds: IntArray,
    ) {
        // 最多 9 条 = 3 页，每页 3 条；ViewFlipper 每 4 秒翻一页
        val todos = TodoWidgetStore.openTodos(context, 9)
        val count = TodoWidgetStore.openCount(context)
        val addPi = openAppPi(context, "todo_add", 10001)
        val openPi = openAppPi(context, "todo", 10002)
        val today = todayDay()

        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_todo_4x2)
            v.setTextViewText(R.id.widget_count, "$count")
            v.setOnClickPendingIntent(R.id.widget_add, addPi)

            if (todos.isEmpty()) {
                v.setViewVisibility(R.id.widget_flipper, View.GONE)
                v.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            } else {
                v.setViewVisibility(R.id.widget_flipper, View.VISIBLE)
                v.setViewVisibility(R.id.widget_empty, View.GONE)
                // 重建页面前先清掉旧页（轮播内容随数据全量替换）
                v.removeAllViews(R.id.widget_flipper)
                for (pageTodos in todos.chunked(3)) {
                    val page = RemoteViews(context.packageName, R.layout.widget_todo_page)
                    for (t in pageTodos) {
                        val row = RemoteViews(context.packageName, R.layout.widget_todo_row)
                        row.setTextViewText(R.id.row_title, t.title)
                        val due = dueLabel(t.dueDay, today)
                        if (due.visible) {
                            row.setViewVisibility(R.id.row_due, View.VISIBLE)
                            row.setTextViewText(R.id.row_due, due.text)
                            row.setTextColor(R.id.row_due, context.getColor(due.colorRes))
                        } else {
                            row.setViewVisibility(R.id.row_due, View.GONE)
                        }
                        // 整行点击 = 勾选该条
                        row.setOnClickPendingIntent(
                            R.id.row_root,
                            togglePi(context, TodoWidgetProvider4x2::class.java, t.id),
                        )
                        page.addView(R.id.widget_page, row)
                    }
                    // 不足一页的行不添加（等价于隐藏，不参与轮播排版）
                    v.addView(R.id.widget_flipper, page)
                }
            }
            v.setOnClickPendingIntent(R.id.widget_root, openPi)
            manager.updateAppWidget(id, v)
        }
    }
}

/// 2x2：大数字头部 + 圆形[+] + 最多 2 条装饰条卡（v5.8 同步行尾截止日文案）。
class TodoWidgetProvider2x2 : TodoWidgetBase() {

    override fun onUpdate(
        context: Context, manager: AppWidgetManager, appWidgetIds: IntArray,
    ) {
        val todos = TodoWidgetStore.openTodos(context, 2)
        val count = TodoWidgetStore.openCount(context)
        val addPi = openAppPi(context, "todo_add", 10011)
        val openPi = openAppPi(context, "todo", 10012)
        val today = todayDay()

        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_todo_2x2)
            v.setTextViewText(R.id.widget_count, "$count")
            v.setOnClickPendingIntent(R.id.widget_add, addPi)

            val rowIds = intArrayOf(R.id.widget_row0, R.id.widget_row1)
            val titleIds = intArrayOf(R.id.widget_title0, R.id.widget_title1)
            val dueIds = intArrayOf(R.id.widget_due0, R.id.widget_due1)
            for (i in rowIds.indices) {
                if (i < todos.size) {
                    val t = todos[i]
                    v.setViewVisibility(rowIds[i], View.VISIBLE)
                    v.setTextViewText(titleIds[i], t.title)
                    val due = dueLabel(t.dueDay, today)
                    if (due.visible) {
                        v.setViewVisibility(dueIds[i], View.VISIBLE)
                        v.setTextViewText(dueIds[i], due.text)
                        v.setTextColor(dueIds[i], context.getColor(due.colorRes))
                    } else {
                        v.setViewVisibility(dueIds[i], View.GONE)
                    }
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
