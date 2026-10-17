/// Stand-in for OneSpend's voice input, so its search field copies verbatim.
/// shortcut: no voice search yet, so the field hides its mic; add a RecognizerIntent bridge to enable it.
abstract final class VoiceInput {
  static Future<bool> available() async => false;
  static Future<String?> listen(String prompt) async => null;
}
