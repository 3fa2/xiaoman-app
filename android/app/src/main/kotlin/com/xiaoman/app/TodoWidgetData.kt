package com.xiaoman.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.database.sqlite.SQLiteDatabase

/// 待办小组件数据访问：直读 drift 的 trinity.sqlite。
/// 安全性：小组件与 Flutter 引擎同进程同 uid，WAL 模式下并发读写安全；
/// 勾选直写会触发 drift 在表上建的触发器 → App 内 watch 流自动收到刷新。
/// （App 从未启动过时 DB 文件不存在，全部方法返回空态，不崩。）
object TodoWidgetData {

    const val ACTION_TOGGLE = "com.xiaoman.app.widget.TODO_TOGGLE"
    const val EXTRA_TODO_ID = "widget_todo_id"
    const val EXTRA_OPEN_ACTION = "open_action"

    data class Todo(val id: Int, val title: String)

    private fun open(context: Context): SQLiteDatabase? {
        val f = context.getDatabasePath("trinity.sqlite")
        if (!f.exists()) return null
        return try {
            SQLiteDatabase.openDatabase(
                f.absolutePath, null, SQLiteDatabase.OPEN_READWRITE,
            )
        } catch (e: Exception) {
            null
        }
    }

    /// 未完成列表（排序与 App 内一致：sortOrder 升序、createdAt 降序）
    fun openTodos(context: Context, limit: Int): List<Todo> {
        val db = open(context) ?: return emptyList()
        try {
            return db.rawQuery(
                "SELECT id, title FROM todos WHERE done = 0 " +
                    "ORDER BY sortOrder ASC, createdAt DESC LIMIT ?",
                arrayOf(limit.toString()),
            ).use { c ->
                buildList {
                    while (c.moveToNext()) {
                        add(Todo(c.getInt(0), c.getString(1) ?: ""))
                    }
                }
            }
        } catch (e: Exception) {
            return emptyList()
        } finally {
            db.close()
        }
    }

    /// 未完成总数
    fun openCount(context: Context): Int {
        val db = open(context) ?: return 0
        try {
            return db.rawQuery(
                "SELECT COUNT(*) FROM todos WHERE done = 0", null,
            ).use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }
        } catch (e: Exception) {
            return 0
        } finally {
            db.close()
        }
    }

    /// 勾选切换（done = NOT done）。updatedAt 用 unix 秒（drift dateTime 默认存储格式）
    fun toggle(context: Context, id: Int) {
        val db = open(context) ?: return
        try {
            db.execSQL(
                "UPDATE todos SET done = NOT done, updatedAt = ? WHERE id = ?",
                arrayOf(System.currentTimeMillis() / 1000, id),
            )
        } catch (e: Exception) {
            // 数据库异常（升级中/损坏）：静默，不动用户数据
        } finally {
            db.close()
        }
    }

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
