# Contexte produit — MusicStream

MusicStream transpose l’expérience de ComicStream à une bibliothèque musicale personnelle : importer ou récupérer ses morceaux, les conserver hors connexion et les écouter sur mobile ou ordinateur.

## Principes

- Local-first : l’application fonctionne sans compte et sans serveur.
- Aucun fichier audio, chemin local ou secret n’est envoyé par défaut.
- Les pistes sont identifiées par SHA-256 afin de dédupliquer les imports et, à terme, synchroniser uniquement les métadonnées.
- Les identifiants de serveurs devront être stockés dans le coffre sécurisé du système.
- Toute synchronisation future chiffrera les données côté client.
- Android cible au minimum l’API 23, exigée par le coffre sécurisé, tout en couvrant la cible principale Android 8.

## Version 0.1

La bibliothèque importe des formats audio courants dans le stockage privé de l’application. Elle persiste le titre issu du nom de fichier, l’état favori et la position de reprise, actualisée pendant l’écoute. Le moteur `just_audio` fournit la file et `just_audio_background` les commandes système.

Les profils WebDAV et HTTP séparent les métadonnées non sensibles, conservées dans les préférences, des mots de passe placés dans le coffre sécurisé du système. L’utilisateur parcourt les dossiers distants et choisit les morceaux à copier hors ligne. La diffusion directe, le FTP, l’extraction de tags, les pochettes, les playlists et les comptes ne sont pas encore implémentés.
