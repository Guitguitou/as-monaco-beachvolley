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
Coach ou Responsable de réservation qui encadre une session.
_Avoid_: Supervisor, animateur

**Coach** :
Entraîneur qui anime un entraînement, un coaching privé ou un stage.
_Avoid_: Responsable

**Responsable de réservation** :
Encadrant qui tient le terrain d'un jeu libre ; il n'entraîne pas.
_Avoid_: Coach (pour un jeu libre), responsable de terrain

**Joueur** :
Membre du club sans rôle particulier.
_Avoid_: Adhérent, user

## Inscriptions

**Désinscription tardive** :
Désinscription d'un entraînement payant après sa date limite d'annulation (ou une fois la session commencée) : non remboursée et comptée dans les alertes du joueur.
_Avoid_: Annulation tardive, late cancel

**Désinscription excusée** :
Désinscription tardive dont le Staff lève la pénalité au moment de retirer le joueur : remboursée et non comptée, mais tracée comme toute désinscription tardive.
_Avoid_: Annulation justifiée, dérogation

## Séances

**Séance annulée** :
Séance prévue qui n'aura pas lieu ; elle reste visible avec son motif d'annulation, fermée aux inscriptions, et les inscrits sont remboursés et prévenus. Ses désinscriptions tardives deviennent des désinscriptions excusées.
_Avoid_: Séance supprimée

**Motif d'annulation** :
Raison d'une séance annulée : météo, moins de 2 inscrits, absence d'encadrant ou autre.

**Suppression de séance** :
Effacement d'une séance qui n'aurait jamais dû exister (erreur de saisie) ; ne laisse aucune trace.
_Avoid_: Annulation

## Licences

**Licence payée** :
Le joueur a réglé sa licence de la saison.
_Avoid_: Compte activé

**Dossier complet** :
Le formulaire d'adhésion et les pièces du joueur sont reçus et validés.

**Peut réserver** :
Joueur dont la licence est payée et le dossier complet : seul cas où il peut s'inscrire à une séance.
_Avoid_: Compte activé
