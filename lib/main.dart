import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NOFI: Movie App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      routes: {MovieDetailPage.routeName: (context) => MovieDetailPage()},
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List movies = [];
  int currentPage = 1;
  String currentQuery = '';
  int? selectedGenre;
  bool hasMore = true;
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  final ScrollController _scrollController = ScrollController();

  // Data genre lokal
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

  @override
  void initState() {
    super.initState();
    fetchMovies();
  }

  /// Fungsi untuk mengambil data movie.
  /// Parameter [isLoadMore] digunakan untuk menambahkan data pada list.
  Future<void> fetchMovies({bool isLoadMore = false}) async {
    if (isLoading) return;
    setState(() {
      isLoading = true;
    });

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

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List newMovies = data['results'];

        if (newMovies.length < 20) {
          hasMore = false;
        } else {
          hasMore = true;
        }

        setState(() {
          if (isLoadMore) {
            movies.addAll(newMovies);
          } else {
            movies = newMovies;
          }
        });
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching movies: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void loadMore() {
    currentPage++;
    fetchMovies(isLoadMore: true);
  }

  void onSearch() {
    // Reset state
    currentPage = 1;
    currentQuery = searchController.text;
    setState(() {
      selectedGenre = null;
    });
    fetchMovies();

    // Kembali ke posisi atas
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void onSelectGenre(int? genreId) {
    setState(() {
      selectedGenre = genreId;
      currentQuery = '';
      searchController.clear();
      currentPage = 1;
    });
    fetchMovies();

    // Kembali ke posisi atas
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    items: [
                      DropdownMenuItem<int?>(child: Text('All'), value: null),
                      ...genres.map((genre) {
                        return DropdownMenuItem<int?>(
                          child: Text(genre['name']),
                          value: genre['id'],
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      onSelectGenre(value);
                    },
                  ),
                ),
                SizedBox(width: 8),
                // Field search
                Expanded(
                  child: TextField(
                    controller: searchController,
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
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: movies.length,
              itemBuilder: (context, index) {
                final movie = movies[index];
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
                final voteAverage = (movie['vote_average'] ?? 0.0) as num;
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
                      // Poster Image (Cached)
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
                (isLoading)
                    ? CircularProgressIndicator()
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

class MovieDetailPage extends StatefulWidget {
  static const routeName = '/movieDetail';

  @override
  _MovieDetailPageState createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage> {
  Map? movieDetail;
  bool isLoading = true;
  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ambil ID movie dari arguments
    final movieId = ModalRoute.of(context)!.settings.arguments as int;
    fetchMovieDetail(movieId);
  }

  /// Mengambil detail movie berdasarkan movieId
  Future<void> fetchMovieDetail(int movieId) async {
    final url = 'https://api.themoviedb.org/3/movie/$movieId?api_key=$apiKey';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          movieDetail = data;
          isLoading = false;
        });
      } else {
        print('Error fetching detail: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Movie Detail')),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : movieDetail == null
              ? Center(child: Text('No data available'))
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      Center(
                        child: CachedNetworkImage(
                          imageUrl:
                              movieDetail!['poster_path'] != null
                                  ? 'https://image.tmdb.org/t/p/w300${movieDetail!['poster_path']}'
                                  : 'https://dummyimage.com/300x450/000/fff&text=No+Image',
                          height: 450,
                          fit: BoxFit.cover,
                          placeholder:
                              (context, url) => Container(
                                height: 450,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                          errorWidget:
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
                          // Info lainnya seperti release date dan runtime
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
