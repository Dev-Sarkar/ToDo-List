class Profile {
  String id;
  String name;

  Profile({required this.id, required this.name});

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] ?? '',
      name: map['fullname'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullname': name,
    };
  }
}
