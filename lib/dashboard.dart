import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  List<Barang> _listBarang = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _stokController = TextEditingController();
  final _kategoriController = TextEditingController();
  final _searchController = TextEditingController();

  String _searchQuery = '';
  File? _profileImage;
  String? _profileImageUrl; // Untuk menyimpan URL gambar di web

  // Base URL API
  final String _baseUrl = 'http://127.0.0.1:8000/api/barang';

  @override
  void initState() {
    super.initState();
    _fetchBarang();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _stokController.dispose();
    _kategoriController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil data dari API
  Future<void> _fetchBarang() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _listBarang = data.map((item) => Barang.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  // Fungsi untuk memilih foto profil - SOLUSI UNTUK WEB
  Future<void> _pickProfileImage() async {
    if (kIsWeb) {
      // Untuk Web - menggunakan image network (contoh)
      setState(() {
        _profileImageUrl = 'https://via.placeholder.com/150/1E88E5/FFFFFF?text=MFW';
      });
      _showSnackBar('Untuk web, silakan gunakan URL gambar', Colors.blue);
    } else {
      // Untuk Mobile - menggunakan image picker biasa
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    }
  }

  // Widget untuk menampilkan gambar profile yang kompatibel dengan web dan mobile
  Widget _buildProfileImage() {
    if (kIsWeb) {
      // Untuk Web
      return _profileImageUrl != null
          ? ClipOval(
              child: Image.network(
                _profileImageUrl!,
                fit: BoxFit.cover,
                width: 120,
                height: 120,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    size: 60,
                    color: Color(0xFF1E88E5),
                  );
                },
              ),
            )
          : const Icon(
              Icons.person,
              size: 60,
              color: Color(0xFF1E88E5),
            );
    } else {
      // Untuk Mobile
      return _profileImage != null
          ? ClipOval(
              child: Image.file(
                _profileImage!,
                fit: BoxFit.cover,
                width: 120,
                height: 120,
              ),
            )
          : const Icon(
              Icons.person,
              size: 60,
              color: Color(0xFF1E88E5),
            );
    }
  }

  // Widget untuk menampilkan gambar profile kecil di header
  Widget _buildSmallProfileImage() {
    if (kIsWeb) {
      // Untuk Web
      return _profileImageUrl != null
          ? ClipOval(
              child: Image.network(
                _profileImageUrl!,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.person,
                    color: Color(0xFF1E88E5),
                    size: 28,
                  );
                },
              ),
            )
          : const Icon(
              Icons.person,
              color: Color(0xFF1E88E5),
              size: 28,
            );
    } else {
      // Untuk Mobile
      return _profileImage != null
          ? ClipOval(
              child: Image.file(
                _profileImage!,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(
              Icons.person,
              color: Color(0xFF1E88E5),
              size: 28,
            );
    }
  }

  // Fungsi untuk menambah barang ke API
  Future<void> _tambahBarangAPI(Barang barang) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama': barang.nama,
          'harga': barang.harga,
          'stok': barang.stok,
          'kategori': barang.kategori,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchBarang(); // Refresh data
        _showSnackBar('✓ Barang berhasil ditambahkan!', Colors.green);
      } else {
        _showSnackBar('Gagal menambah barang: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  // Fungsi untuk mengupdate barang di API
  Future<void> _updateBarangAPI(Barang barang) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${barang.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama': barang.nama,
          'harga': barang.harga,
          'stok': barang.stok,
          'kategori': barang.kategori,
        }),
      );

      if (response.statusCode == 200) {
        await _fetchBarang(); // Refresh data
        _showSnackBar('✓ Barang berhasil diubah!', Colors.blue);
      } else {
        _showSnackBar('Gagal mengubah barang: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  // Fungsi untuk menghapus barang dari API
  Future<void> _deleteBarangAPI(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$id'));

      if (response.statusCode == 200) {
        await _fetchBarang(); // Refresh data
        _showSnackBar('✓ Barang berhasil dihapus!', Colors.red);
      } else {
        _showSnackBar('Gagal menghapus barang: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  List<Barang> get _filteredBarang {
    if (_searchQuery.isEmpty) {
      return _listBarang;
    }
    return _listBarang.where((barang) {
      return barang.nama.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          barang.kategori.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _tambahBarang() {
    _clearControllers();
    _showFormDialog(
      title: 'Tambah Barang Baru',
      icon: Icons.add_circle_outline,
      onSave: () {
        if (_validateForm()) {
          final newBarang = Barang(
            id: 0, // ID akan digenerate oleh server
            nama: _namaController.text,
            harga: int.parse(_hargaController.text),
            stok: int.parse(_stokController.text),
            kategori: _kategoriController.text,
          );
          _tambahBarangAPI(newBarang);
          Navigator.pop(context);
          _clearControllers();
        }
      },
    );
  }

  void _editBarang(Barang barang) {
    _namaController.text = barang.nama;
    _hargaController.text = barang.harga.toString();
    _stokController.text = barang.stok.toString();
    _kategoriController.text = barang.kategori;

    _showFormDialog(
      title: 'Edit Barang',
      icon: Icons.edit_outlined,
      onSave: () {
        if (_validateForm()) {
          final updatedBarang = Barang(
            id: barang.id,
            nama: _namaController.text,
            harga: int.parse(_hargaController.text),
            stok: int.parse(_stokController.text),
            kategori: _kategoriController.text,
          );
          _updateBarangAPI(updatedBarang);
          Navigator.pop(context);
          _clearControllers();
        }
      },
    );
  }

  void _hapusBarang(Barang barang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
            SizedBox(width: 12),
            Text(
              'Konfirmasi Hapus',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Apakah Anda yakin ingin menghapus barang ini?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    barang.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatCurrency(barang.harga)}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteBarangAPI(barang.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // PERBAIKAN: Profile yang kompatibel dengan web
  void _showProfile() {
    // Hitung statistik dari data API
    int totalBarang = _listBarang.length;
    int totalStok = _listBarang.fold<int>(0, (sum, item) => sum + item.stok);
    int totalNilai = _listBarang.fold<int>(0, (sum, item) => sum + (item.harga * item.stok));
    
    // Kategori unik
    Set<String> kategoriUnik = _listBarang.map((e) => e.kategori).toSet();
    int totalKategori = kategoriUnik.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E88E5),
              Color(0xFF64B5F6),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 30),
            
            // Foto Profile yang bisa diubah - KOMPATIBEL WEB
            Stack(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                    child: _buildProfileImage(), // Widget yang sudah dikustom untuk web/mobile
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E88E5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Informasi Profile - DI TENGAH
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Muhammad Fadmo Wijaya',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  '15/11/2025',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Data Real-time dari API',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Statistik - DI TENGAH
                      const Column(
                        children: [
                          Icon(Icons.analytics_outlined, 
                              color: Color(0xFF1E88E5), size: 32),
                          SizedBox(height: 8),
                          Text(
                            'Statistik Inventory',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Ringkasan data barang inventory',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Grid Statistik - DI TENGAH
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        children: [
                          _buildProfileItem(
                            icon: Icons.inventory_2_outlined,
                            title: 'Total Barang',
                            value: '$totalBarang Items',
                            color: Colors.blue,
                            subtitle: '$totalKategori Kategori',
                          ),
                          _buildProfileItem(
                            icon: Icons.shopping_cart_outlined,
                            title: 'Total Stok',
                            value: '$totalStok Units',
                            color: Colors.green,
                            subtitle: 'Tersedia',
                          ),
                          _buildProfileItem(
                            icon: Icons.attach_money,
                            title: 'Total Nilai',
                            value: 'Rp ${_formatCurrency(totalNilai)}',
                            color: Colors.orange,
                            subtitle: 'Inventory',
                          ),
                          _buildProfileItem(
                            icon: Icons.schedule, // GANTI DARI avg_time
                            title: 'Rata-rata',
                            value: totalBarang > 0 
                                ? 'Rp ${_formatCurrency(totalNilai ~/ totalStok)}'
                                : 'Rp 0',
                            color: Colors.purple,
                            subtitle: 'Per Unit',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Info Kategori - DI TENGAH
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.category_outlined, 
                                color: Color(0xFF1E88E5), size: 32),
                            const SizedBox(height: 12),
                            const Text(
                              'Kategori Tersedia',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              kategoriUnik.join(', '),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Last Update - DI TENGAH
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.update, size: 20, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'Terakhir update: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Tombol - DI TENGAH
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _fetchBarang,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh Data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Tutup Profile'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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

  // Widget _buildProfileItem yang diperbaiki
  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String subtitle = '',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  void _showFormDialog({
    required String title,
    required IconData icon,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E88E5).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFF1E88E5)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _namaController,
                label: 'Nama Barang',
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _kategoriController,
                label: 'Kategori',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _hargaController,
                label: 'Harga',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _stokController,
                label: 'Stok',
                icon: Icons.inventory_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _clearControllers();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E88E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF1E88E5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF64B5F6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 2),
        ),
      ),
    );
  }

  bool _validateForm() {
    if (_namaController.text.isEmpty) {
      _showSnackBar('Nama barang tidak boleh kosong', Colors.red);
      return false;
    }
    if (_kategoriController.text.isEmpty) {
      _showSnackBar('Kategori tidak boleh kosong', Colors.red);
      return false;
    }
    if (_hargaController.text.isEmpty) {
      _showSnackBar('Harga tidak boleh kosong', Colors.red);
      return false;
    }
    if (_stokController.text.isEmpty) {
      _showSnackBar('Stok tidak boleh kosong', Colors.red);
      return false;
    }
    return true;
  }

  void _clearControllers() {
    _namaController.clear();
    _hargaController.clear();
    _stokController.clear();
    _kategoriController.clear();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E88E5),
              Color(0xFF64B5F6),
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header dengan Profil
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dashboard Barang',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${_listBarang.length} Barang Tersedia',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _fetchBarang,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Refresh Data',
                    ),
                    Hero(
                      tag: 'profile_avatar',
                      child: GestureDetector(
                        onTap: _showProfile,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: _buildSmallProfileImage(), // Widget yang sudah dikustom
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari barang...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF1E88E5)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Loading/Error/List Barang
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E88E5)),
                              ),
                              SizedBox(height: 16),
                              Text('Memuat data...'),
                            ],
                          ),
                        )
                      : _errorMessage.isNotEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 80,
                                    color: Colors.red[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: _fetchBarang,
                                    child: const Text('Coba Lagi'),
                                  ),
                                ],
                              ),
                            )
                          : _filteredBarang.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        size: 80,
                                        color: Colors.grey[300],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchQuery.isEmpty
                                            ? 'Belum ada barang'
                                            : 'Barang tidak ditemukan',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: _filteredBarang.length,
                                  itemBuilder: (context, index) {
                                    final barang = _filteredBarang[index];
                                    return TweenAnimationBuilder(
                                      duration: Duration(milliseconds: 300 + (index * 100)),
                                      tween: Tween<double>(begin: 0, end: 1),
                                      builder: (context, double value, child) {
                                        return Transform.translate(
                                          offset: Offset(0, 50 * (1 - value)),
                                          child: Opacity(
                                            opacity: value,
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: _buildBarangCard(barang),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahBarang,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Barang'),
      ),
    );
  }

  Widget _buildBarangCard(Barang barang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editBarang(barang),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF64B5F6)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.inventory_2,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barang.nama,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64B5F6).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              barang.kategori,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E88E5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.inventory_outlined,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Stok: ${barang.stok}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatCurrency(barang.harga)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _editBarang(barang),
                      icon: const Icon(Icons.edit_outlined),
                      color: Colors.blue,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: () => _hapusBarang(barang),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Barang {
  final int id;
  final String nama;
  final int harga;
  final int stok;
  final String kategori;

  Barang({
    required this.id,
    required this.nama,
    required this.harga,
    required this.stok,
    required this.kategori,
  });

  // Factory method untuk membuat objek Barang dari JSON
  factory Barang.fromJson(Map<String, dynamic> json) {
    return Barang(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      harga: json['harga'] ?? 0,
      stok: json['stok'] ?? 0, // Default stok 0 jika tidak ada
      kategori: json['kategori'] ?? 'Umum', // Default kategori jika tidak ada
    );
  }
}