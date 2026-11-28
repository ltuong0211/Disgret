package com.nhom.focus.focus_app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.CountDownTimer
import android.os.SystemClock
import android.view.View
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import android.window.OnBackInvokedDispatcher
import kotlin.math.ceil

/**
 * 2.3 Màn can thiệp: hiện đè lên app vừa mở, bắt người dùng dừng lại vài giây rồi cho chọn
 * quay lại học, xem 1 reel động lực, hoặc nghỉ có chủ đích.
 * Giao diện nằm trong res/layout/activity_intervention.xml.
 */
class InterventionActivity : Activity() {

    private var countdown: CountDownTimer? = null

    /** Mở từ nút "Thử màn can thiệp": không ghi sự kiện, không ảnh hưởng tới phiên học. */
    private val isTrial: Boolean
        get() = intent.getBooleanExtra(EXTRA_IS_TRIAL, false)

    /**
     * 2.2 Spec 023: opened at a habit's reminder time over a blocked app, outside a session.
     * The same screen, other words and choices: start that habit now, "Để 10 phút nữa", or go on
     * into the app after the 5-second wait. No Reset-break event is recorded.
     */
    private val isScheduled: Boolean
        get() = intent.getStringExtra(StudyChecks.EXTRA_HABIT_ID) != null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        isShowing = true
        // Gret's breathing animation as smooth as the screen allows.
        DisplayRate.preferHighest(this)
        setContentView(R.layout.activity_intervention)
        setUpChoices()
        setUpBreakOptions()
        showForCurrentIntent()

        // Từ Android 13, nút Back của hệ thống đi qua callback này thay vì onBackPressed.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(
                OnBackInvokedDispatcher.PRIORITY_DEFAULT,
            ) { onBackChoice() }
        }
    }

    /** Màn này chỉ có một bản: nếu bản cũ còn nằm dưới app khác thì được dùng lại với app mới. */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        showForCurrentIntent()
    }

    @Deprecated("Chỉ còn dùng cho Android 12 trở xuống")
    override fun onBackPressed() {
        onBackChoice()
    }

    /** Back means "study", as on the Reset-break screen. */
    private fun onBackChoice() {
        if (isScheduled) startScheduledHabit() else returnToStudy()
    }

    /**
     * Hiện tên app và đếm ngược từ đầu; các lựa chọn chờ đếm xong mới hiện. Gret bơi ra chắn cửa
     * rồi thở cùng người dùng trong vòng đếm ngược (spec 019); câu của Gret đổi theo lần chặn.
     */
    private fun showForCurrentIntent() {
        val appName = intent.getStringExtra(EXTRA_APP_NAME).orEmpty()
        val waitSeconds = intent.getIntExtra(EXTRA_WAIT_SECONDS, FocusGuardService.FIRST_WAIT_SECONDS)
        findViewById<TextView>(R.id.intervention_app_name).text = appName
        if (isScheduled) {
            showScheduledWords(appName)
        } else {
            findViewById<TextView>(R.id.intervention_question).text =
                getString(R.string.intervention_question, appName)
            val lines = resources.getStringArray(R.array.intervention_gret_lines)
            val block = (waitSeconds - FocusGuardService.FIRST_WAIT_SECONDS) /
                FocusGuardService.WAIT_STEP_SECONDS
            findViewById<TextView>(R.id.intervention_gret_line).text =
                lines[block.coerceIn(0, lines.size - 1)]
            showSessionChoiceLabels()
        }

        val breathText = findViewById<TextView>(R.id.intervention_breath)
        breathText.setText(R.string.intervention_breathe)
        val gret = findViewById<GretGuardView>(R.id.intervention_gret)
        gret.onBreath = { inhale ->
            breathText.setText(if (inhale) R.string.intervention_inhale else R.string.intervention_exhale)
        }
        gret.remaining = 1f
        gret.restart()

        findViewById<View>(R.id.intervention_countdown_panel).visibility = View.VISIBLE
        findViewById<View>(R.id.intervention_countdown).visibility = View.VISIBLE
        findViewById<View>(R.id.intervention_choices).visibility = View.GONE
        findViewById<View>(R.id.intervention_break_options).visibility = View.GONE
        startCountdown(waitSeconds)
    }

    private fun setUpChoices() {
        findViewById<Button>(R.id.intervention_back_button).setOnClickListener { onBackChoice() }
        findViewById<Button>(R.id.intervention_reel_button).setOnClickListener {
            if (isScheduled) snoozeScheduled() else watchReel()
        }
        findViewById<Button>(R.id.intervention_break_button).setOnClickListener {
            if (isScheduled) finish() else showBreakOptions()
        }
    }

    // ---------- 2.2 Spec 023: at the reminder time ----------

    private fun showScheduledWords(appName: String) {
        val habitName = intent.getStringExtra(StudyChecks.EXTRA_HABIT_NAME).orEmpty()
        val minutes = intent.getIntExtra(StudyChecks.EXTRA_MINUTES, 0)
        findViewById<TextView>(R.id.intervention_question).text =
            getString(R.string.scheduled_question, habitName, appName)
        findViewById<TextView>(R.id.intervention_gret_line).text =
            getString(R.string.scheduled_gret_line, minutes)
        findViewById<Button>(R.id.intervention_back_button).setText(R.string.scheduled_start_now)
        val snooze = findViewById<Button>(R.id.intervention_reel_button)
        snooze.setText(R.string.scheduled_snooze)
        val habitId = intent.getStringExtra(StudyChecks.EXTRA_HABIT_ID).orEmpty()
        snooze.visibility =
            if (StudyChecks.snoozesLeft(this, habitId) > 0) View.VISIBLE else View.GONE
        findViewById<Button>(R.id.intervention_break_button).text =
            getString(R.string.scheduled_continue, appName)
    }

    /** The screen is reused (singleInstance): a Reset-break opening needs its own labels back. */
    private fun showSessionChoiceLabels() {
        findViewById<Button>(R.id.intervention_back_button).setText(R.string.intervention_back_to_study)
        findViewById<Button>(R.id.intervention_reel_button).apply {
            setText(R.string.intervention_watch_reel)
            visibility = View.VISIBLE
        }
        findViewById<Button>(R.id.intervention_break_button).setText(R.string.intervention_take_break)
    }

    /** Opens DisGret on the motivation step for that habit (one way into a session, ADR-0002). */
    private fun startScheduledHabit() {
        val habitId = intent.getStringExtra(StudyChecks.EXTRA_HABIT_ID)
        startActivity(MainActivity.openIntent(this, NativeActions.START_SCHEDULED, habitId))
        finish()
    }

    private fun snoozeScheduled() {
        val habitId = intent.getStringExtra(StudyChecks.EXTRA_HABIT_ID).orEmpty()
        val habitName = intent.getStringExtra(StudyChecks.EXTRA_HABIT_NAME).orEmpty()
        val minutes = intent.getIntExtra(StudyChecks.EXTRA_MINUTES, 0)
        if (StudyChecks.snooze(this, habitId, habitName, minutes)) {
            Toast.makeText(this, R.string.scheduled_snoozed, Toast.LENGTH_SHORT).show()
        }
        finish()
    }

    private fun setUpBreakOptions() {
        val options = mapOf(
            R.id.intervention_break_5 to 5,
            R.id.intervention_break_10 to 10,
            R.id.intervention_break_15 to 15,
        )
        options.forEach { (buttonId, minutes) ->
            val button = findViewById<Button>(buttonId)
            button.text = getString(R.string.intervention_break_minutes, minutes)
            button.setOnClickListener { takeBreak(minutes) }
        }
        findViewById<Button>(R.id.intervention_break_cancel).setOnClickListener { showChoices() }
    }

    private fun startCountdown(waitSeconds: Int) {
        val countdownText = findViewById<TextView>(R.id.intervention_countdown)
        val gret = findViewById<GretGuardView>(R.id.intervention_gret)
        val total = waitSeconds * MILLIS_PER_SECOND
        countdownText.text = getString(R.string.intervention_seconds, waitSeconds)
        countdown?.cancel()
        countdown = object : CountDownTimer(total, COUNTDOWN_STEP_MILLIS) {
            override fun onTick(millisLeft: Long) {
                countdownText.text =
                    getString(R.string.intervention_seconds, ceil(millisLeft / 1000.0).toInt())
                gret.remaining = millisLeft / total.toFloat()
            }

            override fun onFinish() {
                // Gret stays and keeps breathing while the student chooses.
                gret.remaining = 0f
                countdownText.visibility = View.GONE
                showChoices()
            }
        }.start()
    }

    private fun showChoices() {
        findViewById<View>(R.id.intervention_choices).visibility = View.VISIBLE
        findViewById<View>(R.id.intervention_break_options).visibility = View.GONE
    }

    private fun showBreakOptions() {
        findViewById<View>(R.id.intervention_choices).visibility = View.GONE
        findViewById<View>(R.id.intervention_break_options).visibility = View.VISIBLE
    }

    /** Đưa DisGret lên trước rồi đóng màn chặn. */
    private fun returnToStudy() {
        logChoice(EventQueue.CHOSE_STUDY)
        startActivity(MainActivity.openIntent(this, NativeActions.RESUME_FOCUS))
        finish()
    }

    /** Mở DisGret và chuyển thẳng tới Reels. */
    private fun watchReel() {
        logChoice(EventQueue.CHOSE_REEL)
        startActivity(MainActivity.openIntent(this, NativeActions.OPEN_REELS_DISTRACTED))
        finish()
    }

    /**
     * Người dùng đã chọn nghỉ thì đóng màn chặn để họ vào đúng app vừa mở, không kéo về DisGret.
     * Vì DisGret không mở lên nên hành động đi thẳng qua kênh thay vì qua Intent.
     */
    private fun takeBreak(minutes: Int) {
        if (isTrial) {
            Toast.makeText(this, R.string.intervention_trial_break, Toast.LENGTH_LONG).show()
            startActivity(MainActivity.openIntent(this))
        } else if (FocusGuardService.startBreak(minutes)) {
            EventQueue.add(this, EventQueue.CHOSE_BREAK, mapOf("minutes" to minutes))
            NativeActions.send(NativeActions.BREAK_STARTED, minutes)
        } else {
            // Phiên vừa hết giờ trong lúc đang ở màn này: không còn gì để nghỉ, về xem tổng kết.
            startActivity(MainActivity.openIntent(this))
        }
        finish()
    }

    private fun logChoice(type: String) {
        if (!isTrial) EventQueue.add(this, type)
    }

    override fun onStop() {
        super.onStop()
        // Covered rather than closed by a choice: the blocked app opened a screen of its own over
        // this one while starting (YouTube does ~6 s after a cold start), or Home / screen off.
        // FocusGuardService then treats a block of the same app within 5 s as the same opening.
        if (!isFinishing && !isTrial && !isScheduled) coveredAt = SystemClock.elapsedRealtime()
        // Người dùng bấm Home hoặc tắt màn hình: màn này xong việc. Lần mở app sau sẽ có màn mới
        // với đếm ngược từ đầu, không để một màn cũ nằm chờ ở phía sau.
        finish()
    }

    override fun onDestroy() {
        countdown?.cancel()
        isShowing = false
        super.onDestroy()
    }

    companion object {
        private const val EXTRA_APP_NAME = "app_name"
        private const val EXTRA_WAIT_SECONDS = "wait_seconds"
        private const val EXTRA_IS_TRIAL = "is_trial"
        private const val MILLIS_PER_SECOND = 1_000L
        private const val COUNTDOWN_STEP_MILLIS = 200L

        /** FocusGuardService đọc cờ này để không mở chồng màn chặn lên nhau. */
        @Volatile
        var isShowing = false
            private set

        /** When an intervention was last covered without a choice (elapsedRealtime), else 0. */
        @Volatile
        var coveredAt = 0L
            private set

        fun open(context: Context, appName: String, waitSeconds: Int) {
            context.startActivity(intentFor(context, appName, waitSeconds))
        }

        /** 2.2 Spec 023: at a habit's reminder time, over a blocked app; 5 seconds before choices. */
        fun openScheduled(
            context: Context,
            appName: String,
            habitId: String,
            habitName: String,
            minutes: Int,
        ) {
            val intent = intentFor(context, appName, SCHEDULED_WAIT_SECONDS)
                .putExtra(StudyChecks.EXTRA_HABIT_ID, habitId)
                .putExtra(StudyChecks.EXTRA_HABIT_NAME, habitName)
                .putExtra(StudyChecks.EXTRA_MINUTES, minutes)
            context.startActivity(intent)
        }

        private const val SCHEDULED_WAIT_SECONDS = 5

        /** Nút "Thử màn can thiệp" trong Cài đặt. */
        fun openTrial(context: Context, appName: String) {
            val intent = intentFor(context, appName, FocusGuardService.FIRST_WAIT_SECONDS)
                .putExtra(EXTRA_IS_TRIAL, true)
            context.startActivity(intent)
        }

        private fun intentFor(context: Context, appName: String, waitSeconds: Int): Intent =
            Intent(context, InterventionActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                .putExtra(EXTRA_APP_NAME, appName)
                .putExtra(EXTRA_WAIT_SECONDS, waitSeconds)
    }
}
