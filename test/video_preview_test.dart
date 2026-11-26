import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dialer/core/telecom/call_info.dart';
import 'package:dialer/features/in_call/video_call_view.dart';

void main() {
  CallInfo call(int rotation, {bool front = true}) => CallInfo.fromMap({
    'frontCamera': front,
    'id': 'call-1',
    'state': 'active',
    'video': 'bidirectional',
    'previewWidth': 640,
    'previewHeight': 480,
    'cameraRotation': rotation,
  });

  test('a turned camera frame stands upright in a portrait tile', () {
    // Landscape frames from a sensor at 90° or 270° (back and front cameras) show portrait.
    expect(VideoPreview.heightFor(call(270)), closeTo(104 * 640 / 480, .01));
    expect(VideoPreview.heightFor(call(90)), closeTo(104 * 640 / 480, .01));
    // A sensor already upright keeps the frame's own shape.
    expect(VideoPreview.heightFor(call(0)), closeTo(104 * 480 / 640, .01));
  });

  test('the texture turns the frames, so only the shape swaps', () {
    expect(VideoPreview.upright(call(270)), const Size(480, 640));
    expect(VideoPreview.upright(call(90, front: false)), const Size(480, 640));
    expect(VideoPreview.upright(call(0, front: false)), const Size(640, 480));
  });
}
