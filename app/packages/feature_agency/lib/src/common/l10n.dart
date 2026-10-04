import 'package:flutter/widgets.dart';

import '../l10n/agency_localizations.dart';

export '../l10n/agency_localizations.dart';

extension AgencyL10nX on BuildContext {
  AgencyL10n get l => AgencyL10n.of(this);

  /// 'zh-TW' or 'en' for picking names / template texts.
  String get lang => Localizations.localeOf(this).languageCode == 'zh' ? 'zh-TW' : 'en';
}
