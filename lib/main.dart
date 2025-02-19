import 'dart:async';  // Import dart:async untuk Timer
import 'dart:convert';  // Import dart:convert untuk json.decode
import 'package:flutter/material.dart';   // Import material.dart untuk MaterialApp dan Widget
import 'package:http/http.dart' as http;  // Import http.dart untuk http request
import 'package:cached_network_image/cached_network_image.dart';  // Import cached_network_image.dart untuk CachedNetworkImage
import 'package:flutter_dotenv/flutter_dotenv.dart';  // Import flutter_dotenv.dart untuk dotenv

// Fungsi main async untuk menjalankan aplikasi
void main() async {
  // Load file .env
  await dotenv.load(fileName: ".env");
  // Run aplikasi
  runApp(MyApp());
}

// MyApp untuk menampilkan aplikasi NOFI: Movie App
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // MaterialApp dengan tema dan home page
    return MaterialApp(
      // Judul aplikasi
      title: 'NOFI: Movie App',
      // Tema aplikasi
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // HomePage sebagai home page
      home: HomePage(),
      // Routes untuk navigasi ke MovieDetailPage
      routes: {MovieDetailPage.routeName: (context) => MovieDetailPage()},
    );
  }
}

// HomePage untuk menampilkan list movie
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Variabel state
  List movies = [];
  int currentPage = 1;
  String currentQuery = '';
  int? selectedGenre;
  bool hasMore = true;
  bool isLoading = false;

  // Deklarasikan Timer untuk debounce search
  Timer? _debounce;

  // Controller untuk search
  TextEditingController searchController = TextEditingController();
  // Get API Key dari file .env
  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  // ScrollController untuk load more
  final ScrollController _scrollController = ScrollController();

  // Deklarasikan genres sebagai List<Map<String, dynamic>>
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

  // Fungsi initState untuk memanggil fetchMovies
  @override
  void initState() {
    // Panggil initState dari parent
    super.initState();
    // Fetch data movie
    fetchMovies();
  }

  /// Fungsi untuk mengambil data movie.
  /// Parameter [isLoadMore] digunakan untuk menambahkan data pada list.
  Future<void> fetchMovies({bool isLoadMore = false}) async {
    // Jika isLoading maka return
    if (isLoading) return;
    // Set isLoading=true
    setState(() {
      isLoading = true;
    });

    // Deklarasikan URL kosong
    String url = '';

    // URL berdasarkan: search, filter genre, atau default discover
    if (currentQuery.isNotEmpty) {
      url =
          'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(currentQuery)}&page=$currentPage';
    } else if (selectedGenre != null) {
      url =
          'https://api.themoviedb.org/3/discover/movie?sort_by=popularity.desc&with_genres=$selectedGenre&api_key=$apiKey&page=$currentPage';
    } else {
      url =
          'https://api.themoviedb.org/3/discover/movie?sort_by=popularity.desc&api_key=$apiKey&page=$currentPage';
    }

    // Fetch data dari API
    try {
      final response = await http.get(Uri.parse(url));
      // Jika response OK (status code 200)
      if (response.statusCode == 200) {
        // Decode response body
        final data = json.decode(response.body);
        // Set newMovies sebagai data['results']
        List newMovies = data['results'];

        // Jika newMovies kurang dari 20 maka hasMore=false
        if (newMovies.length < 20) {
          hasMore = false;
        } else {
          hasMore = true;
        }

        // Set state movies dengan newMovies
        setState(() {
          if (isLoadMore) {
            movies.addAll(newMovies);
          } else {
            movies = newMovies;
          }
        });
      } else {
        // Jika response error maka tampilkan error message
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      // Jika terjadi error maka tampilkan error message
      print('Error fetching movies: $e');

    // Finally for set isLoading=false
    } finally {
      // Set isLoading=false
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk load more data
  void loadMore() {
    // currentPage++ is current page + 1
    currentPage++;
    // Fetch data and set isLoadMore=true
    fetchMovies(isLoadMore: true);
  }

  // Fungsi untuk debounce search
  void onSearchChanged(String query) {
    // Jika debounce active maka cancel
    // Lalu set debounce dengan Timer 500ms
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      // Jika query tidak kosong maka panggil onSearch
      if (query.isNotEmpty) {
        onSearch();
      } else {
        // Jika query kosong, kembalikan ke keadaan default
        // Reset state
        currentPage = 1;
        currentQuery = '';
        setState(() {
          selectedGenre = null;
        });

        // Fetch data
        fetchMovies();
        _scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Fungsi untuk search
  void onSearch() {
    // Reset state
    currentPage = 1;
    currentQuery = searchController.text;
    setState(() {
      selectedGenre = null;
    });

    // Fetch data
    fetchMovies();

    // Kembali ke posisi atas
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Fungsi untuk memilih genre
  void onSelectGenre(int? genreId) {
    // Reset state
    setState(() {
      selectedGenre = genreId;
      currentQuery = '';
      searchController.clear();
      currentPage = 1;
    });

    // Fetch data
    fetchMovies();

    // Kembali ke posisi atas
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    // Scaffold dengan AppBar dan body
    return Scaffold(
      appBar: AppBar(title: Text('Movies')),
      body: Column(
        children: [
          // Bagian filter genre dan search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // Dropdown Genre
                Expanded(
                  child: DropdownButton<int?>(
                    hint: Text('Select Genre'),
                    value: selectedGenre,
                    isExpanded: true,
                    // DropdownMenuItem untuk setiap genre
                    items: [
                      // DropdownMenuItem untuk "All Genre"
                      DropdownMenuItem<int?>(child: Text('All Genre'), value: null),
                      ...genres.map((genre) {
                        return DropdownMenuItem<int?>(
                          child: Text(genre['name']),
                          value: genre['id'],
                        );
                      }).toList(),
                    ],
                    // Fungsi onChanged untuk onSelectGenre
                    onChanged: (value) {
                      onSelectGenre(value);
                    },
                  ),
                ),
                SizedBox(width: 8),
                // Field search
                Expanded(
                  child: TextField(
                    // Search Controller
                    controller: searchController,
                    // Fungsi onSearchChanged untuk debounce search
                    onChanged: onSearchChanged,
                    // Fungsi onSearch untuk search
                    onSubmitted: (value) => onSearch(),
                    // Dekorasi input field
                    decoration: InputDecoration(
                      hintText: 'Search Movies',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: onSearch,
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // GridView untuk menampilkan list movie 2 kolom
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              // SliverGridDelegateWithFixedCrossAxisCount untuk 2 kolom
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              // Jumlah item sesuai jumlah movie
              itemCount: movies.length,
              // ItemBuilder untuk menampilkan item movie
              itemBuilder: (context, index) {
                // Movie pada index tertentu
                final movie = movies[index];
                // URL poster image
                final posterPath = movie['poster_path'];
                final imageUrl =
                    posterPath != null
                        ? 'https://image.tmdb.org/t/p/w300$posterPath'
                        : 'https://dummyimage.com/300x450/000/fff&text=No+Image';
                // Mengambil release year dari release_date
                String releaseYear = '';
                if (movie['release_date'] != null &&
                    movie['release_date'].toString().length >= 4) {
                  releaseYear = movie['release_date'].toString().substring(
                    0,
                    4,
                  );
                }
                // Rating movie
                final voteAverage = (movie['vote_average'] ?? 0.0) as num;
                
                // InkWell untuk menavigasi ke MovieDetailPage
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/movieDetail',
                      arguments: movie['id'],
                    );
                  },
                  child: Stack(
                    children: [
                      // Poster Image menggunakan Cached
                      CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              color: Colors.grey[300],
                              child: Center(child: CircularProgressIndicator()),
                            ),
                        errorWidget:
                            (context, url, error) => Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                      ),
                      // Icon dan rating (di pojok kiri atas)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 14),
                              SizedBox(width: 4),
                              Text(
                                voteAverage.toDouble().toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Judul movie dan release year (di bagian bawah poster)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          color: Colors.black54,
                          child: Text(
                            '${movie['title']} (${releaseYear})',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Tombol "Show More"
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child:
            // Jika isLoading maka tampilkan CircularProgressIndicator
                (isLoading)
                    ? CircularProgressIndicator()
                    // Jika hasMore maka tampilkan tombol "Show More"
                    : (hasMore
                        ? ElevatedButton(
                          onPressed: loadMore,
                          child: Text('Show More'),
                        )
                        : SizedBox.shrink()),
          ),
        ],
      ),
    );
  }
}

// MovieDetailPage untuk menampilkan detail movie
class MovieDetailPage extends StatefulWidget {
  static const routeName = '/movieDetail';

  @override
  _MovieDetailPageState createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  // Variabel state
  Map? movieDetail;
  bool isLoading = true;
  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';

  // Fungsi didChangeDependencies untuk memanggil fetchMovieDetail
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ambil ID movie dari arguments
    final movieId = ModalRoute.of(context)!.settings.arguments as int;
    fetchMovieDetail(movieId);
  }

  // Mengambil detail movie berdasarkan movieId
  Future<void> fetchMovieDetail(int movieId) async {
    final url = 'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      // Jika response OK (status code 200)
      if (response.statusCode == 200) {
        // Decode response body
        final data = json.decode(response.body);
        // Set state movieDetail dan isLoading=false
        setState(() {
          movieDetail = data;
          isLoading = false;
        });
      } else {
        // Jika response error maka tampilkan error message
        print('Error fetching detail: ${response.statusCode}');
      }
    } catch (e) {
      // Jika terjadi error maka tampilkan error message
      print('Error: $e');
    }
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    // Scaffold dengan AppBar dan body
    return Scaffold(
      appBar: AppBar(title: Text('Movie Detail')),
      body:
      // Jika isLoading maka tampilkan CircularProgressIndicator
          isLoading
              ? Center(child: CircularProgressIndicator())
              // Jika movieDetail null maka tampilkan pesan "No data available"
              : movieDetail == null
              ? Center(child: Text('No data available'))
              // Jika movieDetail ada maka tampilkan detail movie
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster Image menggunakan Cached
                      Center(
                        child: CachedNetworkImage(
                          imageUrl:
                              // Check jika poster_path null maka tampilkan No Image 
                              movieDetail!['poster_path'] != null
                                  ? 'https://image.tmdb.org/t/p/w300${movieDetail!['poster_path']}'
                                  : 'https://dummyimage.com/300x450/000/fff&text=No+Image',
                          height: 450,
                          fit: BoxFit.cover,
                          placeholder:
                              // Placeholder loading
                              (context, url) => Container(
                                height: 450,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
                              // Replacement icon jika error
                              (context, url, error) => Container(
                                height: 450,
                                color: Colors.grey[300],
                                child: Icon(Icons.error, color: Colors.red),
                              ),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Title, Rating, Release Date, Duration
                      Text(
                        movieDetail!['title'] ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            (movieDetail!['vote_average'] as num)
                                .toDouble()
                                .toStringAsFixed(1),
                            style: TextStyle(fontSize: 16),
                          ),
                          // Info lain seperti release date dan runtime
                          SizedBox(width: 16),
                          Text(
                            'Release: ${movieDetail!['release_date'] ?? 'N/A'}',
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(width: 16),
                          Text(
                            'Duration: ${movieDetail!['runtime'] ?? 'N/A'} min',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Overview
                      Text(
                        movieDetail!['overview'] ?? '',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
