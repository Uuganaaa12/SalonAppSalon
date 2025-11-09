import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salon/theme/app_colors.dart';
import 'package:salon/views/pages/middle/login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> stylistData = {};
  List<Map<String, dynamic>> services = [];
  List<Map<String, dynamic>> categories = [];

  bool isLoading = true;
  bool isEditingProfile = false;
  bool isUploadingPhoto = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    bioController.dispose();
    experienceController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchStylistProfile(),
      _fetchCategories(),
      _fetchServices(),
    ]);
  }

  // Зураг сонгох функц
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // Зураг сонгосны дараа шууд upload хийх
        await _uploadPhoto();
      }
    } catch (e) {
      _showErrorSnackBar('Зураг сонгохад алдаа гарлаа: $e');
    }
  }

  // Зураг сонгох source сонгох диалог
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Зураг сонгох'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Камераас авах'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Галерээс сонгох'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Цуцлах'),
            ),
          ],
        );
      },
    );
  }

  // Зургийг сервер рүү upload хийх
  Future<void> _uploadPhoto() async {
    if (_selectedImage == null) return;

    setState(() {
      isUploadingPhoto = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final stylistId =
        prefs.getString("stylistId") ?? "68ce8a91d5f3e5990d206a50";

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
          "https://salonapp-l5y6.onrender.com/api/stylists/$stylistId/photo",
        ),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Зургийг multipart-д нэмэх
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo', // сервер дээрх field нэр
          _selectedImage!.path,
        ),
      );

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Profile мэдээллийг дахин авах
        await _fetchStylistProfile();
        _showSuccessSnackBar('Зураг амжилттай шинэчлэгдлээ!');
      } else {
        _showErrorSnackBar('Зураг upload хийхэд алдаа гарлаа');
        print('Upload error: $responseBody');
      }
    } catch (e) {
      _showErrorSnackBar('Зураг upload хийхэд алдаа гарлаа: $e');
      print('Upload exception: $e');
    } finally {
      setState(() {
        isUploadingPhoto = false;
        _selectedImage = null;
      });
    }
  }

  // Stylist мэдээлэл авах
  Future<void> _fetchStylistProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final stylistId =
        prefs.getString("stylistId") ?? "68ce8a91d5f3e5990d206a50";

    try {
      final res = await http.get(
        Uri.parse("https://salonapp-l5y6.onrender.com/api/stylists/$stylistId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          stylistData = data;
          nameController.text = data['name'] ?? '';
          phoneController.text = data['phone'] ?? '';
          emailController.text = data['email'] ?? '';
          bioController.text = data['bio'] ?? '';
          experienceController.text = data['experience']?.toString() ?? '';
        });
      }
    } catch (e) {
      print("Error fetching stylist profile: $e");
    }
  }

  // Categories авах
  Future<void> _fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    try {
      final res = await http.get(
        Uri.parse("https://salonapp-l5y6.onrender.com/api/services/categories"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          categories = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  // Services авах
  Future<void> _fetchServices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final stylistId =
        prefs.getString("stylistId") ?? "68ce8a91d5f3e5990d206a50";

    try {
      final res = await http.get(
        Uri.parse(
          "https://salonapp-l5y6.onrender.com/api/services/stylist/$stylistId",
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          services = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error fetching services: $e");
    }
  }

  // Stylist мэдээлэл шинэчлэх
  Future<void> _updateStylistProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final stylistId =
        prefs.getString("stylistId") ?? "68ce8a91d5f3e5990d206a50";

    final body = {
      'name': nameController.text,
      'phone': phoneController.text,
      'email': emailController.text,
      'bio': bioController.text,
      'experience': int.tryParse(experienceController.text) ?? 0,
    };

    try {
      final res = await http.put(
        Uri.parse("https://salonapp-l5y6.onrender.com/api/stylists/$stylistId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        await _fetchStylistProfile();
        setState(() => isEditingProfile = false);
        _showSuccessSnackBar('Профайл амжилттай шинэчлэгдлээ!');
      }
    } catch (e) {
      _showErrorSnackBar('Алдаа гарлаа: $e');
    }
  }

  // Service нэмэх/засах диалог
  void _openServiceForm({Map<String, dynamic>? service}) {
    final nameController = TextEditingController(text: service?["name"] ?? "");
    final descriptionController = TextEditingController(
      text: service?["description"] ?? "",
    );
    final priceController = TextEditingController(
      text: service?["price"]?.toString() ?? "",
    );
    final durationController = TextEditingController(
      text: service?["duration"]?.toString() ?? "",
    );
    String? selectedCategoryId = service?["category"]?["_id"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(service == null ? "Service нэмэх" : "Service засах"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "Үйлчилгээний нэр",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: "Тайлбар"),
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Үнэ"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: "Хугацаа (минут)",
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategoryId,
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category["_id"],
                      child: Text(category["name"]),
                    );
                  }).toList(),
                  onChanged: (val) {
                    selectedCategoryId = val;
                  },
                  decoration: const InputDecoration(labelText: "Ангилал"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Цуцлах"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty &&
                    selectedCategoryId != null) {
                  if (service == null) {
                    await _createService({
                      "name": nameController.text,
                      "description": descriptionController.text,
                      "price": double.tryParse(priceController.text) ?? 0,
                      "duration": int.tryParse(durationController.text) ?? 0,
                      "category": selectedCategoryId!,
                    });
                  } else {
                    await _updateService(service["_id"], {
                      "name": nameController.text,
                      "description": descriptionController.text,
                      "price": double.tryParse(priceController.text) ?? 0,
                      "duration": int.tryParse(durationController.text) ?? 0,
                      "category": selectedCategoryId!,
                    });
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(service == null ? "Нэмэх" : "Хадгалах"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createService(Map<String, dynamic> serviceData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    try {
      final res = await http.post(
        Uri.parse("https://salonapp-l5y6.onrender.com/api/services"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(serviceData),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _fetchServices();
        _showSuccessSnackBar('Service амжилттай нэмэгдлээ!');
      }
    } catch (e) {
      _showErrorSnackBar('Алдаа гарлаа: $e');
    }
  }

  Future<void> _updateService(
    String serviceId,
    Map<String, dynamic> serviceData,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    try {
      print("update service");
      final res = await http.put(
        Uri.parse("https://salonapp-l5y6.onrender.com/api/services/$serviceId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(serviceData),
      );
      print(res.statusCode);

      if (res.statusCode == 200) {
        await _fetchServices();
        _showSuccessSnackBar('Service амжилттай шинэчлэгдлээ!');
      }
    } catch (e) {
      _showErrorSnackBar('Алдаа гарлаа: $e');
    }
  }

  Future<void> _deleteService(String serviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    try {
      final res = await http.delete(
        Uri.parse("https://salonapp-l5y6.onrender.com/api/services/$serviceId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        await _fetchServices();
        _showSuccessSnackBar('Service амжилттай устгагдлаа!');
      }
    } catch (e) {
      _showErrorSnackBar('Алдаа гарлаа: $e');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stylist профайл хэсэг
            _buildProfileSection(),
            const SizedBox(height: 20),

            // Services хэсэг
            _buildServicesSection(),

            const SizedBox(height: 30),

            // Гарах товч
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile зураг ба зураг солих товч
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!) as ImageProvider
                      : stylistData['photo'] != null
                      ? NetworkImage(stylistData['photo'])
                      : const AssetImage('assets/images/bgImage.jpg')
                            as ImageProvider,
                ),
                if (isUploadingPhoto)
                  const Positioned.fill(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.black54,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: isUploadingPhoto ? null : _showImagePickerDialog,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
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
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Миний мэдээлэл",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(isEditingProfile ? Icons.cancel : Icons.edit),
                  onPressed: () {
                    setState(() {
                      isEditingProfile = !isEditingProfile;
                    });
                  },
                ),
              ],
            ),
            const Divider(),

            _buildProfileField(
              "Нэр",
              stylistData['name'],
              nameController,
              Icons.person,
            ),
            const SizedBox(height: 15),
            _buildProfileField(
              "Утас",
              stylistData['phone'],
              phoneController,
              Icons.phone,
            ),
            const SizedBox(height: 15),
            _buildProfileField(
              "И-мэйл",
              stylistData['email'],
              emailController,
              Icons.email,
            ),
            const SizedBox(height: 15),
            _buildProfileField(
              "Туршлага (жил)",
              stylistData['experience']?.toString(),
              experienceController,
              Icons.star,
            ),
            const SizedBox(height: 15),
            _buildProfileField(
              "Товч танилцуулга",
              stylistData['bio'],
              bioController,
              Icons.description,
              maxLines: 3,
            ),

            if (isEditingProfile) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateStylistProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Хадгалах"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServicesSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Миний үйлчилгээнүүд",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _openServiceForm(),
                ),
              ],
            ),
            const Divider(),

            if (services.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Үйлчилгээ байхгүй байна"),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      visualDensity: const VisualDensity(
                        horizontal: 0,
                        vertical: -2, // Бага зэрэг нэмэгдүүлэв
                      ),
                      leading: const CircleAvatar(
                        child: Icon(Icons.design_services),
                      ),
                      title: Text(service["name"] ?? ""),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service["description"] ?? ""),
                          Text(
                            "${service["price"]}төг ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Ангилал: ${service["category"]?["name"] ?? ""}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Дээд талд байрлуулах
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () => _openServiceForm(service: service),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 18,
                            ),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Устгах"),
                                  content: const Text(
                                    "Энэ үйлчилгээг устгахдаа итгэлтэй байна уу?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Цуцлах"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text("Устгах"),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await _deleteService(service["_id"]);
                              }
                            },
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(
    String label,
    String? value,
    TextEditingController? controller,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        if (isEditingProfile && controller != null)
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value ?? 'Мэдээлэл байхгүй',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('stylistId');

          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => const LoginPage(title: "Нэвтрэх"),
            ),
            (route) => false,
          );
        },
        child: const Text('Гарах', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
