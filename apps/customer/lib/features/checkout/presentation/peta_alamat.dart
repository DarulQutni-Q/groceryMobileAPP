import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme.dart';

/// Titik default peta: Jakarta, dipakai kalau alamat belum punya titik
/// tersimpan dan user belum memakai GPS. Ini BUKAN lokasi palsu yang
/// disimpan: titik ini tidak pernah dikirim ke backend kalau user tidak
/// menggeser peta atau memakai GPS.
const jakartaDefault = LatLng(-6.2088, 106.8456);

/// Peta OpenStreetMap dengan pin tengah: pin diam di tengah layar,
/// koordinatnya mengikuti posisi peta saat digeser. Dipakai di formulir
/// alamat dan di halaman pemilih titik GPS.
class PetaAlamat extends StatefulWidget {
  const PetaAlamat({
    super.key,
    required this.initial,
    this.height = 280,
    this.onPointChanged,
    this.gpsOverride,
  });
  final LatLng initial;
  final double height;

  /// Dipanggil tiap posisi peta berubah. [byUser] true kalau perubahan
  /// berasal dari gestur user atau tombol GPS, false kalau dari kode
  /// (mis. pemindahan awal). Pemanggil memakai ini untuk tahu apakah
  /// titik boleh disimpan.
  final void Function(LatLng point, bool byUser)? onPointChanged;

  /// Diisi di tes untuk mensimulasikan GPS tanpa platform channel.
  /// null = lokasi tidak tersedia (izin ditolak / GPS mati).
  final Future<LatLng?> Function()? gpsOverride;

  @override
  State<PetaAlamat> createState() => _PetaAlamatState();
}

class _PetaAlamatState extends State<PetaAlamat> {
  late final _controller = MapController();
  late final _pin = ValueNotifier<LatLng>(widget.initial);
  bool _gpsBusy = false;

  /// Di widget test, ubin jaringan dimatikan supaya tidak ada HTTP dan
  /// hasil tetap deterministik. Di aplikasi nyata ubin selalu aktif.
  static bool get _isTest =>
      Platform.environment['FLUTTER_TEST'] == 'true';

  @override
  void dispose() {
    _controller.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _pakaiGps() async {
    if (_gpsBusy) return;
    setState(() => _gpsBusy = true);
    try {
      final target = widget.gpsOverride != null
          ? await widget.gpsOverride!()
          : await _gpsReal();
      if (!mounted) return;
      if (target == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lokasi tidak tersedia. Periksa izin lokasi / GPS, atau '
              'geser peta manual untuk memindah pin.',
            ),
          ),
        );
        return;
      }
      _controller.move(target, 16);
      _pin.value = target;
      widget.onPointChanged?.call(target, true);
    } finally {
      if (mounted) setState(() => _gpsBusy = false);
    }
  }

  Future<LatLng?> _gpsReal() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(color: limePale),
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: widget.initial,
                  initialZoom: 15,
                  minZoom: 3,
                  maxZoom: 19,
                  onPositionChanged: (camera, hasGesture) {
                    final center = camera.center;
                    _pin.value = center;
                    widget.onPointChanged?.call(center, hasGesture);
                  },
                ),
                children: [
                  if (!_isTest)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'gardenmart_customer',
                    ),
                ],
              ),
              const Center(
                child: IgnorePointer(
                  child: Icon(
                    Icons.location_pin,
                    size: 48,
                    color: dangerRed,
                  ),
                ),
              ),
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  color: Colors.white70,
                  child: const Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: ValueListenableBuilder<LatLng>(
              valueListenable: _pin,
              builder: (context, point, _) => Text(
                key: const Key('peta-koordinat'),
                'Lat: ${point.latitude.toStringAsFixed(6)}, '
                'Lng: ${point.longitude.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12, color: textGrey),
              ),
            ),
          ),
          TextButton.icon(
            key: const Key('peta-gps'),
            onPressed: _gpsBusy ? null : _pakaiGps,
            icon: const Icon(Icons.my_location, size: 18),
            label: Text(_gpsBusy ? 'Mencari...' : 'Gunakan Lokasi Saya'),
          ),
        ],
      ),
    ],
  );
}
