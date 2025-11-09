import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:salon/theme/app_colors.dart';
import 'package:salon/views/pages/middle/login_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> salonData = {};
  bool isLoading = true;
  bool isEditing = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  File? newAvatar;
  List<File> newImages = [];

  @override
  void initState() {
    super.initState();
    fetchSalonProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> fetchSalonProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final salonId = prefs.getString("salonId");

    try {
      final res = await http.get(
        Uri.parse("https://salonapp-l5y6.onrender.com/api/salons/$salonId"),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          salonData = data;
          nameController.text = data['name'] ?? '';
          phoneController.text = data['phone'] ?? '';
          addressController.text = data['address'] ?? '';
          descriptionController.text = data['description'] ?? '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> updateSalonProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final salonId = prefs.getString("salonId");

    if (token == null || salonId == null) return;

    try {
      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("https://salonapp-l5y6.onrender.com/api/salons/$salonId"),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['name'] = nameController.text;
      request.fields['phone'] = phoneController.text;
      request.fields['address'] = addressController.text;
      request.fields['description'] = descriptionController.text;
      request.fields['isActive'] = salonData['isActive'].toString();

      // Add new avatar if selected
      if (newAvatar != null) {
        request.files.add(
          await http.MultipartFile.fromPath('avatar', newAvatar!.path),
        );
      }

      // Add new images if selected
      for (var img in newImages) {
        request.files.add(
          await http.MultipartFile.fromPath('images', img.path),
        );
      }

      var response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        await fetchSalonProfile();
        if (!mounted) return;
        setState(() {
          isEditing = false;
          newAvatar = null;
          newImages = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Амжилттай шинэчлэгдлээ!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Алдаа гарлаа: $e')));
    }
  }

  Future<void> pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => newAvatar = File(picked.path));
    }
  }

  Future<void> pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        newImages = picked.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> removeImage(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final salonId = prefs.getString("salonId");

    try {
      final res = await http.delete(
        Uri.parse(
          "https://salonapp-l5y6.onrender.com/api/salons/$salonId/images",
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'imageUrl': url}),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        await fetchSalonProfile();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Зураг устгагдлаа!')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Алдаа гарлаа: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar section
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: newAvatar != null
                      ? FileImage(newAvatar!)
                      : (salonData['avatar'] != null
                            ? NetworkImage(salonData['avatar'])
                            : const AssetImage('assets/images/bgImage.jpg')
                                  as ImageProvider),
                ),
                if (isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: pickAvatar,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Profile information card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Салоны мэдээлэл",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(isEditing ? Icons.cancel : Icons.edit),
                          onPressed: () {
                            if (!mounted) return;
                            setState(() {
                              isEditing = !isEditing;
                              if (!isEditing) {
                                newAvatar = null;
                                newImages = [];
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildProfileField(
                      "Салоны нэр",
                      isEditing ? null : salonData['name'],
                      isEditing ? nameController : null,
                      Icons.business,
                    ),
                    const SizedBox(height: 15),
                    _buildProfileField(
                      "Утас",
                      isEditing ? null : salonData['phone'],
                      isEditing ? phoneController : null,
                      Icons.phone,
                    ),
                    const SizedBox(height: 15),
                    _buildProfileField(
                      "Хаяг",
                      isEditing ? null : salonData['address'],
                      isEditing ? addressController : null,
                      Icons.location_on,
                    ),
                    const SizedBox(height: 15),
                    _buildProfileField(
                      "Тайлбар",
                      isEditing ? null : salonData['description'],
                      isEditing ? descriptionController : null,
                      Icons.description,
                      maxLines: 3,
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => updateSalonProfile(),
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
            ),
            const SizedBox(height: 20),

            // Images section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Зурагнууд",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.add_a_photo),
                    onPressed: pickImages,
                  ),
              ],
            ),

            // Display new images if in editing mode
            if (isEditing && newImages.isNotEmpty) ...[
              const Text(
                "Шинэ зурагнууд:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: newImages.map<Widget>((img) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          img,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              newImages.remove(img);
                            });
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Display existing images
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: (salonData['images'] ?? []).map<Widget>((img) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        img,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (isEditing)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => removeImage(img),
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Active status toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Салон ажилж байгаа эсэх:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Switch(
                  value: salonData['isActive'] ?? false,
                  onChanged: (val) {
                    if (!mounted) return;
                    setState(() {
                      salonData['isActive'] = val;
                    });
                    updateSalonProfile();
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Logout button
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.only(
                    top: 8.0,
                    left: 100.0,
                    bottom: 8.0,
                    right: 100.0,
                  ),
                ),
                child: const Text('Гарах', style: TextStyle(fontSize: 18)),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('token');
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(title: "Нэвтрэх"),
                    ),
                    (route) => false,
                  );
                },
              ),
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
        if (controller != null)
          TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        else
          Container(
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
}
