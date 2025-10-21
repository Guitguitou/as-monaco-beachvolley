# Déploiement Sidekiq sur Scalingo

## 🚀 Guide de déploiement pour Scalingo

Ce guide explique comment déployer votre application avec Sidekiq sur Scalingo.

## Prérequis

- Avoir l'application déjà déployée sur Scalingo
- Avoir la CLI Scalingo installée : https://doc.scalingo.com/platform/cli/start

## Étapes de déploiement

### 1. Ajouter l'addon Redis

#### Option A : Via la CLI
```bash
# Lister les apps disponibles
scalingo apps

# Ajouter Redis (plan gratuit)
scalingo --app votre-nom-app addons-add redis redis-starter-256

# Vérifier que Redis est bien ajouté
scalingo --app votre-nom-app addons
```

#### Option B : Via le Dashboard Scalingo
1. Allez sur https://dashboard.scalingo.com
2. Sélectionnez votre application
3. Resources > Addons
4. Cliquez sur "+ Add an addon"
5. Sélectionnez "Redis"
6. Choisissez le plan "Starter 256MB" (gratuit)
7. Validez

### 2. Vérifier la variable REDIS_URL

Scalingo configure automatiquement la variable `REDIS_URL` quand vous ajoutez l'addon Redis.

Pour vérifier :
```bash
scalingo --app votre-nom-app env | grep REDIS_URL
```

Vous devriez voir quelque chose comme :
```
REDIS_URL=redis://user:password@host:port
```

### 3. Configurer le worker Sidekiq

#### Option A : Via la CLI
```bash
# Scaler le worker à 1 instance
scalingo --app votre-nom-app scale worker:1
```

#### Option B : Via le Dashboard
1. Allez sur votre application
2. Resources > Containers
3. Dans la section "worker", ajustez le nombre à 1
4. Cliquez sur "Scale"

### 4. Déployer l'application

```bash
# Si vous êtes sur la branche main
git push scalingo main

# Si vous êtes sur une autre branche (ex: Implem-paiement)
git push scalingo Implem-paiement:master
```

### 5. Vérifier que tout fonctionne

#### Vérifier les logs du worker
```bash
scalingo --app votre-nom-app logs --filter worker
```

Vous devriez voir des logs Sidekiq comme :
```
2025-10-21 Booting Sidekiq with redis options...
2025-10-21 Running in ruby 3.2.2
2025-10-21 Sidekiq starting
```

#### Vérifier les logs de l'application
```bash
scalingo --app votre-nom-app logs --filter web
```

#### Accéder à l'interface Sidekiq
1. Connectez-vous à votre application en tant qu'admin
2. Allez à : `https://votre-app.osc-fr1.scalingo.io/admin/sidekiq`
3. Vous devriez voir le dashboard Sidekiq

### 6. Tester avec un job

Connectez-vous à la console Rails sur Scalingo :
```bash
scalingo --app votre-nom-app run rails console
```

Puis testez un job :
```ruby
# Créer un job de test
class TestJob < ApplicationJob
  queue_as :default
  def perform
    Rails.logger.info "✅ Sidekiq fonctionne sur Scalingo !"
  end
end

# Enqueue le job
TestJob.perform_later

# Sortir de la console
exit
```

Vérifiez les logs du worker :
```bash
scalingo --app votre-nom-app logs --filter worker
```

Vous devriez voir le message "✅ Sidekiq fonctionne sur Scalingo !"

## Plans Redis disponibles sur Scalingo

| Plan | RAM | Prix | Usage recommandé |
|------|-----|------|------------------|
| redis-starter-256 | 256 MB | Gratuit | Développement, petites apps |
| redis-business-256 | 256 MB | ~7€/mois | Production légère |
| redis-business-512 | 512 MB | ~14€/mois | Production moyenne |
| redis-business-1024 | 1 GB | ~28€/mois | Production intensive |

💡 **Conseil** : Commencez avec le plan gratuit et scalez si nécessaire.

## Monitoring et gestion

### Voir les stats Redis
```bash
scalingo --app votre-nom-app redis-console
```

Puis dans la console Redis :
```
INFO
```

### Voir les queues Sidekiq
Interface web : `https://votre-app.osc-fr1.scalingo.io/admin/sidekiq`

### Redémarrer le worker
```bash
scalingo --app votre-nom-app restart worker
```

### Scaler le worker (augmenter les instances)
```bash
# Passer à 2 workers
scalingo --app votre-nom-app scale worker:2
```

💰 **Note** : Chaque worker consomme un container, facturé selon votre plan Scalingo.

## Configuration avancée

### Ajuster la concurrence Sidekiq

Par défaut, la concurrence est configurée dans `config/sidekiq.yml` :
- Production : 10 threads (configurable via `SIDEKIQ_CONCURRENCY`)
- Development : 3 threads
- Test : 1 thread

Pour modifier en production, ajoutez une variable d'environnement :
```bash
scalingo --app votre-nom-app env-set SIDEKIQ_CONCURRENCY=20
```

### Configurer les tâches cron

Éditez `config/sidekiq_schedule.yml` avec vos tâches récurrentes, puis déployez.

Exemple :
```yaml
cleanup_old_sessions:
  cron: "0 2 * * *"  # Tous les jours à 2h
  class: CleanupOldSessionsJob
  queue: default
```

Les tâches cron se chargeront automatiquement au démarrage de Sidekiq.

## Troubleshooting

### Le worker ne démarre pas

Vérifiez les logs :
```bash
scalingo --app votre-nom-app logs --filter worker
```

Causes communes :
- Redis non configuré → Ajoutez l'addon Redis
- Erreur dans le Procfile → Vérifiez `Procfile`
- Gems manquantes → Vérifiez que `bundle install` s'est bien exécuté

### Jobs qui ne s'exécutent pas

1. Vérifiez que le worker tourne :
   ```bash
   scalingo --app votre-nom-app ps
   ```

2. Vérifiez les logs du worker :
   ```bash
   scalingo --app votre-nom-app logs --filter worker
   ```

3. Vérifiez l'interface Sidekiq : `/admin/sidekiq`

### Erreur de connexion Redis

Vérifiez que la variable `REDIS_URL` est bien configurée :
```bash
scalingo --app votre-nom-app env | grep REDIS_URL
```

Si elle n'existe pas, l'addon Redis n'est pas correctement configuré.

## Commandes utiles

```bash
# Voir tous les containers en cours
scalingo --app votre-nom-app ps

# Voir les variables d'environnement
scalingo --app votre-nom-app env

# Voir les addons
scalingo --app votre-nom-app addons

# Accéder à la console Rails
scalingo --app votre-nom-app run rails console

# Voir les logs en temps réel
scalingo --app votre-nom-app logs --lines 100

# Redémarrer toute l'app
scalingo --app votre-nom-app restart
```

## Checklist de déploiement

- [ ] Addon Redis ajouté
- [ ] Variable `REDIS_URL` présente
- [ ] Worker Sidekiq scalé à 1 (ou plus)
- [ ] Application déployée avec succès
- [ ] Logs du worker sans erreur
- [ ] Interface Sidekiq accessible à `/admin/sidekiq`
- [ ] Job de test exécuté avec succès
- [ ] Tâches cron configurées (si applicable)

## Support

- [Documentation Scalingo](https://doc.scalingo.com)
- [Documentation Redis sur Scalingo](https://doc.scalingo.com/databases/redis/start)
- [Documentation Sidekiq](https://github.com/sidekiq/sidekiq/wiki)

---

**Note** : N'oubliez pas de monitorer l'utilisation de votre Redis et d'ajuster le plan si nécessaire !

