import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dashboard.dart'; // <-- 1. IMPORT HALAMAN DASHBOARD

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modern Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      // 2. MENGATUR ROUTE (JALUR) NAVIGASI
      initialRoute: '/', // Halaman awal adalah login
      routes: {
        '/': (context) => const LoginPage(), // Route '/' untuk LoginPage
        '/dashboard': (context) => const Dashboard(), // Route '/dashboard' untuk Dashboard
      },
      // 'home' dihapus karena kita menggunakan 'initialRoute'
    );
  }
}

// Custom Painter untuk Menggambar Awan Sederhana
class CloudPainter extends CustomPainter {
  final double xOffset;

  CloudPainter(this.xOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8) // Awan putih semi-transparan
      ..style = PaintingStyle.fill;

    // Awan 1 (berubah posisi berdasarkan offset)
    _drawCloud(canvas, paint, Offset(-100.0 + xOffset * 0.5, size.height * 0.1));
    
    // Awan 2
    _drawCloud(canvas, paint, Offset(50.0 + xOffset * 0.7, size.height * 0.2));

    // Awan 3 (untuk sisi kanan)
    _drawCloud(canvas, paint, Offset(size.width - 150.0 + xOffset * 0.3, size.height * 0.05));
  }

  void _drawCloud(Canvas canvas, Paint paint, Offset offset) {
    // Bentuk awan dibuat dari lingkaran yang tumpang tindih
    canvas.drawCircle(offset.translate(30, 0), 20, paint);
    canvas.drawCircle(offset.translate(50, -10), 30, paint);
    canvas.drawCircle(offset.translate(80, 0), 25, paint);
    canvas.drawRRect( // Bagian dasar awan
      RRect.fromRectAndRadius(
        Rect.fromLTWH(offset.dx + 30, offset.dy - 10, 50, 20),
        const Radius.circular(10),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CloudPainter oldDelegate) {
    return oldDelegate.xOffset != xOffset;
  }
}

// Custom Painter untuk Lingkaran Berputar (Animasi Tambahan)
class CircleSpinnerPainter extends CustomPainter {
  final double rotation;

  CircleSpinnerPainter(this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final primaryColor = const Color(0xFF1E88E5);

    // Lingkaran luar (berputar)
    final circlePaint = Paint()
      ..color = primaryColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      rotation, // Start angle
      math.pi * 0.5, // Sweep angle
      false,
      circlePaint,
    );
    
    // Lingkaran dalam (berputar berlawanan)
    final innerRadius = radius * 0.7;
    final innerCirclePaint = Paint()
      ..color = primaryColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -rotation * 0.5, // Start angle (berlawanan)
      math.pi * 0.7, // Sweep angle
      false,
      innerCirclePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CircleSpinnerPainter oldDelegate) {
    return oldDelegate.rotation != rotation;
  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Tambahkan Controller untuk Animasi Awan dan Lingkaran Berputar
  late AnimationController _cloudController;
  late Animation<double> _cloudAnimation;
  late AnimationController _rotationController;
  late Animation<double> _rotationAnimation;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Inisialisasi Animasi Awan
    _cloudController = AnimationController(
      duration: const Duration(seconds: 45), // Durasi lambat untuk awan
      vsync: this,
    )..repeat();

    _cloudAnimation = Tween<double>(begin: 0.0, end: 400.0).animate(_cloudController); // Jarak geser

    // Inisialisasi Animasi Lingkaran Berputar
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10), // Durasi lebih cepat
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(_rotationController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cloudController.dispose(); // Jangan lupa dispose controller animasi
    _rotationController.dispose(); // Jangan lupa dispose controller animasi
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulasi proses login
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return; // Cek jika widget masih ada
        setState(() {
          _isLoading = false;
        });

        // 3. GANTI SNACKBAR DENGAN NAVIGASI KE DASHBOARD
        // Kita gunakan 'pushReplacementNamed' agar pengguna tidak bisa
        // kembali ke halaman login setelah berhasil masuk.
        Navigator.pushReplacementNamed(context, '/dashboard');

        /*
        // Kode SnackBar yang lama (sekarang diganti):
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
        */
      });
    }
  }
  
  // Fungsi dummy untuk menangani login sosial
  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login dengan $provider... (Belum diimplementasikan)'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // Widget untuk tombol login sosial
  Widget _buildSocialLoginButton(
      IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- Background dengan Animasi ---
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E88E5), // Biru tua
              Color(0xFF64B5F6), // Biru muda
              Color(0xFFE3F2FD), // Biru sangat muda
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 1. Animasi Awan
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _cloudAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: CloudPainter(_cloudAnimation.value),
                    child: Container(),
                  );
                },
              ),
            ),
            
            // 2. Animasi Lingkaran Berputar di Pojok Kiri Atas
            Positioned(
              top: -50,
              left: -50,
              child: SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: CustomPaint(
                        painter: CircleSpinnerPainter(0), // Rotasi diatur oleh Transform.rotate
                        child: Container(),
                      ),
                    );
                  },
                ),
              ),
            ),

            // --- Konten Login ---
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo atau Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 50,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Judul
                      const Text(
                        'Selamat Datang',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Silakan login untuk melanjutkan',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF64B5F6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1E88E5),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF64B5F6),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1E88E5),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password tidak boleh kosong';
                                  }
                                  if (value.length < 6) {
                                    return 'Password minimal 6 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              // Forgot Password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Fitur lupa password'),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Lupa Password?',
                                    style: TextStyle(
                                      color: Color(0xFF1E88E5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Login Button
                              SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E88E5),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // --- Tambahan Tombol Login Sosial ---
                      const Text(
                        'Atau login dengan:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Tombol Google
                          _buildSocialLoginButton(
                            Icons.g_mobiledata_outlined, // Tidak ada ikon Google yang bagus secara default, jadi pakai ini atau custom icon
                            const Color(0xFFDB4437), // Google Red
                            () => _handleSocialLogin('Google'),
                          ),
                          const SizedBox(width: 20),
                          
                          // Tombol GitHub (Menggunakan ikon umum karena tidak ada ikon GitHub default)
                          _buildSocialLoginButton(
                            Icons.code, // Ikon alternatif untuk GitHub
                            const Color(0xFF24292E), // GitHub Dark
                            () => _handleSocialLogin('GitHub'),
                          ),
                          const SizedBox(width: 20),
                          
                          // Tombol Facebook (Menggunakan ikon umum karena tidak ada ikon Facebook default)
                          _buildSocialLoginButton(
                            Icons.facebook, // Ikon alternatif untuk Facebook
                            const Color(0xFF4267B2), // Facebook Blue
                            () => _handleSocialLogin('Facebook'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Belum punya akun? ',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Halaman registrasi'),
                                ),
                              );
                            },
                            child: const Text(
                              'Daftar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                decorationColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
