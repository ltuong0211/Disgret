package com.nhom.focus.focus_app

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.PendingIntent
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.util.Log
import org.json.JSONArray

/**
 * 2.2 Nhắc giờ học có chặn app (spec 023, ADR-0014). Flutter hands over the reminder times of the
 * habits with "Chặn app khi tới giờ" on. At each time an inexact alarm wakes [StudyCheckReceiver];
 * if a blocked app is on screen then, [InterventionActivity] covers it with "Tới giờ … rồi".
 * Otherwise nothing happens: the notification of spec 009 is enough.
 */
object StudyChecks {
    private const val TAG = "StudyChecks"
    private const val PREFS = "study_checks"
    private const val KEY_CHECKS = "checks"
    private const val KEY_BLOCKED = "blocked"
    private const val KEY_SNOOZES = "snoozes_"
    private const val REQUEST_BASE = 7_000
    private const val SNOOZE_REQUEST = 6_999
    private const val LOOK_BACK_MILLIS = 60_000L

    /** "Để 10 phút nữa" at most twice per habit and day (spec 023 FR-006). */
    const val SNOOZE_MINUTES = 10
    const val MAX_SNOOZES = 2

    const val EXTRA_HABIT_ID = "habit_id"
    const val EXTRA_HABIT_NAME = "habit_name"
    const val EXTRA_MINUTES = "minutes"

    /** Replaces every scheduled check with [checks] (maps from `StudyCheck.toMap`). */
    fun schedule(context: Context, checks: List<Map<String, Any?>>, blocked: List<String>) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val previous = prefs.getInt(KEY_CHECKS, 0)
        for (i in 0 until previous) alarms.cancel(pendingIntent(context, REQUEST_BASE + i, null))

        val now = System.currentTimeMillis()
        val upcoming = checks.filter { (it["atMillis"] as? Number)?.toLong() ?: 0L > now }
        upcoming.forEachIndexed { i, check ->
            val at = (check["atMillis"] as Number).toLong()
            val intent = pendingIntent(context, REQUEST_BASE + i, check)
            alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        }
        prefs.edit()
            .putInt(KEY_CHECKS, upcoming.size)
            .putString(KEY_BLOCKED, JSONArray(blocked).toString())
            .apply()
    }

    /** "Để 10 phút nữa": one more check for the same habit later; false when no snooze is left. */
    fun snooze(context: Context, habitId: String, habitName: String, minutes: Int): Boolean {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val key = KEY_SNOOZES + habitId + "_" + today()
        val used = prefs.getInt(key, 0)
        if (used >= MAX_SNOOZES) return false
        prefs.edit().putInt(key, used + 1).apply()
        val at = System.currentTimeMillis() + SNOOZE_MINUTES * 60_000L
        val check = mapOf("habitId" to habitId, "habitName" to habitName, "minutes" to minutes)
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarms.setAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            at,
            pendingIntent(context, SNOOZE_REQUEST, check),
        )
        return true
    }

    fun snoozesLeft(context: Context, habitId: String): Int {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        return MAX_SNOOZES - prefs.getInt(KEY_SNOOZES + habitId + "_" + today(), 0)
    }

    /** The alarm went off: cover a blocked app if one is on screen right now. */
    fun run(context: Context, intent: Intent) {
        val habitId = intent.getStringExtra(EXTRA_HABIT_ID) ?: return
        val habitName = intent.getStringExtra(EXTRA_HABIT_NAME).orEmpty()
        val minutes = intent.getIntExtra(EXTRA_MINUTES, 0)
        // A session is running: Reset break already guards the apps.
        if (FocusGuardService.isRunning) return
        if (!AppPermissions.hasUsageAccess(context) || !AppPermissions.hasOverlayPermission(context)) {
            return
        }
        if (!isUserLookingAtScreen(context)) return
        val app = foregroundApp(context) ?: return
        if (app !in blocked(context) || app in InstalledApps.protectedPackages(context)) return
        InterventionActivity.openScheduled(
            context,
            InstalledApps.labelOf(context, app),
            habitId,
            habitName,
            minutes,
        )
    }

    private fun blocked(context: Context): Set<String> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_BLOCKED, "[]")
        val array = JSONArray(raw)
        return (0 until array.length()).map { array.getString(it) }.toSet()
    }

    /** The app whose screen was opened last in the past minute and not closed since. */
    private fun foregroundApp(context: Context): String? {
        val usage = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val now = System.currentTimeMillis()
        val events = usage.queryEvents(now - LOOK_BACK_MILLIS, now) ?: return null
        var latest: String? = null
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> latest = event.packageName
                UsageEvents.Event.ACTIVITY_PAUSED ->
                    if (event.packageName == latest) latest = null
            }
        }
        // Nothing resumed or paused in the last minute: the user has stayed in one app; ask the
        // daily stats which one was in front last.
        return latest ?: usage.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - LOOK_BACK_MILLIS, now)
            ?.maxByOrNull { it.lastTimeUsed }
            ?.takeIf { now - it.lastTimeUsed < LOOK_BACK_MILLIS }
            ?.packageName
    }

    private fun isUserLookingAtScreen(context: Context): Boolean {
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val keyguard = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        return power.isInteractive && !keyguard.isKeyguardLocked
    }

    private fun today(): String =
        java.text.SimpleDateFormat("yyyy-MM-dd", java.util.Locale.US).format(java.util.Date())

    private fun pendingIntent(context: Context, request: Int, check: Map<String, Any?>?): PendingIntent {
        val intent = Intent(context, StudyCheckReceiver::class.java)
        if (check != null) {
            intent.putExtra(EXTRA_HABIT_ID, check["habitId"] as? String)
            intent.putExtra(EXTRA_HABIT_NAME, check["habitName"] as? String)
            intent.putExtra(EXTRA_MINUTES, (check["minutes"] as? Number)?.toInt() ?: 0)
        }
        return PendingIntent.getBroadcast(
            context,
            request,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    internal fun logSafely(block: () -> Unit) {
        try {
            block()
        } catch (error: RuntimeException) {
            Log.w(TAG, "Study check failed", error)
        }
    }
}

/** Woken by the alarms of [StudyChecks]. */
class StudyCheckReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        StudyChecks.logSafely { StudyChecks.run(context, intent) }
    }
}
