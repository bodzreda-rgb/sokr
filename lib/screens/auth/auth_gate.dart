import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/common_widgets.dart';
import '../admin/admin_dashboard.dart';
import '../shell/main_shell.dart';
import 'login_page.dart';

// da el "bawab": by-listen 3la el auth state
// law mafish session -> Login, law fe -> bngeb el role (admin aw patient)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthService.instance.authChanges,
      builder: (context, snapshot) {
        // session persistence: Supabase by7fz el session lw7do
        final session = AuthService.instance.session;
        if (session == null) return const LoginPage();
        // el key by5aly el RoleRouter yt3ml mn el awel lw el user et8ayar
        return RoleRouter(key: ValueKey(session.user.id));
      },
    );
  }
}

// bngeb el profile mara wa7da w n-route 3la 7asab el role
class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  late Future<UserModel> _future;

  @override
  void initState() {
    super.initState();
    _future = AuthService.instance.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncView<UserModel>(
        future: _future,
        onRetry: () => setState(() => _future = AuthService.instance.loadProfile()),
        // el admin yro7 el admin dashboard, w el patient yro7 el app el 3adi
        builder: (user) => user.role == UserRoles.admin ? const AdminDashboard() : const MainShell(),
      ),
    );
  }
}
