import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_studio/profile_data.dart';
import 'package:feedback_studio/store.dart';
void main() {
  test('Profile validates HTTPS URLs and bounds', () {
    expect(const ProfileData(website: 'https://example.com', avatar: 4).valid, isTrue);
    expect(const ProfileData(photoUrl: 'http://example.com/photo.png').valid, isFalse);
    expect(const ProfileData(avatar: 5).valid, isFalse);
    expect(ProfileData(bio: 'a' * 301).valid, isFalse);
  });
  test('Demo profiles remain separated by account and survive sign-in switching', () async {
    final store = AppStore(demo: true)..enterDemo(false);
    await store.saveProfile('Saad Jadoon', const ProfileData(bio: 'Flutter developer', location: 'Haripur', avatar: 3));
    expect(store.name, 'Saad Jadoon');
    expect(store.profile.location, 'Haripur');
    store.enterDemo(true);
    expect(store.profile.bio, '');
    store.enterDemo(false);
    expect(store.profile.bio, 'Flutter developer');
    await expectLater(store.saveProfile('Saad', const ProfileData(avatar: 9)), throwsArgumentError);
    store.dispose();
  });
}
