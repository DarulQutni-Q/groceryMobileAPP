import 'dart:math' as math;

/// Jarak great-circle (haversine) dalam km. Radius bumi 6371 km.
///
/// Dipakai gating radius toko: jarak user (alamat utama) ke toko.
/// Hasilnya hanya dipakai kalau kedua koordinat ada; kalau ada yang
/// null, pemanggil harus memperlakukan jarak sebagai TIDAK DIKETAHUI
/// (lihat [jarakKeToko]), bukan nol.
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthKm = 6371.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return 2 * earthKm * math.asin(math.sqrt(a));
}

double _rad(double deg) => deg * math.pi / 180;

/// Jarak user ke toko dalam km, atau null kalau salah satu koordinat
/// tidak ada. Null artinya jarak TIDAK DIKETAHUI — bukan 0, bukan dekat,
/// dan tidak boleh dipakai untuk memblokir toko.
double? jarakKeToko({
  required double? userLat,
  required double? userLon,
  required double? tokoLat,
  required double? tokoLon,
}) {
  if (userLat == null ||
      userLon == null ||
      tokoLat == null ||
      tokoLon == null) {
    return null;
  }
  return haversineKm(userLat, userLon, tokoLat, tokoLon);
}

/// Aturan gating radius toko:
/// - jarak tidak diketahui (null) -> BOLEH. Jangan blokir order sah
///   gara-gara data koordinat belum ada.
/// - radius null -> tidak ada batas -> BOLEH.
/// - selebihnya jarak harus <= radius (lebih dari radius -> tidak boleh).
bool tokoDapatDipilih({required double? jarakKm, required int? radiusKm}) {
  if (jarakKm == null || radiusKm == null) return true;
  return jarakKm <= radiusKm;
}

/// Format jarak satu desimal, misal 1.0 km / 17.3 km.
String formatJarakKm(double km) => '${km.toStringAsFixed(1)} km';
