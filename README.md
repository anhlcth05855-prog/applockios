# AppLock - Lock & Guard Private (iOS Version)

Phiên bản iOS của ứng dụng **AppLock - Lock & Guard Private** (chuyển đổi và nâng cấp từ phiên bản Android tại `C:\Users\ASUS\Downloads\applock`), được xây dựng hoàn toàn bằng **Swift 5 & SwiftUI**, tuân thủ nghiêm ngặt các tiêu chuẩn bảo mật của Apple và hỗ trợ từ iOS 16.0 trở lên.

---

## 🚀 Các Tính Năng Chính (Features)

### 1. Khóa Ứng Dụng Chuyên Sâu (App Locker)
- **Hỗ trợ Screen Time API (iOS 16+)**: Tích hợp các framework chính thức của Apple bao gồm `FamilyControls` và `ManagedSettings` để áp dụng khiên bảo vệ (Shield) lên các ứng dụng đã chọn.
- **Tự động hóa qua Apple Shortcuts (Phím tắt)**: Tích hợp sẵn hướng dẫn tương tác từng bước (Interactive Guide) giúp kích hoạt AppLock tức thì 0.01 giây mỗi khi người dùng mở bất kỳ ứng dụng nào (Safari, Facebook, Messenger, Zalo, YouTube, VCB Digibank, MoMo...).
- **Khóa đề xuất thông minh**: Nút "Khóa toàn bộ đề xuất" giúp bảo vệ ngay các ứng dụng tài chính và mạng xã hội chỉ với 1 chạm.

### 2. Đa Dạng Phương Thức Xác Thực (Authentication)
- **Mã PIN 4 số**: Bàn phím số phong cách Cyber độc quyền với phản hồi xúc giác rung (Haptic Feedback) qua `UIImpactFeedbackGenerator`, hiệu ứng rung lắc (Shake Effect) sinh động khi nhập sai.
- **Hình Vẽ Mẫu (Pattern Lock)**: Ma trận 3x3 điểm vẽ nối đường ray neon phát quang, bắt điểm mượt mà theo cử chỉ ngón tay.
- **Sinh trắc học Face ID / Touch ID**: Tích hợp bảo mật phần cứng qua `LocalAuthentication` (`LAContext`).
- **Khôi phục mật khẩu**: Thiết lập câu hỏi bảo mật bí mật để mở khóa khẩn cấp khi quên mật mã.
- **Chính sách khóa lại (Re-lock Policy)**: Tùy chọn khóa ngay khi thoát, khóa khi tắt màn hình, hoặc sau 1 phút.

### 3. Bắt Kẻ Xâm Nhập (Intruder Selfie)
- Tự động và âm thầm kích hoạt **Camera trước** qua `AVFoundation` để chụp lại khuôn mặt kẻ tò mò khi họ nhập sai mật mã quá số lần quy định (1 - 3 lần).
- Nhật ký xâm nhập lưu trữ chi tiết: hình ảnh rõ nét, tên ứng dụng bị cố tình mở, mốc thời gian và số lần nhập sai.

### 4. Két Riêng Tư (Private Vault)
- **Ảnh & Video Bí Mật**: Nhập ảnh/video từ Thư viện qua `PhotosPicker` và lưu trữ cách ly hoàn toàn trong Document Sandbox bảo mật của App, không lộ ra Thư viện ảnh bên ngoài.
- **Trình xem đa phương tiện tích hợp**: Hỗ trợ xem ảnh phóng to, trình phát video `VideoPlayer` mượt mà, và tính năng "Khôi phục về Thư viện ảnh" khi cần.
- **Ghi Chú Khóa (Secret Notes)**: Trình tạo và quản lý ghi chú bí mật (mã thẻ ATM, tài khoản, seed phrase crypto...) hỗ trợ ghim ưu tiên lên đầu.

### 5. Thiết Kế Cyber Dark Luxury
- Bảng màu tối Cyber sang trọng (`#0A0F1D`, `#131B2E`, `#1A233A`) kết hợp điểm nhấn Neon Cyan (`#00E5FF`) và Emerald (`#00E676`).
- Thanh điều hướng nổi (Floating Bottom Bar) hiện đại với hiệu ứng phản xạ ánh sáng (Glassmorphism).

---

## 📁 Cấu Trúc Thư Mục Dự Án (Project Structure)

```
applock-ios/
├── AppLock.xcodeproj/                   # File dự án Xcode chuẩn
│   └── project.pbxproj
├── AppLock/
│   ├── AppLockApp.swift                 # Entry point chính của ứng dụng SwiftUI
│   ├── Info.plist                       # Cấu hình các quyền riêng tư (Camera, Face ID, Photos)
│   ├── Assets.xcassets/                 # Quản lý AppIcon và màu sắc hệ thống
│   │   ├── AppIcon.appiconset/
│   │   └── AccentColor.colorset/
│   ├── Theme/
│   │   └── AppColors.swift              # Bảng màu Cyber Dark & Color extensions
│   ├── Models/
│   │   ├── AppItem.swift                # Model dữ liệu ứng dụng & danh sách mặc định
│   │   ├── IntruderRecord.swift         # Model nhật ký kẻ xâm nhập
│   │   ├── VaultItem.swift              # Model ảnh & video trong két
│   │   ├── SecretNote.swift             # Model ghi chú bí mật
│   │   └── LockType.swift               # Enums phương thức khóa & chính sách khóa lại
│   ├── Services/
│   │   ├── AppLockManager.swift         # Quản lý State chính & lưu trữ UserDefaults
│   │   ├── ScreenTimeManager.swift      # Quản lý FamilyControls & ManagedSettings (Screen Time)
│   │   ├── BiometricManager.swift       # Quản lý Face ID / Touch ID (LocalAuthentication)
│   │   ├── CameraManager.swift          # Chụp ảnh camera trước ngầm (AVCaptureSession)
│   │   ├── VaultManager.swift           # Quản lý tệp két ảnh/video & xuất ra Photos
│   │   └── HapticManager.swift          # Rung phản hồi xúc giác
│   └── Views/
│       ├── MainTabView.swift            # Điều hướng 4 tab chính với thanh bar nổi
│       ├── Components/
│       │   ├── GlassCard.swift          # Thẻ hiệu ứng kính mờ
│       │   ├── CyberHeader.swift        # Tiêu đề Cyber với badge neon
│       │   └── NeonBadge.swift          # Huy hiệu trạng thái phát quang
│       ├── Security/
│       │   ├── PinPadView.swift         # Bàn phím số 4 số với dot indicator
│       │   ├── PatternLockView.swift    # Ma trận vẽ hình khóa 3x3
│       │   ├── LockScreenOverlayView.swift # Màn hình khóa toàn phần
│       │   └── SecuritySetupFlowView.swift # Luồng thiết lập mật mã lần đầu / đổi mật mã
│       ├── AppLock/
│       │   ├── AppLockListView.swift    # Tab 1: Danh sách ứng dụng, tìm kiếm, lọc
│       │   ├── AppRowView.swift         # Dòng ứng dụng với công tắc bật/tắt
│       │   └── ShortcutsGuideView.swift # Hướng dẫn khóa qua Apple Shortcuts
│       ├── Vault/
│       │   ├── VaultView.swift          # Tab 2: Két riêng tư (Ảnh, Video, Ghi chú)
│       │   ├── NoteEditorSheet.swift    # Trình soạn thảo ghi chú bảo mật
│       │   └── MediaDetailView.swift    # Xem chi tiết ảnh/video & khôi phục
│       ├── Intruder/
│       │   └── IntruderLogView.swift    # Tab 3: Nhật ký và ảnh chụp kẻ gian
│       └── Settings/
│           ├── SettingsView.swift       # Tab 4: Cài đặt phương thức, quy tắc khóa
│           └── PermissionStatusView.swift # Dashboard trạng thái quyền hệ thống
└── README.md
```

---

## 🛠 Hướng Dẫn Mở & Chạy Dự Án Trên Xcode

### Bước 1: Mở dự án
1. Khởi động **Xcode** trên máy Mac.
2. Chọn **Open a project or file** và điều hướng tới thư mục `applock-ios`, chọn file:
   ```
   AppLock.xcodeproj
   ```

### Bước 2: Cấu hình Signing (Chữ ký nhà phát triển)
1. Trong thanh điều hướng bên trái của Xcode, nhấn vào biểu tượng dự án gốc **AppLock** (ở trên cùng).
2. Chọn tab **Signing & Capabilities**.
3. Tại mục **Team**, chọn tài khoản Apple ID cá nhân của bạn (Personal Team) hoặc tài khoản Apple Developer.
4. Xcode sẽ tự động tạo hồ sơ provisioning profile phù hợp.

### Bước 3: Chạy trên Thiết bị thật (iPhone qua cáp) hoặc Simulator
1. Kết nối iPhone của bạn vào máy Mac bằng cáp USB / Lightning / Type-C.
2. Trên thanh công cụ phía trên cạnh nút Run, chọn thiết bị iPhone của bạn (hoặc chọn bất kỳ máy ảo nào như *iPhone 15 Pro / iPhone 16*).
3. Nhấn nút **Run** (biểu tượng tam giác ▶️ hoặc tổ hợp phím `Command + R`).
4. Khi ứng dụng cài đặt lần đầu trên iPhone thật:
   - Vào **Cài đặt (Settings) trên iPhone** -> **Cài đặt chung (General)** -> **Quản lý VPN & Thiết bị (VPN & Device Management)** -> Chọn tài khoản phát triển của bạn và bấm **Tin cậy (Trust)**.
   - Quay lại màn hình chính và mở **AppLock**!
