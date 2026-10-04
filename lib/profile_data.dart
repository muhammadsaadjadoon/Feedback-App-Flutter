class ProfileData {
  final String bio, phone, location, website, photoUrl;
  final int avatar;
  const ProfileData({this.bio = '', this.phone = '', this.location = '', this.website = '', this.photoUrl = '', this.avatar = 0});
  factory ProfileData.fromMap(Map<String, dynamic> data) => ProfileData(
    bio: data['bio'] as String? ?? '', phone: data['phone'] as String? ?? '',
    location: data['location'] as String? ?? '', website: data['website'] as String? ?? '',
    photoUrl: data['photoUrl'] as String? ?? '', avatar: data['avatar'] as int? ?? 0);
  Map<String, dynamic> toMap() => {'bio': bio.trim(), 'phone': phone.trim(), 'location': location.trim(), 'website': website.trim(), 'photoUrl': photoUrl.trim(), 'avatar': avatar};
  static bool validUrl(String value) {
    if (value.trim().isEmpty) { return true; }
    final uri = Uri.tryParse(value.trim());
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }
  bool get valid => bio.length <= 300 && phone.length <= 30 && location.length <= 100 && website.length <= 250 && photoUrl.length <= 500 && avatar >= 0 && avatar <= 4 && validUrl(website) && validUrl(photoUrl);
}
