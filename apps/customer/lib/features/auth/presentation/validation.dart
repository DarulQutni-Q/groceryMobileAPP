String? emailError(String? value) {
  if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
  if (value.trim().length > 254 ||
      !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
    return 'Format email tidak valid';
  }
  return null;
}

String? phoneError(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Nomor handphone wajib diisi';
  }
  var number = value.replaceAll(RegExp(r'[ ()-]'), '');
  if (number.startsWith('+')) number = number.substring(1);
  if (number.startsWith('62')) {
    number = number.substring(2);
  } else if (number.startsWith('0')) {
    number = number.substring(1);
  }
  return RegExp(r'^8[0-9]{8,11}$').hasMatch(number)
      ? null
      : 'Nomor handphone Indonesia tidak valid';
}

String? passwordError(String? value) {
  final password = value ?? '';
  if (password.length < 8 || password.length > 20) {
    return 'Kata sandi harus 8 sampai 20 karakter';
  }
  if (!RegExp(r'[a-zA-Z]').hasMatch(password) ||
      !RegExp(r'[0-9]').hasMatch(password) ||
      !RegExp(r'[^a-zA-Z0-9\s]').hasMatch(password)) {
    return 'Kata sandi perlu huruf, angka, dan karakter khusus';
  }
  return null;
}
