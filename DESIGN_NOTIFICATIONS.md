# 🎨 Design des Notifications Push

## 📱 Apparence des notifications

Les notifications push s'affichent différemment selon le navigateur et l'appareil, mais voici ce qui est configuré :

### Sur Desktop (Chrome, Firefox, Edge)

```
┌─────────────────────────────────────┐
│  [Logo] AS Monaco Beach Volley      │
│                                     │
│  Tu passes en liste principale !   │
│                                     │
│  Quelqu'un s'est désinscrit de la  │
│  session Entraînement du 05/01 à   │
│  19h00, tu viens de passer en      │
│  liste principale                   │
└─────────────────────────────────────┘
```

**Caractéristiques** :
- **Titre** : En gras, en haut
- **Corps** : Texte de la notification
- **Icône** : Logo de l'app (logo.png) à gauche
- **Badge** : Logo dans la barre de notification système
- **Clic** : Ouvre l'URL spécifiée dans l'application

### Sur Mobile (Android, iOS)

**Android** :
```
┌─────────────────────────────┐
│ [Logo] AS Monaco Beach     │
│ Volley                     │
│                            │
│ Tu passes en liste         │
│ principale !               │
│                            │
│ Quelqu'un s'est désinscrit │
│ de la session...           │
└─────────────────────────────┘
```

**iOS** :
```
┌─────────────────────────────┐
│ AS Monaco Beach Volley      │
│                            │
│ Tu passes en liste         │
│ principale !               │
│                            │
│ Quelqu'un s'est désinscrit │
│ de la session Entraînement │
│ du 05/01 à 19h00...        │
└─────────────────────────────┘
```

**Caractéristiques mobiles** :
- **Vibration** : 200ms, pause 100ms, 200ms (si activée)
- **Son** : Son système par défaut (peut être désactivé)
- **Affichage** : En haut de l'écran, puis dans le centre de notification

## 🎯 Éléments de design configurés

### Icône et Badge
- **Icône principale** : `/logo.png` (192x192px recommandé)
- **Badge** : `/logo.png` (24x24px recommandé)
- **Image** : Optionnelle, pour les notifications riches (non utilisée actuellement)

### Comportement
- **Tag** : "default" (permet de regrouper les notifications similaires)
- **Interaction requise** : `false` (la notification disparaît automatiquement)
- **Vibration** : Activée sur mobile `[200, 100, 200]`
- **Silencieuse** : `false` (la notification fait du bruit)

### Actions au clic
Quand l'utilisateur clique sur la notification :
1. La notification se ferme
2. L'application s'ouvre (ou l'onglet existant prend le focus)
3. Navigation vers l'URL spécifiée dans la notification

## 📋 Exemples de notifications

### Règle 1 : Passage en liste principale
```
Titre: "Tu passes en liste principale !"
Corps: "Quelqu'un s'est désinscrit de la session Entraînement du 05/01 à 19h00, tu viens de passer en liste principale"
URL: /sessions/123
```

### Règle 2 : Pas assez de crédits
```
Titre: "Pas assez de crédits"
Corps: "Tu n'as pas assez de crédits pour passer en liste principale."
URL: /sessions/123
```

### Règle 3 : Crédits faibles
```
Titre: "Crédits faibles"
Corps: "Attention tu as moins de 500 crédits, pense à recharger 😉"
URL: /packs
```

### Règle 4 : Session annulée
```
Titre: "Session annulée"
Corps: "La session Entraînement du 05/01 est annulée"
URL: /sessions
```

## 🎨 Personnalisation possible

### Changer l'icône
Modifiez dans `app/services/push_notification_service.rb` :
```ruby
def default_icon
  asset_url("votre-icone.png") || "/votre-icone.png"
end
```

### Ajouter une image
Dans le service, vous pouvez ajouter une image :
```ruby
message = {
  title: title,
  body: body,
  icon: icon || default_icon,
  image: "/images/notification-image.jpg", # Image grande
  # ...
}
```

### Modifier la vibration
Dans `public/service-worker.js` :
```javascript
vibrate: data.vibrate || [200, 100, 200, 100, 200] // Pattern personnalisé
```

### Notifications persistantes
Pour que la notification reste jusqu'à interaction :
```ruby
requireInteraction: true
```

## 📱 Support par navigateur

| Fonctionnalité | Chrome | Firefox | Safari | Edge |
|----------------|--------|---------|--------|------|
| Notifications | ✅ | ✅ | ✅ | ✅ |
| Icône | ✅ | ✅ | ✅ | ✅ |
| Badge | ✅ | ✅ | ⚠️ | ✅ |
| Image | ✅ | ❌ | ❌ | ✅ |
| Vibration | ✅ | ✅ | ❌ | ✅ |
| Actions | ✅ | ✅ | ❌ | ✅ |

## 🔧 Améliorations futures possibles

1. **Notifications riches** : Ajouter des images pour certaines notifications
2. **Actions rapides** : Boutons "Voir", "Ignorer" directement dans la notification
3. **Notifications groupées** : Regrouper plusieurs notifications similaires
4. **Personnalisation par type** : Différentes icônes selon le type de notification
5. **Notifications silencieuses** : Option pour certaines notifications moins urgentes

## 📸 Aperçu visuel

Les notifications utilisent le style natif du système d'exploitation :
- **Windows** : Style Windows 10/11
- **macOS** : Style macOS avec animations
- **Android** : Material Design
- **iOS** : Style iOS natif

Le design s'adapte automatiquement au thème système (clair/sombre) de l'utilisateur.
