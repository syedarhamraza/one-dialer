package com.syedarhamraza.recorder.shell

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import com.syedarhamraza.recorder.RecordingService
import kotlin.concurrent.thread

/**
 * Every few hours while paired, checks that the helper still runs and starts it again if it
 * doesn't, so a stopped helper shows up before a call is missed rather than after. When it can't
 * start by itself, [ShellHelper.restart] posts the "tap to start" notification.
 */
class Watchdog : JobService() {
    companion object {
        private const val JOB = 1
        private const val EVERY_MS = 6 * 3_600_000L

        /** Once paired; keeps an already scheduled job (and its timing) as it is. */
        fun schedule(context: Context) {
            val jobs = context.getSystemService(JobScheduler::class.java)
            if (jobs.getPendingJob(JOB) != null) return
            jobs.schedule(JobInfo.Builder(JOB, ComponentName(context, Watchdog::class.java))
                .setPeriodic(EVERY_MS)
                .setPersisted(true) // survives a reboot (RECEIVE_BOOT_COMPLETED)
                .build())
        }

        fun cancel(context: Context) = context.getSystemService(JobScheduler::class.java).cancel(JOB)
    }

    override fun onStartJob(params: JobParameters): Boolean {
        if (RecordingService.current != null) return false // recording, so it runs
        thread {
            try {
                ShellHelper.restart(applicationContext)
            } finally {
                jobFinished(params, false)
            }
        }
        return true
    }

    override fun onStopJob(params: JobParameters) = false
}
