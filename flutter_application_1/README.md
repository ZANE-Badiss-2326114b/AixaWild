# Connexion de l'app Flutter à l'API

L'app Flutter utilise maintenant une URL d'API fixe.

## 1) Démarrer l'API

Depuis le dossier `demo` :

```bash
./gradlew bootRun
```

L'API Flutter est appelée sur `https://api-7e6i.onrender.com/api`.

## 2) Vérifications rapides

- API OK: `curl https://api-7e6i.onrender.com/api/posts -u user:pass`
- Si l'app ne communique pas avec l'API, vérifier la disponibilité du service distant
- Si tu changes d'environnement, il faut modifier le client Dart directement
