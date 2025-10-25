import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:template/features/user/repository/auth_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final _authRepo = AuthRepository();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF5F6F5),
      navigationBar: const CupertinoNavigationBar(
        middle: Text('설정', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            _buildProfileSection(),

            const SizedBox(height: 40),

            _buildSectionTitle('데이터 관리'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _SettingsTile(
                    title: '데이터 초기화',
                    titleColor: Colors.red,
                    icon: CupertinoIcons.delete,
                    iconColor: Colors.red,
                    onTap: () => _showResetDialog(context),
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    title: '로그아웃',
                    titleColor: Colors.red,
                    icon: CupertinoIcons.square_arrow_right,
                    iconColor: Colors.red,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            _buildSectionTitle('정보'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _SettingsTile(
                    title: '고객센터 및 도움말',
                    icon: CupertinoIcons.question_circle,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  _SettingsTile(
                    title: '앱 버전',
                    icon: CupertinoIcons.info,
                    trailing: const Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user?.displayName ?? '이름 없음',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('데이터 초기화'),
        content: const Text('앱의 모든 작업 데이터를 초기화하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('초기화'),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _authRepo.clearAllData();

                if (mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (_) => const CupertinoAlertDialog(
                      title: Text('초기화 완료'),
                      content: Text('저장된 작업 데이터가 모두 삭제되었습니다.'),
                    ),
                  );

                  await Future.delayed(const Duration(seconds: 1));
                  if (mounted) Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: const Text('오류 발생'),
                      content: Text('데이터 초기화 중 오류가 발생했습니다.\n$e'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('확인'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('로그아웃'),
            onPressed: () async {
              Navigator.pop(context);
              await _authRepo.signOut();
              if (mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.icon,
    this.iconColor,
    this.titleColor,
    this.trailing,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: (iconColor ?? Colors.black).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, color: iconColor ?? Colors.black, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  CupertinoIcons.chevron_forward,
                  color: Colors.grey,
                  size: 18,
                ),
          ],
        ),
      ),
    );
  }
}
