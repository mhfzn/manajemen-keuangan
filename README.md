<div align="center">

<img src="https://raw.githubusercontent.com/tandpfun/skill-icons/main/icons/Flutter-Dark.svg" width="70" alt="Flutter Logo">

# ✨ FauzanPay
**HEMAT UANG ANDA SEKARANG!!**

[![Version](https://img.shields.io/badge/Release-v1.0.0%20(MVP)-FF6B6B?style=for-the-badge&logo=github&logoColor=white)](https://github.com/mhfzn/manajemen-keuangan)
[![Flutter Build](https://img.shields.io/badge/Built%20with-Flutter%20%26%20Dart-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Status](https://img.shields.io/badge/Status-Active%20Development-3DDC84?style=for-the-badge)](https://github.com/mhfzn/manajemen-keuangan)

<br/>

*FauzanPay meredefinisi cara Anda mengelola arus kas pribadi. Versi awal ini dirancang khusus dengan filosofi minimalis: memberikan pengalaman pencatatan yang mulus tanpa mengorbankan fitur pelaporan kelas atas.*

</div>

<br/>

## 🚀 Sekilas Tentang Versi Awal (v1.0.0)
Sebagai rilis perdana, fokus utama pengembangan saat ini adalah pada **Stabilitas, Kecepatan, dan Privasi Data**. FauzanPay beroperasi menggunakan arsitektur *Offline-First*, yang menjamin seluruh data finansial Anda terenkripsi dan tersimpan dengan aman hanya di dalam perangkat Anda, tanpa ketergantungan pada server eksternal.

---

## 💎 Fitur Eksklusif

| Fungsionalitas | Keterangan |
| :--- | :--- |
| 📊 **Enterprise Excel Export** | Hasilkan laporan format `.xlsx` dengan standar akuntansi (Grid bersih, Format Rupiah, & *Auto-Line Chart* harian). |
| 🛡️ **Dual-Layer Protection** | Sistem *Recycle Bin* 2 tahap (Histori Sampah & Sampah Permanen) mencegah hilangnya data akibat ketidaksengajaan. |
| 🌓 **Adaptive UI/UX** | Mendukung transisi mulus antara *Light Mode* dan *True Dark Mode* sesuai preferensi mata pengguna. |
| ⚡ **Fluid Performance** | Animasi super halus 60fps dengan manajemen *state* ringan menggunakan `ValueNotifier` dan `SharedPreferences`. |

---

## 📱 Galeri Antarmuka

<div align="center">

| Mode Siang Terang ☀️ | Mode Malam Ekstrem 🌙 | Mesin Pelaporan 📉 |
|:---:|:---:|:---:|
| *(Tarik / Drag gambar 1 ke sini)* | *(Tarik / Drag gambar 2 ke sini)* | *(Tarik / Drag gambar 3 ke sini)* |

</div>

---

## 🗺️ Peta Jalan Pengembangan (Roadmap)

Karena ini masih tahap awal, perjalanan FauzanPay masih panjang. Berikut adalah rencana pembaruan ke depannya:

- [x] **v1.0.0:** *Core Engine*, UI/UX Dasar, Ekspor Excel Canggih, Mode Gelap.
- [ ] **v1.1.0:** Kategori Transaksi Kustom (Ikon & Warna).
- [ ] **v1.2.0:** Keamanan Biometrik (Sidik Jari / Face ID) saat membuka aplikasi.
- [ ] **v2.0.0:** Sinkronisasi *Cloud* opsional dengan akun Google.

---

## ⚙️ Kedalaman Teknis (Tech Stack)

Aplikasi ini tidak hanya sekadar *frontend*, tetapi mengolah data secara intensif menggunakan pustaka terbaik di kelasnya:

```yaml
Dependencies:
  - flutter_material: Framework utama.
  - shared_preferences: Engine penyimpanan lokal berkecepatan tinggi.
  - syncfusion_flutter_xlsio: Pemrosesan memori untuk perakitan file Microsoft Excel.
  - syncfusion_officechart: Injeksi grafik dinamis ke dalam spreadsheet.
  - share_plus & path_provider: Akses sistem operasi tingkat rendah untuk ekspor file.
