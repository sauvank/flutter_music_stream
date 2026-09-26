# MusicStream — Directives pour assistants et agents

## Sécurité absolue

Ce dépôt est privé, mais il doit rester publiable sans nettoyage de sécurité. Ne jamais ajouter ni commiter de mot de passe, jeton, clé API, clé privée, certificat, keystore, configuration Firebase réelle, adresse IP privée réelle, identifiant matériel ou chemin local personnel.

Utiliser uniquement des exemples génériques tels que `192.168.1.100`, `user`, `0123456789ABCDEF` et `/media/music/...`. Les notes privées portent l’extension `.private.md` ou le nom `SECURITY_CONTEXT.md` et restent ignorées par Git.

## Qualité

Toute modification doit être validée avec :

```bash
flutter analyze
flutter test
```

## Documentation et versions

Maintenir `README.md`, `docs/CONTEXT.md`, `docs/ARCHITECTURE.md` et `docs/ROADMAP.md` en cohérence avec le code. Utiliser Conventional Commits. Après une modification finalisée, lancer `./scripts/bump_and_push.sh patch`, sauf demande explicite d’une version mineure ou majeure.
