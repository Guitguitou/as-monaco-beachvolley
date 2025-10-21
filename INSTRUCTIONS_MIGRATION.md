# Instructions de Migration vers Sidekiq - À EXÉCUTER

## ⚠️ IMPORTANT : Étapes à suivre immédiatement

La migration de Solid Queue vers Sidekiq a été préparée, mais vous devez maintenant exécuter les étapes suivantes dans l'ordre :

> 💡 **Note** : Votre application est sur **Scalingo**. Pour le déploiement en production, consultez [SCALINGO_DEPLOYMENT.md](./SCALINGO_DEPLOYMENT.md)

## 1. Installer les nouvelles gems

```bash
bundle install
```

Cette commande va installer :
- `sidekiq` - Le système de queuing
- `sidekiq-cron` - Pour les tâches planifiées
- `sidekiq-unique-jobs` - Pour éviter les doublons
- `redis` - Client Redis

## 2. Installer et démarrer Redis (développement)

### Sur macOS avec Homebrew :
```bash
brew install redis
brew services start redis
```

### Vérifier que Redis fonctionne :
```bash
redis-cli ping
# Devrait répondre : PONG
```

## 3. Configurer les variables d'environnement

Créez ou éditez `.env` à la racine du projet :

```bash
# Redis
REDIS_URL=redis://localhost:6379/1
```

## 4. Appliquer la migration de base de données

```bash
bin/rails db:migrate
```

Cette migration supprimera toutes les tables Solid Queue qui ne sont plus nécessaires.

## 5. Tester localement

Démarrez l'application avec :

```bash
bin/dev
```

Vous devriez voir 3 processus démarrer :
- `web` : Le serveur Rails
- `css` : Tailwind CSS watch
- `sidekiq` : Le worker Sidekiq

## 6. Vérifier que tout fonctionne

1. **Vérifier l'interface Sidekiq** :
   - Connectez-vous en tant qu'admin
   - Allez à http://localhost:3000/admin/sidekiq
   - Vous devriez voir le dashboard Sidekiq

2. **Tester un job en console** :
   ```ruby
   bin/rails console
   
   # Créer un job de test
   class TestJob < ApplicationJob
     queue_as :default
     def perform
       Rails.logger.info "✅ Sidekiq fonctionne !"
     end
   end
   
   # Enqueue le job
   TestJob.perform_later
   
   # Vérifier les logs Sidekiq dans le terminal où bin/dev tourne
   ```

## 7. Configurer les tâches cron (si nécessaire)

Si vous avez des tâches récurrentes, éditez `config/sidekiq_schedule.yml` :

```yaml
cleanup_example:
  cron: "0 2 * * *"  # Tous les jours à 2h du matin
  class: VotreJobClass
  queue: default
  description: "Description de votre tâche"
```

## 8. Nettoyer les anciens fichiers (optionnel)

Une fois que tout fonctionne, vous pouvez supprimer :

```bash
rm config/queue.yml
rm config/recurring.yml
rm db/queue_schema.rb
rm bin/jobs
```

## 9. Déploiement en production sur Scalingo

### Étapes pour Scalingo :

1. **Ajouter l'addon Redis** :
   ```bash
   scalingo --app votre-app addons-add redis redis-starter-256
   ```
   
   Ou via le dashboard Scalingo : Resources > Addons > Redis
   
   ⚠️ Scalingo configure automatiquement la variable `REDIS_URL` !

2. **Ajouter un worker Sidekiq** :
   - Via le dashboard : Resources > Containers
   - Ajoutez un container de type "worker"
   - Scalingo détectera automatiquement la ligne `worker:` du Procfile
   - Configurez 1 container (vous pourrez en ajouter plus tard si nécessaire)

3. **Déployer l'application** :
   ```bash
   git push scalingo main
   ```
   
   Ou depuis votre branche actuelle :
   ```bash
   git push scalingo Implem-paiement:master
   ```

4. **Vérifier les logs** :
   ```bash
   # Logs du worker Sidekiq
   scalingo --app votre-app logs --filter worker
   
   # Logs de l'application web
   scalingo --app votre-app logs --filter web
   ```

### Tailles Redis recommandées :

- **redis-starter-256** : Gratuit, parfait pour commencer
- **redis-business-256** : Si vous avez beaucoup de jobs

### Monitoring sur Scalingo :

Une fois déployé, accédez à l'interface Sidekiq :
- https://votre-app.osc-fr1.scalingo.io/admin/sidekiq

## Commandes utiles

### Démarrer Sidekiq manuellement :
```bash
bundle exec sidekiq -C config/sidekiq.yml
```

### Voir les stats Sidekiq en console :
```bash
bundle exec sidekiq -C config/sidekiq.yml
```

### Vider toutes les queues Sidekiq :
```ruby
bin/rails console
Sidekiq.redis { |r| r.flushdb }
```

### Voir les jobs en attente :
```ruby
bin/rails console
Sidekiq::Queue.new.size
```

## Troubleshooting

### Erreur : "Could not connect to Redis"
➜ Vérifiez que Redis est bien démarré : `redis-cli ping`

### Erreur : "uninitialized constant Sidekiq"
➜ Exécutez `bundle install`

### Les jobs ne s'exécutent pas
➜ Vérifiez que Sidekiq est bien démarré (avec `bin/dev` ou manuellement)

### L'interface /admin/sidekiq est inaccessible
➜ Vérifiez que vous êtes connecté avec un compte admin

## Support

Pour plus de détails, consultez `MIGRATION_SIDEKIQ.md` dans le projet.

## Checklist finale

- [ ] `bundle install` exécuté avec succès
- [ ] Redis installé et démarré
- [ ] Variable `REDIS_URL` configurée dans `.env`
- [ ] Migration de base de données exécutée (`bin/rails db:migrate`)
- [ ] Application démarre avec `bin/dev` sans erreur
- [ ] Interface Sidekiq accessible à `/admin/sidekiq`
- [ ] Test d'un job réussi
- [ ] Tâches cron configurées (si applicable)
- [ ] Déployé en production avec succès

---

**Date de migration** : 10 octobre 2025
**Branche** : Implem-paiement



