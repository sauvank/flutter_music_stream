# Secrets et déploiement

Le modèle suit le principe de `install-vps` : un secret n’est jamais un fichier versionné. Il est fourni au job uniquement par un environnement GitHub protégé, écrit avec des permissions restrictives si un outil exige un fichier, puis supprimé dans une étape `if: always()`.

Secrets éventuellement nécessaires plus tard :

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `FIREBASE_ANDROID_CONFIG`
- `PLAY_STORE_JSON_KEY`

Ils ne sont pas requis pour analyser, tester ou compiler une version debug. Ne jamais placer de valeur réelle dans la documentation, un exemple, une issue ou les journaux CI.

Pour un déploiement VPS futur, utiliser une clé SSH dédiée au projet, une commande forcée et l’option OpenSSH `restrict`. La clé CI ne doit jamais permettre un shell général, un transfert arbitraire ou du port forwarding.
