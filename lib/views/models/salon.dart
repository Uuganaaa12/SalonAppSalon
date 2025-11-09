class Salon {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String description;
  final String history;
  final List<String> images;
  final String avatar;

  Salon({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
    required this.description,
    required this.history,
    required this.images,
    required this.avatar,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['_id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      email: json['email'],
      description: json['description'] ?? '',
      history: json['history'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      avatar: json['avatar'] ?? '',
    );
  }
}
