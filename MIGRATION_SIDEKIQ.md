# Migration de Solid Queue vers Sidekiq

## Changements effectués

### 1. Gemfile
- ✅ Supprimé `solid_queue`
- ✅ Ajouté `sidekiq`, `sidekiq-cron`, `sidekiq-unique-jobs`, et `redis`

### 2. Configuration
- ✅ Créé `config/sidekiq.yml` pour la configuration de Sidekiq
- ✅ Créé `config/initializers/sidekiq.rb` pour l'initialisation
- ✅ Créé `config/sidekiq_schedule.yml` pour les tâches cron (à configurer selon vos besoins)

### 3. Environnements
- ✅ Mis à jour `config/environments/production.rb` pour utiliser `:sidekiq`
- ✅ Mis à jour `config/environments/development.rb` pour utiliser `:sidekiq`
- ✅ Mis à jour `config/environments/test.rb` pour utiliser `:test`

### 4. Déploiement
- ✅ Mis à jour `Procfile` et `Procfile.dev` pour lancer Sidekiq
- ✅ Mis à jour `config/deploy.yml` (Kamal) pour inclure Redis et les workers Sidekiq
- ✅ Retiré le plugin `solid_queue` de `config/puma.rb`

### 5. Interface Web
- ✅ Ajouté les routes pour l'interface web Sidekiq (accessible à `/admin/sidekiq`)
- ✅ Interface protégée par authentification admin

## Prochaines étapes requises

### 1. Installation des gems
```bash
bundle install
```

### 2. Configuration de Redis

#### En développement
Installez et démarrez Redis localement :
```bash
# macOS avec Homebrew
brew install redis
brew services start redis

# Ou démarrez Redis manuellement
redis-server
```

#### En production
Redis est configuré comme service accessoire dans `config/deploy.yml`. Il sera déployé automatiquement avec Kamal.

### 3. Variables d'environnement

Ajoutez à votre fichier `.env` (développement) :
```bash
REDIS_URL=redis://localhost:6379/1
```

En production, la variable `REDIS_URL` est déjà configurée dans `config/deploy.yml` pour pointer vers le service Redis de Kamal.

### 4. Suppression des tables Solid Queue (optionnel)

Si vous souhaitez nettoyer complètement Solid Queue, créez une migration :

```bash
bin/rails generate migration RemoveSolidQueueTables
```

Puis ajoutez dans la migration :
```ruby
class RemoveSolidQueueTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :solid_queue_blocked_executions if table_exists?(:solid_queue_blocked_executions)
    drop_table :solid_queue_claimed_executions if table_exists?(:solid_queue_claimed_executions)
    drop_table :solid_queue_failed_executions if table_exists?(:solid_queue_failed_executions)
    drop_table :solid_queue_ready_executions if table_exists?(:solid_queue_ready_executions)
    drop_table :solid_queue_recurring_executions if table_exists?(:solid_queue_recurring_executions)
    drop_table :solid_queue_scheduled_executions if table_exists?(:solid_queue_scheduled_executions)
    drop_table :solid_queue_jobs if table_exists?(:solid_queue_jobs)
    drop_table :solid_queue_processes if table_exists?(:solid_queue_processes)
    drop_table :solid_queue_recurring_tasks if table_exists?(:solid_queue_recurring_tasks)
    drop_table :solid_queue_semaphores if table_exists?(:solid_queue_semaphores)
    drop_table :solid_queue_pauses if table_exists?(:solid_queue_pauses)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
```

```bash
bin/rails db:migrate
```

### 5. Suppression des fichiers Solid Queue

Vous pouvez supprimer ces fichiers :
- `config/queue.yml`
- `config/recurring.yml`
- `db/queue_schema.rb`
- `bin/jobs`

### 6. Tester en développement

Démarrez votre application avec :
```bash
bin/dev
```

Cela démarrera automatiquement :
- Le serveur Rails
- Tailwind CSS watch
- Sidekiq

### 7. Configuration des tâches cron

Éditez `config/sidekiq_schedule.yml` pour configurer vos tâches récurrentes. Exemple :

```yaml
cleanup_old_sessions:
  cron: "0 2 * * *"  # Tous les jours à 2h du matin
  class: CleanupOldSessionsJob
  queue: default
  description: "Nettoie les anciennes sessions"
```

### 8. Accès à l'interface Web

Une fois connecté en tant qu'admin, vous pouvez accéder à l'interface Sidekiq à :
- Développement : http://localhost:3000/admin/sidekiq
- Production : https://votre-domaine.com/admin/sidekiq

## Fonctionnalités Sidekiq

### Sidekiq de base
- Traitement asynchrone des jobs
- Retry automatique en cas d'échec
- Interface web pour le monitoring
- Support de multiples queues

### Sidekiq-cron
- Planification de tâches récurrentes
- Configuration via YAML
- Gestion via l'interface web

### Sidekiq-unique-jobs
- Empêche les jobs dupliqués
- Configurable par job
- Plusieurs stratégies de déduplication disponibles

## Utilisation dans vos jobs

Vos jobs existants continueront de fonctionner sans modification. Ils héritent de `ApplicationJob` qui utilise maintenant Sidekiq comme adapter.

Pour utiliser des fonctionnalités avancées :

```ruby
class MonJob < ApplicationJob
  queue_as :default
  
  # Utiliser sidekiq-unique-jobs
  sidekiq_options lock: :until_executed,
                  on_conflict: :log
  
  def perform(*args)
    # Votre code ici
  end
end
```

## Déploiement

### Sur Scalingo (votre plateforme)

**Voir le guide détaillé** : [SCALINGO_DEPLOYMENT.md](./SCALINGO_DEPLOYMENT.md)

En résumé :
```bash
# 1. Ajouter Redis
scalingo --app votre-app addons-add redis redis-starter-256

# 2. Scaler le worker
scalingo --app votre-app scale worker:1

# 3. Déployer
git push scalingo main
```

Scalingo va automatiquement :
1. Configurer Redis et la variable `REDIS_URL`
2. Déployer le serveur web
3. Déployer les workers Sidekiq

### Avec Kamal (si vous migrez vers Kamal plus tard)

```bash
# Déployer le service Redis
bin/kamal accessory boot redis

# Déployer l'application
bin/kamal deploy
```

## Troubleshooting

### Redis ne se connecte pas
Vérifiez que Redis est bien démarré :
```bash
redis-cli ping
# Devrait répondre: PONG
```

### Les jobs ne s'exécutent pas
Vérifiez que Sidekiq est bien démarré :
```bash
# En développement (avec bin/dev, il devrait démarrer automatiquement)
# Ou manuellement :
bundle exec sidekiq -C config/sidekiq.yml
```

### Interface web inaccessible
Vérifiez que vous êtes bien connecté avec un compte admin.

## Ressources

- [Documentation Sidekiq](https://github.com/sidekiq/sidekiq/wiki)
- [Sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron)
- [Sidekiq-unique-jobs](https://github.com/mhenrixon/sidekiq-unique-jobs)



