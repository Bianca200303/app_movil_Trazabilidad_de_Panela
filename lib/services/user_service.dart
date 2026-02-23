import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:panela_sys/models/user_model.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('user_id, first_name, last_name')
          .order('first_name');

      
      
      final users = (response as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
      
      return users;
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('user_id, first_name, last_name')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      
      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  Future<UserModel> createUser(UserModel user) async {
    try {
      final response = await _supabase
          .from('users')
          .insert(user.toJson())
          .select('user_id, first_name, last_name')
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }
}
