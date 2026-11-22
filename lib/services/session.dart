import '../models/models.dart';

/// Holds the signed-in user's profile so pushed pages (which live above the shell
/// in the Navigator) can read it. Updated by UserRouter in main.dart.
class Session {
  static AppUser? user;
}
