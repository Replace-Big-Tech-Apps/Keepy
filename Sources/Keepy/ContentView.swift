import SwiftUI

struct ContentView: View {
    @Environment(ReminderStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ClockHeader()
                    if !store.notificationsAllowed { PermissionNotice() }
                    Composer()
                    ReminderSection(index: 1, title: "Upcoming", items: store.upcoming, sent: false)
                    if !store.sent.isEmpty {
                        ReminderSection(index: 2, title: "Sent", items: store.sent, sent: true)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .background(Orbis.canvas)
        .ignoresSafeArea(edges: .top)
    }
}

private struct TopBar: View {
    @Environment(ReminderStore.self) private var store

    var body: some View {
        HStack(spacing: 10) {
            Spacer()
            Text("Keepy").eyebrow(Orbis.ink, size: 10)
            Circle().fill(Orbis.alert).frame(width: 5, height: 5)
            Text(String(format: "%02d", store.upcoming.count)).eyebrow()
        }
        .padding(.horizontal, 20)
        .frame(height: WindowChrome.barHeight)
        .hairline(.bottom)
        .background(WindowChrome())
    }
}

private struct ClockHeader: View {
    @Environment(ReminderStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(store.now.formatted(date: .complete, time: .omitted)).eyebrow()
            Text(store.now.formatted(.dateTime.hour().minute()))
                .font(OrbisFont.pinstripe(76))
                .foregroundStyle(Orbis.ink)
                .monospacedDigit()
        }
    }
}

private struct PermissionNotice: View {
    @Environment(ReminderStore.self) private var store

    var body: some View {
        HStack(spacing: 10) {
            Circle().fill(Orbis.alert).frame(width: 6, height: 6)
            Text("Notifications are off, so reminders can't reach you.")
                .font(.system(size: 12))
                .foregroundStyle(Orbis.ink)
            Spacer()
            Button { store.openNotificationSettings() } label: {
                Text("Settings").eyebrow(Orbis.alert, size: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .overlay(RoundedRectangle(cornerRadius: Orbis.radiusXS).strokeBorder(Orbis.alert.opacity(0.6)))
    }
}

private struct Composer: View {
    @Environment(ReminderStore.self) private var store
    @State private var text = ""
    @State private var date = Composer.defaultDate()
    @FocusState private var focused: Bool

    private var canKeep: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty && date > store.now
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bell").font(.system(size: 11)).foregroundStyle(Orbis.inkWhisper)
                TextField("", text: $text, prompt: Text("Remind me to…")
                    .font(OrbisFont.display(9)).foregroundStyle(Orbis.inkWhisper))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($focused)
                    .onSubmit(keep)
            }
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background(RoundedRectangle(cornerRadius: Orbis.radiusXS).fill(Orbis.canvas))
            .overlay(RoundedRectangle(cornerRadius: Orbis.radiusXS).strokeBorder(focused ? Orbis.ink : Orbis.line))

            HStack(spacing: 0) {
                Chip(title: "+5 min") { date = store.now.addingTimeInterval(5 * 60) }
                Chip(title: "+15 min") { date = store.now.addingTimeInterval(15 * 60) }
                Chip(title: "+1 hr") { date = store.now.addingTimeInterval(60 * 60) }
                Chip(title: "9:00 tmrw") { date = Composer.tomorrowMorning() }
            }
            .overlay(RoundedRectangle(cornerRadius: Orbis.radiusXS).strokeBorder(Orbis.line))

            HStack(spacing: 12) {
                Text("At").eyebrow()
                DatePicker("", selection: $date, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .datePickerStyle(.field)
                Spacer()
                Button(action: keep) {
                    Text("Keep")
                        .eyebrow(canKeep ? Orbis.inkInverse : Orbis.inkWhisper, size: 9)
                        .frame(width: 84, height: 30)
                        .background(RoundedRectangle(cornerRadius: Orbis.radiusXS).fill(canKeep ? Orbis.ink : Orbis.surface))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!canKeep)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Orbis.radiusXS).fill(Orbis.canvasSoft))
        .overlay(RoundedRectangle(cornerRadius: Orbis.radiusXS).strokeBorder(Orbis.line))
        .onAppear { focused = true }
    }

    private func keep() {
        guard canKeep else { return }
        store.add(text, at: date)
        text = ""
        date = Composer.defaultDate()
    }

    /// Fifteen minutes from now, on the minute.
    static func defaultDate() -> Date {
        let soon = Date().addingTimeInterval(15 * 60)
        return Calendar.current.date(bySetting: .second, value: 0, of: soon) ?? soon
    }

    static func tomorrowMorning() -> Date {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return cal.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}

private struct ReminderSection: View {
    @Environment(ReminderStore.self) private var store
    let index: Int
    let title: String
    let items: [Reminder]
    let sent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(String(format: "%02d", index)).eyebrow(size: 8)
                Text(title).eyebrow(Orbis.inkMute, size: 8)
                Text("· \(items.count)").eyebrow(size: 8)
                Spacer()
                if sent {
                    Button { withAnimation { store.clearSent() } } label: {
                        Text("Clear").eyebrow(Orbis.inkMute, size: 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)
            .hairline(.bottom)

            if items.isEmpty {
                Text("Nothing to keep yet.")
                    .font(OrbisFont.pinstripe(26))
                    .foregroundStyle(Orbis.inkWhisper)
                    .padding(.vertical, 18)
            } else {
                ForEach(items) { reminder in
                    ReminderRow(reminder: reminder, sent: sent, next: !sent && reminder.id == items.first?.id)
                }
            }
        }
        .animation(.easeOut(duration: 0.2), value: items)
    }
}

private struct ReminderRow: View {
    @Environment(ReminderStore.self) private var store
    let reminder: Reminder
    let sent: Bool
    let next: Bool
    @State private var hover = false

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Text(reminder.date.formatted(.dateTime.hour().minute()))
                    .font(OrbisFont.pinstripe(30))
                    .monospacedDigit()
                    .foregroundStyle(Orbis.ink)
                Text(dayLabel).eyebrow(size: 7)
            }
            .frame(width: 84, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(reminder.text)
                    .font(.system(size: 13))
                    .foregroundStyle(Orbis.ink)
                    .lineLimit(2)
                Text(sent ? "Sent" : countdown)
                    .eyebrow(next ? Orbis.alert : Orbis.inkWhisper, size: 7)
            }
            Spacer(minLength: 0)
            if next { Circle().fill(Orbis.alert).frame(width: 6, height: 6) }
            IconButton(symbol: "xmark", help: sent ? "Remove" : "Cancel reminder") {
                withAnimation { store.remove(reminder) }
            }
            .opacity(hover ? 1 : 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(hover ? Orbis.surface : .clear)
        .hairline(.bottom)
        .opacity(sent ? 0.5 : 1)
        .contentShape(Rectangle())
        .onHover { hover = $0 }
    }

    private var dayLabel: String {
        let cal = Calendar.current
        if cal.isDateInToday(reminder.date) { return "Today" }
        if cal.isDateInTomorrow(reminder.date) { return "Tomorrow" }
        if cal.isDateInYesterday(reminder.date) { return "Yesterday" }
        return reminder.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    private var countdown: String {
        let seconds = Int(reminder.date.timeIntervalSince(store.now))
        if seconds < 60 { return "in \(seconds)s" }
        let minutes = seconds / 60
        if minutes < 60 { return "in \(minutes) min" }
        let hours = minutes / 60
        if hours < 24 { return "in \(hours) h \(minutes % 60) min" }
        return "in \(hours / 24) d \(hours % 24) h"
    }
}
