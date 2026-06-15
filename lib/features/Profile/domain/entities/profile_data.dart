class Profile {
  final String username;
  final Map<String, List<String>> connectees;
  final String email;
  final String phone;
  final String gender;
  final String dob;

  const Profile({
    required this.username,
    required this.email,
    required this.phone,
    required this.gender,
    required this.dob,
    required this.connectees,
  });

  factory Profile.fromMap(
    Map<String, dynamic> data,
    Map<String, dynamic>? spouseData,
    List<Map<String, dynamic>> childrenData,
  ) {
    return Profile(
      username: "${data['f_Name'] ?? ''} ${data['l_Name'] ?? ''}".trim(),
      email: data['email'] ?? 'N/A',
      phone: data['phone_Number'] ?? 'N/A',
      gender: data['gender'] ?? "N/A",
      dob: data['dob'] ?? "N/A",
      connectees: {
        "Spouse":
            spouseData != null ? ["${spouseData['f_Name'] ?? 'Unknown'}"] : [],
        "Children": childrenData
            .map((child) => (child['f_Name'] ?? 'Unknown') as String)
            .toList(),
      },
    );
  }
}
