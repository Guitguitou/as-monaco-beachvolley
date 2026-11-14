# Déploiement sur Scalingo (Solid Queue, sans Redis)

Cache (`Rails.cache`), jobs (Active Job) et Action Cable reposent sur la base
PostgreSQL de l'application via Solid Cache, Solid Queue et Solid Cable.
Seul l'addon PostgreSQL est nécessaire.

## Architecture

- **web** : Puma, qui traite aussi les jobs quand `SOLID_QUEUE_IN_PUMA=true`
  (plugin Solid Queue en mode `async` : worker, dispatcher et scheduler en threads).
- **worker** (optionnel, scalé à 0 par défaut) : `bin/jobs`, pour sortir les jobs
  du conteneur web si le volume augmente.
- **Tâches récurrentes** : `config/recurring.yml`, exécutées par le scheduler Solid Queue.

## Mise en place

```bash
# 1. Traiter les jobs dans le conteneur web
scalingo --app votre-app env-set SOLID_QUEUE_IN_PUMA=true

# 2. Déployer (le postdeploy lance db:migrate, qui crée les tables solid_*)
git push scalingo main

# 3. Une fois le déploiement vérifié : couper le worker et supprimer Redis
scalingo --app votre-app scale worker:0
scalingo --app votre-app addons-remove <id-addon-redis>
scalingo --app votre-app env-unset REDIS_URL
```

## Vérifier

- Dashboard des jobs (admin) : `https://votre-app.osc-fr1.scalingo.io/admin/jobs`
- Processus actifs (supervisor, worker, dispatcher, scheduler) :

```bash
scalingo --app votre-app run bin/rails runner 'p SolidQueue::Process.pluck(:kind)'
```

## Réglages

| Variable | Défaut | Rôle |
|---|---|---|
| `SOLID_QUEUE_IN_PUMA` | absent | Active le traitement des jobs dans Puma |
| `SOLID_QUEUE_MODE` | `async` | `fork` pour des process séparés (plus de mémoire) |
| `DB_POOL` | `RAILS_MAX_THREADS + 7` | Connexions Postgres par process |
| `JOB_CONCURRENCY` | `1` | Process worker de `bin/jobs` (mode fork) |

## Passer à un worker dédié

Si les jobs ralentissent le web :

```bash
scalingo --app votre-app env-unset SOLID_QUEUE_IN_PUMA
scalingo --app votre-app scale worker:1
```
