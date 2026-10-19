class User {
  const User({
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.phone,
    this.namaToko,
  });

  final String id;
  final String nama;
  final String email;
  final String? phone;
  final String role;
  final String? namaToko;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    nama: json['nama'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String?,
    role: json['role'] as String,
    namaToko: json['nama_toko'] as String?,
  );
}
