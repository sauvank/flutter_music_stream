# Configuration locale

## Installation de test indépendante (Android)

Pour tester sans remplacer l’application signée Google Play ni toucher à sa bibliothèque :

```sh
ORG_GRADLE_PROJECT_musicstreamTestSuffix=.stresstest flutter build apk --debug --target-platform android-arm64
```

L’APK s’appelle « MusicStream Test », possède un stockage distinct et n’utilise pas la configuration Firebase de production. Sans cette variable, l’identifiant et la configuration habituels restent inchangés. Ne jamais désinstaller l’app Play pour contourner une différence de signature.

## Firebase (synchronisation de compte)

Les fichiers de configuration Firebase ne sont pas versionnés. Sans eux,
l’application compile et la synchronisation apparaît comme indisponible.

Projet : celui de `.firebaserc` (local, ignoré par git). Pour régénérer les
fichiers avec le CLI Firebase connecté au compte propriétaire :

```sh
firebase apps:list --project <projet>
firebase apps:sdkconfig ANDROID <appId Android> -o android/app/google-services.json
firebase apps:sdkconfig IOS <appId iOS> -o ios/Runner/GoogleService-Info.plist
```

- Le plugin Gradle `com.google.gms.google-services` n’est appliqué que si
  `android/app/google-services.json` existe.
- Google Sign-In sur Android exige l’empreinte SHA-1 de la clé de signature :
  `firebase apps:android:sha:create <appId> <sha1>` (clé de debug enregistrée;
  ajouter la clé d’envoi Play et la clé de signature Play le moment venu).
- Règles Firestore : `firestore.rules`, déployées par
  `firebase deploy --only firestore`.
- iOS (non testé) : ajouter le `REVERSED_CLIENT_ID` du plist comme URL scheme
  dans `Info.plist` pour Google Sign-In, et une cible iOS 13 minimum pour
  `cloud_firestore`.

## Publication Google Play automatique

`.github/workflows/release.yml` construit l’`.aab` signé et l’envoie à Google
Play à chaque tag `v*` (créé par `scripts/bump_and_push.sh`), sur la piste
**internal**. Lancer le workflow à la main (« Run workflow ») permet de choisir
une autre piste (`alpha`, `beta`, `production`).

Secrets GitHub du dépôt :

- `UPLOAD_KEYSTORE_BASE64`, `UPLOAD_KEYSTORE_PASSWORD` : clé d’envoi (alias
  `upload`, mot de passe de stockage = mot de passe de clé), gardée hors dépôt
  dans `~/.musicstream-keys/`.
- `GOOGLE_SERVICES_JSON_BASE64` : `android/app/google-services.json`.
- `PLAY_SERVICE_ACCOUNT_JSON` : clé JSON d’un compte de service Google Cloud
  invité dans la Play Console (Utilisateurs et autorisations) avec le droit de
  publier des versions. Compte actuel : `play-publisher@musicstream-ks.iam.gserviceaccount.com`
  (projet `musicstream-ks`, API Google Play Android Developer activée).

Le premier `.aab` d’une nouvelle application doit être envoyé à la main dans la
Play Console. Google Sign-In depuis Play exige aussi l’empreinte **SHA-1** de la
clé de signature Play (page « Intégrité de l’appli ») dans Firebase :
`firebase apps:android:sha:create <appId> <sha1>`.
