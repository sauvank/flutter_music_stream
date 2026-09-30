# Feuille de route

## Livré

- [x] Bibliothèque locale, tags, pochettes, favoris, playlists et déduplication SHA-256.
- [x] Lecture mobile en arrière-plan avec commandes système.
- [x] Profils WebDAV/HTTP et import JSON MusicStream/ComicStream sécurisé.
- [x] Navigation distante et téléchargement de morceaux ou dossiers entiers.
- [x] File native persistante avec progression, notifications, pause, reprise et nouvelle tentative.
- [x] Écoute directe d’un fichier distant et import récursif d’un dossier local.
- [x] Affichage distant fiable des tags et pochettes par échantillonnage HTTP.
- [x] Lecture aléatoire et répétition de la file ou du morceau.
- [x] Fondus configurables à la lecture, la pause et la navigation.
- [x] Navigation et import de morceaux ou dossiers depuis un serveur FTP passif.
- [x] Déduplication des téléchargements de dossiers imbriqués, limitation des transferts par serveur et état local complet/partiel/absent des dossiers.
- [x] Suppression individuelle ou globale des téléchargements serveur sans effacer les imports locaux.
- [x] Détection manuelle des nouveaux albums sur les serveurs configurés.
- [x] File de lecture visible et modifiable : lire ensuite, ajouter en fin, sélectionner, réordonner et retirer.
- [x] Volume applicatif persistant et historique des morceaux réellement écoutés.
- [x] Paroles `.lrc` locales et LRCLIB, synchronisées avec la lecture, recherche automatique après accord et traduction à la demande avec cache privé.
- [x] Premier passage de performance pour les grandes bibliothèques et les files de téléchargement volumineuses.
- [x] Badge de disponibilité locale des morceaux dans le navigateur serveur.
- [x] Description et réorganisation manuelle des playlists.
- [x] Choix explicite du thème (système, clair, sombre) persisté.
- [x] Localisation français/anglais avec choix de langue persisté.
- [x] Mesures sur Galaxy S24 : démarrage corrigé (0,7–0,95 s), défilement sans point chaud, import de 40 fichiers (146 Mo) en 2,6 s sans image figée.
- [x] Permission audio demandée avant l’import de dossier et nettoyage des copies orphelines au démarrage.
- [x] Médiathèque de l’appareil comme source distincte, sans copie : 720 morceaux indexés en 17 s sur Galaxy S24.
- [x] Widget d’accueil Android (morceau, pochette, précédent/lecture/suivant), ajoutable depuis Réglages.
- [x] Synchronisation chiffrée de bout en bout (favoris, écoutes, playlists) via un fichier sur un serveur WebDAV de l’utilisateur.
- [x] Bouton de diffusion ouvrant le sélecteur de sortie audio Android (Bluetooth, Alexa appairée).

## En cours


## À venir

- [ ] Diffusion réseau Chromecast/DLNA si besoin (SDK Cast ou découverte UPnP, plus un serveur HTTP local pour les fichiers). Alexa n’accepte pas la diffusion d’applis tierces, uniquement le Bluetooth.

## Différé

- [ ] Égaliseur : attendre une implémentation cohérente Android/iOS. `just_audio 0.10.6` ne fournit actuellement qu’un égaliseur Android; ne pas exposer un réglage sans effet sur iOS.

## Décision ouverte

- Déterminer si HTTP non chiffré doit rester autorisé globalement sur Android ou être limité par une configuration réseau fournie hors dépôt.
