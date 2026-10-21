class Halaman<T> {
  const Halaman({
    required this.data,
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
  });
  final List<T> data;
  final int page, perPage, total, totalPages;
  bool get adaBerikutnya => page < totalPages;

  factory Halaman.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) decode,
  ) {
    final meta = json['meta'] as Map<String, dynamic>;
    return Halaman(
      data: List<T>.unmodifiable(
        (json['data'] as List).map(
          (item) => decode(item as Map<String, dynamic>),
        ),
      ),
      page: meta['page'] as int,
      perPage: meta['per_page'] as int,
      total: meta['total'] as int,
      totalPages: meta['total_pages'] as int,
    );
  }
}
