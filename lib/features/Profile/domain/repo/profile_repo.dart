import 'package:nrbgymkhana/features/Profile/domain/entities/profile_data.dart';

import '../entities/user_data.dart';

abstract class ProfileRepository {
  Future<UserData> fetchUserData();
  Future<Profile> fetchProfile(String uid);
}

