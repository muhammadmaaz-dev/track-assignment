import 'dart:io';

void main() {
  final file = File('lib/screens/setting_screen.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll(
    r'''
  Future<void> _loadNotificationSetting() async {
    final enabled = await NotificationHelper.areNotificationsEnabled();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = enabled;
    });
  }
''',
    r'''
  Future<void> _loadNotificationSetting() async {
    final enabled = await NotificationHelper.areNotificationsEnabled();
    final isRing = await NotificationHelper.isRingEnabled();
    if (!mounted) return;

    setState(() {
      _notificationsEnabled = enabled;
      _ringed = isRing;
    });
  }
''',
  );

  if (!content.contains('Future<void> _toggleRing')) {
    content = content.replaceFirst(
      'Future<void> _toggleNotifications(bool value) async {',
      '''
  Future<void> _toggleRing(bool value) async {
    setState(() {
      _ringed = value;
    });
    await NotificationHelper.setRingEnabled(value);
  }

  Future<void> _toggleNotifications(bool value) async {''',
    );
  }

  file.writeAsStringSync(content);
}
