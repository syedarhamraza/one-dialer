import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/features/settings/help_feedback_screen.dart';

void main() {
  test('feedback subject leads with the tag and drops missing details', () {
    expect(
      HelpFeedbackScreen.feedbackSubject('Bug', version: '1.4.0', device: 'vivo V2309', android: '15'),
      '[Bug] One Dialer 1.4.0 · vivo V2309 · Android 15',
    );
    expect(HelpFeedbackScreen.feedbackSubject('Idea'), '[Idea] One Dialer');
  });
}
