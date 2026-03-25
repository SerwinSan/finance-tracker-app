# 💰 Finance Tracker App

Aplikasi pencatat keuangan pribadi dengan fitur **Virtual Pocketing** (pemisahan saldo), **Smart Ledger** (transaksi cerdas), **Expense Analytics** (visualisasi keuangan), **Saving Goals** (target tabungan), dan **Export Data** (CSV & PDF).

> Built with Flutter + Supabase + SQLite — mendukung mode offline.

---

## ✨ Fitur Utama

### 🔐 Authentication
- Login & Register dengan Supabase Auth
- Session management (auto-login)
- Validasi input (email, password min 8 karakter dengan huruf besar, kecil, angka)
- Error handling dengan pesan Bahasa Indonesia

### 👛 Multi-Pocketing
- Buat beberapa dompet terpisah (misal: Uang Pribadi, Titipan Teman)
- Setiap dompet punya tipe, warna, ikon, dan mata uang sendiri
- Mendukung IDR (Rupiah) dan USD (Dollar)
- CRUD lengkap dengan sinkronisasi online-offline

### 📒 Smart Ledger (Transaksi)
- Catat pemasukan & pengeluaran
- Kategori bawaan + custom categories
- Label "milik siapa" untuk tracking kepemilikan
- Riwayat transaksi dengan filter dan sorting

### 📊 Expense Analytics
- **Pie Chart** — persentase pengeluaran per kategori
- **Bar Chart** — perbandingan pemasukan vs pengeluaran
- **Summary Cards** — total pemasukan, pengeluaran, dan selisih
- Filter periode: mingguan, bulanan, tahunan

### 🎯 Saving Goals
- Buat target tabungan (misal: "Beli Part Sepeda")
- Progress bar visual dengan persentase
- Kontribusi langsung dari dompet tertentu
- Tenggat waktu opsional
- Color picker untuk personalisasi

### 📄 Export Data
- **CSV** — bisa dibuka di Excel / Google Sheets
- **PDF** — laporan A4 rapi dengan summary dan tabel
- Share via WhatsApp, Email, dan lainnya
- Filter berdasarkan periode

### 🎨 UI/UX
- Dark mode & Light mode
- Desain terinspirasi GoPay (user-friendly, semi-formal)
- Material 3 design system
- Responsive layout khusus Android

---

## 🛠️ Tech Stack

| Layer | Teknologi |
|---|---|
| **Framework** | Flutter (Dart) |
| **State Management** | Provider |
| **Backend** | Supabase (PostgreSQL + Auth) |
| **Local Database** | SQLite (sqflite) |
| **Charts** | fl_chart |
| **PDF Generation** | pdf + printing |
| **Networking** | connectivity_plus |
| **Environment** | flutter_dotenv |
| **Sharing** | share_plus |

---

## 📁 Struktur Folder

```
lib/
├── app.dart                       # MaterialApp & routing
├── main.dart                      # Entry point + provider setup
├── config/
│   ├── constants/app_constants.dart
│   └── theme/
│       ├── app_colors.dart
│       └── app_theme.dart
├── data/
│   ├── local/database_helper.dart  # SQLite helper
│   ├── models/                     # Data models
│   ├── repositories/               # Data access layer
│   └── services/                   # Supabase & Export services
├── presentation/
│   ├── providers/                  # State management
│   ├── screens/                    # UI screens
│   └── widgets/                    # Reusable widgets
└── utils/
    ├── formatters.dart             # Currency & date formatting
    └── validators.dart             # Input validation & sanitization
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ^3.11.0
- Android Studio / VS Code
- Supabase account

### Setup

1. **Clone repository**
   ```bash
   git clone https://github.com/SerwinSan/finance-tracker-app.git
   cd finance-tracker-app
   ```

2. **Buat file `.env`** di root project
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run di emulator atau device**
   ```bash
   flutter run
   ```

5. **Build APK (release)**
   ```bash
   flutter build apk --release
   ```

### Supabase Setup

Buat 5 tabel di Supabase:
- `pockets` — Dompet virtual
- `categories` — Kategori transaksi
- `transactions` — Catatan pemasukan/pengeluaran
- `saving_goals` — Target tabungan
- `saving_contributions` — Kontribusi ke target

> RLS (Row Level Security) sudah diaktifkan di semua tabel dengan policy `auth.uid() = user_id`.

---

## 🔒 Security

- **API Keys** — Disimpan di `.env` (tidak masuk Git)
- **Row Level Security** — Aktif di semua tabel Supabase
- **Input Validation** — Guard clause pattern + sanitization (anti-XSS)
- **Password Policy** — Min 8 karakter, huruf besar, kecil, dan angka
- **Offline-first** — Data sensitif disimpan lokal di SQLite

---

## 📱 Platform

- ✅ Android
- ❌ iOS (belum ditest)
- ❌ Web

---

## 📋 Roadmap

- [x] Authentication (Login / Register)
- [x] Multi-Pocketing (Virtual Wallets)
- [x] Smart Ledger (Transaksi)
- [x] Expense Analytics (Charts)
- [x] Saving Goals (Target Tabungan)
- [x] Export Data (CSV & PDF)
- [x] Polish & Security (RLS, Validation, Sanitization)

---

## 👨‍💻 Author

Dibuat sebagai project portofolio Teknik Informatika.

## 📄 License

Project ini dibuat untuk keperluan akademis dan portofolio.
