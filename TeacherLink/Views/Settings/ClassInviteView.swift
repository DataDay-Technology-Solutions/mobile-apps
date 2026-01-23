//
//  ClassInviteView.swift
//  Hall Pass
//
//  QR code class invite system
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct ClassInviteView: View {
    @Environment(\.dismiss) var dismiss
    let classroom: Classroom

    @State private var showShareSheet = false
    @State private var copiedToClipboard = false

    var inviteURL: String {
        "hallpass://join/\(classroom.classCode)"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Class info with new branding
                    VStack(spacing: 8) {
                        Circle()
                            .fill(AppTheme.gradient)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "paperplane.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            )

                        Text(classroom.name)
                            .font(.title2.bold())

                        Text(classroom.gradeLevel)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)

                    // QR Code
                    VStack(spacing: 12) {
                        Text("Scan to Join")
                            .font(.headline)

                        QRCodeView(content: inviteURL)
                            .frame(width: 200, height: 200)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .shadow(color: AppTheme.primary.opacity(0.2), radius: 10)

                        Text("Parents can scan this code to join your class")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Divider()
                        .padding(.horizontal, 40)

                    // Class code
                    VStack(spacing: 12) {
                        Text("Or share the class code")
                            .font(.headline)

                        HStack(spacing: 8) {
                            ForEach(Array(classroom.classCode), id: \.self) { char in
                                Text(String(char))
                                    .font(.title.bold().monospaced())
                                    .frame(width: 40, height: 50)
                                    .background(AppTheme.primary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }

                        Button {
                            UIPasteboard.general.string = classroom.classCode
                            withAnimation {
                                copiedToClipboard = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    copiedToClipboard = false
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: copiedToClipboard ? "checkmark" : "doc.on.doc")
                                Text(copiedToClipboard ? "Copied!" : "Copy Code")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(copiedToClipboard ? AppTheme.secondary : AppTheme.primary)
                        }
                    }

                    Divider()
                        .padding(.horizontal, 40)

                    // Share options
                    VStack(spacing: 16) {
                        Text("Share Invite")
                            .font(.headline)

                        HStack(spacing: 20) {
                            ShareButton(icon: "message.fill", label: "Message", color: AppTheme.secondary) {
                                showShareSheet = true
                            }

                            ShareButton(icon: "envelope.fill", label: "Email", color: AppTheme.primary) {
                                showShareSheet = true
                            }

                            ShareButton(icon: "square.and.arrow.up", label: "More", color: AppTheme.accent) {
                                showShareSheet = true
                            }
                        }
                    }

                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Join")
                            .font(.headline)

                        InstructionRow(number: 1, text: "Download the Hall Pass app")
                        InstructionRow(number: 2, text: "Tap 'Join a Class'")
                        InstructionRow(number: 3, text: "Enter code: \(classroom.classCode)")
                        InstructionRow(number: 4, text: "Start receiving updates!")
                    }
                    .padding()
                    .background(AppTheme.primary.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Invite Parents")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [
                    "Join \(classroom.name) on Hall Pass!\n\nClass Code: \(classroom.classCode)\n\nOr scan the QR code in the app."
                ])
            }
        }
    }
}

struct QRCodeView: View {
    let content: String

    var body: some View {
        if let qrImage = generateQRCode(from: content) {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            // Fallback placeholder
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray5))
                Image(systemName: "qrcode")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
            }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up the QR code
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }

        return UIImage(cgImage: cgImage)
    }
}

struct ShareButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: icon)
                            .foregroundColor(.white)
                    )

                Text(label)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AppTheme.primary)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(number)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                )

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

// Share sheet wrapper for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ClassInviteView(classroom: Classroom(
        id: "class1",
        name: "Mrs. Johnson's 1st Grade",
        gradeLevel: "1st Grade",
        teacherId: "teacher1",
        teacherName: "Mrs. Johnson",
        classCode: "ABC123",
        studentIds: [],
        parentIds: [],
        createdAt: Date(),
    ))
}
