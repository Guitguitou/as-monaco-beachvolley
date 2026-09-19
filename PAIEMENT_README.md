# 💳 Système de Paiement LCL Sherlock's

## 🎯 Vue d'ensemble

Achat de packs (crédits, licences, stages, inscriptions tournoi, équipements)
via **LCL Sherlock's**, l'habillage LCL de Worldline Sips 2.0.

**Conversion** : 100 crédits = 1 EUR

## 📊 Flux de paiement

```
1. Joueur → clique « Acheter » sur /packs
   ↓
2. CreditPurchase créé (status: pending) + référence marchande figée
   ↓
3. Page de transition aux couleurs du club, qui poste vers paymentInit
   ↓
4. Joueur → paie sur la page LCL (CB, et Apple Pay / Google Pay si activés)
   ↓
5. LCL → POST cross-site sur /checkout/return  (Data + Seal signés)
   │  ├─ vérification du Seal
   │  ├─ lecture du responseCode et de la référence
   │  ├─ Sherlock::ApplyOutcome (idempotent)
   │  └─ 302 → GET /checkout/:signed_id
   ↓
6. Page de résultat : payé / refusé / annulé / en attente
```

En parallèle, LCL notifie `/webhooks/sherlock` de serveur à serveur. C'est le
**filet de sécurité** : le joueur peut fermer son onglet avant de revenir, et
cette notification est alors la seule qu'on recevra. Les deux entrées
traversent le même `Sherlock::ApplyOutcome`, dans n'importe quel ordre.

### Pourquoi une URL de retour et une redirection

LCL renvoie le joueur en **POST cross-site**. Avec des cookies en
`SameSite=Lax`, cette requête n'emporte ni jeton CSRF ni cookie de session :
`current_user` y est toujours nil. Le résultat est donc appliqué à partir de la
réponse signée — qui fait autorité — puis on redirige vers un GET, où la
session est de nouveau présente et où la page de résultat peut être rendue.

### Il n'y a pas d'URL d'annulation

Sherlock's n'expose qu'un `normalReturnUrl`. Accepté, refusé, annulé par le
client et session expirée reviennent **tous** sur cette URL : c'est le
`responseCode` de la réponse signée qui porte le résultat.

| responseCode | Issue |
|---|---|
| `00` | payé |
| `17` | annulé par le client |
| tout le reste | refusé |

`Sherlock::Outcome` porte la table complète des codes documentés et **échoue
par défaut** : un code inconnu marque l'achat en échec plutôt que de le laisser
bloqué en `pending`.

## 🧩 Structure du code

```
app/
├── models/
│   └── credit_purchase.rb
├── services/
│   ├── sherlock/
│   │   ├── seal.rb              # calcule et vérifie le sceau (les 2 algos)
│   │   ├── response.rb          # réponse signée → champs vérifiés
│   │   ├── outcome.rb           # responseCode → payé / refusé / annulé
│   │   ├── apply_outcome.rb     # applique l'issue, idempotent
│   │   ├── gateway.rb           # interface + fabrique selon SHERLOCK_GATEWAY
│   │   ├── real_gateway.rb      # requête paymentInit signée
│   │   ├── fake_gateway.rb      # réponse scellée, pour le dev
│   │   ├── payment_request.rb   # URL + champs à poster
│   │   ├── create_payment.rb    # prépare la requête d'un achat
│   │   ├── handle_callback.rb   # entrée du webhook
│   │   └── data_parser.rb       # "k=v|k=v" → hash
│   └── credit_purchases/
│       ├── process_payment.rb   # aiguille vers le processeur du type de pack
│       └── processors/
├── jobs/
│   ├── sherlock_callback_job.rb
│   ├── post_payment_fulfillment_job.rb  # email de confirmation (Brevo)
│   └── expire_stale_purchases_job.rb    # clôture les pending abandonnés
├── controllers/
│   ├── packs_controller.rb      # #buy → page de transition
│   ├── checkout_controller.rb   # #create (retour LCL) + #show (résultat)
│   └── webhooks/
│       └── sherlock_controller.rb
└── views/
    ├── packs/redirect.html.erb
    └── checkout/{paid,failed,cancelled,pending}.html.erb
```

## 🚀 Développement

La passerelle simulée poste sur l'URL de retour une réponse **scellée avec le
même sceau que la vraie passerelle**. Le flux complet est donc exercé en local,
vérification du sceau comprise.

```bash
# .env
SHERLOCK_GATEWAY=fake
APP_HOST=http://localhost:3000
CURRENCY=EUR
REDIS_URL=redis://localhost:6379/1
```

```bash
redis-server        # terminal 1
bin/dev             # terminal 2 (Rails + Sidekiq)
```

Aller sur `/packs`, acheter un pack, vérifier le solde et le statut de l'achat.

Pour rejouer un refus ou une annulation sans toucher au code :

```bash
SHERLOCK_FAKE_RESPONSE_CODE=05   # autorisation refusée
SHERLOCK_FAKE_RESPONSE_CODE=17   # annulation par le client
SHERLOCK_FAKE_RESPONSE_CODE=97   # session expirée
```

## 🏦 Production

Voir `ENV_VARIABLES.md` pour la liste complète. Le minimum :

```bash
SHERLOCK_GATEWAY=real
SHERLOCK_MERCHANT_ID=...
SHERLOCK_API_KEY=...          # clé secrète du contrat
SHERLOCK_KEY_VERSION=1
APP_HOST=https://...
```

`normalReturnUrl` et `automaticResponseUrl` sont transmis à chaque requête : il
n'y a **rien à déclarer côté LCL**. `SHERLOCK_RETURN_URL_SUCCESS` permet de
forcer l'URL de retour ; sans elle, c'est `#{APP_HOST}/checkout/return`.

## 🍎 Apple Pay et Google Pay

`paymentMeanBrandList` fait apparaître les wallets sur la page de paiement :

```bash
SHERLOCK_PAYMENT_MEAN_BRAND_LIST=CB,VISA,MASTERCARD,APPLEPAY,GOOGLEPAY
```

⚠️ Envoyer une marque **non active sur le contrat** fait échouer
l'initialisation du paiement. D'où le pilotage par variable d'environnement :
on ajoute chaque moyen au moment où LCL le confirme, sans redéployer.

**Apple Pay** — en mode Paypage, il suffit de souscrire l'option sur le contrat
Sherlock's. C'est LCL qui gère l'enrôlement auprès d'Apple : pas de compte
développeur Apple, pas de validation de domaine, rien à coder. Restrictions :
appareil Apple uniquement, pas d'iframe, pas de one-click, `captureDay` ≤ 6,
CVV non valorisé, 3DS porté par Apple Pay.

**Google Pay** — demande en plus un contrat CB de vente à distance auprès de
LCL, une inscription sur la console Google Pay, et la transmission du numéro de
contrat à Sherlock's. `gatewayMerchantId` = notre `merchantId` Sherlock's.
Marques acceptées : MASTERCARD, VISA, ELECTRON.

Documentation : [Apple Pay](https://sherlocks-documentation.secure.lcl.fr/fr/integration-apple-pay.html)
· [Google Pay](https://sherlocks-documentation.secure.lcl.fr/fr/integration-google-pay.html)
· [paymentMeanBrandList](https://sherlocks-documentation.secure.lcl.fr/en/data-dictionary/paymentmeanbrandlist.html)

## 🔐 Sécurité

- Sceau vérifié sur **le retour navigateur comme sur le webhook** : c'est la
  seule source de vérité du résultat, les paramètres bruts ne le sont pas.
- Deux algorithmes supportés selon le contrat : `sha256` (historique,
  `SHA256(Data + secret)`) et `HMAC-SHA-256`, alors annoncé dans le Data via
  `sealAlgorithm`.
- `SHERLOCK_API_KEY` est obligatoire hors développement : son absence lève une
  erreur au lieu de retomber silencieusement sur un secret de test.
- La page de résultat est atteinte par un `signed_id` daté (2 h), ce qui permet
  de l'afficher à un acheteur non connecté sans exposer d'identifiant.
- CSRF désactivé uniquement sur le retour de paiement et le webhook, qui sont
  des requêtes cross-site par nature.

## 🎨 Personnalisation de la page de paiement

`SHERLOCK_TEMPLATE_NAME` désigne la feuille de style (nom du zip déposé chez
Sherlock's, 32 caractères max) qui habille la page de paiement. Sans elle, le
joueur passe du rouge ASMBV à un écran LCL générique.

## 🧪 Tests

```bash
bundle exec rspec spec/services/sherlock spec/requests/checkout_spec.rb \
                  spec/requests/webhooks spec/requests/packs_spec.rb \
                  spec/models/credit_purchase_spec.rb spec/jobs
```

## 🆘 Dépannage

### Le paiement ne se crédite pas

1. Statut de l'achat et réponse brute reçue :
   ```bash
   bin/rails runner 'p CreditPurchase.last.slice(:status, :sherlock_fields)'
   ```
2. Sidekiq tourne-t-il ? `bundle exec sidekiq -C config/sidekiq.yml`
3. Chercher `[Sherlock:webhook]` et `[Sherlock:return]` dans les logs.

### « Nous n'avons pas pu vérifier ce retour de paiement »

Le sceau ne correspond pas. Vérifier `SHERLOCK_API_KEY` et que
`SHERLOCK_SEAL_ALGO` correspond bien à l'algorithme du contrat.

### L'initialisation du paiement échoue chez LCL

Le plus souvent une marque de `SHERLOCK_PAYMENT_MEAN_BRAND_LIST` non active sur
le contrat. Vider la variable pour revenir aux moyens par défaut.

## 🎯 Prochaines évolutions

- [ ] Imports journaliers CSV (transactions, opérations, impayés)
- [ ] Rapprochement bancaire
- [ ] Gestion des impayés et chargebacks
- [ ] Remboursements partiels
- [ ] Badge 3DS garanti / non garanti (`threed_ls_code`)
- [ ] Alertes Sentry sur achat payé non rapproché > 72 h
- [ ] Flux invité : ne créer le compte qu'après paiement accepté
