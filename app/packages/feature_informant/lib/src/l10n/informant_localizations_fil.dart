// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'informant_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Filipino Pilipino (`fil`).
class InformantL10nFil extends InformantL10n {
  InformantL10nFil([String locale = 'fil']) : super(locale);

  @override
  String get skip => 'Laktawan';

  @override
  String get notSure => 'Hindi sigurado';

  @override
  String get onboardingLanguageTitle => 'Piliin ang wika';

  @override
  String get onboardingLanguageBody =>
      'Mapapalitan mo ito anumang oras sa Settings.';

  @override
  String get onboardingWhatTitle =>
      'Iulat ang kahina-hinalang drone, bangkang walang tao at iba pang sasakyan';

  @override
  String get onboardingWhatBody =>
      'May nakitang drone malapit sa paliparan o kampo militar, bangkang walang tao sa laot, o sasakyang dumaong sa dalampasigan? Iulat ito sa loob ng isang minuto. Diretso ang ulat sa ahensyang may pananagutan: pulis, civil aviation, Coast Guard o depensa.';

  @override
  String get onboardingSafetyTitle => 'Kaligtasan mo ang una';

  @override
  String get onboardingSafetyApproach =>
      'Huwag kailanman lapitan o sundan ang nagpapalipad ng drone.';

  @override
  String get onboardingSafetyDistance =>
      'Lumayo sa drone at mag-ingat sa mga sasakyan sa paligid mo.';

  @override
  String get onboardingSafetyDanger =>
      'Kung may taong nasa panganib, tumawag muna sa 110.';

  @override
  String get onboardingPrivacyTitle => 'Hindi kailangang magpakilala';

  @override
  String get onboardingPrivacyNoAccount =>
      'Hindi namin hihingin ang pangalan mo, numero ng telepono o account.';

  @override
  String get onboardingPrivacyCollected =>
      'Ang ulat ay naglalaman ng iyong lokasyon, ang direksiyong tinututukan ng telepono, anumang larawan, video o tunog na idaragdag mo, at isang random na ID na ginawa noong in-install mo ang app.';

  @override
  String get onboardingPrivacyUse =>
      'Ginagamit lamang ng mga awtoridad ng pamahalaan ng Taiwan ang mga ulat para sa mga insidente ng drone at sa dagat.';

  @override
  String get onboardingPermissionsTitle => 'Mga pahintulot';

  @override
  String get onboardingPermissionsBody =>
      'Mas nagiging kapaki-pakinabang ang ulat mo sa bawat pahintulot. Puwede kang tumanggi sa alinman at makakapag-report ka pa rin.';

  @override
  String get onboardingStart => 'Magsimula';

  @override
  String get permLocationTitle => 'Lokasyon';

  @override
  String get permLocationBody =>
      'Inilalagay ang ulat mo sa mapa para malaman ng mga opisyal kung saan titingin.';

  @override
  String get permCameraTitle => 'Camera';

  @override
  String get permCameraBody =>
      'Para matutukan mo ang drone at makakuha ng larawan o video.';

  @override
  String get permMicrophoneTitle => 'Mikropono';

  @override
  String get permMicrophoneBody =>
      'Nire-record ang tunog ng mga elisi, na tumutulong matukoy ang uri ng drone.';

  @override
  String get permNearbyTitle => 'Mga kalapit na device (Bluetooth at Wi-Fi)';

  @override
  String get permNearbyBody =>
      'Sinasagap ang Remote ID na ibinobrodkast ng drone: ang serial number, posisyon at kung minsan ang posisyon ng nagpapalipad.';

  @override
  String get permNotificationsTitle => 'Mga notification';

  @override
  String get permNotificationsBody =>
      'Sinasabihan ka kapag may update ang kaso mo. Walang detalye ng kaso ang mga notification.';

  @override
  String get permAllow => 'Payagan';

  @override
  String get permGranted => 'Pinayagan';

  @override
  String get permOpenSettings => 'Buksan ang settings';

  @override
  String get homeReportButton => 'Mag-ulat';

  @override
  String get homeReportHint =>
      'Wala pang isang minuto. Hindi kailangang mag-sign up.';

  @override
  String get homeMyReports => 'Mga ulat ko';

  @override
  String get homeNoReports =>
      'Wala ka pang naipapadalang ulat mula sa device na ito.';

  @override
  String get homeZonesMap => 'Mapa ng mga no-fly zone';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeWebBanner =>
      'Para sa drone na lumilipad ngayon, mas tumpak ang ulat mula sa Android app: nasusukat nito ang direksiyon ng drone at nasasagap ang Remote ID nito.';

  @override
  String get homeGetAndroidApp => 'I-download ang Android app';

  @override
  String get homeEvidenceRequested => 'Humihingi ng ebidensiya';

  @override
  String get homePendingSend => 'Naghihintay maipadala';

  @override
  String get homeStatusOffline => 'Huling alam na status';

  @override
  String get caseNumberLabel => 'Numero ng kaso';

  @override
  String get reportTitle => 'Mag-ulat';

  @override
  String get stepAim => 'Tutok';

  @override
  String get stepDetails => 'Detalye';

  @override
  String get stepEvidence => 'Ebidensiya';

  @override
  String get locationWaiting => 'Hinahanap ang lokasyon mo…';

  @override
  String locationAccuracy(int meters) {
    return 'Lokasyon ±$meters m';
  }

  @override
  String get locationUnavailable =>
      'Naka-off o hindi pinapayagan ang lokasyon. I-on ito, o itakda ang posisyon mo sa mapa.';

  @override
  String get locationPickOnMap => 'Itakda sa mapa';

  @override
  String get locationManual => 'Itinakda ang lokasyon sa mapa';

  @override
  String get mapPickTitle => 'I-tap kung nasaan ka';

  @override
  String get mapPickConfirm => 'Gamitin ang lokasyong ito';

  @override
  String get remoteIdTitle => 'Remote ID';

  @override
  String remoteIdReceives(String transports) {
    return 'Nakikinig sa: $transports';
  }

  @override
  String remoteIdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drone ang nagbobrodkast ng Remote ID',
      one: '1 drone ang nagbobrodkast ng Remote ID',
      zero: 'Wala pang drone na nagbobrodkast ng Remote ID sa malapit',
    );
    return '$_temp0';
  }

  @override
  String get remoteIdUnsupported =>
      'Hindi kayang sumagap ng Remote ID ang teleponong ito.';

  @override
  String get remoteIdPermission =>
      'Payagan ang \"Mga kalapit na device\" para masagap ng app ang Remote ID.';

  @override
  String get remoteIdUnknownSerial => 'Wala pang natanggap na serial number';

  @override
  String remoteIdDistance(int meters) {
    return '$meters m ang layo';
  }

  @override
  String remoteIdHeight(int meters) {
    return '$meters m ang taas';
  }

  @override
  String get transportBt4 => 'Bluetooth';

  @override
  String get transportBt5 => 'Bluetooth long range';

  @override
  String get transportWifiBeacon => 'Wi-Fi beacon';

  @override
  String get transportWifiNan => 'Wi-Fi Aware';

  @override
  String get aimInstruction =>
      'Itutok ang telepono sa drone o sasakyang-dagat at i-tap ang \"I-lock ang direksiyon\".';

  @override
  String get aimBearing => 'Direksiyon';

  @override
  String get aimElevation => 'Anggulo pataas';

  @override
  String get aimCalibrate =>
      'Kailangang i-calibrate ang compass: igalaw ang telepono nang pa-figure 8 nang ilang beses.';

  @override
  String get aimNoCompass =>
      'Walang compass reading sa device na ito. Puwede mong laktawan ang hakbang na ito.';

  @override
  String get aimNoCamera => 'Hindi magamit ang camera';

  @override
  String get aimLock => 'I-lock ang direksiyon';

  @override
  String get aimTakePhoto => 'Kumuha rin ng larawan';

  @override
  String get aimSkip => 'Laktawan ang pagtutok';

  @override
  String aimLocked(int bearing, int elevation) {
    return 'Naka-lock ang direksiyon: $bearing°, $elevation° pataas';
  }

  @override
  String get aimAgain => 'Tumutok ulit';

  @override
  String get detailsTitle => 'Ano ang nakita mo?';

  @override
  String get detailsOptional =>
      'Opsyonal ang lahat dito. Laktawan kung nagmamadali ka.';

  @override
  String get detailsHeight => 'Gaano kataas?';

  @override
  String get detailsHeightHint =>
      'Ang 10-palapag na gusali ay mga 30 m ang taas.';

  @override
  String get heightBelow30 => 'Mababa sa 30 m';

  @override
  String get height30to60 => '30–60 m';

  @override
  String get height60to120 => '60–120 m';

  @override
  String get heightAbove120 => 'Mataas sa 120 m';

  @override
  String get detailsMovement => 'Gumagalaw ba ito?';

  @override
  String get movementHovering => 'Nakalutang lang';

  @override
  String get movementMoving => 'Gumagalaw';

  @override
  String get detailsCount => 'Ilan ang drone?';

  @override
  String get countOne => '1';

  @override
  String get countTwo => '2';

  @override
  String get countThreePlus => '3 o higit pa';

  @override
  String get detailsDescription => 'May iba pa ba? (opsyonal)';

  @override
  String get detailsDescriptionHint =>
      'Halimbawa: lumilipad sa itaas ng palaruan ng paaralan, may pulang ilaw, malakas na ugong';

  @override
  String get evidenceTitle => 'Larawan, video at tunog';

  @override
  String get evidenceSpeedNote =>
      'Mas mahalaga ang mabilis na pagpapadala kaysa perpektong ebidensiya. Puwede mo nang ipadala ngayon; sa background maa-upload ang mga file.';

  @override
  String get mediaPhoto => 'Larawan';

  @override
  String get mediaVideo => 'Video';

  @override
  String get mediaAudio => 'Recording ng tunog';

  @override
  String get evidenceRecordSound => 'I-record ang tunog';

  @override
  String get evidenceStopRecording => 'Itigil ang pag-record';

  @override
  String evidenceRecording(int seconds) {
    return 'Nire-record ang tunog ng elisi… $seconds seg';
  }

  @override
  String get evidenceNone => 'Wala pang naidagdag na file.';

  @override
  String get evidenceRemove => 'Alisin ang file';

  @override
  String get evidenceAimPhoto => 'Larawang kinuha nang i-lock ang direksiyon';

  @override
  String get evidenceCaptureFailed =>
      'Hindi nakuha ang file. Pakisubukan ulit.';

  @override
  String get sendNow => 'Ipadala na ang ulat';

  @override
  String get sending => 'Ipinapadala…';

  @override
  String get sendQueuedTitle => 'Na-save ang ulat';

  @override
  String get sendQueuedBody =>
      'Walang koneksiyon sa ngayon. Naka-save ang ulat mo sa teleponong ito at awtomatikong ipapadala kapag online ka na ulit.';

  @override
  String get sendRateLimited =>
      'Masyadong maraming ulat ang naipadala mula sa device o network na ito kamakailan. Maghintay ng ilang minuto at subukan ulit. Kung may taong nasa panganib, tumawag sa 110.';

  @override
  String sendRejected(String message) {
    return 'Hindi matanggap ang ulat: $message';
  }

  @override
  String get sendFailedTitle => 'Hindi naipadala ang ulat';

  @override
  String get discardTitle => 'Itapon ang ulat na ito?';

  @override
  String get discardBody => 'Wala pang naipapadala.';

  @override
  String get discard => 'Itapon';

  @override
  String get sentTitle => 'Naipadala ang ulat';

  @override
  String get sentBody =>
      'Salamat. Naipasa na ang ulat mo sa ahensiyang may pananagutan.';

  @override
  String sentUploading(int done, int total) {
    return 'Ina-upload ang mga file: $done sa $total';
  }

  @override
  String get sentUploadsDone => 'Na-upload na ang lahat ng file.';

  @override
  String get sentUploadsBackground =>
      'Tuloy ang pag-upload sa background, kahit isara mo ang app.';

  @override
  String get sentUploadsKeepOpen =>
      'Panatilihing bukas ang pahinang ito hanggang matapos ma-upload ang mga file.';

  @override
  String get sentKeyNote =>
      'Ang teleponong ito lang ang may hawak ng pribadong susi para masubaybayan ang ulat na ito. Kapag in-uninstall mo ang app o binura ang data nito, hindi mo na makikita ang mga update.';

  @override
  String get sentKeyNoteWeb =>
      'Ang browser na ito lang ang may hawak ng pribadong susi para masubaybayan ang ulat na ito. Kapag binura mo ang data ng browser, hindi mo na makikita ang mga update.';

  @override
  String get sentAndroidHint =>
      'Sa susunod, kayang sukatin ng Android app ang direksiyon ng drone at sagapin ang Remote ID nito, kaya mas kapaki-pakinabang ang ulat mo.';

  @override
  String get sentViewStatus => 'Tingnan ang status';

  @override
  String get sentBackHome => 'Bumalik sa home';

  @override
  String caseTitle(String caseNumber) {
    return 'Kaso $caseNumber';
  }

  @override
  String get caseProgress => 'Progreso';

  @override
  String get caseOutcome => 'Resulta';

  @override
  String get caseEvidenceRequests => 'Mga hiling para sa dagdag na ebidensiya';

  @override
  String get caseEvidenceSafety =>
      'Ipadala lang ang ligtas mong makukuha mula sa kinaroroonan mo.';

  @override
  String get caseEvidenceAnswered => 'Nasagot na — salamat.';

  @override
  String caseEvidenceSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ipadala ang $count file',
      one: 'Ipadala ang 1 file',
    );
    return '$_temp0';
  }

  @override
  String get caseEvidenceSent => 'Salamat. Ina-upload na ang mga file mo.';

  @override
  String get caseEvidenceClosed => 'Sarado na ang hiling na ito.';

  @override
  String get caseNotOnDevice =>
      'Hindi naka-save sa device na ito ang ulat na ito.';

  @override
  String caseUpdated(String time) {
    return 'Na-update $time';
  }

  @override
  String get zonesTitle => 'Mga no-fly zone';

  @override
  String get zonesLegend => 'Palatandaan';

  @override
  String get zonesMyLocation => 'Lokasyon ko';

  @override
  String get zonesNote =>
      'Ipinapakita lang ang mga drone zone na inilathala ng Civil Aviation Administration (CAA). May ilang restricted area na hindi ipinapakita sa pampublikong mapa.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsPrivacy => 'Privacy at tungkol sa app';

  @override
  String get settingsPrivacyBody =>
      'Ang reporting.tw ay serbisyo ng pamahalaan ng Taiwan para iulat ang kahina-hinalang drone, bangkang walang tao at iba pang sasakyan sa himpapawid, dagat o baybayin. Anonimo ang mga ulat: hindi namin hinihingi ang pangalan, numero o account mo. Kasama sa ulat ang lokasyon mo, ang direksyong itinutok mo ang telepono, ang mga sagot mo, mga larawan, video o tunog na idinagdag mo, mga Remote ID na nasagap ng telepono, at random na ID na ginawa nang i-install ang app. Maaaring awtomatikong suriin ng AI model ang mga larawan para tulungan ang mga opisyal. Ginagamit lamang ito ng mga awtoridad ng Taiwan para sa mga insidenteng ito.';

  @override
  String get settingsClearHistory => 'Burahin ang history ng ulat';

  @override
  String get settingsClearHistoryBody =>
      'Buburahin nito sa device na ito ang mga ulat mo at ang mga pribadong susi para masubaybayan ang mga ito. Hindi mo na makikita ang mga update o masasagot ang mga hiling para sa mga ulat na ito. Hindi babawiin ang mga ulat na naipadala na.';

  @override
  String get settingsClear => 'Burahin';

  @override
  String get settingsHistoryCleared => 'Nabura na ang history ng ulat.';

  @override
  String get settingsShowIntro => 'Ipakita ulit ang panimula';

  @override
  String settingsVersion(String version) {
    return 'Bersiyon $version';
  }
}
