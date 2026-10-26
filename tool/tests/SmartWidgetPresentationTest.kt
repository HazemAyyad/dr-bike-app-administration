package com.application.doctorbike

import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

// Standalone JVM regression checks; uses the same policy as the Android widget.
fun main() {
    val utc = TimeZone.getTimeZone("UTC")
    fun at(hour: Int, minute: Int = 0): Long = Calendar.getInstance(utc).apply {
        clear()
        set(2026, Calendar.OCTOBER, 26, hour, minute)
    }.timeInMillis
    var checks = 0
    fun verify(name: String, result: Boolean) {
        check(result) { name }
        checks++
    }
    fun clock(hour: Int, minute: Int = 0) =
        SmartWidgetPresentation.formatLastRead(at(hour, minute), utc, Locale.US)

    verify("midnight is 12 AM", clock(0) == "26/10 12:00 صباحًا")
    verify("before noon is AM", clock(11, 59) == "26/10 11:59 صباحًا")
    verify("noon is 12 PM", clock(12) == "26/10 12:00 مساءً")
    verify("afternoon uses 12-hour clock", clock(15, 7) == "26/10 03:07 مساءً")
    verify("late night is PM", clock(23, 59) == "26/10 11:59 مساءً")
    verify("timezone changes both the date and AM/PM",
        SmartWidgetPresentation.formatLastRead(at(23), TimeZone.getTimeZone("GMT+03:00"), Locale.US)
            == "27/10 02:00 صباحًا")
    verify("unknown read time is never fabricated", SmartWidgetPresentation.formatLastRead(0L) == "—")

    verify("explicit OFF stays OFF even if cached state changes",
        !SmartWidgetPresentation.desiredState(true, false) &&
            !SmartWidgetPresentation.desiredState(false, false))
    verify("explicit ON stays ON even if cached state changes",
        SmartWidgetPresentation.desiredState(true, true) &&
            SmartWidgetPresentation.desiredState(false, true))
    verify("old widget intents retain their prior action",
        !SmartWidgetPresentation.desiredState(true, null) &&
            SmartWidgetPresentation.desiredState(false, null))

    val requested = mapOf("1" to true, "2" to false)
    verify("all requested switches must be confirmed",
        SmartWidgetPresentation.requestedStatesMatch(requested, mapOf("1" to true, "2" to false)))
    verify("a different reported state is not confirmation",
        !SmartWidgetPresentation.requestedStatesMatch(requested, mapOf("1" to false, "2" to false)))
    verify("a missing switch is not confirmation",
        !SmartWidgetPresentation.requestedStatesMatch(requested, mapOf("1" to true)))
    verify("an unreadable switch is not confirmation",
        !SmartWidgetPresentation.requestedStatesMatch(requested, mapOf("1" to true, "2" to "unknown")))
    verify("no requested data cannot confirm an operation",
        !SmartWidgetPresentation.requestedStatesMatch(emptyMap(), emptyMap<String, Any>()))
    verify("fractional values cannot be mistaken for OFF",
        SmartWidgetPresentation.switchBoolean(0.5) == null)
    println("$checks smart widget policy checks passed")
}
