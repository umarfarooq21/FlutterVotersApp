import 'package:flutter/foundation.dart';
import 'package:quiz_app/models/plan777_mobile_response.dart';
import 'package:quiz_app/services/api_service.dart';
import 'package:quiz_app/services/auth_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImpactController extends ChangeNotifier {
  static const personalGoalPrefKey = 'impact.personal_goal_voters';

  int personalGoal = 10;
  int confirmedVoters = 0;
  bool isVoterImpactLoading = true;
  String? voterImpactError;

  Plan777MobileResponse? plan777;
  bool isPlan777Loading = true;
  String? plan777Error;

  Future<void> bootstrap() async {
    await loadGoal();
    await Future.wait([loadVoterImpact(), loadPlan777()]);
  }

  Future<void> loadGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(personalGoalPrefKey);
    if (stored != null && stored > 0) {
      personalGoal = stored;
      notifyListeners();
    }
  }

  Future<void> saveGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(personalGoalPrefKey, goal);
    personalGoal = goal;
    notifyListeners();
  }

  Future<void> loadVoterImpact() async {
    isVoterImpactLoading = true;
    voterImpactError = null;
    notifyListeners();

    try {
      final loggedIn = await AuthStorage.hasSession();
      if (!loggedIn) {
        isVoterImpactLoading = false;
        confirmedVoters = 0;
        voterImpactError = 'Sign in to see your goal.';
        notifyListeners();
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        isVoterImpactLoading = false;
        confirmedVoters = 0;
        voterImpactError = 'Sign in to see your goal.';
        notifyListeners();
        return;
      }

      final response = await ApiService.voterImpact(
        userId: userId,
        token: token,
      );

      if (response == null) {
        isVoterImpactLoading = false;
        voterImpactError = 'Could not load your goal.';
        notifyListeners();
        return;
      }

      final serverGoal = response.goal;
      if (serverGoal > 0) {
        await saveGoal(serverGoal);
      }

      if (serverGoal > 0) {
        personalGoal = serverGoal;
      }
      confirmedVoters = response.confirmedVoters;
      isVoterImpactLoading = false;
      voterImpactError = null;
      notifyListeners();
    } catch (e, st) {
      debugPrint('ImpactController.loadVoterImpact: $e\n$st');
      isVoterImpactLoading = false;
      voterImpactError = 'Could not load your goal.';
      notifyListeners();
    }
  }

  Future<void> loadPlan777() async {
    isPlan777Loading = true;
    plan777Error = null;
    notifyListeners();

    try {
      final loggedIn = await AuthStorage.hasSession();
      if (!loggedIn) {
        isPlan777Loading = false;
        plan777 = null;
        plan777Error = 'Sign in to view the community goal.';
        notifyListeners();
        return;
      }

      final userId = await AuthStorage.getUserId();
      final token = await AuthStorage.getAccessToken();
      if (userId == null || token == null || userId.isEmpty || token.isEmpty) {
        isPlan777Loading = false;
        plan777 = null;
        plan777Error = 'Sign in to view the community goal.';
        notifyListeners();
        return;
      }

      final res = await ApiService.getPlan777Mobile(
        userId: userId,
        token: token,
      );

      if (res == null) {
        isPlan777Loading = false;
        if (plan777 == null) {
          plan777Error = 'Could not load community goal.';
        }
        notifyListeners();
        return;
      }

      plan777 = res;
      isPlan777Loading = false;
      plan777Error = null;
      notifyListeners();
    } catch (e, st) {
      debugPrint('ImpactController.loadPlan777: $e\n$st');
      isPlan777Loading = false;
      if (plan777 == null) {
        plan777Error = 'Could not load community goal.';
      }
      notifyListeners();
    }
  }
}
