# Connexion de l'app Flutter à l'API `demo`

Si `curl_test.sh` passe mais que l'app Flutter n'accède pas à l'API, le problème vient généralement de l'URL de base selon la plateforme.

## 1) Démarrer l'API

Depuis le dossier `demo` :

```bash
./gradlew bootRun
```

L'API écoute sur `http://localhost:8080/api`.

## 2) URL utilisée par Flutter

Le client Flutter prend automatiquement :

- Android émulateur: `http://10.0.2.2:8080/api`
- Web / Linux / macOS / Windows / iOS simulateur: `http://localhost:8080/api`

Tu peux forcer une URL avec `--dart-define`.

## 3) Lancer Flutter avec une URL explicite (recommandé)

### Android (émulateur)

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
```

### Android (téléphone réel en USB)

Remplace `<IP_PC>` par l'IP locale de ta machine (ex: `192.168.1.42`) :

```bash
flutter run --dart-define=API_BASE_URL=http://<IP_PC>:8080/api
```

### Web

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
```

## 4) Vérifications rapides

- API OK: `curl http://localhost:8080/api/posts -u user:pass`
- Depuis Android émulateur: ne pas utiliser `localhost`, utiliser `10.0.2.2`
- Si l'API tourne dans Docker, utiliser un hostname/IP accessible depuis l'app, pas `demo` sauf réseau Docker partagé
