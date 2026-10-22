# Từ AGP 9 (R8 chặt hơn), bản release crash lúc khởi động:
#   InitializationProvider → "Failed to create an instance of class
#   androidx.work.impl.WorkDatabase.canonicalName"
# Room (bên trong WorkManager) dựng `<Tên>_Impl` bằng reflection từ tên lớp
# database. R8 đổi tên / xoá lớp Impl hoặc constructor rỗng của nó nên
# Class.forName thất bại. Giữ nguyên tên + constructor cho mọi RoomDatabase.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keepnames class * extends androidx.room.RoomDatabase
-keep class androidx.work.impl.WorkDatabase_Impl { *; }

# Worker được WorkManager tạo bằng reflection theo tên lớp lưu trong DB.
-keep class * extends androidx.work.ListenableWorker {
    <init>(android.content.Context, androidx.work.WorkerParameters);
}
