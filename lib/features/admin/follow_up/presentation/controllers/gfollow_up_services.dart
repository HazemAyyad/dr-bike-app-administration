import '../../data/models/followup_modle.dart';

class FollowUpServices {
  final List<FollowupModel> initialFollowups = [];

  final List<FollowupModel> informFollowups = [];

  final List<FollowupModel> finishAndAgreementFollowups = [];

  final List<FollowupModel> archivedFollowups = [];

  // singleton pattern
  static final FollowUpServices _instance = FollowUpServices._internal();
  factory FollowUpServices() => _instance;
  FollowUpServices._internal();
}
