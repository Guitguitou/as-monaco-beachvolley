# 🔓 Gestion des comptes non activés

## Vue d'ensemble

Les comptes non activés (`activated_at: nil`) peuvent désormais se connecter à l'application avec un accès limité. Ils doivent acheter une licence ou s'inscrire à un stage pour activer leur compte et débloquer toutes les fonctionnalités.

## 🎯 Fonctionnement

### Comptes non activés - Accès limité

**Peuvent accéder à :**
- ✅ Page des **Packs** (uniquement licences et stages)
- ✅ Page des **Stages** (consultation et inscription)
- ✅ **Règles & Informations** (toutes les pages)
- ✅ **Mon profil**

**Ne peuvent PAS accéder à :**
- ❌ Calendrier des sessions
- ❌ Mes sessions
- ❌ Inscription aux entraînements/jeux libres
- ❌ Packs de crédits
- ❌ Historique des crédits

### Comptes activés - Accès complet

Tous les accès débloqués après achat d'une licence.

### Admins

Toujours accès complet, même si le compte n'est pas activé.

## 🎨 Interface utilisateur

### Sidebar pour comptes non activés

Affiche uniquement :
- 📦 **Packs** (défini comme page d'accueil)
- 🏁 **Stages**
- 👤 **Mon profil**
- 📋 **Règles & informations** (section dépliable)
- 🚪 **Déconnexion**

### Sidebar pour comptes activés

Affiche tout :
- 📅 Calendrier
- 🏁 Stages
- 🏐 Mes sessions
- 💳 Packs
- 📚 Entraînements (coach) [si coach/admin]
- 👤 Mon profil
- 📋 Règles & informations
- 🛡️ Admin [si admin]
- 🚪 Déconnexion

### Bannière d'information

Sur la page Packs, les comptes non activés voient une bannière bleue explicative :

```
Bienvenue ! 👋
Votre compte n'est pas encore activé. Vous avez accès limité aux fonctionnalités suivantes :
• Consulter et acheter des licences pour activer votre compte
• Consulter et vous inscrire aux stages
• Consulter les règles et informations

💡 Achetez votre licence ci-dessous pour débloquer toutes les fonctionnalités !
```

## 📂 Fichiers modifiés

### Modèle
- **`app/models/user.rb`**
  - Modifié `active_for_authentication?` pour permettre la connexion des non activés
  - Supprimé la vérification `activated?` dans `inactive_message`

### Permissions
- **`app/models/ability.rb`**
  - Permissions différenciées entre activés et non activés
  - Non activés : accès limité aux packs licence/stage + stages
  - Activés : accès complet

### Controller
- **`app/controllers/application_controller.rb`**
  - Ajout de `redirect_non_activated_users` pour restreindre l'accès
  - Modification de `accueil` pour rediriger vers `/packs`
  - Liste des chemins autorisés pour les non activés

### Vues
- **`app/views/layouts/_sidebar.html.erb`**
  - Sidebar conditionnelle selon statut activé/non activé
  - Logo redirige vers `/packs` pour les non activés

- **`app/views/packs/index.html.erb`**
  - Bannière d'information améliorée
  - Solde de crédits caché pour les non activés

### Tests
- **`spec/models/user_non_activated_spec.rb`**
  - Tests de connexion et scopes
  
- **`spec/models/ability_non_activated_spec.rb`**
  - Tests des permissions pour activés/non activés

## 🔐 Logique de redirection

### Pour les comptes non activés

Quand un compte non activé essaie d'accéder à une page non autorisée :

```ruby
# Redirect vers /packs avec message
redirect_to packs_path, 
  alert: "Votre compte n'est pas encore activé. 
         Achetez une licence ou un pack stage pour accéder à toutes les fonctionnalités."
```

### Chemins autorisés pour comptes non activés

```ruby
# Pages principales
- /packs
- /stages (liste)
- /stages/:id (détail)
- /profile

# Pages infos
- /infos/*

# Authentification Devise
- /users/sign_in
- /users/sign_up
- /users/password
- etc.

# Processus d'achat
- /checkout/*
- /packs/:id/buy
```

## 💰 Activation du compte

Le compte est activé automatiquement lors de l'achat d'une licence :

```ruby
# Dans app/models/credit_purchase.rb
def process_licence_purchase
  if user.present?
    user.activate! unless user.activated?
    # ...
  end
end
```

## 🧪 Tests

Pour exécuter les tests :

```bash
# Tests des comptes non activés
bundle exec rspec spec/models/user_non_activated_spec.rb

# Tests des permissions
bundle exec rspec spec/models/ability_non_activated_spec.rb

# Tous les tests passent
21 examples, 0 failures ✅
```

## 📊 Scénarios d'utilisation

### Scénario 1 : Nouvel utilisateur

1. **Création du compte** → `activated_at: nil`
2. **Connexion** → ✅ Possible
3. **Redirection** → `/packs`
4. **Sidebar** → Version limitée (Packs, Stages, Profil, Infos)
5. **Bannière** → Message d'accueil avec explications
6. **Actions possibles** :
   - Acheter une licence → Active le compte
   - S'inscrire à un stage → Compte reste non activé
   - Consulter les infos

### Scénario 2 : Achat de licence

1. **Sur /packs** → Clic sur "Acheter" une licence
2. **Paiement Sherlock** → Processus de paiement
3. **Callback succès** → `user.activate!` appelé automatiquement
4. **Compte activé** → `activated_at: Time.current`
5. **Accès débloqué** → Toutes les fonctionnalités disponibles
6. **Sidebar** → Version complète
7. **Redirection root** → Page d'accueil normale

### Scénario 3 : Tentative d'accès non autorisé

```
Utilisateur non activé essaie d'aller sur /sessions
→ Redirection vers /packs
→ Message : "Votre compte n'est pas encore activé..."
```

## 🎨 Design

- **Bannière** : Fond bleu clair (`bg-blue-50`), bordure bleue (`border-blue-500`)
- **Message** : Ton accueillant et informatif (pas agressif)
- **Icône** : Info circle (pas d'alerte)
- **Couleurs** : Bleu pour l'information, pas de rouge/orange

## 🔄 Flux d'activation

```
Inscription
    ↓
Connexion (accès limité)
    ↓
/packs (page d'accueil)
    ↓
Achat licence OU stage
    ↓
Paiement réussi
    ↓
[Si licence] → Activation automatique (activated_at ≠ nil)
    ↓
Accès complet débloqué
```

## 📝 Notes techniques

- Le status `activated?` est déterminé par `activated_at.present?`
- Les admins contournent toutes les restrictions (`current_user.admin?`)
- Le filtrage des packs se fait via CanCanCan (`can?(:read, pack)`)
- La redirection s'applique via un `before_action` dans `ApplicationController`
- Les routes publiques (infos) restent accessibles même sans activation

## 🐛 Dépannage

### L'utilisateur non activé ne peut pas se connecter
- Vérifier que `disabled_at` est `nil` (compte non désactivé)
- Vérifier les méthodes Devise `active_for_authentication?`

### L'utilisateur non activé voit des packs de crédits
- Vérifier les permissions dans `ability.rb`
- Vérifier le filtrage dans `packs_controller.rb`

### La bannière ne s'affiche pas
- Vérifier `@show_activation_notice` dans le controller
- Vérifier que l'utilisateur a bien `activated_at: nil`

### La redirection ne fonctionne pas
- Vérifier le `before_action :redirect_non_activated_users`
- Vérifier la liste des `allowed_paths`
- Regarder les logs pour les redirections multiples

