import 'package:flutter/material.dart';

import '../shared/user_profile_content.dart';
import '../agent/agent_scaffold.dart';

class AgentProfileScreen extends StatelessWidget {
  const AgentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AgentScaffold(
      title: 'Profile',
      body: UserProfileContent(rolePrefix: 'agent'),
    );
  }
}
