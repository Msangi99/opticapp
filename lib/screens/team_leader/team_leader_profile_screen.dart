import 'package:flutter/material.dart';

import '../shared/user_profile_content.dart';
import 'team_leader_scaffold.dart';

class TeamLeaderProfileScreen extends StatelessWidget {
  const TeamLeaderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeamLeaderScaffold(
      title: 'Profile',
      body: UserProfileContent(rolePrefix: 'team-leader'),
    );
  }
}
