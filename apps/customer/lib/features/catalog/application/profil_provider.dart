import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Override profil lokal (disimpan di perangkat). Dipakai tab Akun supaya
/// nama/telepon/email yang diubah di Ubah Profil langsung tampil tanpa
/// menunggu endpoint profil backend (belum ada; backend hanya punya
/// GET /auth/me).
class ProfilLokal {
  const ProfilLokal({
    this.nama,
    this.telepon,
    this.email,
    this.gender,
    this.avatarPath,
    this.tanggalLahir,
  });
  final String? nama;
  final String? telepon;
  final String? email;
  final String? gender;
  final String? avatarPath;
  final String? tanggalLahir;
}

class ProfilLokalNotifier extends StateNotifier<ProfilLokal> {
  ProfilLokalNotifier() : super(const ProfilLokal()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ProfilLokal(
      nama: prefs.getString('profil_nama'),
      telepon: prefs.getString('profil_telepon'),
      email: prefs.getString('profil_email'),
      gender: prefs.getString('profil_gender'),
      avatarPath: prefs.getString('profil_avatar'),
      tanggalLahir: prefs.getString('profil_tanggal_lahir'),
    );
  }

  Future<void> simpan({
    required String nama,
    required String telepon,
    required String email,
    required String gender,
    required String tanggalLahir,
    String? avatarPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profil_nama', nama);
    await prefs.setString('profil_telepon', telepon);
    await prefs.setString('profil_email', email);
    await prefs.setString('profil_gender', gender);
    await prefs.setString('profil_tanggal_lahir', tanggalLahir);
    if (avatarPath != null) {
      await prefs.setString('profil_avatar', avatarPath);
    }
    state = ProfilLokal(
      nama: nama,
      telepon: telepon,
      email: email,
      gender: gender,
      avatarPath: avatarPath ?? state.avatarPath,
      tanggalLahir: tanggalLahir,
    );
  }
}

final profilLokalProvider =
    StateNotifierProvider<ProfilLokalNotifier, ProfilLokal>(
      (ref) => ProfilLokalNotifier(),
    );
