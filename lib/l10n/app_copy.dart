import 'package:flutter/widgets.dart';

import 'feature_copy.dart';
import 'long_copy.dart';

String localizeAppCopy(String source, Locale locale) {
  if (locale.languageCode != 'fil' && locale.languageCode != 'tl') {
    return source;
  }

  final exact =
      _tagalogCopy[source] ??
      tagalogFeatureCopy[source] ??
      tagalogLongCopy[source];
  if (exact != null) {
    return exact;
  }

  for (final rule in _tagalogCopyRules) {
    final match = rule.pattern.firstMatch(source);
    if (match != null) {
      return rule.translate(match);
    }
  }

  return source;
}

extension AppCopyString on String {
  String localizedCopy(BuildContext context) {
    return localizeAppCopy(this, Localizations.localeOf(context));
  }
}

const Map<String, String> _tagalogCopy = {
  'About': 'Tungkol sa app',
  'About burnout': 'Tungkol sa burnout',
  'Accept': 'Tanggapin',
  'Account': 'Account',
  'Adjust photo': 'I-adjust ang photo',
  'AI insight': 'AI insight',
  'AI-powered nutrition tracker': 'AI-powered nutrition tracker',
  'Allow floating assistant': 'Payagan ang floating assistant',
  'Analyze': 'I-analyze',
  'Approximate values are okay.': 'Okay lang ang approximate values.',
  'Assistant': 'Assistant',
  'Assistant access pauses until you sign in again.':
      'Naka-pause ang assistant hanggang mag-sign in ka ulit.',
  'Back': 'Bumalik',
  'Back to log in': 'Bumalik sa log in',
  'Biometric not available': 'Hindi available ang biometric',
  'Biometric verification failed':
      'Hindi successful ang biometric verification',
  'Burnout is a chronic stress signal':
      'Ang burnout ay signal ng tuloy-tuloy na stress',
  'Burnout risk awareness and adaptive lifestyle support.':
      'Burnout-risk awareness at adaptive lifestyle support.',
  'Burnout risk score': 'Burnout risk score',
  'Burnout risk trend': 'Burnout risk trend',
  'Burnout score details': 'Burnout score details',
  'Cancel': 'Kanselahin',
  'Change avatar': 'Palitan ang avatar',
  'Change password': 'Palitan ang password',
  'Choose': 'Pumili',
  'Choose a meal type, then add a photo':
      'Pumili ng meal type, tapos mag-add ng photo',
  'Choose a new account password': 'Pumili ng bagong account password',
  'Choose again': 'Pumili ulit',
  'Choose from gallery': 'Pumili sa gallery',
  'Clear account data': 'I-clear ang account data',
  'Clear all account data?': 'I-clear lahat ng account data?',
  'Clear data': 'I-clear ang data',
  'Close for now': 'Isara muna',
  'Confirm': 'I-confirm',
  'Confirm deactivation': 'I-confirm ang deactivation',
  'Content hidden': 'Nakatago ang content',
  'Continue': 'Magpatuloy',
  'Create account': 'Gumawa ng account',
  'Daily goal': 'Daily goal',
  'Daily steps': 'Daily steps',
  'Daily steps is not supported on this device.':
      'Hindi supported ang daily steps sa device na ito.',
  'Deactivate account': 'I-deactivate ang account',
  'Done': 'Tapos na',
  'Drag to reposition and pinch or scroll to zoom.':
      'I-drag para ilipat, tapos pinch o scroll para mag-zoom.',
  'Edit avatar': 'I-edit ang avatar',
  'Edit daily step goal': 'I-edit ang daily step goal',
  'Edit goals': 'I-edit ang goals',
  'Edit profile': 'I-edit ang profile',
  'Edit wellness': 'I-edit ang wellness',
  'Edit wellness profile': 'I-edit ang wellness profile',
  'Email verification': 'Email verification',
  'Environmental conditions': 'Environmental conditions',
  'Estimate nutrition from typed meal details.':
      'I-estimate ang nutrition gamit ang meal details na tina-type mo.',
  'Export Report (Word)': 'I-export ang report (Word)',
  'Floating assistant is ready and will appear when you leave VitalySync.':
      'Ready na ang floating assistant at lalabas ito kapag umalis ka sa VitalySync.',
  'Floating assistant is turned off outside the app.':
      'Naka-off na ang floating assistant sa labas ng app.',
  'Focus recommendations': 'Focus recommendations',
  'Forgot password?': 'Nakalimutan ang password?',
  'Generated insight and nudge': 'Generated insight at nudge',
  'Goal tracking': 'Goal tracking',
  'Goal tracking is unavailable right now.':
      'Hindi available ang goal tracking ngayon.',
  'Got it': 'Gets ko',
  'Help and support': 'Help at support',
  'History': 'History',
  'How streak savers work': 'Paano gumagana ang streak savers',
  'Informational Only': 'For information only',
  'Insight history': 'Insight history',
  'kcal left': 'kcal pa',
  'Keep your momentum going': 'Ituloy lang ang momentum mo',
  'Key signals': 'Key signals',
  'Learn more about burnout': 'Alamin pa ang tungkol sa burnout',
  'Local data retention': 'Local data retention',
  'Permissions settings': 'Permission settings',
  'Log a gentle check-in': 'Mag-log ng gentle check-in',
  'Log and scoring guide': 'Log at scoring guide',
  'Log new meal': 'Mag-log ng bagong meal',
  'Log out': 'Mag-log out',
  'Log out of VitalySync?': 'Mag-log out sa VitalySync?',
  'Macro balance': 'Macro balance',
  'Manual log': 'Manual log',
  'Mark all read': 'Markahan lahat bilang nabasa',
  'Mark read': 'Markahan bilang nabasa',
  'Mood trend': 'Mood trend',
  'My goals': 'Mga goal ko',
  'My streak': 'Streak ko',
  'Need help?': 'Kailangan ng help?',
  'No insights yet': 'Wala pang insights',
  'No nutrition nudge right now. Keep meals simple and steady today.':
      'Walang nutrition nudge ngayon. Keep meals simple at steady today.',
  'No score history yet': 'Wala pang score history',
  'No symptoms logged this week.': 'Walang symptoms na na-log this week.',
  'None today': 'Wala today',
  'Not now': 'Hindi muna',
  'Notifications': 'Notifications',
  'Nutrition nudge': 'Nutrition nudge',
  'Open settings': 'Buksan ang settings',
  'Open system settings': 'Buksan ang system settings',
  'Open VitalySync to finish this log.':
      'Buksan ang VitalySync para tapusin ang log na ito.',
  'Open VitalySync to log a meal.':
      'Buksan ang VitalySync para mag-log ng meal.',
  'Pause. Let today get lighter.': 'Pause muna. Gawing mas magaan ang today.',
  'Permanently clear data': 'Permanenteng i-clear ang data',
  'Personal info': 'Personal info',
  'Personal information': 'Personal information',
  'PERSONALIZED INSIGHTS': 'PERSONALIZED INSIGHTS',
  'Please authenticate to continue': 'Mag-authenticate para magpatuloy',
  'Preparing Report...': 'Inihahanda ang report...',
  'Preview changes before saving': 'I-preview ang changes bago i-save',
  'Privacy and security': 'Privacy at security',
  'Profile avatar updated.': 'Updated na ang profile avatar.',
  'Quick actions': 'Quick actions',
  'Quick water log': 'Quick water log',
  'Reactivate account': 'I-reactivate ang account',
  'Reactivate and continue': 'I-reactivate at magpatuloy',
  'Ready to log': 'Ready nang mag-log',
  'Recent streak activity': 'Recent streak activity',
  'Redo today\'s log': 'Ulitin ang log today',
  'Reminder settings saved.': 'Saved na ang reminder settings.',
  'Rest choice saved': 'Saved na ang rest choice',
  'Restore your VitalySync account?': 'I-restore ang VitalySync account mo?',
  'Retry': 'Subukan ulit',
  'Review meal': 'I-review ang meal',
  'Save today\'s check-in?': 'I-save ang check-in today?',
  'Save without restoring': 'I-save nang hindi nire-restore',
  'Settings': 'Settings',
  'Settings center': 'Settings center',
  'Sign out safely on this device': 'Mag-sign out safely sa device na ito',
  'Sleep pattern': 'Sleep pattern',
  'Sleep quality': 'Sleep quality',
  'Small wins.\nStrong streaks.': 'Small wins.\nStrong streaks.',
  'Smart nudge': 'Smart nudge',
  'Stay': 'Manatili',
  'Step goal': 'Step goal',
  'STREAK': 'STREAK',
  'Streak leaderboard': 'Streak leaderboard',
  'Streak savers': 'Streak savers',
  'Symptom frequency': 'Dalas ng symptoms',
  'Take a break without losing your history':
      'Mag-break nang hindi nawawala ang history mo',
  'Take photo': 'Kumuha ng photo',
  'Tap to hide': 'I-tap para itago',
  'Tap to view': 'I-tap para makita',
  'Terms and privacy policy': 'Terms at privacy policy',
  'This week': 'This week',
  'Today': 'Today',
  'Today\'s exercise goal canceled.': 'Canceled na ang exercise goal today.',
  'Top 3 streaks': 'Top 3 streaks',
  'Try again': 'Subukan ulit',
  'Unlock': 'I-unlock',
  'Update your baseline context': 'I-update ang baseline context mo',
  'Use 1 for never and 5 for always.':
      'Gamitin ang 1 para never at 5 para always.',
  'Use device location': 'Gamitin ang device location',
  'Use English food names for better estimates.':
      'Gumamit ng English food names para mas accurate ang estimate.',
  'Use savers and save': 'Gamitin ang savers at i-save',
  'Use suggested avatar': 'Gamitin ang suggested avatar',
  'User Report': 'User report',
  'Verify email': 'I-verify ang email',
  'Version': 'Version',
  'View': 'Tingnan',
  'View all': 'Tingnan lahat',
  'View goal': 'Tingnan ang goal',
  'View history': 'Tingnan ang history',
  'View streak card': 'Tingnan ang streak card',
  'VitalySync assistant': 'VitalySync assistant',
  'VitalySync is locked': 'Naka-lock ang VitalySync',
  'WELLNESS DATA': 'WELLNESS DATA',
  'Weekly performance': 'Weekly performance',
  'Weekly step analytics': 'Weekly step analytics',
  'Wellness goals': 'Wellness goals',
  'Wellness history': 'Wellness history',
  'Wellness index': 'Wellness index',
  'Wellness profile': 'Wellness profile',
  'Your daily wellness rhythm': 'Daily wellness rhythm mo',
  'Your profile avatar': 'Profile avatar mo',
  'A little backup for real-life days':
      'Kaunting backup para sa real-life days',
  'About this section': 'Tungkol sa section na ito',
  'Account security': 'Account security',
  'Content privacy': 'Content privacy',
  'Device security': 'Device security',
  'Hide sensitive content': 'Itago ang sensitive content',
  'Do not show in leaderboard': 'Huwag ipakita sa leaderboard',
  'Biometric lock': 'Biometric lock',
  'Email verified': 'Verified ang email',
  'Email not verified': 'Hindi pa verified ang email',
  'App language': 'Wika ng app',
  'Appearance': 'Itsura',
  'Language': 'Wika',
  'Display': 'Display',
  'Font size': 'Laki ng text',
  'Preview': 'Preview',
  'Light mode': 'Light mode',
  'Dark mode': 'Dark mode',
  'New password': 'Bagong password',
  'Confirm new password': 'I-confirm ang bagong password',
  'Password': 'Password',
  'Current password': 'Kasalukuyang password',
  'Type CONFIRM': 'I-type ang CONFIRM',
  'Type CONFIRM below to continue.':
      'I-type ang CONFIRM sa ibaba para magpatuloy.',
  'Confirmation is case-sensitive.': 'Case-sensitive ang confirmation.',
  'Verification code': 'Verification code',
  'Goal steps': 'Goal steps',
  'Open daily log': 'Buksan ang daily log',
  'Refresh assistant': 'I-refresh ang assistant',
  'Refresh weather': 'I-refresh ang weather',
  'Dismiss': 'I-dismiss',
  'Liked': 'Nagustuhan',
  'Like insight': 'I-like ang insight',
  'Disliked': 'Hindi nagustuhan',
  'Dislike insight': 'I-dislike ang insight',
  'Retry activity sync': 'Subukan ulit ang activity sync',
  'Refresh weekly steps': 'I-refresh ang weekly steps',
  'Skip tutorial': 'I-skip ang tutorial',
  'Leaderboard': 'Leaderboard',
  'Add meal': 'Mag-add ng meal',
  'Remove meal': 'Alisin ang meal',
  'Clear meal': 'I-clear ang meal',
  'Cancel crop': 'Kanselahin ang crop',
  'Retry nutrition data': 'Subukan ulit ang nutrition data',
  'About burnout score': 'Tungkol sa burnout score',
  'Refresh': 'I-refresh',
  'Close': 'Isara',
  'Close recovery mode': 'Isara ang recovery mode',
  'User avatar': 'User avatar',
  'Current profile avatar': 'Kasalukuyang profile avatar',
  'Avatar preview': 'Avatar preview',
  'Leaderboard section': 'Leaderboard section',
  'Streak category': 'Streak category',
  'Unknown location': 'Hindi matukoy ang location',
  'No description available': 'Walang available na description',
  'Unknown': 'Hindi matukoy',
  'high': 'mataas',
  'moderate': 'katamtaman',
  'low': 'mababa',
  'steady': 'steady',
  'watch': 'bantayan',
  'needs support': 'kailangan ng suporta',
  'active': 'active',
  'completed': 'kumpleto',
  'pending': 'pending',
  'scheduled': 'scheduled',
};

final List<_CopyRule> _tagalogCopyRules = [
  _CopyRule(RegExp(r'^Welcome back, (.+)$'), (m) => 'Welcome back, ${m[1]}'),
  _CopyRule(RegExp(r'^(\d+) unread$'), (m) => '${m[1]} unread'),
  _CopyRule(RegExp(r'^(\d+) day$'), (m) => '${m[1]} araw'),
  _CopyRule(RegExp(r'^(\d+) days$'), (m) => '${m[1]} araw'),
  _CopyRule(RegExp(r'^Current: (.+)$'), (m) => 'Kasalukuyan: ${m[1]}'),
  _CopyRule(RegExp(r'^Step (\d+) of (\d+)$'), (m) => 'Step ${m[1]} of ${m[2]}'),
  _CopyRule(RegExp(r'^Updated (.+)$'), (m) => 'Na-update ${m[1]}'),
  _CopyRule(RegExp(r'^For (.+)$'), (m) => 'Para sa ${m[1]}'),
  _CopyRule(RegExp(r'^(.+) (\d+)$'), (m) => '${m[1]} ${m[2]}'),
  _CopyRule(RegExp(r'^(.+) • (.+)$'), (m) => '${m[1]} • ${m[2]}'),
  _CopyRule(RegExp(r'^(.+) \((\d+)%\)$'), (m) => '${m[1]} (${m[2]}%)'),
  _CopyRule(RegExp(r'^(\d+) yrs$'), (m) => '${m[1]} taon'),
  _CopyRule(
    RegExp(r'^Current: (.+)  -  Best: (.+)$'),
    (m) => 'Kasalukuyan: ${m[1]}  -  Pinakamahusay: ${m[2]}',
  ),
  _CopyRule(
    RegExp(r'^(.+) - (Gender not set|Role not set|.+)$'),
    (m) =>
        '${m[1]} - ${m[2] == 'Gender not set'
            ? 'Walang gender'
            : m[2] == 'Role not set'
            ? 'Walang role'
            : m[2]}',
  ),
  _CopyRule(
    RegExp(r'^Energy logged as (.+)\.$'),
    (m) => 'Na-log ang energy bilang ${m[1]}.',
  ),
  _CopyRule(
    RegExp(r'^Logged as (.+) pressure\.$'),
    (m) => 'Na-log bilang ${m[1]} pressure.',
  ),
  _CopyRule(
    RegExp(r'^Recovery logged as (.+)\.$'),
    (m) => 'Na-log ang recovery bilang ${m[1]}.',
  ),
  _CopyRule(
    RegExp(r'^(\d+) pending check-ins? will upload in the background\.$'),
    (m) => '${m[1]} pending check-in ang ia-upload sa background.',
  ),
  _CopyRule(
    RegExp(r'^Please complete (.+) before saving\.$'),
    (m) => 'Kumpletuhin ang ${m[1]} bago mag-save.',
  ),
  _CopyRule(
    RegExp(r'^Saved offline\. (\d+) check-ins? waiting to sync\.$'),
    (m) => 'Saved offline. ${m[1]} check-in ang naghihintay mag-sync.',
  ),
  _CopyRule(
    RegExp(
      r'^You missed (\d+) days?\. Use (\d+) streak savers? to protect your streak before saving today\.$',
    ),
    (m) =>
        'Na-miss mo ang ${m[1]} araw. Gumamit ng ${m[2]} streak saver para protektahan ang streak bago mag-save today.',
  ),
  _CopyRule(
    RegExp(
      r'^You need (\d+) savers?, but only have (\d+)\. You can still save today and start a fresh streak\.$',
    ),
    (m) =>
        'Kailangan mo ng ${m[1]} saver pero ${m[2]} lang ang available. Puwede ka pa ring mag-save today at magsimula ng bagong streak.',
  ),
  _CopyRule(
    RegExp(r'^(\d+) savers? available this month$'),
    (m) => '${m[1]} saver ang available ngayong buwan',
  ),
  _CopyRule(
    RegExp(r'^Use (\d+) savers? and save$'),
    (m) => 'Gumamit ng ${m[1]} saver at i-save',
  ),
  _CopyRule(
    RegExp(r'^(.+) unlocked for editing\.$'),
    (m) => 'Puwede nang i-edit ang ${m[1]}.',
  ),
  _CopyRule(
    RegExp(r'^(.+) is already logged\. Triple-tap it to edit\.$'),
    (m) => 'Naka-log na ang ${m[1]}. I-triple-tap para i-edit.',
  ),
  _CopyRule(RegExp(r'^Meal (\d+)$'), (m) => 'Meal ${m[1]}'),
  _CopyRule(
    RegExp(r'^Rank (\d+), (.+), (.+), (.+)$'),
    (m) => 'Rank ${m[1]}, ${m[2]}, ${m[3]}, ${m[4]}',
  ),
  _CopyRule(RegExp(r'^Avatar for (.+)$'), (m) => 'Avatar ni ${m[1]}'),
  _CopyRule(RegExp(r'^(\d+) savers?$'), (m) => '${m[1]} saver'),
  _CopyRule(
    RegExp(r'^Used (.+) to protect (.+)\.$'),
    (m) => 'Gumamit ng ${m[1]} para protektahan ang ${m[2]}.',
  ),
  _CopyRule(
    RegExp(r'^(Earned|Used) (.+)\.$'),
    (m) => '${m[1] == 'Earned' ? 'Nakakuha ng' : 'Gumamit ng'} ${m[2]}.',
  ),
  _CopyRule(RegExp(r'^(\d+(?:\.\d+)?) hours$'), (m) => '${m[1]} oras'),
  _CopyRule(RegExp(r'^(\d[\d,]*) steps$'), (m) => '${m[1]} steps'),
  _CopyRule(RegExp(r'^(.+) risk$'), (m) => '${m[1]} risk'),
  _CopyRule(RegExp(r'^(\d+)% confidence$'), (m) => '${m[1]}% confidence'),
  _CopyRule(RegExp(r'^(\d+)% complete$'), (m) => '${m[1]}% kumpleto'),
  _CopyRule(
    RegExp(r'^Using last saved environment snapshot from (.+)\.$'),
    (m) => 'Gamit ang huling saved environment snapshot mula ${m[1]}.',
  ),
  _CopyRule(RegExp(r'^Version (.+)$'), (m) => 'Version ${m[1]}'),
  _CopyRule(
    RegExp(r'^Build (.+) - Updated (.+)$'),
    (m) => 'Build ${m[1]} - Na-update ${m[2]}',
  ),
  _CopyRule(
    RegExp(r'^(.+) reminders are enabled(?: (.+))?$'),
    (m) => 'Enabled ang ${m[1]} reminders${m[2] == null ? '' : ' ${m[2]}'}',
  ),
  _CopyRule(
    RegExp(r'^(Dark|Light) mode, (.+), (.+) text$'),
    (m) => '${m[1]} mode, ${m[2]}, ${m[3]} text',
  ),
  _CopyRule(
    RegExp(r'^Enter the password for (.+) before continuing\.$'),
    (m) => 'I-enter ang password para sa ${m[1]} bago magpatuloy.',
  ),
  _CopyRule(RegExp(r'^Every (\d+) hours$'), (m) => 'Bawat ${m[1]} oras'),
  _CopyRule(RegExp(r'^Average: (.+)h$'), (m) => 'Average: ${m[1]}h'),
  _CopyRule(
    RegExp(r'^Daily step goal updated to (.+)\.$'),
    (m) => 'Na-update ang daily step goal sa ${m[1]}.',
  ),
  _CopyRule(RegExp(r'^(.+) best: (.+)$'), (m) => '${m[1]} best: ${m[2]}'),
  _CopyRule(
    RegExp(r'^(\d+) of (\d+) goal days reached$'),
    (m) => '${m[1]} sa ${m[2]} goal days ang naabot',
  ),
  _CopyRule(RegExp(r'^Enter your (.+)$'), (m) => 'I-enter ang ${m[1]} mo'),
  _CopyRule(
    RegExp(r'^Enter a valid (.+)$'),
    (m) => 'Mag-enter ng valid na ${m[1]}',
  ),
  _CopyRule(
    RegExp(r'^Send again in (\d+)s$'),
    (m) => 'I-send ulit sa loob ng ${m[1]}s',
  ),
  _CopyRule(
    RegExp(r'^Code sent to (.+)$'),
    (m) => 'Na-send ang code sa ${m[1]}',
  ),
  _CopyRule(RegExp(r'^Unable to (.+)$'), (m) => 'Hindi ma-${m[1]}'),
  _CopyRule(RegExp(r'^Failed to (.+)$'), (m) => 'Hindi successful ang ${m[1]}'),
];

class _CopyRule {
  final RegExp pattern;
  final String Function(RegExpMatch match) translate;

  const _CopyRule(this.pattern, this.translate);
}
