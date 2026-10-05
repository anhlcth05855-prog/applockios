import SwiftUI

public struct NoteEditorSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var existingNote: SecretNote?
    var onSave: (SecretNote) -> Void
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isPinned: Bool = false
    
    public init(existingNote: SecretNote? = nil, onSave: @escaping (SecretNote) -> Void) {
        self.existingNote = existingNote
        self.onSave = onSave
    }
    
    public var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Header
                HStack {
                    Button("Hủy") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Text(existingNote != nil ? "Sửa Ghi Chú" : "Ghi Chú Mới")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    
                    Spacer()
                    
                    Button("Lưu") {
                        saveNote()
                    }
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppColors.cyan)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty && content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                VStack(spacing: 12) {
                    // Pinned toggle
                    HStack {
                        Image(systemName: isPinned ? "pin.fill" : "pin")
                            .foregroundColor(isPinned ? AppColors.amber : AppColors.textSecondary)
                        Text("Ghim lên đầu")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Toggle("", isOn: $isPinned)
                            .labelsHidden()
                            .tint(AppColors.cyan)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    
                    // Title field
                    TextField("Tiêu đề ghi chú bí mật...", text: $title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                        .padding(14)
                        .background(AppColors.cardBackground)
                        .cornerRadius(12)
                    
                    // Content field
                    ZStack(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("Nội dung riêng tư (mật khẩu tài khoản, số thẻ, mã bảo mật, seed phrase...)...")
                                .font(.system(size: 15))
                                .foregroundColor(AppColors.textMuted)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                        }
                        
                        TextEditor(text: $content)
                            .font(.system(size: 15))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(10)
                            .scrollContentBackground(.hidden)
                            .background(AppColors.cardBackground)
                            .cornerRadius(12)
                    }
                    .frame(minHeight: 250)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .onAppear {
            if let note = existingNote {
                title = note.title
                content = note.content
                isPinned = note.isPinned
            }
        }
    }
    
    private func saveNote() {
        let note = SecretNote(
            id: existingNote?.id ?? UUID().uuidString,
            title: title.isEmpty ? "Ghi chú không tiêu đề" : title,
            content: content,
            updatedAt: Date(),
            isPinned: isPinned
        )
        onSave(note)
        HapticManager.shared.notification(.success)
        presentationMode.wrappedValue.dismiss()
    }
}
