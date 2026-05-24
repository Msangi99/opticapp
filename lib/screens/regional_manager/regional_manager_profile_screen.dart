import 'package:flutter/material.dart';

import '../shared/user_profile_content.dart';
import 'regional_manager_scaffold.dart';

class RegionalManagerProfileScreen extends StatelessWidget {
  const RegionalManagerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegionalManagerScaffold(
      title: 'Profile',
      body: UserProfileContent(rolePrefix: 'regional-manager'),
    );
  }
}
