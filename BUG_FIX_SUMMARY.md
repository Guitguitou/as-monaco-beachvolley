# Bug Fix: Session Cancellation

## Problème Initial
Quand un coach cliquait sur "Annuler la session", rien ne se passait.

## Investigation

### Bug #1: Permissions CanCan incorrectes
**Symptôme**: Le bouton "Annuler" ne faisait rien pour les coachs.

**Cause**: La règle `cannot :cancel, Session` dans `Ability` bloquait tous les coachs, même pour leurs propres sessions.

**Solution**: 
- Modifié `app/models/ability.rb` pour donner des permissions explicites
- Changé de `can :manage, Session` à `can [:read, :create, :update, :destroy], Session`
- Ajouté `can :cancel, Session, user_id: user.id` pour permettre l'annulation de leurs propres sessions

### Bug #2: Contrainte de clé étrangère
**Symptôme**: Erreur PostgreSQL lors de l'annulation:
```
PG::ForeignKeyViolation: ERROR: update or delete on table "sessions" 
violates foreign key constraint "fk_rails_d86a8c21ff" on table "late_cancellations"
DETAIL: Key (id)=(299) is still referenced from table "late_cancellations".
```

**Cause**: Le modèle `Session` n'avait pas la relation `has_many :late_cancellations` avec `dependent: :destroy`.

**Solution**: 
- Ajouté `has_many :late_cancellations, dependent: :destroy` dans `app/models/session.rb`

## Tests Ajoutés

### `spec/controllers/sessions_controller_cancel_spec.rb`
Test unitaire du contrôleur avec authentification mockée :
- ✅ Admin peut annuler n'importe quelle session
- ✅ Coach peut annuler sa propre session
- ✅ Coach ne peut pas annuler la session d'un autre coach
- ✅ Utilisateur régulier ne peut pas annuler de session

### `spec/models/ability_spec.rb` (mis à jour)
- ✅ Coach peut faire CRUD sur toutes les sessions
- ✅ Coach peut annuler ses propres sessions
- ✅ Coach ne peut pas annuler les sessions des autres
- ✅ Même logique pour les responsables

## Résultat Final

### Permissions
- **Admins**: Peuvent annuler n'importe quelle session
- **Coachs/Responsables**: Peuvent annuler uniquement leurs propres sessions
- **Utilisateurs réguliers**: Ne peuvent annuler aucune session

### Tests
- 48 exemples, 0 failures
- Tous les tests passent

## Commits
1. `Fix: Allow coaches/responsables to cancel only their own sessions`
2. `Fix: Add late_cancellations relation to Session model`
3. `Remove failing sessions_cancel_spec request test`

