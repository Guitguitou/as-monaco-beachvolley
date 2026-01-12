# 📱 Quand les notifications se déclenchent

## Règle 1 : Passage en liste principale ✅

### Quand ça se déclenche
Quand un utilisateur en liste d'attente passe automatiquement en liste principale après qu'une place se libère.

### Scénarios concrets

1. **Un joueur se désinscrit d'une session complète**
   - Session avec 12 places, toutes prises
   - Joueur A est en liste d'attente (13ème)
   - Joueur B (inscrit) clique sur "Je me désinscris"
   - ✅ **Notification envoyée à Joueur A** : "Quelqu'un s'est désinscrit de la session XXX du XX/XX à XXh, tu viens de passer en liste principale"

2. **Un admin retire un joueur d'une session complète**
   - Admin retire un joueur via l'interface admin
   - ✅ **Notification envoyée au premier en liste d'attente**

3. **Un coach retire un participant de sa session**
   - Coach retire un participant via `sync_participants`
   - ✅ **Notification envoyée au premier en liste d'attente**

### Où dans le code
- `app/models/session.rb` → `promote_from_waitlist!` (ligne 180-191)
- Appelé depuis :
  - `app/controllers/registrations_controller.rb` → `destroy` (ligne 81)
  - `app/controllers/sessions_controller.rb` → `sync_participants` (ligne 209)
  - `app/controllers/admin/sessions_controller.rb` → `sync_participants` (ligne 154)

---

## Règle 2 : Pas assez de crédits pour passer en liste principale ✅

### Quand ça se déclenche
Quand un utilisateur en liste d'attente ne peut pas être promu en liste principale car il n'a pas assez de crédits.

### Scénarios concrets

1. **Session complète, joueur en liste d'attente avec crédits insuffisants**
   - Session coûte 400 crédits
   - Joueur A est en liste d'attente avec seulement 200 crédits
   - Une place se libère
   - ❌ Joueur A ne peut pas être promu (pas assez de crédits)
   - ✅ **Notification envoyée à Joueur A** : "Tu n'as pas assez de crédits pour passer en liste principale."

2. **Plusieurs joueurs en liste d'attente, le premier n'a pas assez de crédits**
   - Joueur A (1er en liste) : 200 crédits
   - Joueur B (2ème en liste) : 1000 crédits
   - Une place se libère
   - ❌ Joueur A ne peut pas être promu
   - ✅ **Notification envoyée à Joueur A**
   - ✅ Joueur B est promu (s'il a assez de crédits)

### Où dans le code
- `app/models/session.rb` → `promote_from_waitlist!` (ligne 160-168)
- Même déclencheurs que la Règle 1

---

## Règle 3 : Crédits faibles (< 500) ✅

### Quand ça se déclenche
Quand le solde de crédits d'un utilisateur passe sous 500 crédits (et qu'il était au-dessus avant).

### Scénarios concrets

1. **Paiement d'une session qui fait passer sous 500**
   - Joueur a 600 crédits
   - S'inscrit à une session de 200 crédits
   - Solde passe à 400 crédits
   - ✅ **Notification envoyée** : "Attention tu as moins de 500 crédits, pense à recharger 😉"

2. **Achat d'un pack qui fait passer sous 500**
   - Joueur a 600 crédits
   - Achat d'un pack de 200 crédits (débit)
   - Solde passe à 400 crédits
   - ✅ **Notification envoyée**

3. **Ajustement manuel par l'admin qui fait passer sous 500**
   - Admin ajuste le solde d'un joueur
   - ✅ **Notification envoyée si passage sous 500**

4. **Remboursement qui fait passer sous 500** (cas rare mais possible)
   - Si un remboursement négatif fait passer sous 500
   - ✅ **Notification envoyée**

### Protection anti-spam
- ✅ Maximum 1 notification par 24h
- Si le joueur reste sous 500, pas de nouvelle notification avant 24h

### Où dans le code
- `app/models/credit_transaction.rb` → Callbacks `after_create_commit`, `after_update_commit`, `after_destroy_commit`
- Se déclenche à chaque transaction de crédits (paiement, remboursement, achat, ajustement)

---

## Règle 4 : Session annulée ✅

### Quand ça se déclenche
Quand une session où l'utilisateur est inscrit (status: confirmed) est annulée.

### Scénarios concrets

1. **Un coach annule sa session**
   - Coach clique sur "Annuler la session"
   - ✅ **Notification envoyée à tous les joueurs inscrits** : "La session XX du XX/XX est annulée"

2. **Un admin annule une session**
   - Admin annule une session via l'interface
   - ✅ **Notification envoyée à tous les joueurs inscrits**

3. **Session supprimée**
   - Si une session est supprimée (destroy)
   - ✅ **Notification envoyée à tous les joueurs inscrits**

### Important
- ❌ Les joueurs en liste d'attente ne reçoivent PAS de notification
- ✅ Seulement les joueurs avec `status: :confirmed`

### Où dans le code
- `app/controllers/sessions_controller.rb` → `cancel` (ligne 86-125)
- Route : `POST /sessions/:id/cancel`

---

## 📊 Résumé des déclencheurs

| Règle | Déclencheur | Fréquence | Protection |
|-------|-------------|-----------|------------|
| **Règle 1** | Désinscription d'une session complète | À chaque désinscription | Non |
| **Règle 2** | Tentative de promotion sans crédits | À chaque tentative | Non |
| **Règle 3** | Passage sous 500 crédits | À chaque transaction | ✅ 24h cache |
| **Règle 4** | Annulation de session | À chaque annulation | Non |

---

## 🔍 Exemples de flux complets

### Exemple 1 : Désinscription avec promotion
```
1. Session complète (12/12)
2. Joueur A en liste d'attente
3. Joueur B se désinscrit
   → promote_from_waitlist! appelé
   → Joueur A a assez de crédits ?
     ✅ OUI → Règle 1 déclenchée
     ❌ NON → Règle 2 déclenchée
```

### Exemple 2 : Paiement qui fait passer sous 500
```
1. Joueur a 600 crédits
2. S'inscrit à session (200 crédits)
   → CreditTransaction créée
   → after_create_commit déclenché
   → Solde passe à 400
   → previous_balance (600) >= 500 && current_balance (400) < 500 ?
     ✅ OUI → Règle 3 déclenchée
```

### Exemple 3 : Annulation de session
```
1. Session avec 5 joueurs inscrits
2. Coach annule la session
   → cancel appelé
   → Récupère tous les registrations.confirmed
   → Envoie notification à chaque joueur
   → Règle 4 déclenchée 5 fois
```

---

## ⚠️ Cas particuliers

### Règle 1 & 2 : Coaching privé
- Les coachings privés coûtent 0 crédit pour les participants
- Donc la Règle 2 ne se déclenchera jamais pour un coaching privé

### Règle 3 : Transactions multiples
- Si plusieurs transactions font passer sous 500 rapidement
- Seule la première déclenche une notification (protection 24h)

### Règle 4 : Sessions sans joueurs
- Si une session est annulée sans joueurs inscrits
- Aucune notification envoyée (liste vide)
