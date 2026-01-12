# Notifications Push - Guide d'installation et d'utilisation

Ce guide explique comment configurer et utiliser le système de notifications push dans l'application AS Monaco Beach Volley.

## 📋 Prérequis

1. **Gem webpush** : Déjà ajoutée au Gemfile
2. **Clés VAPID** : Nécessaires pour l'authentification des notifications push

## 🔑 Configuration des clés VAPID

Les clés VAPID (Voluntary Application Server Identification) sont nécessaires pour envoyer des notifications push. Vous devez générer une paire de clés publique/privée.

### Génération des clés VAPID

Vous pouvez utiliser le script Ruby suivant pour générer les clés :

```ruby
require 'webpush'

vapid_key = Webpush.generate_key
puts "Public Key:  #{vapid_key.public_key}"
puts "Private Key: #{vapid_key.private_key}"
```

### Configuration dans Rails

**Méthode recommandée : Variables d'environnement (`.env`)**

Ajoutez les clés dans votre fichier `.env` :

```bash
VAPID_PUBLIC_KEY=votre_cle_publique
VAPID_PRIVATE_KEY=votre_cle_privee
VAPID_SUBJECT=mailto:votre-email@example.com
```

**Alternative : Rails credentials**

Si vous préférez utiliser les Rails credentials :

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

Ajoutez :

```yaml
vapid:
  public_key: VOTRE_CLE_PUBLIQUE
  private_key: VOTRE_CLE_PRIVEE
  subject: mailto:votre-email@example.com  # ou l'URL de votre app
```

**Note** : Le système cherche d'abord dans les variables d'environnement (`.env`), puis dans les Rails credentials en fallback.

## 🚀 Installation

1. **Installer la gem** :
   ```bash
   bundle install
   ```

2. **Exécuter les migrations** :
   ```bash
   bin/rails db:migrate
   ```

3. **Vérifier que le service worker est accessible** :
   Le fichier `public/service-worker.js` doit être accessible à l'URL `/service-worker.js`

## 📱 Fonctionnement

### Côté client

1. **Abonnement automatique** : Quand un utilisateur se connecte, le contrôleur Stimulus `push-notifications` s'active automatiquement
2. **Demande de permission** : Le navigateur demande la permission d'envoyer des notifications
3. **Enregistrement** : L'abonnement est sauvegardé en base de données

### Côté serveur

Les notifications peuvent être envoyées de deux façons :

#### 1. Via le service directement

```ruby
PushNotificationService.send_to_user(
  user,
  title: "Nouvelle session disponible",
  body: "Une nouvelle session a été créée",
  url: session_path(session)
)
```

#### 2. Via un job en arrière-plan

```ruby
SendPushNotificationJob.perform_later(
  user.id,
  title: "Nouvelle session disponible",
  body: "Une nouvelle session a été créée",
  url: session_path(session)
)
```

#### 3. Via les règles de notification

```ruby
# Envoyer une notification basée sur un événement
PushNotificationService.send_for_event(
  "session_created",
  context: { session: session, user: current_user }
)
```

## 📝 Règles de notification

Le système supporte deux approches :

### Approche 1 : Règles codées en dur

Vous pouvez créer des règles directement dans le code en créant des enregistrements `NotificationRule` :

```ruby
NotificationRule.create!(
  name: "Nouvelle session créée",
  event_type: "session_created",
  title_template: "Nouvelle session : {{session_name}}",
  body_template: "Une nouvelle session a été créée le {{session_date}}",
  enabled: true
)
```

### Approche 2 : Interface admin (à venir)

Une interface admin permettra de créer et gérer les règles de notification via l'interface web.

## 🎯 Types d'événements supportés

- `session_created` : Nouvelle session créée
- `session_cancelled` : Session annulée
- `registration_opened` : Inscriptions ouvertes
- `registration_confirmed` : Inscription confirmée
- `registration_cancelled` : Inscription annulée
- `credit_low` : Crédits faibles
- `stage_created` : Nouveau stage créé
- `stage_registration_opened` : Inscriptions au stage ouvertes

## 🔧 Intégration dans le code

### Exemple : Notifier lors de la création d'une session

Dans votre contrôleur ou service :

```ruby
class SessionsController < ApplicationController
  def create
    @session = Session.create!(session_params)
    
    # Envoyer la notification en arrière-plan
    PushNotificationService.send_for_event(
      "session_created",
      context: { session: @session }
    )
    
    redirect_to @session
  end
end
```

### Exemple : Notifier lors d'une inscription confirmée

```ruby
class RegistrationsController < ApplicationController
  def create
    @registration = current_user.registrations.create!(registration_params)
    
    if @registration.confirmed?
      PushNotificationService.send_for_event(
        "registration_confirmed",
        context: { 
          session: @registration.session,
          user: current_user,
          registration: @registration
        }
      )
    end
  end
end
```

## 🧪 Tests

Pour tester les notifications en développement :

1. Assurez-vous que votre application est en HTTPS (requis pour les notifications push)
   - En local, vous pouvez utiliser `ngrok` ou configurer Rails avec SSL
   
2. Ouvrez la console du navigateur pour voir les logs

3. Vérifiez que le service worker est enregistré dans l'onglet Application > Service Workers

## 🐛 Dépannage

### Les notifications ne s'affichent pas

1. Vérifiez que les clés VAPID sont correctement configurées
2. Vérifiez que le service worker est enregistré
3. Vérifiez les permissions de notification dans les paramètres du navigateur
4. Vérifiez la console du navigateur pour les erreurs

### Erreur "Invalid subscription"

Cela signifie que l'abonnement a expiré ou est invalide. Le système supprime automatiquement ces abonnements.

## 📚 Ressources

- [Web Push Protocol](https://web.dev/push-notifications-overview/)
- [Service Workers](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API)
- [Gem webpush](https://github.com/zaru/webpush)
