# AS Monaco Beach Volley

Gestion des sessions, inscriptions, crédits et licences du club de beach volley de l'AS Monaco.

## Rôles

**Admin** :
Membre du bureau qui gère l'ensemble du club dans l'application.
_Avoid_: Manager, gérant

**Responsable financier** :
Membre du bureau chargé des crédits, paiements et transactions.
_Avoid_: Trésorier, financial manager

**Staff** :
Tout Admin ou Responsable financier, c'est-à-dire toute personne ayant accès à l'espace d'administration.
_Avoid_: Bureau, management

**Encadrant** :
Coach ou Responsable qui encadre une session.
_Avoid_: Supervisor, animateur

**Joueur** :
Membre du club sans rôle particulier.
_Avoid_: Adhérent, user

## Inscriptions

**Désinscription tardive** :
Désinscription d'un entraînement payant après sa date limite d'annulation (ou une fois la session commencée) : non remboursée et comptée dans les alertes du joueur.
_Avoid_: Annulation tardive, late cancel

**Désinscription excusée** :
Désinscription tardive dont le Staff lève la pénalité au moment de retirer le joueur : remboursée et non comptée.
_Avoid_: Annulation justifiée, dérogation
