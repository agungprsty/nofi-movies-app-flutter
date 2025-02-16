# NOFI: Movie App

## Into

Aplikasi ini dibangun dengan Flutter dan memiliki tiga fitur utama:

1. **Menampilkan Daftar Movie dari Sumber Data Lokal dan API**
   - Menggunakan list/array lokal untuk genre.
    ```dart
    final List<Map<String, dynamic>> genres = [
      {"id": 28, "name": "Action"},
      {"id": 12, "name": "Adventure"},
      {"id": 16, "name": "Animation"},
      {"id": 35, "name": "Comedy"},
      {"id": 80, "name": "Crime"},
      {"id": 99, "name": "Documentary"},
      {"id": 18, "name": "Drama"},
      {"id": 107, "name": "Family"},
      {"id": 14, "name": "Fantasy"},
      {"id": 36, "name": "History"},
      {"id": 27, "name": "Horror"},
      {"id": 104, "name": "Music"},
      {"id": 964, "name": "Mystery"},
      {"id": 107, "name": "Romance"},
      {"id": 878, "name": "Science Fiction"},
      {"id": 107, "name": "TV Movie"},
      {"id": 53, "name": "Thriller"},
      {"id": 107, "name": "War"},
      {"id": 37, "name": "Western"},
    ];
    ```
   - Mengambil data json movie populer dari API [The Movie Database](https://www.themoviedb.org/documentation/api) menggunakan API key yang diatur secara dinamis melalui file `.env`.
  
1. **Tampilan Movie dalam Layout Grid 2 Kolom**
   - Menampilkan poster movie dengan overlay rating di pojok kiri atas dan judul beserta tahun rilis di bagian bawah.
   - Desain responsif dan modern.
  
2. **Optimalisasi Aplikasi**
   - **API Key Management:** API key tidak hardcode, melainkan disimpan di file `.env` dan di-load menggunakan paket `flutter_dotenv`.
   - **Caching Gambar:** Menggunakan paket `cached_network_image` untuk cache gambar sehingga loading lebih cepat.
   - **App Icon:** Icon aplikasi sudah disesuaikan dengan menggunakan paket `flutter_launcher_icons`, memudahkan pengujian dan distribusi versi debug/test.

## Struktur Kode Penting

- **main.dart**  
  Memuat file `.env` dan menjalankan aplikasi:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_dotenv/flutter_dotenv.dart';

  void main() async {
    await dotenv.load(fileName: ".env");
    runApp(MyApp());
  }

- **API Key Management**
  Di file manapun yang membutuhkan API key (misalnya di HomePage), gunakan:
  ```dart
  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  ```

- **App Icon**
  File icon aplikasi diletakkan pada assets/icon/icon.png.
  Konfigurasi pada pubspec.yaml:
  ```yaml
  dev_dependencies:
    flutter_launcher_icons: "^0.14.3"
  ```
  
  Konfigurasi pada flutter_launcher_icons.yaml:
  ```yaml
  flutter_icons:
    android: "launcher_icon"
    ios: true
    image_path: "assets/icon/icon.png"
  ```
  Untuk menghasilkan icon, jalankan:
  ```bash
  flutter pub run flutter_launcher_icons
  ```
- **Caching Gambar**
  Menggunakan paket cached_network_image untuk menampilkan gambar dengan cache:
  ```dart
  CachedNetworkImage(
    imageUrl: imageUrl,
    fit: BoxFit.cover,
    placeholder: (context, url) => Container(
      color: Colors.grey[300],
      child: Center(child: CircularProgressIndicator()),
    ),
    errorWidget: (context, url, error) => Container(
      color: Colors.grey[300],
      child: Icon(Icons.error, color: Colors.red),
    ),
  );
  ```

- **Tampilan Grid Movie**
  GridView dengan 2 kolom yang menampilkan poster, rating, dan judul movie:
  ```dart
  GridView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.all(8.0),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.65,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
    ),
    itemCount: movies.length,
    itemBuilder: (context, index) {
      // Implementasi item movie dengan CachedNetworkImage dan overlay informasi.
    },
  );
  ```

- **Pagination dan Tombol "Load More"**
  Pada fungsi fetchMovies, jika jumlah data yang diambil kurang dari 20 maka tidak ada data berikutnya. Tombol "Load More" hanya akan tampil jika hasMore bernilai true:
  ```dart
  Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: (isLoading)
        ? CircularProgressIndicator()
        : (hasMore
            ? ElevatedButton(
                onPressed: loadMore,
                child: Text('Show More'),
              )
            : SizedBox.shrink()),
  );
  ```
## How to Run the Application

1. Clone this project
2. Edit file .env.example to .env and adjustment value TMDB_API_KEY
3. Generate App Icon: 
    ```bash 
    flutter pub run flutter_launcher_icons
    ```
4. Install Dependency
    ```bash
    flutter pub get
    ```
5. Jalankan Aplikasi
    ```bash
    flutter run
    ```