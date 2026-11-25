import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/widgets/place_video_call.dart';

void main() {
  const meet = 'vnd.android.cursor.item/com.google.android.apps.tachyon.phone.meet';
  const whatsapp = {
    'label': 'WhatsApp',
    'dataId': 1,
    'mimeType': 'vnd.android.cursor.item/vnd.com.whatsapp.video.call',
  };

  List<String> labels(List<VideoOption> o) => [for (final x in o) x.label];

  test('no apps and no Meet: nothing to offer', () {
    expect(videoOptionsFrom(const [], meetByNumber: false), isEmpty);
  });

  test('Meet by number when Meet is installed and the contact has no Meet row', () {
    final o = videoOptionsFrom(const [whatsapp], meetByNumber: true);
    expect(labels(o), ['WhatsApp', 'Meet']);
    expect(o.last.dataId, isNull);
  });

  test("the contact's own Meet row replaces Meet by number", () {
    final o = videoOptionsFrom(const [
      whatsapp,
      {'label': 'Meet', 'dataId': 3, 'mimeType': meet},
    ], meetByNumber: true);
    expect(labels(o), ['WhatsApp', 'Meet']);
    expect(o.last.dataId, 3);
  });
}
