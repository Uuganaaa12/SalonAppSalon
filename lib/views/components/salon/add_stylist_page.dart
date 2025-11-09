import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:salon/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class AddStylistPage extends StatefulWidget {
  final String? stylistId;
  final Map<String, dynamic>? stylistData;

  const AddStylistPage({super.key, this.stylistId, this.stylistData});

  @override
  State<AddStylistPage> createState() => _AddStylistPageState();
}

class _AddStylistPageState extends State<AddStylistPage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneController = TextEditingController();
  final bioController = TextEditingController();
  final experienceController = TextEditingController();
  final specialtiesController = TextEditingController();

  bool loading = false;
  XFile? pickedImage;

  @override
  void initState() {
    super.initState();
    if (widget.stylistData != null) {
      nameController.text = widget.stylistData!['name'] ?? '';
      emailController.text = widget.stylistData!['email'] ?? '';
      phoneController.text = widget.stylistData!['phone'] ?? '';
      bioController.text = widget.stylistData!['bio'] ?? '';
      experienceController.text =
          widget.stylistData!['experience']?.toString() ?? '';
      specialtiesController.text =
          (widget.stylistData!['specialties'] as List<dynamic>?)?.join(', ') ??
          '';
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => pickedImage = image);
  }

  Future<void> saveStylist() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final salonId = prefs.getString("salonId");

    if (token == null || salonId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Token эсвэл salonId алга.")),
      );
      setState(() => loading = false);
      return;
    }

    final url = widget.stylistId == null
        ? Uri.parse("https://salonapp-l5y6.onrender.com/api/stylists")
        : Uri.parse(
            "https://salonapp-l5y6.onrender.com/api/stylists/${widget.stylistId}",
          );

    var request = widget.stylistId == null
        ? http.MultipartRequest('POST', url)
        : http.MultipartRequest('PUT', url);

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['name'] = nameController.text;
    request.fields['email'] = emailController.text;
    if (widget.stylistId == null)
      request.fields['password'] = passwordController.text;
    request.fields['phone'] = phoneController.text;
    request.fields['bio'] = bioController.text;
    request.fields['experience'] = experienceController.text;
    request.fields['specialties'] = specialtiesController.text;
    request.fields['salon'] = salonId;

    if (pickedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          pickedImage!.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );
    }

    try {
      final response = await request.send();
      setState(() => loading = false);

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        final resBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Амжилтгүй: $resBody")));
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Алдаа: $e")));
    }
  }

  Widget _buildImagePreview() {
    if (pickedImage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.withOpacity(0.3), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Image.file(
              File(pickedImage!.path),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => setState(() => pickedImage = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUpdate = widget.stylistId != null;

    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.arrow_back_ios, color: AppColors.background),
        title: Text(
          isUpdate ? " Гоо сайханч засах" : "Шинэ гоо сайханч нэмэх",
          style: TextStyle(color: AppColors.background),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Нэр"),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Нэр оруулна уу" : null,
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: "Имэйл"),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Имэйл оруулна уу";
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(v)) {
                        return "Зөв имэйл хаяг оруулна уу";
                      }
                      return null;
                    },
                  ),
                  if (!isUpdate)
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: "Нууц үг"),
                      obscureText: true,
                      validator: (v) =>
                          v == null || v.isEmpty ? "Нууц үг оруулна уу" : null,
                    ),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Утас"),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Утас оруулна уу";
                      // Зөвхөн тоо шалгах
                      if (!RegExp(r'^\d+$').hasMatch(v)) {
                        return "Зөвхөн тоо оруулна уу";
                      }
                      // 8 оронтой эсэх шалгах
                      if (v.length != 8) {
                        return "Утас 8 оронтой байх ёстой";
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: bioController,
                    decoration: const InputDecoration(labelText: "Танилцуулга"),
                    maxLines: 3,
                  ),
                  TextFormField(
                    controller: experienceController,
                    decoration: const InputDecoration(
                      labelText: "Туршлага (жил)",
                    ),
                    keyboardType: TextInputType.number,
                    // validator: (v) =>
                    //     v == null || v.isEmpty ? "Туршлага оруулна уу" : null,
                  ),
                  TextFormField(
                    controller: specialtiesController,
                    decoration: const InputDecoration(
                      labelText: "Тусгай чиглэлүүд (, тусгаарлаж бич)",
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Зураг сонгох товч
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: pickImage,
                      icon: Icon(
                        pickedImage == null ? Icons.add_a_photo : Icons.edit,
                      ),
                      label: Text(
                        pickedImage == null ? "Зураг сонгох" : "Зураг солих",
                        style: const TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  // Зургийн preview
                  _buildImagePreview(),

                  const SizedBox(height: 20),

                  // Хадгалах товч
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : saveStylist,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: loading ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isUpdate ? "Хадгалах" : "Бүртгэх",
                        style: const TextStyle(
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
          if (loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
