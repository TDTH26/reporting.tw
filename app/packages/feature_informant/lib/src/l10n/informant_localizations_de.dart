// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'informant_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class InformantL10nDe extends InformantL10n {
  InformantL10nDe([String locale = 'de']) : super(locale);

  @override
  String get skip => 'Überspringen';

  @override
  String get notSure => 'Nicht sicher';

  @override
  String get onboardingLanguageTitle => 'Sprache wählen';

  @override
  String get onboardingLanguageBody =>
      'Sie können die Sprache jederzeit in den Einstellungen ändern.';

  @override
  String get onboardingWhatTitle =>
      'Verdächtige Drohnen, unbemannte Boote und andere Objekte melden';

  @override
  String get onboardingWhatBody =>
      'Sie haben eine Drohne in der Nähe eines Flughafens oder einer militärischen Anlage gesehen, ein unbemanntes Boot vor der Küste oder ein Boot, das an einem Strand anlandet? Melden Sie es in weniger als einer Minute. Ihre Meldung geht direkt an die zuständige Stelle: Polizei, Zivilluftfahrt, Küstenwache oder Verteidigung.';

  @override
  String get onboardingSafetyTitle => 'Ihre Sicherheit hat Vorrang';

  @override
  String get onboardingSafetyApproach =>
      'Nähern Sie sich niemals der Person, die die Drohne steuert, und folgen Sie ihr nicht.';

  @override
  String get onboardingSafetyDistance =>
      'Halten Sie Abstand zur Drohne und achten Sie auf den Verkehr um Sie herum.';

  @override
  String get onboardingSafetyDanger =>
      'Wenn jemand in Gefahr ist, rufen Sie zuerst 110 an.';

  @override
  String get onboardingPrivacyTitle => 'Grundsätzlich anonym';

  @override
  String get onboardingPrivacyNoAccount =>
      'Wir fragen nie nach Ihrem Namen, Ihrer Telefonnummer oder einem Konto.';

  @override
  String get onboardingPrivacyCollected =>
      'Eine Meldung enthält Ihren Standort, die Richtung, in die Sie das Telefon halten, von Ihnen hinzugefügte Fotos, Videos oder Tonaufnahmen sowie eine zufällige Kennung, die bei der Installation der App erzeugt wurde.';

  @override
  String get onboardingPrivacyUse =>
      'Meldungen werden ausschließlich von Behörden Taiwans genutzt, um Vorfälle mit Drohnen und auf See zu bearbeiten.';

  @override
  String get onboardingPermissionsTitle => 'Berechtigungen';

  @override
  String get onboardingPermissionsBody =>
      'Jede Berechtigung macht Ihre Meldungen nützlicher. Sie können jede davon ablehnen und trotzdem Meldungen senden.';

  @override
  String get onboardingStart => 'Los geht\'s';

  @override
  String get permLocationTitle => 'Standort';

  @override
  String get permLocationBody =>
      'Zeigt Ihre Meldung auf der Karte, damit die Einsatzkräfte wissen, wo sie suchen müssen.';

  @override
  String get permCameraTitle => 'Kamera';

  @override
  String get permCameraBody =>
      'Damit können Sie auf die Drohne zielen und Fotos oder Videos aufnehmen.';

  @override
  String get permMicrophoneTitle => 'Mikrofon';

  @override
  String get permMicrophoneBody =>
      'Nimmt das Geräusch der Rotoren auf. Das hilft, den Drohnentyp zu bestimmen.';

  @override
  String get permNearbyTitle => 'Geräte in der Nähe (Bluetooth und WLAN)';

  @override
  String get permNearbyBody =>
      'Empfängt das Remote-ID-Signal der Drohne: Seriennummer, Position und manchmal die Position der steuernden Person.';

  @override
  String get permNotificationsTitle => 'Benachrichtigungen';

  @override
  String get permNotificationsBody =>
      'Informiert Sie, wenn Ihr Fall aktualisiert wird. Benachrichtigungen enthalten nie Einzelheiten zum Fall.';

  @override
  String get permAllow => 'Erlauben';

  @override
  String get permGranted => 'Erlaubt';

  @override
  String get permOpenSettings => 'Einstellungen öffnen';

  @override
  String get homeReportButton => 'Sichtung melden';

  @override
  String get homeReportHint =>
      'Dauert weniger als eine Minute. Keine Anmeldung nötig.';

  @override
  String get homeMyReports => 'Meine Meldungen';

  @override
  String get homeNoReports =>
      'Sie haben von diesem Gerät noch keine Meldungen gesendet.';

  @override
  String get homeZonesMap => 'Karte der Flugverbotszonen';

  @override
  String get homeSettings => 'Einstellungen';

  @override
  String get homeWebBanner =>
      'Bei aktuellen Sichtungen sendet die Android-App genauere Meldungen: Sie misst die Richtung zur Drohne und empfängt deren Remote-ID-Signal.';

  @override
  String get homeGetAndroidApp => 'Android-App herunterladen';

  @override
  String get homeEvidenceRequested => 'Beweismittel angefordert';

  @override
  String get homePendingSend => 'Wartet auf Versand';

  @override
  String get homeStatusOffline => 'Zuletzt bekannter Status';

  @override
  String get caseNumberLabel => 'Fallnummer';

  @override
  String get reportTitle => 'Sichtung melden';

  @override
  String get stepAim => 'Zielen';

  @override
  String get stepDetails => 'Details';

  @override
  String get stepEvidence => 'Beweismittel';

  @override
  String get locationWaiting => 'Standort wird ermittelt…';

  @override
  String locationAccuracy(int meters) {
    return 'Standort ±$meters m';
  }

  @override
  String get locationUnavailable =>
      'Die Standortbestimmung ist ausgeschaltet oder nicht erlaubt. Schalten Sie sie ein oder legen Sie Ihre Position auf der Karte fest.';

  @override
  String get locationPickOnMap => 'Auf Karte festlegen';

  @override
  String get locationManual => 'Standort auf der Karte festgelegt';

  @override
  String get mapPickTitle => 'Tippen Sie auf Ihren Standort';

  @override
  String get mapPickConfirm => 'Diesen Standort verwenden';

  @override
  String get remoteIdTitle => 'Remote ID';

  @override
  String remoteIdReceives(String transports) {
    return 'Empfang über: $transports';
  }

  @override
  String remoteIdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Drohnen senden Remote ID',
      one: '1 Drohne sendet Remote ID',
      zero: 'Noch keine Drohne in der Nähe, die Remote ID sendet',
    );
    return '$_temp0';
  }

  @override
  String get remoteIdUnsupported =>
      'Dieses Telefon kann keine Remote-ID-Signale empfangen.';

  @override
  String get remoteIdPermission =>
      'Erlauben Sie „Geräte in der Nähe“, damit die App Remote ID empfangen kann.';

  @override
  String get remoteIdUnknownSerial => 'Seriennummer nicht empfangen';

  @override
  String remoteIdDistance(int meters) {
    return '$meters m entfernt';
  }

  @override
  String remoteIdHeight(int meters) {
    return '$meters m hoch';
  }

  @override
  String get transportBt4 => 'Bluetooth';

  @override
  String get transportBt5 => 'Bluetooth Long Range';

  @override
  String get transportWifiBeacon => 'WLAN-Beacon';

  @override
  String get transportWifiNan => 'Wi-Fi Aware';

  @override
  String get aimInstruction =>
      'Richten Sie das Telefon auf die Drohne oder das Boot und tippen Sie auf „Richtung festhalten“.';

  @override
  String get aimBearing => 'Richtung';

  @override
  String get aimElevation => 'Neigung nach oben';

  @override
  String get aimCalibrate =>
      'Der Kompass muss kalibriert werden: Bewegen Sie das Telefon einige Male in Form einer Acht.';

  @override
  String get aimNoCompass =>
      'Auf diesem Gerät gibt es keine Kompassdaten. Sie können diesen Schritt überspringen.';

  @override
  String get aimNoCamera => 'Kamera nicht verfügbar';

  @override
  String get aimLock => 'Richtung festhalten';

  @override
  String get aimTakePhoto => 'Auch ein Foto aufnehmen';

  @override
  String get aimSkip => 'Zielen überspringen';

  @override
  String aimLocked(int bearing, int elevation) {
    return 'Richtung festgehalten: $bearing°, $elevation° nach oben';
  }

  @override
  String get aimAgain => 'Erneut zielen';

  @override
  String get detailsTitle => 'Was haben Sie gesehen?';

  @override
  String get detailsOptional =>
      'Alle Angaben hier sind freiwillig. Überspringen Sie sie, wenn es eilt.';

  @override
  String get detailsHeight => 'Wie hoch war es?';

  @override
  String get detailsHeightHint =>
      'Ein Gebäude mit 10 Stockwerken ist etwa 30 m hoch.';

  @override
  String get heightBelow30 => 'Unter 30 m';

  @override
  String get height30to60 => '30–60 m';

  @override
  String get height60to120 => '60–120 m';

  @override
  String get heightAbove120 => 'Über 120 m';

  @override
  String get detailsMovement => 'Hat es sich bewegt?';

  @override
  String get movementHovering => 'Schwebend';

  @override
  String get movementMoving => 'In Bewegung';

  @override
  String get detailsCount => 'Wie viele Drohnen?';

  @override
  String get countOne => '1';

  @override
  String get countTwo => '2';

  @override
  String get countThreePlus => '3 oder mehr';

  @override
  String get detailsDescription => 'Sonst noch etwas? (optional)';

  @override
  String get detailsDescriptionHint =>
      'Zum Beispiel: flog über den Schulhof, rote Lichter, lautes Summen';

  @override
  String get evidenceTitle => 'Fotos, Videos und Ton';

  @override
  String get evidenceSpeedNote =>
      'Schnelles Senden ist wichtiger als perfekte Beweismittel. Sie können jetzt senden; Dateien werden im Hintergrund hochgeladen.';

  @override
  String get mediaPhoto => 'Foto';

  @override
  String get mediaVideo => 'Video';

  @override
  String get mediaAudio => 'Tonaufnahme';

  @override
  String get evidenceRecordSound => 'Ton aufnehmen';

  @override
  String get evidenceStopRecording => 'Aufnahme beenden';

  @override
  String evidenceRecording(int seconds) {
    return 'Rotorgeräusch wird aufgenommen… $seconds s';
  }

  @override
  String get evidenceNone => 'Noch keine Dateien hinzugefügt.';

  @override
  String get evidenceRemove => 'Datei entfernen';

  @override
  String get evidenceAimPhoto =>
      'Foto beim Festhalten der Richtung aufgenommen';

  @override
  String get evidenceCaptureFailed =>
      'Die Datei konnte nicht aufgenommen werden. Bitte versuchen Sie es erneut.';

  @override
  String get sendNow => 'Meldung jetzt senden';

  @override
  String get sending => 'Wird gesendet…';

  @override
  String get sendQueuedTitle => 'Meldung gespeichert';

  @override
  String get sendQueuedBody =>
      'Zurzeit besteht keine Verbindung. Ihre Meldung ist auf diesem Telefon gespeichert und wird automatisch gesendet, sobald Sie wieder online sind.';

  @override
  String get sendRateLimited =>
      'Von diesem Gerät oder Netzwerk wurden in letzter Zeit zu viele Meldungen gesendet. Bitte warten Sie einige Minuten und versuchen Sie es dann erneut. Wenn jemand in Gefahr ist, rufen Sie 110 an.';

  @override
  String sendRejected(String message) {
    return 'Die Meldung konnte nicht angenommen werden: $message';
  }

  @override
  String get sendFailedTitle => 'Meldung nicht gesendet';

  @override
  String get discardTitle => 'Diese Meldung verwerfen?';

  @override
  String get discardBody => 'Es wurde noch nichts gesendet.';

  @override
  String get discard => 'Verwerfen';

  @override
  String get sentTitle => 'Meldung gesendet';

  @override
  String get sentBody =>
      'Vielen Dank. Ihre Meldung wurde an die zuständige Stelle weitergeleitet.';

  @override
  String sentUploading(int done, int total) {
    return 'Dateien werden hochgeladen: $done von $total';
  }

  @override
  String get sentUploadsDone => 'Alle Dateien hochgeladen.';

  @override
  String get sentUploadsBackground =>
      'Das Hochladen läuft im Hintergrund weiter, auch wenn Sie die App schließen.';

  @override
  String get sentUploadsKeepOpen =>
      'Lassen Sie diese Seite geöffnet, bis alle Dateien hochgeladen sind.';

  @override
  String get sentKeyNote =>
      'Nur dieses Telefon besitzt den privaten Schlüssel, mit dem Sie diese Meldung verfolgen können. Wenn Sie die App deinstallieren oder ihre Daten löschen, sehen Sie keine Aktualisierungen mehr.';

  @override
  String get sentKeyNoteWeb =>
      'Nur dieser Browser besitzt den privaten Schlüssel, mit dem Sie diese Meldung verfolgen können. Wenn Sie Ihre Browserdaten löschen, sehen Sie keine Aktualisierungen mehr.';

  @override
  String get sentAndroidHint =>
      'Beim nächsten Mal kann die Android-App die Richtung zur Drohne messen und ihre Remote ID empfangen. Dadurch wird Ihre Meldung noch nützlicher.';

  @override
  String get sentViewStatus => 'Status anzeigen';

  @override
  String get sentBackHome => 'Zur Startseite';

  @override
  String caseTitle(String caseNumber) {
    return 'Fall $caseNumber';
  }

  @override
  String get caseProgress => 'Fortschritt';

  @override
  String get caseOutcome => 'Ergebnis';

  @override
  String get caseEvidenceRequests => 'Anfragen nach weiteren Beweismitteln';

  @override
  String get caseEvidenceSafety =>
      'Senden Sie nur, was Sie von Ihrem Standort aus gefahrlos aufnehmen können.';

  @override
  String get caseEvidenceAnswered => 'Beantwortet – vielen Dank.';

  @override
  String caseEvidenceSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien senden',
      one: '1 Datei senden',
    );
    return '$_temp0';
  }

  @override
  String get caseEvidenceSent =>
      'Vielen Dank. Ihre Dateien werden hochgeladen.';

  @override
  String get caseEvidenceClosed => 'Diese Anfrage ist nicht mehr offen.';

  @override
  String get caseNotOnDevice =>
      'Diese Meldung ist nicht auf diesem Gerät gespeichert.';

  @override
  String caseUpdated(String time) {
    return 'Aktualisiert $time';
  }

  @override
  String get zonesTitle => 'Flugverbotszonen';

  @override
  String get zonesLegend => 'Legende';

  @override
  String get zonesMyLocation => 'Mein Standort';

  @override
  String get zonesNote =>
      'Zeigt nur die veröffentlichten Drohnenzonen der Zivilluftfahrtbehörde (CAA). Manche Sperrgebiete sind auf öffentlichen Karten nicht verzeichnet.';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsPrivacy => 'Datenschutz und Info';

  @override
  String get settingsPrivacyBody =>
      'reporting.tw ist ein Dienst der Regierung Taiwans zum Melden verdächtiger Drohnen, unbemannter Boote und anderer verdächtiger Objekte in der Luft, auf See oder an der Küste. Meldungen sind anonym: Wir fragen nie nach Ihrem Namen, Ihrer Telefonnummer oder einem Konto. Eine Meldung enthält Ihren Standort, die Richtung, in die Sie das Telefon gehalten haben, Ihre Antworten auf die Fragen, von Ihnen hinzugefügte Fotos, Videos oder Tonaufnahmen, von Ihrem Telefon empfangene Remote-ID-Signale sowie eine zufällige Kennung, die bei der Installation der App erzeugt wurde. Fotos können automatisch von einem KI-Modell ausgewertet werden, um den Einsatzkräften die Einschätzung der Meldung zu erleichtern. Diese Informationen werden ausschließlich von Behörden Taiwans zur Bearbeitung solcher Vorfälle genutzt.';

  @override
  String get settingsClearHistory => 'Meldeverlauf löschen';

  @override
  String get settingsClearHistoryBody =>
      'Dadurch werden Ihre Meldungen und die zugehörigen privaten Schlüssel zur Nachverfolgung von diesem Gerät entfernt. Sie sehen dann keine Aktualisierungen mehr und können Anfragen zu diesen Meldungen nicht mehr beantworten. Bereits gesendete Meldungen werden nicht zurückgezogen.';

  @override
  String get settingsClear => 'Löschen';

  @override
  String get settingsHistoryCleared => 'Meldeverlauf gelöscht.';

  @override
  String get settingsShowIntro => 'Einführung erneut anzeigen';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }
}
