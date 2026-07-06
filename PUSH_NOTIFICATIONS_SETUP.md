# 🚀 Configuration des Notifications Push - Guide de démarrage

## ✅ Ce qui a été créé

### 1. Base de données
- ✅ Migration `create_push_subscriptions` : Table pour stocker les abonnements push des utilisateurs
- ✅ Migration `create_notification_rules` : Table pour stocker les règles de notification configurables

### 2. Modèles
- ✅ `PushSubscription` : Modèle pour les abonnements push
- ✅ `NotificationRule` : Modèle pour les règles de notification (avec système de templates)

### 3. Contrôleurs
- ✅ `Api::PushSubscriptionsController` : API pour gérer les abonnements (créer/supprimer)
- ✅ `Admin::NotificationRulesController` : Interface admin pour gérer les règles de notification

### 4. Services
- ✅ `PushNotificationService` : Service principal pour envoyer les notifications
- ✅ `SendPushNotificationJob` : Job SolidQueue pour envoyer les notifications en arrière-plan

### 5. Frontend
- ✅ `push_notifications_controller.js` : Contrôleur Stimulus pour gérer l'abonnement côté client
- ✅ `service-worker.js` : Service Worker pour recevoir et afficher les notifications

### 6. Routes
- ✅ `/api/push_subscriptions` : API pour les abonnements
- ✅ `/admin/notification_rules` : Interface admin pour les règles

## 📋 Prochaines étapes

### 1. Installer la gem webpush

```bash
bundle install
```

### 2. Générer les clés VAPID

```bash
bin/rails vapid:generate
```

Cela générera une paire de clés publique/privée. Ajoutez-les dans votre fichier `.env` :

```bash
# Ajoutez ces lignes dans votre fichier .env
VAPID_PUBLIC_KEY=VOTRE_CLE_PUBLIQUE
VAPID_PRIVATE_KEY=VOTRE_CLE_PRIVEE
VAPID_SUBJECT=mailto:votre-email@example.com
```

**Note** : Le système cherche d'abord dans les variables d'environnement (`.env`), puis dans les Rails credentials si vous préférez les utiliser.

### 3. Exécuter les migrations

```bash
bin/rails db:migrate
```

### 4. Tester l'abonnement

1. Démarrez votre serveur Rails
2. Connectez-vous en tant qu'utilisateur
3. Le navigateur devrait demander la permission pour les notifications
4. Vérifiez dans la console du navigateur que l'abonnement est enregistré

### 5. Créer des règles de notification (optionnel)

Vous pouvez créer des règles directement en console Rails :

```ruby
NotificationRule.create!(
  name: "Nouvelle session créée",
  event_type: "session_created",
  title_template: "Nouvelle session : {{session_name}}",
  body_template: "Une nouvelle session a été créée le {{session_date}}",
  enabled: true
)
```

Ou utiliser l'interface admin (après avoir créé les vues) : `/admin/notification_rules`

## 🎯 Utilisation

### Envoyer une notification simple

```ruby
PushNotificationService.send_to_user(
  user,
  title: "Nouvelle session disponible",
  body: "Une nouvelle session a été créée",
  url: session_path(session)
)
```

### Envoyer via un événement (avec règles)

```ruby
PushNotificationService.send_for_event(
  "session_created",
  context: { 
    session: session,
    session_name: session.name,
    session_date: session.date.strftime("%d/%m/%Y")
  }
)
```

### Envoyer en arrière-plan

```ruby
SendPushNotificationJob.perform_later(
  user.id,
  title: "Notification",
  body: "Message",
  url: root_path
)
```

## 📝 Exemples d'intégration

### Dans un contrôleur (ex: SessionsController)

```ruby
def create
  @session = Session.create!(session_params)
  
  # Notifier tous les utilisateurs activés
  PushNotificationService.send_for_event(
    "session_created",
    context: { 
      session: @session,
      session_name: @session.name,
      session_date: @session.date.strftime("%d/%m/%Y")
    }
  )
  
  redirect_to @session
end
```

### Dans un callback de modèle

```ruby
class Session < ApplicationRecord
  after_create :notify_users
  
  private
  
  def notify_users
    PushNotificationService.send_for_event(
      "session_created",
      context: { 
        session: self,
        session_name: name,
        session_date: date.strftime("%d/%m/%Y")
      }
    )
  end
end
```

## 🔧 Notes importantes

1. **HTTPS requis** : Les notifications push nécessitent HTTPS (sauf en localhost)
2. **Service Worker** : Le fichier `public/service-worker.js` doit être accessible
3. **Permissions** : Les utilisateurs doivent accepter les notifications
4. **Abonnements multiples** : Un utilisateur peut avoir plusieurs abonnements (différents appareils)

## 📚 Documentation complète

Voir `PUSH_NOTIFICATIONS_README.md` pour plus de détails.
