//
//  View+Extensions.swift
//  TeacherLink
//

import SwiftUI

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension Color {
    static let teacherLinkBlue = Color(red: 0.2, green: 0.5, blue: 0.9)
    static let teacherLinkGreen = Color(red: 0.2, green: 0.8, blue: 0.5)
    static let teacherLinkOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    static let teacherLinkPurple = Color(red: 0.6, green: 0.3, blue: 0.9)
}

extension Date {
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    func formatted(style: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
}
