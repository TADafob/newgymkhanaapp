import 'package:nrbgymkhana/features/Profile/domain/entities/profile_data.dart';
import 'package:nrbgymkhana/features/Profile/domain/repo/profile_repo.dart';
import '../../domain/entities/user_data.dart';
import '../datasources/firestore_service.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final FirestoreService _firestoreService;

  ProfileRepositoryImpl(this._firestoreService);

  @override
  Future<UserData> fetchUserData() async {
    final data = await _firestoreService.getUserRelatedData();

    return UserData(
      activeSubscriptions: data['subscriptionsCount'] ?? 0,
    );
  }

  @override
  Future<Profile> fetchProfile(String uid) async {
    final data = await _firestoreService.getMemberData(uid);

    // Get spouse details if available.
    final spouseData = data['Fam_Members']?['Spouse'] != null
        ? await _firestoreService.getMemberByUserId(data['Fam_Members']['Spouse'])
        : null;

    // Get children details if available.
    final childrenData = data['Fam_Members']?['Children'] != null
        ? await _firestoreService.getMembersByUserIds(
            List<String>.from(data['Fam_Members']['Children'] as List))
        : <Map<String, dynamic>>[];

    return Profile.fromMap(data, spouseData, childrenData);
  }
}
