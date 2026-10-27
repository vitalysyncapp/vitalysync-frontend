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
  'Add': 'Magdagdag',
  'Delete': 'I-delete',
  'Daily check-in': 'Araw-araw na check-in',
  'Weekly check-in': 'Lingguhang check-in',
  'Quick check-ins': 'Mga quick check-in',
  'Quick check-in': 'Mabilisang check-in',
  'Swipe right for quick check-ins':
      'Mag-swipe pakanan para sa mga mabilisang check-in',
  'DAILY QUICK CHECK-INS': 'MGA DAILY QUICK CHECK-IN',
  'WEEKLY QUICK CHECK-INS': 'MGA WEEKLY QUICK CHECK-IN',
  'Tap to preview and confirm. Long press to edit or delete. Swipe left for the full questionnaire.':
      'I-tap para tingnan at kumpirmahin. Long press para i-edit o i-delete. Mag-swipe pakaliwa para sa buong questionnaire.',
  'Preview quick check-in': 'Tingnan ang quick check-in',
  'Confirm quick check-in': 'Kumpirmahin ang quick check-in',
  'Scroll to explore moods and activities.':
      'Mag-scroll para makita ang mga damdamin at aktibidad.',
  'Edit': 'I-edit',
  'Not answered': 'Walang sagot',
  'Very sad': 'Napakalungkot',
  'Very happy': 'Napakasaya',
  'Pressure': 'Pressure',
  'No quick check-ins for this type yet. Add one to make future logging faster.':
      'Wala pang quick check-in para sa uri na ito. Magdagdag para mas mabilis ang susunod na pag-log.',
  'Showing saved presets. Connect to manage or sync them.':
      'Ipinapakita ang naka-save na presets. Kumonekta para i-manage o i-sync ang mga ito.',
  'Add quick check-in': 'Magdagdag ng quick check-in',
  'Choose check-in type': 'Pumili ng uri ng check-in',
  'Create a reusable shortcut for your answers.':
      'Gumawa ng magagamit na shortcut para sa iyong mga sagot.',
  'Save all 14 daily answers.': 'I-save ang lahat ng 14 daily na sagot.',
  'Save 9 practical inputs and 11 reflection answers.':
      'I-save ang 9 praktikal na sagot at 11 reflection answers.',
  'New quick check-in': 'Bagong quick check-in',
  'Edit quick check-in': 'I-edit ang quick check-in',
  'Daily preset': 'Araw-araw na preset',
  'Weekly preset': 'Lingguhang preset',
  'Choose an emoji': 'Pumili ng emoji',
  'Name your preset': 'Pangalanan ang iyong preset',
  'Make it easy to recognize later.': 'Gawing madaling makilala sa susunod.',
  'Pick the feeling that matches this preset.':
      'Piliin ang damdaming babagay sa preset na ito.',
  'Your answers': 'Iyong mga sagot',
  'Answer all 14 questions once. You can edit them anytime.':
      'Sagutin ang lahat ng 14 tanong nang isang beses. Maaari mo itong i-edit anumang oras.',
  'Add 9 practical inputs and all 11 weekly reflection answers.':
      'Idagdag ang 9 praktikal na input at lahat ng 11 sagot sa lingguhang reflection.',
  'Loading questionnaire': 'Nilo-load ang questionnaire',
  'Quick check-in name': 'Pangalan ng quick check-in',
  'For example: Productive': 'Halimbawa: Produktibo',
  'Enter a name between 1 and 40 characters.':
      'Maglagay ng pangalan na 1 hanggang 40 character.',
  'Edit or delete quick check-in': 'I-edit o i-delete ang quick check-in',
  'Log now': 'I-log ngayon',
  'Sleep:': 'Tulog:',
  'Water:': 'Tubig:',
  'Energy:': 'Enerhiya:',
  'Save quick check-in': 'I-save ang quick check-in',
  'Delete quick check-in': 'I-delete ang quick check-in',
  'Delete quick check-in?': 'I-delete ang quick check-in?',
  'Quick check-in updated.': 'Na-update ang quick check-in.',
  'Quick check-in deleted.': 'Na-delete ang quick check-in.',
  'Replace today\'s check-in?': 'Palitan ang check-in ngayong araw?',
  'Replace and save': 'Palitan at i-save',
  'This preset does not match today\'s required check-in.':
      'Hindi tugma ang preset sa kailangang check-in ngayong araw.',
  'Unable to sync quick check-ins. Showing saved presets when available.':
      'Hindi ma-sync ang quick check-ins. Ipinapakita ang mga naka-save na preset kung mayroon.',
  'Unable to load quick check-ins.': 'Hindi ma-load ang mga quick check-in.',
  'Connect to the internet to create this quick check-in.':
      'Kumonekta sa internet para gawin ang quick check-in na ito.',
  'Connect to the internet to update this quick check-in.':
      'Kumonekta sa internet para i-update ang quick check-in na ito.',
  'Connect to the internet to delete this quick check-in.':
      'Kumonekta sa internet para i-delete ang quick check-in na ito.',
  'Open VitalySync to use a quick check-in.':
      'Buksan ang VitalySync para gumamit ng mabilisang check-in.',
  'Tired face': 'Pagod na mukha',
  'Sad face': 'Malungkot na mukha',
  'Neutral face': 'Neutral na mukha',
  'Calm face': 'Kalmadong mukha',
  'Happy face': 'Masayang mukha',
  'Celebrating face': 'Nagdiriwang na mukha',
  'Focused face': 'Nakatuong mukha',
  'Sleepy face': 'Inaantok na mukha',
  'Loved face': 'Minamahal na mukha',
  'Relieved face': 'Gumaan ang loob na mukha',
  'Anxious face': 'Balisa na mukha',
  'Energized rocket': 'Masiglang rocket',
  'Tired': 'Pagod',
  'Sad': 'Malungkot',
  'Neutral': 'Neutral',
  'Calm': 'Kalmado',
  'Happy': 'Masaya',
  'Celebrating': 'Nagdiriwang',
  'Focused': 'Nakatuon',
  'Sleepy': 'Inaantok',
  'Loved': 'Minamahal',
  'Relaxed': 'Relaks',
  'Unsure': 'Hindi sigurado',
  'Energized': 'Masigla',
  'Productive': 'Produktibo',
  'Busy': 'Abala',
  'Studying': 'Nag-aaral',
  'Creative': 'Malikhain',
  'Cooking': 'Nagluluto',
  'Gardening': 'Naghahalaman',
  'Caring': 'Nag-aalaga',
  'Teaching': 'Nagtuturo',
  'Fixing things': 'Nag-aayos',
  'Exploring': 'Nag-e-explore',
  'Singing': 'Kumakanta',
  'Dancing': 'Sumasayaw',
  'Joyful': 'Tuwang-tuwa',
  'Strong': 'Malakas',
  'Stretching': 'Nag-i-stretch',
  'Walking': 'Naglalakad',
  'Cycling': 'Nagbibisikleta',
  'Swimming': 'Lumalangoy',
  'Climbing': 'Umaakyat',
  'Resting': 'Nagpapahinga',
  'Mindful': 'Mapagmuni-muni',
  'Overwhelmed': 'Nabibigatan',
  'Uncertain': 'Nag-aalinlangan',
  'Unwell': 'Masama ang pakiramdam',
  'Quick check-in emojis': 'Mga emoji ng quick check-in',
  'Noto Emoji illustrations by Google · Apache License 2.0':
      'Mga ilustrasyong Noto Emoji ng Google · Apache License 2.0',
  'No estimate yet': 'Wala pang tantiya',
  'Estimate available': 'May tantiya na',
  'Loading estimate': 'Kinukuha ang tantiya',
  'Very low risk': 'Napakababang panganib',
  'Low risk': 'Mababang panganib',
  'Moderate risk': 'Katamtamang panganib',
  'High risk': 'Mataas na panganib',
  'Very high risk': 'Napakataas na panganib',
  'Critical risk': 'Kritikal na panganib',
  'Complete your baseline or first check-in':
      'Kumpletuhin ang baseline o unang check-in',
  'Check-in saved offline · estimate updates after sync':
      'Na-save offline ang check-in · maa-update ang tantiya pagkatapos mag-sync',
  'Baseline · complete a daily check-in to update':
      'Baseline · mag-daily check-in para ma-update',
  'Complete daily check-ins to build your trend.':
      'Mag-daily check-in para makita ang trend mo.',
  '1 check-in · more entries build a trend':
      '1 check-in · dagdagan ang mga entry para makita ang trend',
  'Another idea': 'Ibang idea',
  'Great job': 'Ang galing',
  'Nice one': 'Ayos',
  'Well done': 'Magaling',
  'Okay, got it': 'Sige, noted',
  'No worries': 'Walang problema',
  'That small step really counts.': 'Mahalaga ang maliit na hakbang na iyan.',
  'Keep that gentle momentum going.': 'Ituloy mo lang ang magandang simula.',
  'We’ll give this one some space.': 'Bibigyan muna natin ito ng espasyo.',
  'We’ll find a better moment later.':
      'Hahanap tayo ng mas magandang oras mamaya.',
  'Helpful': 'Nakatulong',
  'Not helpful': 'Hindi nakatulong',
  'Glad this helps!': 'Mabuti kung nakatulong!',
  'Feedback noted.': 'Salamat sa feedback.',
  'Was this helpful?': 'Nakatulong ba ito?',
  'Saved offline': 'Naka-save offline',
  'A small step for today': 'Isang maliit na hakbang ngayon',
  'What this is based on': 'Kung saan ito naka-base',
  'Your picture is still taking shape': 'Nabubuo pa ang larawan mo',
  'A few check-ins will help us notice your personal patterns.':
      'Makakatulong ang ilang check-ins para mapansin ang personal patterns mo.',
  'Unable to save your response. Please try again.':
      'Hindi na-save ang sagot mo. Pakisubukan ulit.',
  'No other suggestion fits right now. Check back after your next log.':
      'Wala pang ibang angkop na suggestion ngayon. Balikan pagkatapos ng susunod na log.',
  'Done. You made a little room for yourself.':
      'Tapos na. Naglaan ka ng kaunting oras para sa sarili.',
  'Let’s find a different small step.':
      'Humanap tayo ng ibang maliit na hakbang.',
  'Of course. We’ll give this some space.':
      'Sige. Bigyan muna natin ito ng space.',
  'Thanks. We’ll adjust your suggestions.':
      'Salamat. Ia-adjust namin ang suggestions para sa iyo.',
  'Thanks. That helps us learn what fits.':
      'Salamat. Nakakatulong ito para malaman kung ano ang bagay sa iyo.',
  'No other nutrition suggestion fits right now.':
      'Wala pang ibang angkop na nutrition suggestion ngayon.',
  'Your daily essentials': 'Mga pangunahing detalye ng araw mo',
  'WEEKLY CHECK-IN DAY': 'ARAW NG WEEKLY CHECK-IN',
  'Weekly day: 9 practical inputs': 'Weekly day: 9 praktikal na sagot',
  '11-item weekly reflection': '11-item na lingguhang pagninilay',
  'Previous 22-item weekly reflection':
      'Dating 22-item na lingguhang pagninilay',
  '9 practical inputs here and 11 questions in your weekly reflection. No repeated daily reflection questions.':
      '9 praktikal na sagot dito at 11 tanong sa lingguhang pagninilay. Hindi na uulitin ang mga tanong sa daily reflection.',
  '11 reflection questions: 5 exhaustion, 3 detachment, and 3 accomplishment. Your daily check-in has only 9 practical inputs on weekly days.':
      '11 tanong: 5 tungkol sa pagkapagod, 3 sa pagkalayo ng loob, at 3 sa mga nagawa. Sa weekly day, 9 praktikal na sagot lamang ang nasa daily check-in.',
  "Weekly reflection": "Lingguhang pagninilay",
  "Weekly log": "Lingguhang log",
  "Complete weekly log": "Sagutan ang lingguhang log",
  "Edit weekly log": "I-edit ang lingguhang log",
  "Save weekly log": "I-save ang lingguhang log",
  "Weekly log saved.": "Na-save ang lingguhang log.",
  "Weekly log saved offline and queued to sync.":
      "Na-save offline ang lingguhang log at nakaabang para mag-sync.",
  "Burnout Risk estimate": "Tantya ng burnout risk",
  "Today's pressure": "Pressure ngayong araw",
  "Daily detachment": "Pagkalayo ng loob ngayong araw",
  "Daily focus": "Focus ngayong araw",
  "Daily accomplishment": "Mga nagawa ngayong araw",
  "No weekly questionnaire completed yet.":
      "Wala pang nasagutang lingguhang questionnaire.",
  "Think about the past seven days.":
      "Isipin ang iyong karanasan sa nakaraang pitong araw.",
  "Weekly answers saved offline. Scores appear after syncing.":
      "Na-save offline ang mga sagot. Lalabas ang mga score pagkatapos mag-sync.",
  "Your first weekly log is scheduled after you start daily logging.":
      "Iiskedyul ang unang lingguhang log pagkatapos mong magsimula ng araw-araw na logging.",
  "11 questions about exhaustion, detachment, and accomplishment. Scored separately from your daily index.":
      "11 tanong tungkol sa pagkapagod, pagkalayo ng loob, at mga nagawa. Hiwalay ang mga score sa iyong daily index.",
  "Custom Maslach-based reflection. This is an adaptation, not the official MBI or a diagnosis.":
      "Pagninilay na batay sa Maslach. Isa itong adaptation, hindi opisyal na MBI o diagnosis.",
  "Higher exhaustion or detachment means more burden. Higher accomplishment means greater fulfillment.":
      "Mas mataas na pagkapagod o pagkalayo ng loob ay nangangahulugang mas mabigat na pasanin. Mas mataas na accomplishment ay mas positibo.",
  "I feel worn out after dealing with everyday demands.":
      "Pakiramdam ko ay ubos ang lakas ko matapos harapin ang mga pang-araw-araw na gawain.",
  "I find it tiring to keep up with what is expected of me.":
      "Napapagod akong makasabay sa mga inaasahan sa akin.",
  "I feel emotionally spent when another task comes up.":
      "Pakiramdam ko ay ubos ang emosyonal kong lakas kapag may panibagong gawain.",
  "I feel that my responsibilities use up my emotional strength.":
      "Pakiramdam ko ay nauubos ang emosyonal kong lakas sa mga responsibilidad.",
  "I can find a useful way forward when a task becomes difficult.":
      "Nakakahanap ako ng paraan upang magpatuloy kapag mahirap ang isang gawain.",
  "I feel that my efforts make a positive difference.":
      "Pakiramdam ko ay may positibong epekto ang aking mga pagsisikap.",
  "I handle unexpected demands effectively.":
      "Maayos kong nahaharap ang mga hindi inaasahang gawain.",
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
  _CopyRule(
    RegExp(
      r'^(.+) was saved and will appear on (daily|weekly) check-in days\.$',
    ),
    (m) =>
        'Na-save ang ${m[1]} at lalabas ito sa mga ${m[2] == 'daily' ? 'araw-araw' : 'lingguhang'} check-in.',
  ),
  _CopyRule(
    RegExp(r'^(.+) is ready for quick logging\.$'),
    (m) => 'Handa na ang ${m[1]} para sa mabilisang pag-log.',
  ),
  _CopyRule(
    RegExp(r'^(.+) will replace the answers already saved for today\.$'),
    (m) =>
        'Papalitan ng ${m[1]} ang mga sagot na naka-save na para ngayong araw.',
  ),
  _CopyRule(
    RegExp(r'^(.+) will be removed from every signed-in device\.$'),
    (m) => 'Aalisin ang ${m[1]} sa lahat ng device na naka-sign in.',
  ),
  _CopyRule(RegExp(r'^Edit (.+)$'), (m) => 'I-edit ang ${m[1]}'),
  _CopyRule(
    RegExp(r'^(.+) risk · (\d+)% confidence$'),
    (m) =>
        '${localizeAppCopy('${m[1]} risk', const Locale('fil'))} · ${m[2]}% confidence',
  ),
  _CopyRule(
    RegExp(r'^Last check-in · (.+)$'),
    (m) => 'Huling check-in · ${localizeAppCopy(m[1]!, const Locale('fil'))}',
  ),
  _CopyRule(
    RegExp(r'^(.+) · saved offline$'),
    (m) => '${localizeAppCopy(m[1]!, const Locale('fil'))} · na-save offline',
  ),
  _CopyRule(
    RegExp(r'^Limited confidence · (\d+)% confidence$'),
    (m) => 'Limitadong confidence · ${m[1]}% confidence',
  ),
  _CopyRule(
    RegExp(
      r'^Your baseline estimate is (\d+)/100\. Complete a daily check-in to update it with your recent inputs\.$',
    ),
    (m) =>
        'Ang baseline estimate mo ay ${m[1]}/100. Mag-daily check-in para ma-update ito gamit ang mga pinakabagong sagot mo.',
  ),
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
