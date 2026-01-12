# Tests pour les Notifications Push

## 📋 Tests créés

### Factories
- ✅ `spec/factories/push_subscriptions.rb` : Factory pour les abonnements push
- ✅ `spec/factories/notification_rules.rb` : Factory pour les règles de notification

### Tests de modèles
- ✅ `spec/models/push_subscription_spec.rb` : Tests du modèle PushSubscription
- ✅ `spec/models/notification_rule_spec.rb` : Tests du modèle NotificationRule
- ✅ `spec/models/session_waitlist_notifications_spec.rb` : Tests des règles 1 et 2 (liste d'attente)
- ✅ `spec/models/credit_transaction_low_credits_spec.rb` : Tests de la règle 3 (crédits faibles)

### Tests de services
- ✅ `spec/services/push_notification_service_spec.rb` : Tests du service PushNotificationService

### Tests de jobs
- ✅ `spec/jobs/send_push_notification_job_spec.rb` : Tests du job SendPushNotificationJob

### Tests de contrôleurs/API
- ✅ `spec/requests/api/push_subscriptions_spec.rb` : Tests de l'API push subscriptions
- ✅ `spec/requests/sessions_cancel_notification_spec.rb` : Tests de la règle 4 (session annulée)

## 🧪 Exécution des tests

```bash
# Tous les tests de notifications
bundle exec rspec spec/models/push_subscription_spec.rb spec/models/notification_rule_spec.rb spec/services/push_notification_service_spec.rb spec/jobs/send_push_notification_job_spec.rb spec/requests/api/push_subscriptions_spec.rb spec/models/session_waitlist_notifications_spec.rb spec/models/credit_transaction_low_credits_spec.rb spec/requests/sessions_cancel_notification_spec.rb

# Tests par catégorie
bundle exec rspec spec/models/push_subscription_spec.rb
bundle exec rspec spec/services/push_notification_service_spec.rb
bundle exec rspec spec/requests/api/push_subscriptions_spec.rb
```

## 📝 Couverture des tests

### Règle 1 : Passage en liste principale ✅
- Test dans `spec/models/session_waitlist_notifications_spec.rb`
- Vérifie que la notification est envoyée quand un utilisateur passe de waitlisted à confirmed

### Règle 2 : Pas assez de crédits ✅
- Test dans `spec/models/session_waitlist_notifications_spec.rb`
- Vérifie que la notification est envoyée quand un utilisateur ne peut pas être promu faute de crédits

### Règle 3 : Crédits faibles (< 500) ✅
- Test dans `spec/models/credit_transaction_low_credits_spec.rb`
- Vérifie que la notification est envoyée quand le solde passe sous 500
- Vérifie la protection anti-spam (24h)

### Règle 4 : Session annulée ✅
- Test dans `spec/requests/sessions_cancel_notification_spec.rb`
- Vérifie que les notifications sont envoyées à tous les utilisateurs inscrits
- Vérifie que les utilisateurs en liste d'attente ne reçoivent pas de notification

## 🔧 Notes importantes

- Les tests utilisent des mocks pour Webpush et les clés VAPID
- Les tests utilisent FactoryBot pour créer les données de test
- Les tests suivent les conventions RSpec du projet
- Les tests sont isolés et utilisent des transactions
