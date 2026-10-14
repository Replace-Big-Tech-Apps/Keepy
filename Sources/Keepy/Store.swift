import AppKit
import Foundation
import Observation
import UserNotifications

struct Reminder: Codable, Identifiable, Hashable {
    var id = UUID()
    var text: String
    var date: Date
}

/// Reminders live in a JSON file; each one is also a pending system notification,
/// so macOS delivers it on time even when Keepy isn't running.
@MainActor @Observable
final class ReminderStore {
    static let shared = ReminderStore()

    private(set) var reminders: [Reminder] = []
    private(set) var notificationsAllowed = true
    /// Ticks every second so the clock, countdowns and Upcoming/Sent split stay live.
    private(set) var now = Date()

    var upcoming: [Reminder] { reminders.filter { $0.date > now }.sorted { $0.date < $1.date } }
    var sent: [Reminder] { reminders.filter { $0.date <= now }.sorted { $0.date > $1.date } }

    private let center = UNUserNotificationCenter.current()
    private let fileURL: URL = {
        let dir = URL.applicationSupportDirectory.appending(path: "Keepy")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appending(path: "reminders.json")
    }()

    private init() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Reminder].self, from: data) {
            reminders = saved
        }
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            MainActor.assumeIsolated { ReminderStore.shared.now = Date() }
        }
    }

    func start() {
        Task {
            _ = try? await center.requestAuthorization(options: [.alert, .sound])
            await refreshPermission()
            await resync()
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            Task { await ReminderStore.shared.refreshPermission() }
        }
    }

    func add(_ text: String, at date: Date) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, date > Date() else { return }
        let reminder = Reminder(text: trimmed, date: date)
        reminders.append(reminder)
        schedule(reminder)
        save()
    }

    func remove(_ reminder: Reminder) {
        reminders.removeAll { $0.id == reminder.id }
        center.removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
        save()
    }

    func clearSent() {
        reminders.removeAll { $0.date <= now }
        save()
    }

    func openNotificationSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    private func refreshPermission() async {
        let settings = await center.notificationSettings()
        // Only nag once the user has actually said no.
        notificationsAllowed = settings.authorizationStatus != .denied
    }

    /// Re-registers any upcoming reminder the system has lost (e.g. after a reinstall).
    private func resync() async {
        let pending = Set(await center.pendingNotificationRequests().map(\.identifier))
        for reminder in upcoming where !pending.contains(reminder.id.uuidString) {
            schedule(reminder)
        }
    }

    private func schedule(_ reminder: Reminder) {
        let content = UNMutableNotificationContent()
        content.title = reminder.text
        content.sound = .default
        let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)
        center.add(UNNotificationRequest(identifier: reminder.id.uuidString, content: content, trigger: trigger))
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(reminders) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
