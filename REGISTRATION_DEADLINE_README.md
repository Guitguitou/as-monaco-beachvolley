# ⏰ Limite d'inscription à 17h le jour J

## Vue d'ensemble

Une limite d'inscription a été ajoutée pour les **entraînements uniquement** : les utilisateurs ne peuvent plus s'inscrire après **17h le jour de la session**.

## 🎯 Fonctionnement

### Pour les utilisateurs réguliers
- **Avant 17h** le jour de l'entraînement → ✅ Inscription possible
- **Après 17h** le jour de l'entraînement → ❌ Inscription bloquée
- Message affiché : "Les inscriptions sont closes (limite : 17h le jour de la session)."

### Pour les admins et entraîneurs
- **Peuvent toujours inscrire** des participants, même après 17h
- Un message informatif s'affiche : "Délai d'inscription dépassé (17h), mais vous pouvez inscrire."

### Comportement par type de session

| Type de session | Limite 17h appliquée |
|----------------|---------------------|
| Entraînement   | ✅ Oui              |
| Jeu libre      | ❌ Non              |
| Coaching privé | ❌ Non              |
| Tournoi        | ❌ Non              |

## 📂 Fichiers modifiés

### Modèle
- **`app/models/session.rb`**
  - Constante `REGISTRATION_DEADLINE_HOUR = 17`
  - Méthode `past_registration_deadline?` : vérifie si la deadline est dépassée
  - Méthode `registration_open_state_for` : inclut la vérification de deadline

### Controller
- **`app/controllers/registrations_controller.rb`**
  - Vérification de la deadline dans `create`
  - Méthode `can_bypass_deadline?` : permet aux admins/coachs de bypass
  - Redirection avec message d'erreur si deadline dépassée

### Vue
- **`app/views/sessions/show.html.erb`**
  - Message d'info pour admins/coachs quand deadline dépassée
  - Le bouton d'inscription est automatiquement désactivé pour les utilisateurs réguliers

### Tests
- **`spec/models/session_registration_deadline_spec.rb`**
  - 9 tests couvrant tous les scénarios
  - Tests avant/après 17h
  - Tests pour différents types de sessions

## 🔧 Logique technique

### Calcul de la deadline

La deadline est calculée à **17h le jour de la session** :

```ruby
deadline = start_at.change(hour: 17, min: 0, sec: 0)
```

**Exemples :**
- Session le 7 nov 2025 à 19h → Deadline : 7 nov 2025 à 17h00
- Session le 8 nov 2025 à 10h → Deadline : 8 nov 2025 à 17h00 (veille au soir impossible)
- Session le 10 nov 2025 à 20h → Deadline : 10 nov 2025 à 17h00

### Qui peut bypass la deadline ?

```ruby
def can_bypass_deadline?
  current_user.admin? || current_user == @session.user
end
```

- **Admins** : oui, toujours
- **Coach de la session** : oui, pour sa propre session
- **Utilisateurs réguliers** : non

## 💡 Exemples d'utilisation

### Scénario 1 : Utilisateur à 16h
```
Session : Entraînement Terrain 1 - 7 nov 2025 19h-20h30
Heure actuelle : 7 nov 2025 16h00
→ Inscription possible ✅
```

### Scénario 2 : Utilisateur à 18h
```
Session : Entraînement Terrain 1 - 7 nov 2025 19h-20h30
Heure actuelle : 7 nov 2025 18h00
→ "Les inscriptions sont closes (limite : 17h le jour de la session)." ❌
```

### Scénario 3 : Admin à 18h
```
Session : Entraînement Terrain 1 - 7 nov 2025 19h-20h30
Heure actuelle : 7 nov 2025 18h00
Utilisateur : Admin
→ Inscription possible ✅
→ Message info : "Délai d'inscription dépassé (17h), mais vous pouvez inscrire."
```

### Scénario 4 : Jeu libre à 18h
```
Session : Jeu Libre - 7 nov 2025 19h-20h30
Heure actuelle : 7 nov 2025 18h00
→ Inscription possible ✅ (pas de deadline pour jeu libre)
```

## 🧪 Tests

Pour exécuter les tests :

```bash
# Tests de la deadline
bundle exec rspec spec/models/session_registration_deadline_spec.rb

# Tous les tests passent
9 examples, 0 failures ✅
```

## 🎨 Interface utilisateur

### Pour les utilisateurs réguliers (après 17h)
- Le bouton "Je m'inscris" est **désactivé** (grisé)
- Message affiché dans le bouton : "Les inscriptions sont closes (limite : 17h le jour de la session)."

### Pour les admins/coachs (après 17h)
- Le formulaire "Ajouter un·e inscrit·e" reste **actif**
- Badge bleu informatif : "Délai d'inscription dépassé (17h), mais vous pouvez inscrire."

## 🔄 Évolutions futures possibles

- Rendre l'heure configurable par session (champ `registration_deadline_hour`)
- Ajouter un délai différent pour les jeux libres si nécessaire
- Notification automatique à 17h pour rappeler aux inscrits
- Statistiques sur les inscriptions tardives (via admin/coach)

## 📝 Notes techniques

- La vérification se fait côté **serveur** (modèle + controller)
- L'UI se met à jour automatiquement via `can_register_with_reason`
- Le fuseau horaire utilisé est celui de la session (`Time.current`)
- Les sessions déjà passées restent fermées à l'inscription (logique existante)

## 🐛 Dépannage

Si la limite ne fonctionne pas :
1. Vérifier que la session est bien de type `entrainement`
2. Vérifier l'heure du serveur : `Time.current`
3. Vérifier les logs pour d'éventuelles erreurs
4. La limite ne s'applique qu'aux entraînements, pas aux jeux libres

Si un admin ne peut pas inscrire après 17h :
1. Vérifier que l'utilisateur a bien le flag `admin: true`
2. Vérifier que le coach est bien assigné à la session (`session.user`)

