# Accès pour la revue Google Play

L'app n'a pas de compte : la revue a seulement besoin d'une source. Source de démo hébergée sur Firebase Hosting (`hosting/demo/`, morceaux synthétisés par ffmpeg, donc sans droits tiers). Déploiement : `firebase deploy --only hosting`.

URL : `https://musicstream-ks.web.app/demo/` (type HTTP, sans utilisateur ni mot de passe).

## Texte à coller (Play Console → Accès à l'application, en anglais)

```
No account or login is required. The app plays music from sources the user adds.
To see content, add this public demo source:
1. Open the "Servers" tab (cloud icon in the bottom bar) and tap "+".
2. Name: Demo. Type: HTTP.
3. Address: https://musicstream-ks.web.app/demo/
4. Leave username and password empty, then tap Save.
5. Open the "Demo" server, tap scan/browse, open "Demo Album" and play any track.
The source is always online, public, and valid in all countries.
```
