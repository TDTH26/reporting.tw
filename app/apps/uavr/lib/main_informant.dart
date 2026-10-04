import 'package:feature_informant/feature_informant.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_core/uavr_core.dart';

import 'bootstrap.dart';

/// Informant app: Android (Play Store) and web (reporting.tw/app/).
void main() => runUavr(AppFlavor.informant, const InformantApp(), before: (_) => registerBackgroundUploads());
