import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Titik default peta: Dewantara (sekitar Keude Krueng Geukueh), dipakai
/// kalau toko belum punya titik tersimpan. Ini BUKAN lokasi yang disimpan:
/// titik ini tidak pernah dikirim ke backend kalau seller tidak menggeser
/// peta (lihat _titik di TokoEditor yang tetap null sampai ada geseran).
const dewantaraDefault = LatLng(5.2443, 97.0248);

/// Peta OpenStreetMap dengan pin tengah: pin diam di tengah layar,
/// koordinatnya mengikuti posisi peta saat digeser. Dipakai di formulir
/// Info Toko supaya seller bisa menandai lokasi tokonya sendiri.
class PetaToko extends StatefulWidget {
  const PetaToko({super.key, required this.initial, this.onPointChanged});
  final LatLng initial;
  final void Function(LatLng point)? onPointChanged;

  @override
  State<PetaToko> createState() => _PetaTokoState();
}

class _PetaTokoState extends State<PetaToko> {
  final _controller = MapController();
  late var _pin = widget.initial;

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
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: widget.initial,
                  initialZoom: 15,
                  onPositionChanged: (position, hasGesture) {
                    if (!hasGesture) return;
                    final center = position.center;
                    if (center == _pin) return;
                    setState(() => _pin = center);
                    widget.onPointChanged?.call(center);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // User-Agent wajib kebijakan tile OSM; tanpa ini
                    // flutter_map memberi peringatan proyek bisa diblokir.
                    userAgentPackageName: 'com.daerul.seller',
                  ),
                ],
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
