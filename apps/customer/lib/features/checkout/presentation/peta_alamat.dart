import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';

import '../../../core/theme.dart';

/// Titik default peta: Dewantara (sekitar Keude Krueng Geukueh), dipakai
/// kalau alamat belum punya titik tersimpan dan user belum memakai GPS.
/// Ini BUKAN lokasi palsu yang disimpan: titik ini tidak pernah dikirim
/// ke backend kalau user tidak menggeser peta atau memakai GPS.
const dewantaraDefault = LatLng(5.2443, 97.0248);

gmaps.LatLng _keGmaps(LatLng p) => gmaps.LatLng(p.latitude, p.longitude);
LatLng _dariGmaps(gmaps.LatLng p) => LatLng(p.latitude, p.longitude);

/// Peta Google Maps dengan pin tengah: pin diam di tengah layar,
/// koordinatnya mengikuti posisi peta saat digeser. Dipakai di formulir
/// alamat dan di halaman pemilih titik GPS.
///
/// API key Google Maps dibaca Android dari local.properties
/// (MAPS_API_KEY) lewat manifest placeholder; iOS dari AppDelegate.
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
  gmaps.GoogleMapController? _controller;
  late final _pin = ValueNotifier<LatLng>(widget.initial);
  bool _gpsBusy = false;
  bool _suppressCameraMove = false;

  /// Di widget test, GoogleMap tidak dirender (platform view tidak ada
  /// di flutter_test). Sebagai gantinya tampil placeholder polos supaya
  /// pin, tombol GPS, dan teks koordinat tetap bisa dites.
  static bool get _isTest =>
      Platform.environment['FLUTTER_TEST'] == 'true';

  @override
  void dispose() {
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
      _pin.value = target;
      widget.onPointChanged?.call(target, true);
      final controller = _controller;
      if (controller != null) {
        _suppressCameraMove = true;
        await controller.animateCamera(
          gmaps.CameraUpdate.newLatLngZoom(_keGmaps(target), 16),
        );
      }
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

  void _onCameraMove(gmaps.CameraPosition position) {
    final center = _dariGmaps(position.target);
    _pin.value = center;
    if (_suppressCameraMove) return;
    widget.onPointChanged?.call(center, true);
  }

  void _onCameraIdle() {
    _suppressCameraMove = false;
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
                  if (_isTest)
                    const Center(
                      child: Text(
                        'Peta Google Maps',
                        style: TextStyle(color: textGrey),
                      ),
                    )
                  else
                    gmaps.GoogleMap(
                      initialCameraPosition: gmaps.CameraPosition(
                        target: _keGmaps(widget.initial),
                        zoom: 15,
                      ),
                      minMaxZoomPreference:
                          const gmaps.MinMaxZoomPreference(3, 19),
                      onMapCreated: (controller) {
                        _controller = controller;
                      },
                      onCameraMove: _onCameraMove,
                      onCameraIdle: _onCameraIdle,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
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
