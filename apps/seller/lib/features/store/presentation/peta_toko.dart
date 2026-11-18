import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

/// Titik default peta: Dewantara (sekitar Keude Krueng Geukueh), dipakai
/// kalau toko belum punya titik tersimpan. Ini BUKAN lokasi yang disimpan:
/// titik ini tidak pernah dikirim ke backend kalau seller tidak menggeser
/// peta (lihat _titik di TokoEditor yang tetap null sampai ada geseran).
const dewantaraDefault = LatLng(5.2443, 97.0248);

gmaps.LatLng _keGmaps(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);
LatLng _dariGmaps(gmaps.LatLng p) => LatLng(p.latitude, p.longitude);

/// Peta Google Maps dengan pin tengah: pin diam di tengah layar,
/// koordinatnya mengikuti posisi peta saat digeser. Dipakai di formulir
/// Info Toko supaya seller bisa menandai lokasi tokonya sendiri.
///
/// API key Google Maps dibaca Android dari local.properties
/// (MAPS_API_KEY) lewat manifest placeholder; iOS dari AppDelegate.
class PetaToko extends StatefulWidget {
  const PetaToko({super.key, required this.initial, this.onPointChanged});
  final LatLng initial;
  final void Function(LatLng point)? onPointChanged;

  @override
  State<PetaToko> createState() => _PetaTokoState();
}

class _PetaTokoState extends State<PetaToko> {
  late var _pin = widget.initial;

  /// Di widget test, GoogleMap tidak dirender (platform view tidak ada
  /// di flutter_test). Sebagai gantinya tampil placeholder polos supaya
  /// teks koordinat tetap bisa dites.
  static bool get _isTest =>
      Platform.environment['FLUTTER_TEST'] == 'true';

  void _onCameraMove(gmaps.CameraPosition position) {
    final center = _dariGmaps(position.target);
    if (center == _pin) return;
    setState(() => _pin = center);
    widget.onPointChanged?.call(center);
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  if (_isTest)
                    Container(color: const Color(0xFFE8F5E9))
                  else
                    gmaps.GoogleMap(
                      initialCameraPosition: gmaps.CameraPosition(
                        target: _keGmaps(widget.initial),
                        zoom: 15,
                      ),
                      onCameraMove: _onCameraMove,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                  const Center(
                    child: Icon(
                      Icons.location_on,
                      size: 40,
                      color: Color(0xFFDC043A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Titik: ${_pin.latitude.toStringAsFixed(5)}, '
            '${_pin.longitude.toStringAsFixed(5)}',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      );
}
