# CarPlayMaster (Rootless) 🚗💨

**CarPlayMaster** là tweak jailbreak toàn diện dành cho **Apple CarPlay**, được tối ưu hóa đặc biệt cho **iPhone 6s Plus (chip Apple A9, iOS 15.0 - 15.8.3 Rootless - Dopamine / palera1n)**, hỗ trợ mở rộng cho các thiết bị từ **iOS 14.0 đến iOS 16.x** và tương thích với hầu hết các dòng xe trên thị trường (màn hình chuẩn 7-8", màn hình dài 10.25" - 12.3", màn hình dọc kiểu Tesla/Ford).

---

## 🌟 Các Tính Năng Nổi Bật

### 1. Đưa Mọi Ứng Dụng Lên CarPlay (Bypass App Restrictions)
- Cho phép hiển thị và mở bất kỳ ứng dụng nào: **YouTube, TikTok, Netflix, Google Maps, VietMap Live, Zing MP3, Spotify, Safari, Chrome, VTV Go, Games...** trực tiếp trên màn hình xe.
- Ép xoay ngang tự động (**Force Landscape**) cho các ứng dụng vốn chỉ hỗ trợ màn hình dọc.
- Thanh điều khiển Dock nổi thông minh:
  - 🔘 **Home Button**: Quay lại màn hình chính CarPlay.
  - 🔄 **Rotate Button**: Đổi hướng xoay ứng dụng mượt mà.
  - ⛶ **Fullscreen Toggle**: Phóng to toàn màn hình loại bỏ thanh viền.
  - ❌ **Close Button**: Đóng app và trở lại giao diện gốc.

### 2. Mở Khóa Giới Hạn An Toàn Khi Xe Đang Chạy (Bypass Speed Lock)
- **Gõ bàn phím khi xe đang di chuyển**: Bỏ hoàn toàn giới hạn khóa bàn phím của Apple khi xe vào số hoặc lăn bánh (`CRVehiclePolicyMonitor`).
- **Không giới hạn cuộn trang (No 12-Item Truncation)**: Cuộn danh bạ, danh sách bài hát, danh sách địa điểm thoải mái mà không bị giới hạn 12 mục như CarPlay mặc định.
- **Mở khóa cảm ứng toàn phần**: Tương tác cảm ứng liên tục không bị gián đoạn.

### 3. Tương Thích Mọi Kích Thước Màn Hình Xe (Multi-Car Display Grid)
- **Tùy chỉnh số cột icon (Columns)**:
  - Hỗ trợ **4 Cột, 5 Cột, 6 Cột, 7 Cột**.
  - Rất thích hợp cho các dòng xe có màn hình siêu dài 10.25" hoặc 12.3" (Mercedes-Benz, BMW, Hyundai Tucson/Santa Fe, Kia K5/Carnival, Mazda...).
- **Tùy chỉnh số dòng icon (Rows)**: 2 dòng hoặc 3 dòng (phù hợp xe có màn hình vuông hoặc màn hình dọc như Ford Ranger/Mach-E, Subaru, Tesla style).
- **Thu phóng icon (Scale)**: Tùy chỉnh kích thước biểu tượng từ 40px đến 60px để hiển thị sắc nét trên cả màn hình độ phân giải thấp và cao.
- **Ẩn nhãn tên ứng dụng (Hide Labels)**: Tạo giao diện xe tối giản, sang trọng chuẩn xe sang.
- **Tùy chọn vị trí Dock**: Tự động theo tay lái thuận (LHD / RHD), hoặc cố định bên Trái / bên Phải.

### 4. Tiện Ích Độc Quyền Cho iPhone 6s Plus (A9 Thermal & Battery Monitor)
- iPhone 6s Plus khi vừa cắm sạc trên xe vừa chạy 4G/GPS dẫn đường rất nhanh nóng máy và gây sụt nguồn/giật lag.
- **Hiển thị % Pin thật & Biểu tượng sạc** ngay trên thanh trạng thái (Status Bar) CarPlay.
- **Giám sát nhiệt độ chip A9**:
  - 🟢 **Xanh lá**: Nhiệt độ lý tưởng.
  - 🟡 **Vàng**: Máy ấm nhẹ.
  - 🟠 **Cam**: Máy bắt đầu nóng.
  - 🔴 **Đỏ**: Cảnh báo quá nhiệt! Giúp lái xe kịp thời bật điều hòa chĩa vào điện thoại để bảo vệ pin và chống nổ.

### 5. Sử Dụng Độc Lập & Chống Tắt Màn Hình (Anti-Sleep)
- **Chống tự động khóa màn hình**: Giữ màn hình iPhone luôn sáng hoặc không bị sleep khi đang cắm CarPlay.
- **Dùng độc lập**: Hành khách ngồi ghế phụ có thể cầm điện thoại nhắn tin, lướt web mà không làm ngắt quãng bản đồ đang chạy trên màn hình xe.
- **Chống đóng băng tiến trình (`SBSuspendedUnderLockManager`)**: Ứng dụng trên xe (nhạc, video) tiếp tục phát mượt mà kể cả khi bấm khóa màn hình iPhone.

### 6. Hình Nền AMOLED Black & Bảo Vệ Riêng Tư
- **AMOLED Pure Black**: Chuyển hình nền CarPlay sang đen tuyền 100% giúp giảm chói mắt khi lái xe ban đêm và tiết kiệm điện năng.
- **Bảo mật tin nhắn**: Ẩn nội dung xem trước của thông báo Zalo, Messenger, SMS, Telegram khi có người lạ hoặc khách đi cùng trên xe.

---

## 🛠 Hướng Dẫn Biên Dịch & Cài Đặt

### Cách 1: Tự động build file `.deb` qua GitHub Actions (Khuyên Dùng)
Không cần máy Mac, không cần cài đặt phần mềm phức tạp trên máy tính:
1. Đưa toàn bộ mã nguồn này lên một GitHub Repository cá nhân của bạn.
2. Vào mục **Actions** trên GitHub repository.
3. Chọn workflow **Build CarPlayMaster Deb (Rootless)** và nhấn **Run workflow**.
4. Chờ 1-2 phút, sau khi hoàn thành hãy vào mục **Artifacts** tải file `CarPlayMaster-Rootless-deb.zip` về và giải nén sẽ được file `.deb`.

### Cách 2: Biên dịch thủ công bằng Theos (macOS / Linux / WSL)
Yêu cầu đã cài đặt Theos và toolchain iOS:
```bash
# Thiết lập đường dẫn Theos
export THEOS=~/theos

# Biên dịch ra gói .deb rootless
make clean
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless
```
File `.deb` hoàn chỉnh sẽ nằm trong thư mục `packages/`.

---

## 📱 Cài Đặt Lên iPhone 6s Plus (iOS 15 Rootless)

1. Gửi file `.deb` sang iPhone (qua AirDrop, Google Drive, hoặc Filza File Manager).
2. Mở ứng dụng **Sileo** hoặc **Zebra** trên iPhone đã jailbreak.
3. Chọn file `.deb` và nhấn **Cài đặt (Install)**.
4. Nhấn **Khởi động lại SpringBoard (Respring)** sau khi cài xong.
5. Vào **Cài đặt (Settings) -> CarPlay Master** để tùy chỉnh theo ý thích.
6. Cắm cáp kết nối với xe hơi hoặc kết nối không dây để trải nghiệm!

---

## 🚘 Danh Sách Xe & Thiết Bị Đã Thử Nghiệm Thành Công
- **Thiết bị**: iPhone 6s Plus, iPhone 7 Plus, iPhone 8 Plus, iPhone X, iPhone 11/12/13/14 (Dopamine 2.x, palera1n rootless).
- **Hãng xe**: Honda (CR-V, Civic), Toyota (Cross, Camry), Mazda (Mazda 3, CX-5), Hyundai (Santa Fe, Tucson), Kia (Seltos, Carnival), Mercedes-Benz (MBUX), BMW (iDrive), Ford (Sync 3/4), các màn hình Android Carlinkit / Zestech / Teyes / Android Box.
