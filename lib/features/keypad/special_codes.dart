/// A code the keypad acts on as soon as it's typed, like AOSP's SpecialCharSequenceMgr.
sealed class SpecialCode {
  const SpecialCode();
}

/// `*#*#<digits>#*#*`: broadcast to whichever app registered it (testing menus and the like).
class SecretCode extends SpecialCode {
  const SecretCode(this.digits);
  final String digits;
}

/// `*#06#` (IMEI) or `*#07#` (SAR): the system or the phone maker's dialer code handles these.
class DeviceCode extends SpecialCode {
  const DeviceCode(this.code);
  final String code;
  bool get isImei => code == '*#06#';
}

final _secret = RegExp(r'^\*#\*#(\d+)#\*#\*$');

/// The special code [number] is, or null. Network codes (`*#21#`, `*123#`) aren't: they're dialled.
SpecialCode? specialCode(String number) {
  if (_secret.firstMatch(number) case final m?) return SecretCode(m[1]!);
  if (number == '*#06#' || number == '*#07#') return DeviceCode(number);
  return null;
}
