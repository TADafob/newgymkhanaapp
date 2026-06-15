import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/Profile/data/datasources/firestore_service.dart';
import 'package:nrbgymkhana/features/Profile/data/repositories/profile_repo_impl.dart';
import 'package:nrbgymkhana/features/Profile/domain/entities/user_data.dart';
import 'package:nrbgymkhana/features/Profile/domain/entities/profile_data.dart';
import 'package:nrbgymkhana/features/Profile/domain/repo/profile_repo.dart';

// Provider for the unified FirestoreService.
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Provider for the ProfileRepository implementation.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return ProfileRepositoryImpl(service);
});

// FutureProvider for user data (e.g., bookings, transactions, subscriptions).
final userDataProvider = FutureProvider<UserData>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.fetchUserData();
});

// FutureProvider.family for profile data by uid.
final profileProvider = FutureProvider.family<Profile, String>((ref, uid) async {
  final repository = ref.watch(profileRepositoryProvider);
  return await repository.fetchProfile(uid);
});
