# Déploiement SolidQueue sur Scalingo

## 🚀 Guide de déploiement pour Scalingo

Ce guide explique comment déployer votre application avec SolidQueue (jobs) et SolidCache (cache) sur Scalingo. Les deux tournent sur la base Postgres existante — aucun addon Redis n'est nécessaire.

## Prérequis

- Avoir l'application déjà déployée sur Scalingo
- Avoir la CLI Scalingo installée : https://doc.scalingo.com/platform/cli/start

## Étapes de déploiement

### 1. Activer le worker SolidQueue

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

### 2. Déployer l'application

```bash
# Si vous êtes sur la branche main
git push scalingo main
```

Les migrations (tables `solid_queue_*`, `solid_cache_entries`, `solid_cable_messages`) s'appliquent automatiquement via `bin/postdeploy.sh` (`bundle exec rake db:migrate`).

### 3. Vérifier que tout fonctionne

#### Vérifier les logs du worker
```bash
scalingo --app votre-nom-app logs --filter worker
```

Vous devriez voir des logs SolidQueue comme :
```
SolidQueue-1.4.0 Started Supervisor
SolidQueue-1.4.0 Started Dispatcher
SolidQueue-1.4.0 Started Worker
```

#### Vérifier les logs de l'application
```bash
scalingo --app votre-nom-app logs --filter web
```

#### Accéder à l'interface d'admin des jobs
1. Connectez-vous à votre application en tant qu'admin
2. Allez à : `https://votre-app.osc-fr1.scalingo.io/admin/jobs`
3. Vous devriez voir le dashboard Mission Control Jobs

### 4. Tester avec un job

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
    Rails.logger.info "✅ SolidQueue fonctionne sur Scalingo !"
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

Vous devriez voir le message "✅ SolidQueue fonctionne sur Scalingo !"

## Monitoring et gestion

### Voir les jobs
Interface web : `https://votre-app.osc-fr1.scalingo.io/admin/jobs`

Ou en console :
```ruby
SolidQueue::Job.count
SolidQueue::FailedExecution.count
```

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

### Ajuster la concurrence SolidQueue

La configuration se trouve dans `config/queue.yml` (threads, nombre de processus). Le nombre de processus est piloté par la variable d'environnement `JOB_CONCURRENCY` :

```bash
scalingo --app votre-nom-app env-set JOB_CONCURRENCY=2
```

### Configurer les tâches récurrentes

Éditez `config/recurring.yml` avec vos tâches récurrentes, puis déployez. Exemple :
```yaml
production:
  cleanup_old_sessions:
    class: CleanupOldSessionsJob
    queue: default
    schedule: every day at 2am
```

Les tâches se chargent automatiquement au démarrage de `bin/jobs`.

## Troubleshooting

### Le worker ne démarre pas

Vérifiez les logs :
```bash
scalingo --app votre-nom-app logs --filter worker
```

Causes communes :
- Erreur dans le Procfile → Vérifiez `Procfile` (`worker: bin/jobs`)
- Migrations `solid_queue_*` non appliquées → Vérifiez `bin/postdeploy.sh`
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

3. Vérifiez l'interface d'admin : `/admin/jobs`

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

- [ ] Worker SolidQueue scalé à 1 (ou plus)
- [ ] Application déployée avec succès
- [ ] Migrations `solid_queue_*`/`solid_cache_entries`/`solid_cable_messages` appliquées
- [ ] Logs du worker sans erreur
- [ ] Interface d'admin accessible à `/admin/jobs`
- [ ] Job de test exécuté avec succès
- [ ] Tâches récurrentes configurées (si applicable)
- [ ] Addon Redis retiré du dashboard Scalingo (une fois la stabilité validée)

## Support

- [Documentation Scalingo](https://doc.scalingo.com)
- [Documentation SolidQueue](https://github.com/rails/solid_queue)
- [Documentation Mission Control Jobs](https://github.com/rails/mission_control-jobs)
