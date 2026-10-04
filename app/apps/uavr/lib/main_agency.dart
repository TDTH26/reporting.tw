import 'package:feature_agency/feature_agency.dart';
import 'package:uavr_core/uavr_core.dart';

import 'bootstrap.dart';

/// Agency console: web only, served on the government network.
void main() => runUavr(AppFlavor.agency, const AgencyApp());
