# À quoi sert VAPID_SUBJECT ?

## 🎯 Rôle principal

`VAPID_SUBJECT` est un identifiant de contact requis par le protocole VAPID (Voluntary Application Server Identification) pour identifier votre application qui envoie les notifications push.

## 📋 Utilisation concrète

### 1. Identification de l'application
- Les services de notification push (Firebase, Chrome, etc.) utilisent ce champ pour identifier qui envoie les notifications
- C'est comme une "signature" de votre application

### 2. Contact en cas de problème
- Si un service de push détecte un abus ou un problème avec vos notifications
- Il peut utiliser cette adresse pour vous contacter
- Par exemple : notifications trop fréquentes, contenu suspect, etc.

### 3. Conformité au protocole Web Push
- Le protocole Web Push (RFC 8291) exige ce champ
- Sans lui, certaines plateformes peuvent refuser vos notifications

## 🔧 Format accepté

Vous pouvez utiliser deux formats :

### Format 1 : mailto: (recommandé)
```bash
VAPID_SUBJECT=mailto:contact@asmonaco-beachvolley.com
```

### Format 2 : URL de votre application
```bash
VAPID_SUBJECT=https://votre-app.osc-fr1.scalingo.io
```

**Recommandation** : Utilisez `mailto:` avec une adresse email réelle que vous consultez régulièrement.

## ⚠️ Que se passe-t-il si vous ne le mettez pas ?

Dans le code, il y a un fallback :
```ruby
def vapid_subject
  ENV["VAPID_SUBJECT"] || Rails.application.credentials.dig(:vapid, :subject) || root_url
end
```

Si `VAPID_SUBJECT` n'est pas défini, le système utilisera l'URL racine de votre application (`root_url`). Cela fonctionne, mais :
- ❌ Moins clair pour identifier votre application
- ❌ Pas de moyen de contact direct en cas de problème
- ⚠️ Certains services peuvent être plus stricts

## 💡 Exemple concret

Quand vous envoyez une notification, le service push reçoit :
```json
{
  "vapid": {
    "subject": "mailto:contact@asmonaco-beachvolley.com",
    "public_key": "...",
    "private_key": "..."
  }
}
```

Le service push sait que :
- L'application s'identifie comme "mailto:contact@asmonaco-beachvolley.com"
- En cas de problème, il peut contacter cette adresse
- C'est une application légitime (les clés VAPID sont signées avec ce subject)

## ✅ Recommandation

Utilisez une adresse email réelle que vous consultez :
```bash
VAPID_SUBJECT=mailto:contact@asmonaco-beachvolley.com
```

Ou l'email de l'administrateur technique :
```bash
VAPID_SUBJECT=mailto:admin@asmonaco-beachvolley.com
```

## 📚 Référence

- [RFC 8291 - Web Push Protocol](https://tools.ietf.org/html/rfc8291)
- [VAPID Specification](https://tools.ietf.org/html/rfc8292)
