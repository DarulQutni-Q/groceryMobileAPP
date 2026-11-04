import 'package:flutter/material.dart';

import 'api.dart';
import 'pages/pengguna_page.dart';
import 'pages/pesanan_page.dart';
import 'pages/ringkasan_page.dart';
import 'pages/toko_page.dart';
import 'pages/versi_page.dart';
import 'pages/voucher_promo_page.dart';
import 'widgets.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  final _api = AdminApi();
  bool _memuat = true;
  bool _masuk = false;

  @override
  void initState() {
    super.initState();
    _api.muatToken().then((_) {
      if (mounted) {
        setState(() {
          _masuk = _api.token != null;
          _memuat = false;
        });
      }
    });
  }

  void _keluar() {
    _api.logout();
    setState(() => _masuk = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GardenMart Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: hijauTua,
          primary: hijauTua,
        ),
        scaffoldBackgroundColor: latar,
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dataTableTheme: const DataTableThemeData(
          // Default DataTable membatasi tinggi baris ke 48px sehingga teks
          // multi-baris (mis. alamat toko) terpotong; biarkan baris tumbuh
          // mengikuti isi.
          dataRowMaxHeight: double.infinity,
        ),
      ),
      home: _memuat
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _masuk
              ? Shell(api: _api, onKeluar: _keluar)
              : LoginPage(
                  api: _api,
                  onMasuk: () => setState(() => _masuk = true),
                ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.api, required this.onMasuk});

  final AdminApi api;
  final VoidCallback onMasuk;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _memuat = false;
  String? _galat;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _memuat = true;
      _galat = null;
    });
    try {
      await widget.api.login(_email.text.trim(), _password.text);
      widget.onMasuk();
    } catch (error) {
      setState(() {
        _galat = AdminApi.pesanGalat(error) ?? 'Login gagal';
        _memuat = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'GardenMart Admin',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: hijauTua,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masuk dengan akun admin server.',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      key: const Key('login-email'),
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email admin',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      ),
                      validator: (v) =>
                          (v ?? '').contains('@') ? null : 'Email tidak valid',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('login-password'),
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kata sandi',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                      ),
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Kata sandi wajib diisi' : null,
                      onFieldSubmitted: (_) => _masuk(),
                    ),
                    if (_galat != null) ...[
                      const SizedBox(height: 16),
                      Text(_galat!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _memuat ? null : _masuk,
                      child: _memuat
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Akun admin dibuat dari ADMIN_EMAIL dan '
                      'ADMIN_PASSWORD di environment server.',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Menu {
  ringkasan('Ringkasan', Icons.dashboard),
  pesanan('Pesanan', Icons.receipt_long),
  toko('Toko', Icons.store),
  pengguna('Pengguna', Icons.people),
  voucherPromo('Voucher & Promo', Icons.local_offer),
  versiKesehatan('Versi & Kesehatan', Icons.health_and_safety);

  const _Menu(this.label, this.icon);
  final String label;
  final IconData icon;
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.api, required this.onKeluar});

  final AdminApi api;
  final VoidCallback onKeluar;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  var _menu = _Menu.ringkasan;

  Widget _halaman() {
    switch (_menu) {
      case _Menu.ringkasan:
        return RingkasanPage(api: widget.api, onUnauthorized: widget.onKeluar);
      case _Menu.pesanan:
        return PesananPage(api: widget.api, onUnauthorized: widget.onKeluar);
      case _Menu.toko:
        return TokoPage(api: widget.api, onUnauthorized: widget.onKeluar);
      case _Menu.pengguna:
        return PenggunaPage(api: widget.api, onUnauthorized: widget.onKeluar);
      case _Menu.voucherPromo:
        return VoucherPromoPage(
          api: widget.api,
          onUnauthorized: widget.onKeluar,
        );
      case _Menu.versiKesehatan:
        return VersiKesehatanPage(
          api: widget.api,
          onUnauthorized: widget.onKeluar,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, batas) {
        if (batas.maxWidth >= 900) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('GardenMart Admin'),
              backgroundColor: hijauTua,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  tooltip: 'Keluar',
                  onPressed: widget.onKeluar,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NavigationRail(
                  selectedIndex: _Menu.values.indexOf(_menu),
                  onDestinationSelected: (i) =>
                      setState(() => _menu = _Menu.values[i]),
                  labelType: NavigationRailLabelType.all,
                  destinations: _Menu.values
                      .map(
                        (m) => NavigationRailDestination(
                          icon: Icon(m.icon),
                          label: Text(m.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: _halaman(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('GardenMart Admin'),
            backgroundColor: hijauTua,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                tooltip: 'Keluar',
                onPressed: widget.onKeluar,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          drawer: Drawer(
            child: ListView(
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: hijauTua),
                  child: Text(
                    'GardenMart Admin',
                    style: TextStyle(color: Colors.white, fontSize: 22),
                  ),
                ),
                for (final m in _Menu.values)
                  ListTile(
                    leading: Icon(m.icon),
                    title: Text(m.label),
                    selected: m == _menu,
                    onTap: () {
                      setState(() => _menu = m);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: _halaman(),
              ),
            ),
          ),
        );
      },
    );
  }
}
