# Server Health-Check Dashboard

Tugas Praktikum Pemrograman Perangkat Bergerak (Flutter):
**Async Parallel Fetching (`Future.wait`) & Pull-to-Refresh (`RefreshIndicator`)**

## Deskripsi

Dashboard untuk memantau status 3 layanan server secara **paralel**:

| Service | Delay | Status yang Mungkin |
|---|---|---|
| Database Server | 2 detik | Online (80%) / Offline |
| API Gateway | 3 detik (terlama) | Online (70%) / Degraded |
| Storage Service | 1 detik | Online (selalu) |

Karena menggunakan `Future.wait`, total waktu loading hanya **~3 detik**
(mengikuti delay terlama), bukan 2+3+1 = **6 detik** jika sekuensial.
Durasi aktual ditampilkan di UI (timer live) dan di-log ke console sebagai bukti.

## Struktur Kode

```
lib/
├── main.dart                      # Entry point + DashboardPage (StatefulWidget)
├── services/
│   └── server_service.dart        # Service resmi: 3 method static yang
│                                  # mengembalikan Future<Map<String, dynamic>>
└── widgets/
    ├── service_card.dart          # Card status per service + pewarnaan dinamis
    └── shimmer_card.dart          # Placeholder shimmer saat loading
```

### `lib/services/server_service.dart`
Menyediakan 3 method `static`: `checkDatabase()`, `checkApiGateway()`, dan
`checkStorage()`. Masing-masing mensimulasikan HTTP request dengan
`Future.delayed` berdurasi berbeda dan mengembalikan `Map` berisi
`service`, `status`, dan `latency`.

### `lib/main.dart`
- `_fetchAll()` memanggil ketiga service sekaligus via **`Future.wait`**
  sambil menjalankan `Stopwatch` + `Timer.periodic` untuk menampilkan
  timer live selama loading.
- Seluruh konten dibungkus **`RefreshIndicator`** (pull-to-refresh) dengan
  `AlwaysScrollableScrollPhysics`.
- `AnimatedSwitcher` mengatur transisi halus antara shimmer (loading)
  dan card hasil fetch.
- Card ringkasan menampilkan durasi fetch terakhir vs target paralel (~3 s)
  vs estimasi sekuensial (~6 s).

### `lib/widgets/service_card.dart`
Menampilkan satu service: ikon, nama, latency, waktu pengecekan, dan badge
status. Extension `HealthStatusStyle` memetakan status ke warna:

| Status | Warna |
|---|---|
| `Online` | Hijau |
| `Degraded` | Oranye/Amber |
| `Offline` | Merah |

### `lib/widgets/shimmer_card.dart`
Efek shimmer (gradient beranimasi) murni Flutter — tanpa package eksternal.

## Menjalankan

```bash
flutter pub get
flutter run -d chrome   # atau device lain yang tersedia
```
