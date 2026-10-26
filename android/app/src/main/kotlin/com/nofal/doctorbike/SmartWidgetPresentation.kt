package com.application.doctorbike

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone

internal object SmartWidgetPresentation {
    fun formatLastRead(
        timestamp: Long,
        zone: TimeZone = TimeZone.getDefault(),
        locale: Locale = Locale.getDefault(),
    ): String {
        if (timestamp <= 0L) return "—"
        val calendar = Calendar.getInstance(zone).apply { timeInMillis = timestamp }
        val period = if (calendar.get(Calendar.AM_PM) == Calendar.AM) "صباحًا" else "مساءً"
        val clock = SimpleDateFormat("dd/MM hh:mm", locale).apply { timeZone = zone }
        return "${clock.format(Date(timestamp))} $period"
    }

    // The action is chosen when rendering the button, not recomputed from a
    // potentially different cached state when Android delivers the click.
    fun desiredState(renderedActive: Boolean, explicitTarget: Boolean?): Boolean =
        explicitTarget ?: !renderedActive

    fun switchBoolean(value: Any?): Boolean? = when (value) {
        is Boolean -> value
        is Number -> when (value.toDouble()) { 0.0 -> false; 1.0 -> true; else -> null }
        is String -> when (value.lowercase(Locale.ROOT)) {
            "true", "1" -> true
            "false", "0" -> false
            else -> null
        }
        else -> null
    }

    fun requestedStatesMatch(
        expected: Map<String, Boolean>,
        reported: Map<String, *>,
    ): Boolean = expected.isNotEmpty() && expected.all { (dp, target) ->
        switchBoolean(reported[dp]) == target
    }
}
