# Quy tắc Phát triển và Kiến trúc Dự án (SMS Navigator)

Tài liệu này quy định các nguyên tắc thiết kế, kiến trúc phần mềm, và chuẩn mực viết code cho dự án. Mọi tác vụ phát triển code trong dự án bắt buộc phải tuân thủ nghiêm ngặt các quy tắc dưới đây.

---

## 1. Quản lý State: BLoC & Equatable

- **Thư viện chuẩn**: Sử dụng `flutter_bloc` và `bloc`.
- **State Class**:
  - Bắt buộc kế thừa từ `Equatable`.
  - Khai báo constructor là `const`.
  - Tất cả các thuộc tính (fields) phải là `final` (đảm bảo tính bất biến - immutability).
  - Triển khai đầy đủ getter `List<Object?> get props => [...]` chứa tất cả các trường dữ liệu của State để so sánh giá trị chính xác và tối ưu số lần rebuild UI.
  - Cập nhật State thông qua phương thức `copyWith(...)`, tuyệt đối không mutate (sửa đổi trực tiếp) State hiện tại.
- **Event Class**:
  - Bắt buộc kế thừa từ `Equatable`.
  - Khai báo constructor `const`.
- **Ví dụ chuẩn**:
  ```dart
  import 'package:equatable/equatable.dart';

  class ExampleState extends Equatable {
    final bool isLoading;
    final String? errorMessage;
    final List<String> items;

    const ExampleState({
      this.isLoading = false,
      this.errorMessage,
      this.items = const [],
    });

    ExampleState copyWith({
      bool? isLoading,
      String? errorMessage,
      List<String>? items,
    }) {
      return ExampleState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        items: items ?? this.items,
      );
    }

    @override
    List<Object?> get props => [isLoading, errorMessage, items];
  }
  ```

---

## 2. Hạn chế Code Generation (Minimal Generated Code)

- **Nguyên tắc**: Hạn chế tối đa việc thêm và sử dụng các thư viện sinh code như `build_runner`, `freezed`, `@JsonSerializable`,...
- **Mục tiêu**:
  - Giảm thời gian build dự án.
  - Tránh các file rác phát sinh (`*.g.dart`, `*.freezed.dart`).
  - Hạn chế xung đột version giữa các package build runner và SDK.
  - Giữ codebase minh bạch, dễ trace và debug trực tiếp.
- **Thực thi**:
  - Tự viết tay các hàm: `copyWith`, `props` (Equatable), `toMap` / `fromMap` (hoặc `toJson` / `fromJson`), constructor.
  - Sử dụng các mẫu code ngắn gọn, rõ ràng.

---

## 3. Kiến trúc 3 Tầng: UI - Controller (BLoC) - Data

Kiến trúc phân tầng rõ ràng, đảm bảo luồng dữ liệu một chiều (Unidirectional Data Flow):

```
┌─────────────────────────────────────────────────────────┐
│                    TẦNG UI (VIEW)                       │
│    - Screens / Pages                                    │
│    - Widgets / Components                               │
└───────────────────────────┬─────────────────────────────┘
                            │ (Events / BlocBuilder)
┌───────────────────────────▼─────────────────────────────┐
│               TẦNG CONTROLLER (BLOC)                    │
│    - BLoC (Events -> States)                            │
│    - Điều phối luồng nghiệp vụ                          │
└───────────────────────────┬─────────────────────────────┘
                            │ (Use Cases)
┌───────────────────────────▼─────────────────────────────┐
│                    TẦNG DATA                            │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │                   Repositories                    │  │
│  │   - Đại diện cho từng Use Case cụ thể             │  │
│  │   - 1 Repo có thể điều phối nhiều Services        │  │
│  │   - Xử lý mapping model -> entity & bắt lỗi       │  │
│  └─────────────────────────┬─────────────────────────┘  │
│                            │ (CRUD / SDK calls)         │
│  ┌─────────────────────────▼─────────────────────────┐  │
│  │                     Services                      │  │
│  │   - Giao tiếp Backend (Firebase) & Device APIs    │  │
│  │   - FirestoreService, AuthService, SmsService...  │  │
│  └───────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### 3.1. Tầng UI (Presentation Layer)
- Chỉ chịu trách nhiệm hiển thị giao diện và bắt sự kiện người dùng (onPressed, onSubmitted,...).
- Gửi sự kiện vào BLoC qua `context.read<MyBloc>().add(MyEvent())`.
- Lắng nghe sự thay đổi của State thông qua `BlocBuilder`, `BlocListener`, `BlocConsumer`, hoặc `BlocSelector`.
- **Tuyệt đối cấm**:
  - Không chứa logic tính toán nghiệp vụ phức tạp.
  - Không gọi trực tiếp vào Repository, Service, hay Firebase SDK.

### 3.2. Tầng Controller (BLoC Layer)
- Nhận Event từ UI, xử lý logic điều phối.
- Gọi các phương thức của **Repository** để lấy dữ liệu hoặc thực thi thay đổi.
- Emit State tương ứng (Loading, Success, Failure,...).
- **Tuyệt đối cấm**:
  - Không gọi trực tiếp xuống Service hoặc gọi Firebase SDK.
  - Không giữ tham chiếu tới `BuildContext` hoặc Flutter Widgets trong BLoC.

### 3.3. Tầng Data: Repository & Services (Tuân thủ Dependency Injection)
Khối Data được tách thành 2 tầng con:

#### a. Repository:
- Là điểm tiếp xúc duy nhất giữa Tầng Controller (BLoC) và Tầng Data.
- **Mỗi hàm trong Repository đại diện cho 1 Use Case cụ thể** của ứng dụng (ví dụ: `sendSmsAndRecordTransaction()`, `getNavigationalCoordinates()`, `getCurrentUserProfile()`).
- **Một Repository có thể chứa và phối hợp nhiều Services** thông qua Constructor Injection (ví dụ: `NavigationRepository` có thể cần cả `FirestoreService` để lưu lịch sử và `SmsPlatformService` để gửi tọa độ qua SMS).
- Chịu trách nhiệm chuyển đổi data thô thành Model nghiệp vụ, gom cụm logic usecase và chuẩn hóa lỗi (Exceptions/Failures).

#### b. Services:
- Đại diện cho các tác vụ backend/hệ thống nguyên thủy (CRUD đơn thuần, API calls, platform-specific wrappers).
- Ví dụ:
  - `FirestoreService`: Thực hiện CRUD collection/document trên Firestore.
  - `FirebaseAuthService`: Đăng nhập, đăng ký, đăng xuất, lấy UID.
  - `SmsPlatformService`: Gọi hàm SMS của thiết bị qua MethodChannel hoặc plugin native.
- Không chứa use case logic phức tạp của ứng dụng.

#### c. Dependency Injection (DI):
- Cung cấp dependencies từ ngoài vào thông qua constructor (hoặc service locator như `get_it` / `RepositoryProvider`).
- Dễ dàng thay thế bằng mock implementation khi viết unit test.

---

## 4. Backend: Server riêng + Firebase (FCM)

- Dự án có **Backend server riêng** (Node.js/Express + Firestore Admin, repo `sms_navigator_server`) — KHÔNG phải kiến trúc Firebase-only. Server là nguồn chân lý duy nhất cho kênh E2EE, membership và key-envelope.
- **FCM (Firebase Cloud Messaging)** chỉ đóng vai trò **chuông thông báo** (wake-up bell) do server bắn ra; app luôn reconcile với server khi mở, nên mất FCM không mất dữ liệu.
- **Quy tắc thao tác Backend**:
  - Toàn bộ lời gọi HTTP tới server phải nằm trong các class thuộc tầng **Services** (ví dụ: `MessageApiService`, `ChannelApiService`, `DeviceApiService`), endpoint tập trung ở `core/constants/api_endpoints.dart`.
  - Tầng UI và BLoC không được gọi HTTP trực tiếp.
  - Lời gọi Firebase SDK trong app (FCM token, notification foreground) phải nằm trong tầng **Services** (ví dụ: `FcmNotificationService`); bọc lỗi thành domain error/exception thân thiện trước khi trả về Repository.

---

## 5. Nguyên tắc SOLID

Mọi thiết kế class và module phải tuân thủ 5 nguyên tắc SOLID:
1. **S - Single Responsibility Principle (Đơn trách nhiệm)**:
   - Mỗi file, class hoặc widget chỉ phụ trách một nhiệm vụ duy nhất (Widget chỉ vẽ UI, Bloc quản lý state, Repository xử lý use case, Service gọi Firebase).
2. **O - Open/Closed Principle (Mở rộng - Đóng sửa đổi)**:
   - Định nghĩa abstract class / interface cho Repository và Service để dễ mở rộng chức năng mà không làm thay đổi các class đang phụ thuộc.
3. **L - Liskov Substitution Principle (Thay thế Liskov)**:
   - Các class triển khai (Implementation) có thể thay thế hoàn toàn cho abstract interface mà không làm thay đổi tính đúng đắn của chương trình.
4. **I - Interface Segregation Principle (Phân tách Interface)**:
   - Không tạo các interface "khổng lồ". Chia nhỏ interface theo từng mục đích sử dụng.
5. **D - Dependency Inversion Principle (Đảo ngược Phụ thuộc)**:
   - Tầng cấp cao (BLoC) không phụ thuộc trực tiếp vào tầng cấp thấp (Service/Firebase), mà phụ thuộc vào Abstraction (Repository interface).
   - Inject dependencies qua constructor.

---

## 6. Tổ chức Code & Chuẩn mực Thiết kế Flutter

### 6.1. Cấu trúc thư mục (Feature-first Structure)
```
lib/
├── core/                        # Tài nguyên dùng chung toàn ứng dụng
│   ├── constants/               # Hằng số (colors, strings, assets, keys)
│   ├── di/                      # Thiết lập Dependency Injection (get_it / providers)
│   ├── errors/                  # App exceptions & failures
│   ├── theme/                   # App theme, styles
│   └── utils/                   # Helpers, formatters, extensions
├── features/                    # Các tính năng theo mô-đun (Feature-first)
│   └── <feature_name>/
│       ├── presentation/        # Tầng UI & Controller
│       │   ├── bloc/            # Bloc, Event, State
│       │   ├── pages/           # Screens / Pages
│       │   └── widgets/         # Widgets chỉ dùng riêng cho feature này
│       └── data/                # Tầng Data
│           ├── models/          # Data transfer objects / Models
│           ├── repositories/    # Repository interfaces & implementations
│           └── services/        # Services (Firebase, local storage, native SMS)
├── app.dart                     # MaterialApp config, global providers, routes
└── main.dart                    # Entry point, khởi tạo Firebase & DI
```

### 6.2. Chuẩn mực Flutter Widgets
- **Khai báo `const`**: Đặt từ khóa `const` ở tất cả các constructor của Widget khi tham số là bất biến để tối ưu rendering.
- **Tách Widget nhỏ gọn**:
  - Không viết lồng widget quá sâu (tránh "nested hell").
  - Tránh dùng hàm private dạng `Widget _buildItem()` vì không tối ưu lifecycle và rebuild. Ưu tiên tách thành các `StatelessWidget` độc lập.
- **Quản lý bộ nhớ**:
  - Luôn `dispose()` các `TextEditingController`, `ScrollController`, `StreamSubscription` khi không còn sử dụng.
  - Đóng Bloc thông qua lifecycle quản lý của `BlocProvider` hoặc gọi `bloc.close()`.

---

## 7. Khóa Cứng Phiên Bản Package (Strict Version Pinning)

- **Quy tắc tuyệt đối**: Trong `pubspec.yaml`, mọi package ở cả `dependencies` và `dev_dependencies` phải được **khóa cứng phiên bản chính xác**.
- **Cấm sử dụng**: Dấu mũ (`^`), dấu lớn hơn hoặc bằng (`>=`), hoặc dải phiên bản (`1.0.0 <2.0.0`).
- **Ví dụ**:
  - ✅ **Đúng**:
    ```yaml
    dependencies:
      flutter:
        sdk: flutter
      flutter_bloc: 8.1.6
      equatable: 2.0.7
      firebase_core: 3.12.1
      cloud_firestore: 5.6.5
    ```
  - ❌ **Sai**:
    ```yaml
    dependencies:
      flutter_bloc: ^8.1.6
      equatable: ^2.0.7
    ```
- **Mục đích**: Bảo đảm tính đồng nhất giữa môi trường phát triển cục bộ của từng developer và hệ thống CI/CD, tránh phát sinh lỗi do các bản cập nhật ngầm.

---

## 8. Môi trường phát triển & Công cụ (FVM)

- Dự án sử dụng **FVM (Flutter Version Management)** để đồng bộ SDK.
- Khi chạy các lệnh Flutter/Dart, ưu tiên sử dụng `fvm flutter ...` (ví dụ: `fvm flutter pub get`, `fvm flutter analyze`).
