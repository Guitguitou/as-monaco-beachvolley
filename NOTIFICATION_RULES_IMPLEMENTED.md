# 📱 Règles de Notification Push Implémentées

## ✅ Règles en dur implémentées

### Règle 1 : Passage en liste principale ✅
**Déclencheur** : Quand un utilisateur en liste d'attente passe en liste principale après qu'une place se libère.

**Message** : "Quelqu'un s'est désinscrit de la session XXX du XX/XX à XXh, tu viens de passer en liste principale"

**Implémentation** : 
- Dans `Session#promote_from_waitlist!` après qu'une promotion réussit
- Fichier : `app/models/session.rb`

**Code** :
```ruby
SendPushNotificationJob.perform_later(
  reg.user.id,
  title: "Tu passes en liste principale !",
  body: "Quelqu'un s'est désinscrit de la session #{title} du #{session_date} à #{session_time}, tu viens de passer en liste principale",
  url: Rails.application.routes.url_helpers.session_path(self)
)
```

---

### Règle 2 : Pas assez de crédits pour passer en liste principale ✅
**Déclencheur** : Quand un utilisateur en liste d'attente ne peut pas passer en liste principale car il n'a pas assez de crédits.

**Message** : "Tu n'as pas assez de crédits pour passer en liste principale."

**Implémentation** : 
- Dans `Session#promote_from_waitlist!` quand on détecte que l'utilisateur n'a pas assez de crédits
- Fichier : `app/models/session.rb`

**Code** :
```ruby
if reg.user.balance.amount < amount
  SendPushNotificationJob.perform_later(
    reg.user.id,
    title: "Pas assez de crédits",
    body: "Tu n'as pas assez de crédits pour passer en liste principale.",
    url: Rails.application.routes.url_helpers.session_path(self)
  )
  next
end
```

---

### Règle 3 : Crédits faibles (< 500) ✅
**Déclencheur** : Quand le solde de crédits d'un utilisateur passe sous 500 crédits.

**Message** : "Attention tu as moins de 500 crédits, pense à recharger 😉"

**Implémentation** : 
- Dans `CreditTransaction` via des callbacks `after_create_commit`, `after_update_commit`, `after_destroy_commit`
- Fichier : `app/models/credit_transaction.rb`
- **Protection anti-spam** : Notification envoyée maximum 1 fois par 24h (via cache SolidCache)

**Code** :
```ruby
def check_low_credits_notification(previous_balance, current_balance)
  if previous_balance >= 500 && current_balance < 500 && current_balance >= 0
    cache_key = "low_credits_notification:#{user.id}"
    last_notification = Rails.cache.read(cache_key)
    
    if last_notification.nil? || last_notification < 24.hours.ago
      SendPushNotificationJob.perform_later(...)
      Rails.cache.write(cache_key, Time.current, expires_in: 24.hours)
    end
  end
end
```

---

### Règle 4 : Session annulée ✅
**Déclencheur** : Quand une session où l'utilisateur est inscrit est annulée.

**Message** : "La session xx du xx/xx est annulée"

**Implémentation** : 
- Dans `SessionsController#cancel` après avoir détruit la session
- Fichier : `app/controllers/sessions_controller.rb`
- Notifie tous les utilisateurs qui étaient inscrits (status: confirmed)

**Code** :
```ruby
registered_users.each do |user|
  SendPushNotificationJob.perform_later(
    user.id,
    title: "Session annulée",
    body: "La session #{session_name} du #{session_date} est annulée",
    url: Rails.application.routes.url_helpers.sessions_path
  )
end
```

---

## 🧪 Comment tester

### Prérequis
1. Installer la gem : `bundle install`
2. Générer les clés VAPID : `bin/rails vapid:generate`
3. Ajouter les clés dans les credentials Rails
4. Exécuter les migrations : `bin/rails db:migrate`
5. Créer les règles (optionnel) : `bin/rails notifications:create_default_rules`

### Test Règle 1 : Passage en liste principale
1. Créer une session complète (max_players atteint)
2. S'inscrire en liste d'attente avec un utilisateur A
3. S'inscrire en liste d'attente avec un utilisateur B
4. Désinscrire l'utilisateur A
5. ✅ L'utilisateur B devrait recevoir une notification

### Test Règle 2 : Pas assez de crédits
1. Créer une session avec un prix (ex: 400 crédits)
2. S'inscrire en liste d'attente avec un utilisateur qui a < 400 crédits
3. Libérer une place dans la session
4. ✅ L'utilisateur devrait recevoir une notification "Pas assez de crédits"

### Test Règle 3 : Crédits faibles
1. Avoir un utilisateur avec >= 500 crédits
2. Effectuer une transaction qui fait passer sous 500 crédits
3. ✅ L'utilisateur devrait recevoir une notification
4. Effectuer une autre transaction (toujours < 500)
5. ✅ Aucune nouvelle notification (protection anti-spam 24h)

### Test Règle 4 : Session annulée
1. Créer une session
2. S'inscrire avec un utilisateur
3. Annuler la session (via le bouton "Annuler")
4. ✅ L'utilisateur devrait recevoir une notification

---

## 📝 Notes importantes

- **Toutes les notifications sont envoyées en arrière-plan** via `SendPushNotificationJob` (SolidQueue)
- **Les notifications nécessitent que l'utilisateur soit abonné** (via le contrôleur Stimulus)
- **La règle 3 a une protection anti-spam** : maximum 1 notification par 24h
- **Les notifications incluent un lien** vers la page pertinente (session, packs, etc.)

---

## 🔄 Prochaines étapes

Une fois ces règles testées et validées, on pourra créer l'interface admin pour permettre de :
- Créer de nouvelles règles
- Modifier les messages existants
- Activer/désactiver des règles
- Voir l'historique des notifications envoyées
