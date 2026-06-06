import 'package:flutter/material.dart';

import '../shared/user_profile_content.dart';
import 'superadmin_scaffold.dart';

class SuperadminProfileScreen extends StatelessWidget {
  const SuperadminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SuperadminScaffold(
      title: 'Profile',
      body: UserProfileContent(rolePrefix: 'superadmin'),
    );
  }
}
