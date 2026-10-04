import 'package:feature_field/feature_field.dart';
import 'package:uavr_capture/uavr_capture.dart';
import 'package:uavr_core/uavr_core.dart';

import 'bootstrap.dart';

/// Field officer app: Android, distributed through agency MDM / managed Google Play.
void main() => runUavr(AppFlavor.field, const FieldApp(), before: (_) => registerBackgroundUploads());
