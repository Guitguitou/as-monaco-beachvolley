# Configuration des Notifications Push sur Scalingo

## ✅ Ce qui est déjà configuré

Votre application utilise déjà :
- ✅ **Redis** : Pour Sidekiq et le cache (déjà configuré)
- ✅ **Sidekiq** : Pour les jobs en arrière-plan (déjà configuré)
- ✅ **HTTPS** : Fourni automatiquement par Scalingo (requis pour les notifications push)

## 🔧 Configuration nécessaire

### 1. Générer les clés VAPID

En local, générez les clés :

```bash
bin/rails vapid:generate
```

Cela affichera quelque chose comme :
```
Public Key: BJfU6JKGrcU2gIB8MsICBiblfxlw2nF10nPY3i_SmcCs_x_lBXmIHY9zLcj5VN3VQeO8idfr43J--iVzFX8TntM
Private Key: 55Tw_tlK8B8yMuwxFB24m4zlBPKovswke3CycI2RFlo
```

### 2. Ajouter les variables d'environnement sur Scalingo

#### Option A : Via la CLI Scalingo

```bash
# Remplacez "votre-nom-app" par le nom de votre app Scalingo
scalingo --app votre-nom-app env-set VAPID_PUBLIC_KEY="BJfU6JKGrcU2gIB8MsICBiblfxlw2nF10nPY3i_SmcCs_x_lBXmIHY9zLcj5VN3VQeO8idfr43J--iVzFX8TntM"

scalingo --app votre-nom-app env-set VAPID_PRIVATE_KEY="55Tw_tlK8B8yMuwxFB24m4zlBPKovswke3CycI2RFlo"

scalingo --app votre-nom-app env-set VAPID_SUBJECT="mailto:votre-email@example.com"
```

**Important** : Remplacez les clés par celles générées par `bin/rails vapid:generate` et mettez votre email réel dans `VAPID_SUBJECT`.

#### Option B : Via le Dashboard Scalingo

1. Allez sur https://dashboard.scalingo.com
2. Sélectionnez votre application
3. Allez dans **Environment** (ou **Variables**)
4. Cliquez sur **"Add variable"**
5. Ajoutez les 3 variables :
   - `VAPID_PUBLIC_KEY` = votre clé publique
   - `VAPID_PRIVATE_KEY` = votre clé privée
   - `VAPID_SUBJECT` = `mailto:votre-email@example.com`

### 3. Vérifier les variables

```bash
scalingo --app votre-nom-app env | grep VAPID
```

Vous devriez voir :
```
VAPID_PUBLIC_KEY=BJfU6JKGrcU2gIB8MsICBiblfxlw2nF10nPY3i_SmcCs_x_lBXmIHY9zLcj5VN3VQeO8idfr43J--iVzFX8TntM
VAPID_PRIVATE_KEY=55Tw_tlK8B8yMuwxFB24m4zlBPKovswke3CycI2RFlo
VAPID_SUBJECT=mailto:votre-email@example.com
```

### 4. Redémarrer l'application

Après avoir ajouté les variables, redémarrez l'application :

```bash
scalingo --app votre-nom-app restart
```

### 5. Vérifier que le service worker est accessible

Le fichier `public/service-worker.js` doit être accessible. Testez :

```bash
curl https://votre-app.osc-fr1.scalingo.io/service-worker.js
```

Vous devriez voir le contenu du service worker.

## 📋 Checklist de configuration

- [ ] Clés VAPID générées avec `bin/rails vapid:generate`
- [ ] Variable `VAPID_PUBLIC_KEY` ajoutée sur Scalingo
- [ ] Variable `VAPID_PRIVATE_KEY` ajoutée sur Scalingo
- [ ] Variable `VAPID_SUBJECT` ajoutée sur Scalingo (avec votre email)
- [ ] Application redémarrée
- [ ] Service worker accessible à `/service-worker.js`
- [ ] Migrations exécutées : `scalingo --app votre-app run rails db:migrate`

## 🔍 Vérification

### Tester depuis la console Rails

```bash
scalingo --app votre-app run rails console
```

Puis dans la console :

```ruby
# Vérifier que les clés sont bien chargées
ENV["VAPID_PUBLIC_KEY"]
ENV["VAPID_PRIVATE_KEY"]
ENV["VAPID_SUBJECT"]

# Tester l'envoi d'une notification (remplacez user_id par un ID réel)
user = User.find(123)
SendPushNotificationJob.perform_now(
  user.id,
  title: "Test",
  body: "Ceci est un test",
  url: "/"
)
```

### Vérifier les logs

```bash
# Logs de l'application
scalingo --app votre-app logs --filter web

# Logs du worker (pour voir les jobs de notification)
scalingo --app votre-app logs --filter worker
```

## ⚠️ Points importants

1. **HTTPS requis** : Les notifications push nécessitent HTTPS. Scalingo le fournit automatiquement ✅

2. **Service Worker** : Le fichier `public/service-worker.js` doit être accessible. Il est automatiquement servi par Rails ✅

3. **Redis** : Déjà configuré pour Sidekiq et le cache. Utilisé aussi pour la protection anti-spam de la règle 3 ✅

4. **Sidekiq** : Déjà configuré. Les notifications sont envoyées en arrière-plan via `SendPushNotificationJob` ✅

5. **Migrations** : N'oubliez pas d'exécuter les migrations après le déploiement :
   ```bash
   scalingo --app votre-app run rails db:migrate
   ```

## 🐛 Dépannage

### Les notifications ne s'envoient pas

1. Vérifiez que les variables VAPID sont bien définies :
   ```bash
   scalingo --app votre-app env | grep VAPID
   ```

2. Vérifiez les logs du worker :
   ```bash
   scalingo --app votre-app logs --filter worker
   ```

3. Vérifiez que Sidekiq tourne :
   ```bash
   scalingo --app votre-app ps
   ```
   Vous devriez voir un container "worker" en cours d'exécution.

### Erreur "Invalid VAPID keys"

- Vérifiez que les clés sont complètes (pas tronquées)
- Régénérez les clés si nécessaire : `bin/rails vapid:generate`
- Vérifiez qu'il n'y a pas d'espaces ou de caractères invisibles

### Le service worker n'est pas accessible

- Vérifiez que le fichier `public/service-worker.js` existe
- Vérifiez les logs de l'application pour les erreurs 404
- Redéployez l'application si nécessaire

## 📚 Ressources

- [Documentation Scalingo - Variables d'environnement](https://doc.scalingo.com/platform/app/environment-variables)
- [Documentation Scalingo - Redis](https://doc.scalingo.com/databases/redis/start)
- [Documentation Scalingo - Sidekiq](https://doc.scalingo.com/languages/ruby/sidekiq)
