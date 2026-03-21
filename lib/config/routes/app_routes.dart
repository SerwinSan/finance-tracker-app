/// Definisi named routes untuk navigasi.
library;

class AppRoutes {
  AppRoutes._();

  // Auth
  static const String login = '/login';
  static const String register = '/register';

  // Main
  static const String home = '/home';
  static const String main = '/main';

  // Pockets
  static const String pockets = '/pockets';
  static const String pocket_detail = '/pocket-detail';
  static const String pocket_form = '/pocket-form';

  // Transactions
  static const String transactions = '/transactions';
  static const String transaction_form = '/transaction-form';

  // Analytics
  static const String analytics = '/analytics';

  // Saving Goals
  static const String saving_goals = '/saving-goals';
  static const String saving_goal_detail = '/saving-goal-detail';
  static const String saving_goal_form = '/saving-goal-form';

  // Settings
  static const String settings = '/settings';
}
