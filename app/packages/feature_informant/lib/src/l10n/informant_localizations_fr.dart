// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'informant_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class InformantL10nFr extends InformantL10n {
  InformantL10nFr([String locale = 'fr']) : super(locale);

  @override
  String get skip => 'Passer';

  @override
  String get notSure => 'Je ne sais pas';

  @override
  String get onboardingLanguageTitle => 'Choisissez votre langue';

  @override
  String get onboardingLanguageBody =>
      'Vous pouvez la modifier à tout moment dans les Paramètres.';

  @override
  String get onboardingWhatTitle =>
      'Signalez les drones, bateaux sans équipage et autres engins suspects';

  @override
  String get onboardingWhatBody =>
      'Vous avez vu un drone près d\'un aéroport ou d\'un site militaire, un bateau sans équipage au large des côtes ou un engin qui accoste sur une plage ? Signalez-le en moins d\'une minute. Votre signalement est transmis directement au service compétent : police, aviation civile, garde-côtes ou défense.';

  @override
  String get onboardingSafetyTitle => 'Votre sécurité passe avant tout';

  @override
  String get onboardingSafetyApproach =>
      'N\'approchez jamais la personne qui pilote le drone et ne la suivez pas.';

  @override
  String get onboardingSafetyDistance =>
      'Restez à distance du drone et faites attention à la circulation autour de vous.';

  @override
  String get onboardingSafetyDanger =>
      'Si quelqu\'un est en danger, appelez d\'abord le 110.';

  @override
  String get onboardingPrivacyTitle => 'Anonyme par conception';

  @override
  String get onboardingPrivacyNoAccount =>
      'Nous ne vous demandons jamais votre nom, votre numéro de téléphone ni de créer un compte.';

  @override
  String get onboardingPrivacyCollected =>
      'Un signalement contient votre position, la direction dans laquelle vous pointez le téléphone, les photos, vidéos ou sons que vous ajoutez, ainsi qu\'un identifiant aléatoire créé lors de l\'installation de l\'application.';

  @override
  String get onboardingPrivacyUse =>
      'Les signalements sont utilisés uniquement par les autorités de Taïwan pour traiter les incidents liés aux drones et les incidents maritimes.';

  @override
  String get onboardingPermissionsTitle => 'Autorisations';

  @override
  String get onboardingPermissionsBody =>
      'Chaque autorisation rend vos signalements plus utiles. Vous pouvez refuser n\'importe laquelle et continuer à envoyer des signalements.';

  @override
  String get onboardingStart => 'Commencer';

  @override
  String get permLocationTitle => 'Position';

  @override
  String get permLocationBody =>
      'Place votre signalement sur la carte, pour que les agents sachent où chercher.';

  @override
  String get permCameraTitle => 'Appareil photo';

  @override
  String get permCameraBody =>
      'Vous permet de viser le drone et de prendre des photos ou des vidéos.';

  @override
  String get permMicrophoneTitle => 'Micro';

  @override
  String get permMicrophoneBody =>
      'Enregistre le bruit des rotors, ce qui aide à identifier le type de drone.';

  @override
  String get permNearbyTitle => 'Appareils à proximité (Bluetooth et Wi-Fi)';

  @override
  String get permNearbyBody =>
      'Capte le signal Remote ID du drone : son numéro de série, sa position et parfois celle de la personne qui le pilote.';

  @override
  String get permNotificationsTitle => 'Notifications';

  @override
  String get permNotificationsBody =>
      'Vous prévient lorsque votre dossier est mis à jour. Les notifications ne contiennent jamais de détails sur le dossier.';

  @override
  String get permAllow => 'Autoriser';

  @override
  String get permGranted => 'Autorisé';

  @override
  String get permOpenSettings => 'Ouvrir les paramètres';

  @override
  String get homeReportButton => 'Signaler une observation';

  @override
  String get homeReportHint =>
      'Moins d\'une minute. Aucune inscription nécessaire.';

  @override
  String get homeMyReports => 'Mes signalements';

  @override
  String get homeNoReports =>
      'Vous n\'avez encore envoyé aucun signalement depuis cet appareil.';

  @override
  String get homeZonesMap => 'Carte des zones interdites de vol';

  @override
  String get homeSettings => 'Paramètres';

  @override
  String get homeWebBanner =>
      'Pour une observation en direct, l\'application Android envoie des signalements plus précis : elle mesure la direction du drone et capte son signal Remote ID.';

  @override
  String get homeGetAndroidApp => 'Télécharger l\'application Android';

  @override
  String get homeEvidenceRequested => 'Éléments demandés';

  @override
  String get homePendingSend => 'En attente d\'envoi';

  @override
  String get homeStatusOffline => 'Dernier statut connu';

  @override
  String get caseNumberLabel => 'Numéro de dossier';

  @override
  String get reportTitle => 'Signaler une observation';

  @override
  String get stepAim => 'Viser';

  @override
  String get stepDetails => 'Détails';

  @override
  String get stepEvidence => 'Éléments';

  @override
  String get locationWaiting => 'Recherche de votre position…';

  @override
  String locationAccuracy(int meters) {
    return 'Position ±$meters m';
  }

  @override
  String get locationUnavailable =>
      'La localisation est désactivée ou non autorisée. Activez-la ou indiquez votre position sur la carte.';

  @override
  String get locationPickOnMap => 'Indiquer sur la carte';

  @override
  String get locationManual => 'Position indiquée sur la carte';

  @override
  String get mapPickTitle => 'Touchez l\'endroit où vous êtes';

  @override
  String get mapPickConfirm => 'Utiliser cette position';

  @override
  String get remoteIdTitle => 'Remote ID';

  @override
  String remoteIdReceives(String transports) {
    return 'Écoute sur : $transports';
  }

  @override
  String remoteIdCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drones émettent un Remote ID',
      one: '1 drone émet un Remote ID',
      zero: 'Aucun drone n\'émet encore de Remote ID à proximité',
    );
    return '$_temp0';
  }

  @override
  String get remoteIdUnsupported =>
      'Ce téléphone ne peut pas recevoir les signaux Remote ID.';

  @override
  String get remoteIdPermission =>
      'Autorisez « Appareils à proximité » pour que l\'application puisse capter le Remote ID.';

  @override
  String get remoteIdUnknownSerial => 'Numéro de série non reçu';

  @override
  String remoteIdDistance(int meters) {
    return 'à $meters m';
  }

  @override
  String remoteIdHeight(int meters) {
    return '$meters m de haut';
  }

  @override
  String get transportBt4 => 'Bluetooth';

  @override
  String get transportBt5 => 'Bluetooth longue portée';

  @override
  String get transportWifiBeacon => 'Balise Wi-Fi';

  @override
  String get transportWifiNan => 'Wi-Fi Aware';

  @override
  String get aimInstruction =>
      'Pointez le téléphone vers le drone ou l\'embarcation et touchez « Verrouiller la direction ».';

  @override
  String get aimBearing => 'Direction';

  @override
  String get aimElevation => 'Angle vers le haut';

  @override
  String get aimCalibrate =>
      'La boussole doit être étalonnée : déplacez le téléphone en dessinant un 8 plusieurs fois.';

  @override
  String get aimNoCompass =>
      'Aucune donnée de boussole sur cet appareil. Vous pouvez passer cette étape.';

  @override
  String get aimNoCamera => 'Appareil photo indisponible';

  @override
  String get aimLock => 'Verrouiller la direction';

  @override
  String get aimTakePhoto => 'Prendre aussi une photo';

  @override
  String get aimSkip => 'Passer la visée';

  @override
  String aimLocked(int bearing, int elevation) {
    return 'Direction verrouillée : $bearing°, $elevation° vers le haut';
  }

  @override
  String get aimAgain => 'Viser à nouveau';

  @override
  String get detailsTitle => 'Qu\'avez-vous vu ?';

  @override
  String get detailsOptional =>
      'Tout est facultatif ici. Passez cette étape si le temps presse.';

  @override
  String get detailsHeight => 'À quelle hauteur ?';

  @override
  String get detailsHeightHint =>
      'Un immeuble de 10 étages mesure environ 30 m de haut.';

  @override
  String get heightBelow30 => 'Moins de 30 m';

  @override
  String get height30to60 => '30–60 m';

  @override
  String get height60to120 => '60–120 m';

  @override
  String get heightAbove120 => 'Plus de 120 m';

  @override
  String get detailsMovement => 'Était-il en mouvement ?';

  @override
  String get movementHovering => 'En vol stationnaire';

  @override
  String get movementMoving => 'En mouvement';

  @override
  String get detailsCount => 'Combien de drones ?';

  @override
  String get countOne => '1';

  @override
  String get countTwo => '2';

  @override
  String get countThreePlus => '3 ou plus';

  @override
  String get detailsDescription => 'Autre chose ? (facultatif)';

  @override
  String get detailsDescriptionHint =>
      'Par exemple : survolait la cour de l\'école, lumières rouges, bourdonnement fort';

  @override
  String get evidenceTitle => 'Photos, vidéos et sons';

  @override
  String get evidenceSpeedNote =>
      'Envoyer rapidement compte plus que des éléments parfaits. Vous pouvez envoyer maintenant ; les fichiers sont téléversés en arrière-plan.';

  @override
  String get mediaPhoto => 'Photo';

  @override
  String get mediaVideo => 'Vidéo';

  @override
  String get mediaAudio => 'Enregistrement sonore';

  @override
  String get evidenceRecordSound => 'Enregistrer le son';

  @override
  String get evidenceStopRecording => 'Arrêter l\'enregistrement';

  @override
  String evidenceRecording(int seconds) {
    return 'Enregistrement du bruit des rotors… $seconds s';
  }

  @override
  String get evidenceNone => 'Aucun fichier ajouté pour l\'instant.';

  @override
  String get evidenceRemove => 'Supprimer le fichier';

  @override
  String get evidenceAimPhoto =>
      'Photo prise lors du verrouillage de la direction';

  @override
  String get evidenceCaptureFailed =>
      'Impossible d\'enregistrer le fichier. Veuillez réessayer.';

  @override
  String get sendNow => 'Envoyer le signalement maintenant';

  @override
  String get sending => 'Envoi en cours…';

  @override
  String get sendQueuedTitle => 'Signalement enregistré';

  @override
  String get sendQueuedBody =>
      'Il n\'y a pas de connexion pour le moment. Votre signalement est enregistré sur ce téléphone et sera envoyé automatiquement dès que vous serez de nouveau en ligne.';

  @override
  String get sendRateLimited =>
      'Trop de signalements ont été envoyés récemment depuis cet appareil ou ce réseau. Veuillez patienter quelques minutes, puis réessayer. Si quelqu\'un est en danger, appelez le 110.';

  @override
  String sendRejected(String message) {
    return 'Le signalement n\'a pas pu être accepté : $message';
  }

  @override
  String get sendFailedTitle => 'Signalement non envoyé';

  @override
  String get discardTitle => 'Abandonner ce signalement ?';

  @override
  String get discardBody => 'Rien n\'a encore été envoyé.';

  @override
  String get discard => 'Abandonner';

  @override
  String get sentTitle => 'Signalement envoyé';

  @override
  String get sentBody =>
      'Merci. Votre signalement a été transmis au service compétent.';

  @override
  String sentUploading(int done, int total) {
    return 'Téléversement des fichiers : $done sur $total';
  }

  @override
  String get sentUploadsDone => 'Tous les fichiers ont été téléversés.';

  @override
  String get sentUploadsBackground =>
      'Le téléversement continue en arrière-plan, même si vous fermez l\'application.';

  @override
  String get sentUploadsKeepOpen =>
      'Laissez cette page ouverte jusqu\'à la fin du téléversement des fichiers.';

  @override
  String get sentKeyNote =>
      'Seul ce téléphone détient la clé privée permettant de suivre ce signalement. Si vous désinstallez l\'application ou effacez ses données, vous ne verrez plus les mises à jour.';

  @override
  String get sentKeyNoteWeb =>
      'Seul ce navigateur détient la clé privée permettant de suivre ce signalement. Si vous effacez les données de votre navigateur, vous ne verrez plus les mises à jour.';

  @override
  String get sentAndroidHint =>
      'La prochaine fois, l\'application Android pourra mesurer la direction du drone et capter son Remote ID, ce qui rendra votre signalement plus utile.';

  @override
  String get sentViewStatus => 'Voir le statut';

  @override
  String get sentBackHome => 'Retour à l\'accueil';

  @override
  String caseTitle(String caseNumber) {
    return 'Dossier $caseNumber';
  }

  @override
  String get caseProgress => 'Avancement';

  @override
  String get caseOutcome => 'Résultat';

  @override
  String get caseEvidenceRequests => 'Demandes d\'éléments supplémentaires';

  @override
  String get caseEvidenceSafety =>
      'N\'envoyez que ce que vous pouvez capter en toute sécurité depuis l\'endroit où vous êtes.';

  @override
  String get caseEvidenceAnswered => 'Répondu — merci.';

  @override
  String caseEvidenceSend(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Envoyer $count fichiers',
      one: 'Envoyer 1 fichier',
    );
    return '$_temp0';
  }

  @override
  String get caseEvidenceSent =>
      'Merci. Vos fichiers sont en cours de téléversement.';

  @override
  String get caseEvidenceClosed => 'Cette demande n\'est plus ouverte.';

  @override
  String get caseNotOnDevice =>
      'Ce signalement n\'est pas enregistré sur cet appareil.';

  @override
  String caseUpdated(String time) {
    return 'Mis à jour $time';
  }

  @override
  String get zonesTitle => 'Zones interdites de vol';

  @override
  String get zonesLegend => 'Légende';

  @override
  String get zonesMyLocation => 'Ma position';

  @override
  String get zonesNote =>
      'Affiche uniquement les zones drones publiées par l\'aviation civile (CAA). Certaines zones réglementées ne figurent pas sur les cartes publiques.';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsPrivacy => 'Confidentialité et à propos';

  @override
  String get settingsPrivacyBody =>
      'reporting.tw est un service du gouvernement de Taïwan permettant de signaler les drones, bateaux sans équipage et autres engins suspects dans les airs, en mer ou sur la côte. Les signalements sont anonymes : nous ne vous demandons jamais votre nom, votre numéro de téléphone ni de créer un compte. Un signalement contient votre position, la direction dans laquelle vous avez pointé le téléphone, vos réponses aux questions, les photos, vidéos ou sons que vous ajoutez, les signaux Remote ID captés par votre téléphone et un identifiant aléatoire créé lors de l\'installation de l\'application. Les photos peuvent être analysées automatiquement par un modèle d\'IA afin d\'aider les agents à évaluer le signalement. Ces informations sont utilisées uniquement par les autorités de Taïwan pour traiter ces incidents.';

  @override
  String get settingsClearHistory => 'Effacer l\'historique des signalements';

  @override
  String get settingsClearHistoryBody =>
      'Cette action supprime de cet appareil vos signalements et leurs clés privées de suivi. Vous ne verrez plus les mises à jour et ne pourrez plus répondre aux demandes concernant ces signalements. Les signalements déjà envoyés ne sont pas retirés.';

  @override
  String get settingsClear => 'Effacer';

  @override
  String get settingsHistoryCleared => 'Historique des signalements effacé.';

  @override
  String get settingsShowIntro => 'Revoir la présentation';

  @override
  String settingsVersion(String version) {
    return 'Version $version';
  }
}
