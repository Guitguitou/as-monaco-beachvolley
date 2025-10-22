Guide démarrage rapide
Introduction dans le presse-papier
A qui s'adresse ce document ?Copier le lien vers A qui s'adresse ce document ? dans le presse-papier
Ce document s’adresse aux commerçants qui souhaitent une intégration rapide et simple de la solution Sherlock's. Il vous permet de démarrer avec le connecteur Sherlock’s Paypage POST sans personnalisation des pages de paiement.

Les options décrites dans ce guide sont les plus couramment utilisées.

Ce guide vous explique comment accepter des paiements :

en euros ;
avec les moyens de paiement Visa, Vpay, Electron, Mastercard, Maestro et PayPal ;
sécurisés par 3-D Secure.
Vous utilisez Sherlock's Gestion pour la gestion de caisse et recevez quotidiennement les journaux par mail.

Ce document est valable pour la version 2.18 du connecteur et les versions ultérieures.

PrérequisCopier le lien vers Prérequis dans le presse-papier
Une connaissance élémentaire des standards relatifs aux langages de programmation Web pratiqués aujourd’hui, tels que Java, PHP ou .Net, est nécessaire pour développer la connexion à Sherlock’s Paypage POST.

Note: toutes les portions de code de ce document sont fournies à titre d’exemple, il convient de les adapter à votre site Web afin qu’elles soient pleinement exploitables.
Gestion de la clé secrèteCopier le lien vers Gestion de la clé secrète dans le presse-papier
Lors de votre inscription, LCL met à disposition sur Sherlock’s Téléchargement (voir l'annexe "Télécharger la clé secrète"), une clé secrète qui permet de sécuriser les échanges entre votre site et le serveur Sherlock's.

Vous êtes responsable de sa conservation et devez prendre toutes les mesures pour :

en restreindre l'accès ;
la sauvegarder de manière chiffrée ;
ne jamais la copier sur un disque non sécurisé ;
ne jamais l'envoyer (e-mail, courrier) de manière non sécurisée.
Sherlock's en brefCopier le lien vers Sherlock's en bref dans le presse-papier
Sherlock's est une solution de paiement e-commerce multicanale sécurisée conforme à la norme PCI DSS. Elle vous permet d’accepter et de gérer des transactions de paiement en prenant en compte les règles métiers liées à votre activité (paiement à la livraison, paiement différé, paiement récurrent, paiement en plusieurs fois, …).

Vous gardez le choix de votre établissement bancaire et des moyens de paiement acceptés.

Quotidiennement, Sherlock's envoie par mail les journaux d’activité :

Le journal des transactions qui récapitule l’ensemble des transactions acceptées ou refusées.
Le journal des opérations qui récapitule les opérations de caisse que vous avez effectuées.
Le journal de rapprochement des transactions qui donne la vue financière des paiements crédités sur vos comptes.
Le journal de rapprochement des impayés qui rapproche les impayés de l’établissement bancaire (ex. contestation porteur) avec les transactions que vous avez acceptées.
Sherlock's propose l’interface Sherlock’s Paypage pour connecter votre site Web à la plateforme de paiement.

Sherlock’s Paypage assure l’interface de paiement directement avec votre client via un navigateur Internet ou un mobile.Sherlock’s Paypage met donc à votre disposition des pages de paiements sécurisées, prêtes à l’emploi et accessibles par vos clients.

Sherlock’s Paypage s’accompagne d’une interface web de gestion de caisse : Sherlock's Gestion. Elle vous permet de créer et gérer vos transactions. (validation, annulation, remboursement, ….)

Fonctionnement de Sherlock’s PaypageCopier le lien vers Fonctionnement de Sherlock’s Paypage dans le presse-papier

 
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
95.38ko

Ref	Nom	Fréquence	Description
a1	Requête de paiement Sherlock’s Paypage	24h/24h	Requête de paiement envoyée par vous au serveur Sherlock's
a2	Réponse automatique	24h/24h	Réponse du serveur Sherlock's qui vous est envoyée une fois le paiement effectué. Envoi automatique indépendant de l’action du client. En cas d'abandon du client, vous recevrez la réponse automatique environ 15 minutes après la redirection du client vers les pages de paiement Sherlock's
a3	Réponse manuelle	24h/24h	Réponse du serveur Sherlock's qui vous est envoyée lorsque le client clique sur « continuer ». Envoi conditionné par l’action du client.
d1	Authentification du porteur	24h/24h	Requête envoyée au serveur d’authentification 3-D Secure de la banque du porteur
e1	Demande d’autorisation	24h/24h	Demande d’autorisation envoyée à votre établissement bancaire
e2	Remise en paiement	1/jour	Remise en paiement envoyé par Sherlock's vers l’établissement bancaire pour vous créditer
e3	Retour du paiement	24h/24h	Retour de l’établissement bancaire sur le traitement d’acquisition des paiements
b	Gestion de caisse	24h/24h	Opération de caisse envoyée par vous au serveur Sherlock's
c	Journaux	1/jour	Journaux envoyés par mail
Cinématique d'une transaction CB, VISA, MASTERCARDCopier le lien vers Cinématique d'une transaction CB, VISA, MASTERCARD dans le presse-papier

 
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
92.48ko

Le parcours client est le suivant :

Validation du panier de votre page commerçant,
Redirection du client sur la page Sherlock's de sélection du moyen de paiement,
Saisie des données carte,
Authentification du client sur une page de sa banque (si 3-D Secure),
Affichage du ticket de caisse par Sherlock's,
Confirmation de la prise en compte de la commande sur votre page commerçant.
Dans cette cinématique que la saisie des données de la carte s'effectue chez Sherlock's.Vous n’avez pas connaissance de ces données sensibles.

Cinématique d'une transaction PayPalCopier le lien vers Cinématique d'une transaction PayPal dans le presse-papier

 
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
76.27ko

Le parcours client est le suivant :

Validation du panier sur votre page commerçant
Redirection du client sur la page de sélection du moyen de paiement Sherlock's
Identification du client sur une page PayPal et validation du moyen de paiement
Affichage du ticket de caisse par Sherlock's
Confirmation de la prise en compte de la commande sur votre page commerçant
Identification des transactionsCopier le lien vers Identification des transactions dans le presse-papier
Les transactions de votre boutique sont identifiées de manière unique grâce au champ transactionReference.

Cet identifiant est calculé par Sherlock's ou par vous lors de la création de la transaction. Le couple (transactionReference, merchantId) identifie de manière unique la transaction pendant toute la vie de la transaction.

Démarrer avec Sherlock’s Paypage POST en 5 étapesCopier le lien vers Démarrer avec Sherlock’s Paypage POST en 5 étapes dans le presse-papier
Pour accepter des paiements via Sherlock's vous devez avoir préalablement signé :

un contrat de vente à distance e-commerce/vente par correspondance (VPC) avec votre banque ;
un contrat d’acceptation avec le revendeur de la solution Sherlock's ;
La souscription au service 3-D Secure de Visa et MasterCard qui sécurise les paiements internet est une clause obligatoire du contrat de vente à distance avec votre banque.

Pour pouvoir accepter les paiements PayPal, vous devez également avoir signé un contrat avec PayPal. Votre compte commerçant PayPal doit également être configuré de manière à autoriser l’appel à Sherlock's (cf annexe "paramétrer son compte PayPal").

Étape 1 : inscrire la boutiqueCopier le lien vers Étape 1 : inscrire la boutique dans le presse-papier
Afin d’inscrire votre boutique, vous devez remplir le formulaire d’inscription envoyé par LCL et le retourner à ce dernier.

Lors de la saisie du formulaire, vous désignez un contact administratif et un contact technique afin que LCL puisse vous communiquer les informations nécessaires pour démarrer votre boutique.

LCL procède alors à l’enregistrement de la boutique et vous retourne votre identifiant commerçant (merchantId) ainsi que vos identifiants et mots de passe Portail Sherlock's (récupération de la clé secrète et gestion de caisse).

Note: Pour Portail Sherlock's, les informations de connexion sont envoyées au contact administratif.
L’inscription de la boutique n’est pas nécessaire pour commencer à intégrer le connecteur et à tester la connexion sur l’environnement de simulation. Vous pouvez ne demander l’inscription de votre boutique qu’au moment de faire les tests en production.

Etape 2 : Connecter votre site à Sherlock’s PaypageCopier le lien vers Etape 2 : Connecter votre site à Sherlock’s Paypage dans le presse-papier
Vous devez intégrer le connecteur Sherlock’s Paypage POST pour connecter votre site commerçant au serveur de paiement Sherlock's.

Vous devez donc mettre en place les liens a1 (requête de paiement), a2 et a3 (réponse de paiement automatique et manuelle) décrits dans ce schéma :


 
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
97.74ko

Attention: bien que la réponse automatique ne soit pas obligatoire, il est fortement conseillé de l’implémenter.
Si le client ne clique pas sur « continuer », la réponse manuelle ne sera pas envoyée et vous n’aurez pas de réponse venant de Sherlock's vous confirmant le traitement de la transaction.

Note: pour vous aider à vous connecter à Sherlock's, vous pouvez consulter les exemples de code présents sur notre dépôt GitHub.
Générer la requête de paiementCopier le lien vers Générer la requête de paiement dans le presse-papier
La requête paiement est envoyée depuis une page de votre site web vers le serveur Sherlock's via un formulaire web avec la méthode POST. Ce formulaire doit pointer vers l’URL du serveur de paiement Sherlock's et contenir les champs suivants :

Donnée du formulaire	Présence	Description
Data	Obligatoire	Ensemble des champs de la requête de paiement (champs décrits ci-dessous dans la partie « construire la requête de paiement : donnée Data »)
InterfaceVersion	Obligatoire	L’interface version définit la version de la requête et de la réponse échangée avec le serveur de paiement. Les champs décrits ci-après correspondent à la dernière interfaceVersion. Si vous utilisez une version antérieure du connecteur, il est possible que certains champs ne soient pas disponibles et ne puissent être utilisés.
Seal	Obligatoire	Signature de la donnée Data qui permet de garantir la sécurité de la requête de paiement
Encode	Optionnel	Dans le cas où la donnée Data comporte des caractères spéciaux, vous devez changer l’encodage. La valeur du champ Encode précise la méthode d’encodage utilisée pour la donnée Data. En cas d’encodage, le seal est calculé sur la donnée data encodé.
Valeurs:

Base64 : encodage du champ data en base 64
Base64URL : encodage du champ data en base64URL
SealAlgorithm	Optionnel	Algorithme utilisé pour le calcul de l’empreinte de la donnée Data
Valeurs :

HMAC-SHA-256 : L'algorithme utilisé est HMAC-SHA-256
HMAC-SHA-512 : L'algorithme utilisé est HMAC-SHA-512
SHA-256 : L'algorithme utilisé est SHA-256
Tip: par défaut, le sceau est calculé avec l'algorithme SHA-256, pour qu’un sceau soit calculé avec l'algorithme HMAC-SHA-256, les paramètres d'entrée de la requête doivent contenir le champ sealAlgorithm avec la valeur suivante : HMAC-SHA-256.
Construire la requête de paiement : donnée DataCopier le lien vers Construire la requête de paiement : donnée Data dans le presse-papier
La donnée Data est composée de plusieurs champs, elle contient toutes les informations relatives à la transaction.

Elle est fournie sous la forme d’une chaîne de caractères respectant la syntaxe suivante :

<nomChamp1>=<valeurChamp1>|<nomChamp2>=<valeurChamp2>|… |<nomChampN>=<valeurChampN>
Copy
La donnée Data est composée des champs suivants :

Champs obligatoires
Champs	Format	Description
amount	N12	Montant de la transaction. Il doit être transmis dans la plus petite unité de la devise. Ex : pour l’Euro, un montant de 10,50€ doit être transmis sous la forme 1050.
currencyCode	N3 (restricted values / ISO4217)	Code de la devise de la transaction. Ce code est compatible ISO 4217. Ex : le code de l’euro est 978.
keyVersion	N10	Version de la clé secrète du commerçant utilisée pour calculer le seal du message. Ex : KeyVersion=1 pour la 1ère clé générée à l’inscription de la boutique.
merchantId	N15	Identifiant de la boutique, fourni par Sherlock's au commerçant lors de l’inscription de sa boutique.
normalReturnUrl	ANS512 (url)	URL du commerçant pour le retour à la boutique en cas d’acceptation ou de refus de la transaction (réponse manuelle). Ex : https://www.monsite.fr/RetourPaiement
automaticResponseUrl	ANS512 (url)	URL fournie par le commerçant et utilisée par le serveur de paiement pour notifier au commerçant de manière online et automatique le résultat de la transaction (réponse automatique).
NB : champ non obligatoire mais utilisation fortement recommandée pour que vous receviez la réponse de paiement même si le client ne clique pas sur « continuer »

Principaux champs métiers facultatifs qui vous permettent de faciliter la correspondance entre votre système d’information et le serveur de paiement Sherlock's
Champs	Format	Description
customerId	ANS19 (restrictedString)	Identifiant du client
customerEmail	ANS128 (email)	E-mail du client
orderId	ANS32	Numéro de commande associé à la transaction de paiement.
returnContext	ANSU255 (extendedString)	Contexte de la commande transmis dans la requête de paiement et restitué sans modification dans la réponse et le journal des transactions. Vous pouvez y stocker toute les informations qui facilitent le traitement de la réponse.
Champs CB, Visa, Mastercard, Vpay, Electron et Maestro : Pas de champ spécifique
Champs PayPal (champs disponibles depuis la version HP_2.18)
Champs	Format	Description
addrOverride	ANS20 (restricted values)	Indicateur vous permettant :
d’afficher l’adresse de livraison sur les pages PayPal,
de savoir, si l’adresse à afficher est celle que vous communiquez ou s’il s’agit de celle stockée par PayPal
de déterminer si vous pouvez modifier l’adresse stockée par PayPal.
Valeurs :

NO_OVERRIDE : PayPal affiche l'adresse enregistrée par le client sur son compte PayPal.
OVERRIDE : PayPal affiche l'adresse communiquée par le commerçant, l'adresse enregistrée par le client sur son compte PayPal est supprimée.
NO_DISPLAY (Valeur par défaut) : Aucune adresse n'est affichée. L'adresse envoyée par le commerçant n'est pas prise en compte par PayPal
invoiceId	AN127	Numéro de commande, équivaut à l’orderId mais doit être unique chez PayPal. Obligatoire pour l’utilisation de PayPal.
landingPage	AN5 (restricted values)	Indicateur vous permettant de masquer le formulaire de souscription sur les pages PayPal.
Valeurs :

true : La page de souscription est affichée
false : La page de souscription n'est pas affichée, PayPal affiche directement la page d'identification
mobile	AN5 (restricted values)	Indicateur vous permettant de préciser si le terminal utilisé par le client est le mobile
Valeurs :

true : L'appareil utilisé est un mobile
false : L'appareil utilisé n'est pas un mobile
orderDescription	ANS127	Description de la commande
Sécuriser la requêteCopier le lien vers Sécuriser la requête dans le presse-papier
La requête contient les paramètres de la transaction et est envoyée par le navigateur Web du client. Il est théoriquement possible pour un pirate d’intercepter la demande et de la modifier avant l’envoi au serveur de paiement.

De ce fait, il est nécessaire de renforcer la sécurité pour assurer l’intégrité des paramètres de la transaction envoyée. Sherlock's répond à ce besoin par un échange de signatures qui permet de vérifier :

l’intégrité des messages requête et réponse ;
l’authentification de l’émetteur et du destinataire car ils se partagent la même clé secrète.
IMPORTANT: si votre clé secrète est compromise, ou si vous supposez que c’est le cas, vous devez impérativement demander son renouvellement en vous connectant à Sherlock’s Téléchargement.
Signer l'empreinte de la requête de paiementCopier le lien vers Signer l'empreinte de la requête de paiement dans le presse-papier
La sécurisation de la requête est effectuée en calculant la valeur « hashée » conformément aux paramètres de la transaction (donnée Data). Ensuite, la clé secrète y est ajoutée. Toutes les chaînes de caractères sont converties en UTF-8 avant le « hashage ».

L’algorithme de « hashage » génère un résultat irréversible qui doit être envoyé sous forme hexadécimale dans le champ POST nommée Seal.

Lorsque le message est reçu, le destinataire doit recalculer la valeur « hashée » pour la comparer à celle reçue. Toute différence indique que les données échangées ont été falsifiées.

Il existe 2 méthodes pour signer l’empreinte de la donnée Data :

Pour l’algorithme HMAC-SHA256 :

Utilisation de la donnée Data uniquement (encodée si l’option correspondante est choisie)
Utilisation de la clé secrète partagée pour générer la variante HMAC du message
Codage UTF-8 des données constituant le résultat de l’opération précédente
« Hashage » HMAC-SHA256 des octets obtenus
HMAC-SHA256( UTF-8(Data), UTF-8(secretKey))
Copy
Pour l’algorithme SHA-256 (bien que celui-ci soit la valeur par défaut, cet algorithme n’est plus recommandé à ce jour) :

Concaténation du champ Data et de la clé secrète (encodée si l’option correspondante est choisie)
Codage UTF-8 des données constituant le résultat de l’opération précédente
« Hashage » SHA256 des octets obtenus
SHA256( UTF-8(Data+secretKey))
Copy
Exemples de code Hmac Sha256Copier le lien vers Exemples de code Hmac Sha256 dans le presse-papier
Exemple d’encodage Hmac Sha256 en Php 5
<?php

…

// Seal computation thanks to hash sorted data hash with merchant key

$data_to_send= utf8_encode($data)

$seal=hash_hmac('sha256', $data_to_send, $secretKey);

…
…

?>
Copy
data_to_send et secretKey doivent utiliser un jeu de caractères UTF-8. Référez-vous à la fonction utf8_encode pour la conversion de caractères ISO-8859-1 en UTF-8.

Exemple d’encodage Hmac Sha256 en Java
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class ExampleHMACSHA256 {

/**
 * table to convert a nibble to a hex char.
 */
static final char[] hexChar = {
   '0' , '1' , '2' , '3' ,
   '4' , '5' , '6' , '7' ,
   '8' , '9' , 'a' , 'b' ,
   'c' , 'd' , 'e' , 'f'};

/**
 * Fast convert a byte array to a hex string
 * with possible leading zero.
 * @param b array of bytes to convert to string
 * @return hex representation, two chars per byte.
 */
public static String encodeHexString ( byte[] b )
   {
   StringBuffer sb = new StringBuffer( b.length * 2 );
   for ( int i=0; i<b.length; i++ )
      {
      // look up high nibble char
      sb.append( hexChar [( b[i] & 0xf0 ) >>> 4] );

      // look up low nibble char
      sb.append( hexChar [b[i] & 0x0f] );
      }
   return sb.toString();
   }

/**
 * Computes the seal
 * @param Data the parameters to cipher
 * @param secretKey the secret key to append to the parameters
 * @return hex representation of the seal, two chars per byte.
 */
public static String computeSeal(String data, String secretKey) throws Exception
{
  Mac hmacSHA256 = Mac.getInstance("HmacSHA256");
  SecretKeySpec keySpec = new SecretKeySpec(secretKey.getBytes(), "HmacSHA256");
  hmacSHA256.init(keySpec);

  return encodeHexString(hmacSHA256.doFinal(data.getBytes()));
}

/**
 * @param args
 */
public static void main(String[] args) {
try {
System.out.println (computeSeal("parameters", "key"));
} catch (Exception e) {
e.printStackTrace();
}
}

}
Copy
Exemple d’encodage Hmac Sha256 en .net
(Exemple effectué à l’aide d’un simple formulaire nommé « Form1 » contenant deux champs texte pour saisir data et txtSecretKey, ainsi qu’un autre champ pour afficher lblHEX).

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.Security.Cryptography;

namespace ExampleDotNET
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void cmdGO_Click(object sender, EventArgs e)
        {
            String sChaine = data.Text;
            UTF8Encoding utf8 = new UTF8Encoding();
            Byte[] encodedBytes = utf8.GetBytes(sChaine);

            byte[] shaResult;

            HMAC hmac = new HMAC.Create("HMACSHA256");
            var key = "YourSecretKey";
            hmac.Key = utf8.GetBytes(key);
            hmac.Initialize();

            shaResult = hmac.ComputeHash(encodedBytes);

            lblHEX.Text = ByteArrayToHEX(shaResult);
        }

        private string ByteArrayToHEX(byte[] ba)
        {
            StringBuilder hex = new StringBuilder(ba.Length * 2);
            foreach (byte b in ba)
                hex.AppendFormat("{0:x2}", b);
            return hex.ToString();
        }

    }
}
Copy
Exemples de code Sha256Copier le lien vers Exemples de code Sha256 dans le presse-papier
Exemple d’encodage Sha256 en Php 5
<?php
echo hash('sha256', $data.$secretKey);
?>
Copy
Le jeu de caractères UTF-8 doit être utilisé pour les données Data et secretKey. Pour effectuer une conversion de ISO-8859-1 à UTF-8, faites appel à la fonction utf8_encode.

Exemple d’encodage Sha256 en Java
import java.security.MessageDigest;

public class ExampleSHA256 {

/**
 * table to convert a nibble to a hex char.
 */
static final char[] hexChar = {
   '0' , '1' , '2' , '3' ,
   '4' , '5' , '6' , '7' ,
   '8' , '9' , 'a' , 'b' ,
   'c' , 'd' , 'e' , 'f'};

/**
 * Fast convert a byte array to a hex string
 * with possible leading zero.
 * @param b array of bytes to convert to string
 * @return hex representation, two chars per byte.
 */
public static String encodeHexString ( byte[] b )
   {
   StringBuffer sb = new StringBuffer( b.length * 2 );
   for ( int i=0; i<b.length; i++ )
      {
      // look up high nibble char
      sb.append( hexChar [( b[i] & 0xf0 ) >>> 4] );

      // look up low nibble char
      sb.append( hexChar [b[i] & 0x0f] );
      }
   return sb.toString();
   }

/**
 * Computes the seal
 * @param Data the parameters to cipher
 * @param secretKey the secret key to append to the parameters
 * @return hex representation of the seal, two chars per byte.
 */
public static String computeSeal(String Data, String secretKey) throws Exception
{
  MessageDigest md = MessageDigest.getInstance("SHA-256");
  md.update((Data+secretKey).getBytes("UTF-8"));

  return encodeHexString(md.digest());
}

/**
 * @param args
 */
public static void main(String[] args) {
try {
System.out.println (computeSeal("parameters", "key"));
} catch (Exception e) {
e.printStackTrace();
}
}
}
Copy
Exemple d’encodage Sha256 en .NET
Exemple complété à l’aide d’un simple formulaire appelé « Form 1 » contenant deux champs de texte à renseigner : data, txtSecretKey et un autre à afficher : lblHEX.

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.Security.Cryptography;

namespace ExampleDotNET
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void cmdGO_Click(object sender, EventArgs e)
        {
            String sChaine = data.Text + txtSecretKey.Text;
            UTF8Encoding utf8 = new UTF8Encoding();
            Byte[] encodedBytes = utf8.GetBytes(sChaine);

            byte[] shaResult;
            SHA256 shaM = new SHA256Managed();
            shaResult = shaM.ComputeHash(encodedBytes);

            lblHEX.Text = ByteArrayToHEX(shaResult);
        }

        private string ByteArrayToHEX(byte[] ba)
        {
            StringBuilder hex = new StringBuilder(ba.Length * 2);
            foreach (byte b in ba)
                hex.AppendFormat("{0:x2}", b);
            return hex.ToString();
        }

    }
}
Copy
Envoyer la requête à Sherlock'sCopier le lien vers Envoyer la requête à Sherlock's dans le presse-papier
La demande de paiement est une requête HTTPS POST adressée à Sherlock’s Paypage POST.

Exemple de requête dans le formulaire Web (Data non encodé. Les champs optionnels sealAlgotrihm et encode ne sont pas renseignés).

html
<form method="post" action="https://url.vers.serveur.sips/paymentInit">
    <input type="hidden" name="Data" value="amount=55|currencyCode=978|merchantId=011223744550001|normalReturnUrl=http://www.normalreturnurl.com|transactionReference=534654|keyVersion=1">
    <input type="hidden" name="InterfaceVersion" value="HP_2.18">
    <input type="hidden" name="Seal" value="21a57f2fe765e1ae4a8bf15d73fc1bf2a533f547f2343d12a499d9c0592044d4">
    <input type="submit" value="Payer">
</form>
Copy
copier dans le presse papierCopier le code dans le presse papier
Traitement des erreursCopier le lien vers Traitement des erreurs dans le presse-papier
Voici une liste des erreurs que vous pourriez rencontrer et les messages pour chacun de ces cas. Si l’erreur persiste, contactez l’assistance.

Etat	Exemple de message d’erreur	Action à réaliser
MerchantId inexistant	Merchant ID (merchantId) not found : findMerchantPoi [220555555550002] is not found [5c62b84e3ae83d]	Vérifiez le merchantId utilisé avec celui retourné par Sherlock's après l’inscription.
Algorithme de seal incorrect	Invalid field value : Invalid sealAlgorithm value (SHA-257) [609eac90a8ee1e]]	Vérifiez l’algorithme seal utilisé (champ seal)
Erreur clé secrète	Invalid signature : rge7gesgd86g556dgv4r89g4d6 [609aec21985569]	La signature calculée par Sherlock's à la réception de la requête n’est pas identique à celle que vous avez envoyée.
Lors des tests en simulation, vérifiez la valeur de la clé utilisée avec celle fournie plus loin dans ce document (cf étape 3)
Sur le serveur de production, vérifiez la clé utilisée avec celle récupérée sur Sherlock’s Téléchargement
Version de clé invalide	Invalid field value : Unable to find a valid key for the following keyVersion=0 [609aec2b60b1d0]	Sherlock's ne trouve pas la version de clé que vous indiquez (champ keyVersion).
Lors des tests en simulation, vérifiez la version de la clé utilisée avec celle fournie plus loin dans ce document (cf étape 3)
Sur le serveur de production, vérifiez la version de la clé utilisée avec celle récupérée sur Sherlock’s Téléchargement
Champ Encode incorrect	Invalid keyword : ENCODE [609aecdee11d52]	Vérifiez que l’algorithme de l’encodage que vous utilisez est correctement renseigné dans le champ encode.
URL de retour incorrecte	Technical problem : code=30 message=normalReturnUrl is invalid https:// [609aec31b00b94]	Vérifiez la syntaxe de l’URL que vous indiquez dans le champ normaReturnUrl
Note: les messages sont affichés sur la plateforme de simulation pour vous aider à valider l’intégration de votre site Web. Pour des raisons de sécurité, des messages d’erreur beaucoup plus simples sont affichés sur la plateforme de production. Ex « Erreur lors du traitement de la requête de paiement. Contactez votre commerçant ».
Traiter la réponse de paiementCopier le lien vers Traiter la réponse de paiement dans le presse-papier
Une fois le paiement terminé :

Sherlock's affiche le ticket de caisse
Une réponse automatique vous est envoyée à l’URL contenue dans le champ autoResponseUrl de la requête (optionnel mais fortement conseillé).
Sherlock's invite le client à revenir sur votre site grâce à l’URL renseignée dans le champ normalReturnUrl de la requête. L'action faite par le client déclenche l'envoi d'une réponse manuelle.
Ces quatre champs sont retournés par Sherlock's dans les réponses (automatique et manuelle) :

Champs	Description
Data	Contient les champs de réponse. Respecte la même syntaxe que le champ Data de la requête de paiement.
Encode	Type d’encodage utilisé. S’il vaut base64 ou base64url, le champ Data doit être décodé en Base64/Base64Url pour retrouver la chaîne des champs concaténés.
Seal	Signature du champ Data qui permet de garantir la sécurité de la réponse de paiement.
InterfaceVersion	Valeur et numéro de version de l’interface utilisée.
Vérifier la sécurité de la réponseCopier le lien vers Vérifier la sécurité de la réponse dans le presse-papier
Tout d’abord vous devez vérifier la sécurité du message retourné en recalculant le Seal selon la même méthode que celle utilisée pour la requête. Ensuite, comparez le champ Seal calculé avec celui de la réponse Sherlock's.

Si les Seal sont identiques, vous poursuivez en traitant la réponse de paiement contenue dans le champ Data.

Dans le cas contraire, vous devez stopper le traitement: vérifier la clé secrète et/ou l’algorithme utilisés et si besoin contacter le support technique.

Analyser la réponse de paiementCopier le lien vers Analyser la réponse de paiement dans le presse-papier
La réponse de paiement contenue dans le champ Data est composée :

Champs génériques
Champs	Format	Description
amount	N12	Montant de la transaction. Le montant est transmis dans la plus petite unité de la devise. Exemple pour l’Euro : un montant de 10,50 Euros doit être transmis sous la forme 1050.
currencyCode	N3 (restricted value / ISO4217)	Code de la devise de la transaction. Ce code est compatible ISO 4217.
customerId	AN19 (restrictedString)	Identifiant du client
customerEmail	ANS128 (email)	E-mail du contact
transactionReference	AN35	Identifiant unique de la transaction par commerçant.
guaranteeIndicator	A1 (restricted values)	Niveau de garantie de la transaction (tableau des valeurs ci-dessous).
orderId	ANS32	Numéro de commande associé à la transaction de paiement
responseCode	N2 (restricted values)	Code réponse du serveur Sherlock's (tableau des valeurs ci-dessous).
acquirerResponseCode	AN2 (restricted values)	Code réponse retourné par l’acquéreur lors d’une demande d’autorisation (tableau des valeurs ci-dessous).
authorisationId	AN10/ANS32	Identifiant d’autorisation, retourné par le serveur d’autorisation de la banque du client en cas d’accord (non renseigné en cas de refus).
maskedPAN	ANS19	Numéro de PAN masqué.
panExpiryDate	N6 (YYYYMM)	Date d'expiration du PAN.
paymentMeanBrand	ANS20 (restricted values)	Nom du moyen de paiement utilisé par le client. Valeurs :
CB
VISA
MASTERCARD
ELECTRON
VPAY
MAESTRO
PAYPAL
returnContext	ANSU255 (extendedString)	Contexte de la commande transmis dans la requête de paiement et restitué sans modification dans la réponse et le journal des transactions.
Champs si paiement carte
Champs	Format	Description
holderAuthenStatus	ANS20 (restricted values)	Résultat du processus d’authentification porteur (tableau des valeurs ci-dessous).
cardProductCode	AN5	Code produit de la carte.
cardProductName	ANS70	Libellé du code produit de la carte.
issuerCode	AN6	Code émetteur de la carte
issuerCountryCode	A3 (restricted values)	Code pays de l’émetteur de la carte
issuingCountryCode	A3 (restricted values)	Code pays dans lequel la carte est émise
Champs si paiement PayPal

pas de champ spécifique
Valeurs des champs à analyser
Le champ responseCode donne le résultat de l’acceptation.

La valeur 00 dans le champ responseCode signifie que le paiement est accepté.

En cas de refus (responseCode différent de 00), le champ acquirerResponseCode précise la nature du refus de la banque (si paiement carte) ou du serveur PayPal (si paiement PayPal).

responseCode	Description	Type refus
00	Transaction acceptée	
05	Transaction refusée	Bancaire
34	Suspicion de fraude (seal erroné)	Fraude
75	Nombre maximum de tentatives atteint	Moyen de paiement
90	Service temporairement indisponible	Technique
97	Session expirée (aucune action de l'utilisateur pendant 15 min), transaction refusée	Technique
99	Problème temporaire au niveau du serveur Sherlock's	Technique
holderAuthentStatus	Description	Valeur 3-D
ATTEMPT	Le client n’a pas eu à s’authentifier.	3D_ATTEMPT
CANCEL	Le client a abandonné durant l'authentification.	3D_ABORT
ERROR	Problème technique lors de l’authentification 3DS.	3D_ERROR
FAILURE	Le client n’a pas réussi à s’authentifier (erreur de mot de passe).	3D_FAILURE
NOT_ENROLLED	La carte utilisée n’est pas enrôlée 3-D Secure.	3D_NOTENROLLED
NOT_PARTICIPATING	Le client ne s’est pas authentifié car :
le type de carte n’est pas supporté par le 3DS ;
vous n’êtes pas inscrit au programme 3DS.
SSL
SUCCESS	Le porteur de la carte s’est authentifié correctement.	3D_SUCCESS
guaranteeIndicator	Description
Y	Paiement 3D garanti
N	Paiement 3D non garanti
U	Garantie 3D non définie
Paiement non 3D
acquirerResponseCode	Description	Correspondance responseCode
00	Transaction approuvée ou traitée avec succès	00
02	Contacter l'émetteur du moyen de paiement	02
03	Accepteur invalide	03
04	Conserver le support du moyen de paiement	05
05	Ne pas honorer	05
07	Conserver le support du moyen de paiement, conditions spéciales	05
08	Approuver après l'identification	05
12	Transaction invalide	12
13	Montant invalide	05
14	Coordonnées du moyen de paiement invalides	14
15	Émetteur du moyen de paiement inconnu	05
17	Paiement interrompu par le client	17
24	Opération impossible	05
25	Transaction inconnue	05
30	Erreur de format	30
31	Id de l'organisation d'acquisition inconnu	05
33	Moyen de paiement expiré	05
34	Suspicion de fraude	34
40	Fonction non supportée	05
41	Moyen de paiement perdu	05
43	Moyen de paiement volé	34
51	Provision insuffisante ou crédit dépassé	05
54	Moyen de paiement expiré	05
56	Moyen de paiement manquant dans le fichier	05
57	Transaction non autorisée pour ce porteur	05
58	Transaction interdite au terminal	05
59	Suspicion de fraude	05
60	L'accepteur du moyen de paiement doit contacter l'acquéreur	05
61	Excède le maximum autorisé	05
62	Transaction en attente de confirmation de paiement	05
63	Règles de sécurité non respectées	05
65	Nombre de transactions du jour dépassé	05
68	Réponse non parvenue ou reçue trop tard	05
75	Nombre de tentatives de saisie des coordonnées du moyen de paiement dépassé	75
87	Terminal inconnu	05
90	Arrêt momentané du système	90
91	Emetteur du moyen de paiement inaccessible	90
92	La transaction ne contient pas les informations suffisantes pour être redirigée vers l'organisme d'autorisation Transaction dupliquée	90
94	Transaction dupliquée	90
96	Mauvais fonctionnement du système	90
97	Requête expirée: transaction refusée	90
98	Serveur inaccessible	90
99	Incident technique	99
A1	Paiement refusé par l'acquéreur (données 3-D Secure manquantes dans la demande d'autorisation).	05
Traitement de la réponseCopier le lien vers Traitement de la réponse dans le presse-papier
Etat	Champs de la réponse	Action à réaliser
Paiement 3-D Secure accepté	
responseCode = 00

acquirerResponseCode = 00

garanteeIndicator = Y,N,U, vide

Vous pouvez livrer la commande en fonction du niveau de garantie que vous souhaitez (champ garanteeIndicator).
Refus 3-D Secure	
reponseCode = 05

holderAuthenStatus = FAILURE

L’authentification du client a échoué, ce n’est pas nécessairement un cas de fraude. Vous pouvez proposer à votre client de payer avec autre moyen de paiement en générant une nouvelle requête.
Refus bancaire	responseCode = 05	L’autorisation est refusée pour un motif non lié à la fraude. Vous pouvez proposer à votre client de payer avec un autre moyen de paiement en générant une nouvelle requête.
Repli VADS	
responseCode = 05

acquirerResponseCode = A1

Le paiement a été refusé par l'acquéreur car il manque les données 3-D Secure dans la demande d'autorisation.
Veuillez retenter le paiement avec une cinématique 3-D Secure.
Refus fraude	responseCode = 34	Autorisation refusée pour cause de fraude. Ne livrez pas la commande.
Refus nombre max d’essais atteint	responseCode = 75	Le client a fait plusieurs tentatives toutes échouées car les informations saisies n’étaient pas correctes. Deux possibilités :
Difficulté pour votre client à renseigner les informations carte
Tentative de carding (recherches de numéros de cartes possibles)
Prenez contact avec votre client pour définir avec lui la suite à donner.
Refus suite problème technique	
responseCode = 90, 99

acquirerResponseCode = 90 à 98

Problème technique temporaire lors du traitement de la transaction. Proposez à votre client de refaire un paiement ultérieurement.
Etape 3 : Tester la connexion à Sherlock’s PaypageCopier le lien vers Etape 3 : Tester la connexion à Sherlock’s Paypage dans le presse-papier
Une fois le développement de la connexion à Sherlock’s Paypage réalisé, vous pouvez effectuer un test sur le serveur de simulation Sherlock’s Paypage.

Pour effectuer ce test, il faut utiliser les identifiants suivants :

URL	https://sherlocks-payment-webinit-simu.secure.lcl.fr/paymentInit
ID du commerçant (merchantId)	002016000000001
Clé secrète (secretKey)	002016000000001_KEY1
Version de la clé (keyVersion)	1
Ce serveur de simulation n’est pas raccordé aux serveurs bancaires réels car sa fonction est de valider la connexion entre votre site Web et le serveur de paiement.

Sherlock’s Paypage simule donc l’appel aux serveurs d’autorisation pour vous permettre de tester les différents résultats d’un paiement.

Il n’est donc pas nécessaire d’utiliser des cartes réelles pour effectuer les tests.

Tester des transactions CB, VISA, MASTERCARDCopier le lien vers Tester des transactions CB, VISA, MASTERCARD dans le presse-papier
Le numéro de carte (PAN) doit comporter de 16 à 19 chiffres
Les six premiers chiffres du PAN déterminent le type de carte, conformément au tableau ci-dessous :
Type de carte	Début du numéro de carte
VPAY	400000
VISA	410000
CB	420000
Cartes co-badgées CB et VISA	430000
Cartes co-badgées CB et VPAY	440000
Cartes co-badgées CB et VISA_ELECTRON	450000
Cartes co-badgées VISA et MASTERCARD	460000
MAESTRO	500000
MASTERCARD	510000
Cartes co-badgées CB et MASTERCARD	520000
Cartes co-badgées CB et MAESTRO	530000
Le code réponse Sherlock's (champ responseCode) est calculé à partir des deux derniers chiffres du numéro de carte.
Le code de sécurité (CVV) comporte 3 ou 4 chiffres. Cette valeur est sans importance pour le résultat de la simulation.
Exemple : Si vous utilisez le numéro de carte 4100 0000 0000 0005, la carte sera identifiée comme VISA et le paiement sera refusé (code réponse Sherlock's 05).

Note: Si le code réponse Sherlock's calculé n’est pas référencé, la transaction est acceptée (respondeCode = 00).
Les cartes co-badgées peuvent être utilisées avec chacune des marques définies dans le tableau.

Toutes les cartes sont enrôlées 3-D Secure, vous êtes redirigé vers le serveur de simulation 3-D Secure sur lequel vous choisissez le résultat désiré de l’authentification 3-D Secure.

Tester des transactions PayPalCopier le lien vers Tester des transactions PayPal dans le presse-papier
Si vous choisissez de tester PayPal, vous êtes redirigé vers le serveur de simulation qui simule les transactions PayPal selon leur résultat du paiement chez PayPal. Ensuite, vous retournez au serveur de paiement qui affiche le ticket avec le résultat du paiement.

Etape 4 : Valider la connexion en productionCopier le lien vers Etape 4 : Valider la connexion en production dans le presse-papier
Une fois la connexion de votre site Web à testée, vous êtes à présent en mesure de valider la connexion à Sherlock’s Paypage POST de production.

Pour ce faire, vous devez changer l’URL pour vous connecter au serveur Sherlock's de production en utilisant les identifiants reçus lors l’inscription (merchantId, secretKey et keyVersion).

URL	https://sherlocks-payment-webinit.secure.lcl.fr/paymentInit
merchantId	Identifiant de la boutique reçu par mail
secretKey	Clé secrète que vous récupérez via Sherlock’s Téléchargement
keyVersion	Version clé secrète récupérée sur Sherlock’s Téléchargement (logiquement 1 pour la 1ère clé)
Attention: une erreur fréquente est d’oublier un de ces quatre paramètres ce qui conduit systématiquement à une erreur.
Au préalable, nous conseillons d’isoler votre site Web du public pour éviter que des clients effectuent des transactions pendant cette phase de validation.

Comment valider le bon fonctionnement en productionCopier le lien vers Comment valider le bon fonctionnement en production dans le presse-papier
Immédiatement :

faites une transaction avec une carte de paiement réelle (si possible la vôtre). Si la transaction est acceptée, elle sera envoyée en banque pour créditer votre compte commerçant et débiter le compte carte ;
vérifiez que vos pages de paiement intègrent vos paramètres de personnalisation ;
consultez la transaction via Sherlock's Gestion à partir du transactionReference.
Le lendemain :

vérifiez la présence de la transaction dans le journal des transactions ;
vérifiez sur votre compte que l’opération a bien été créditée ;
remboursez la transaction via Sherlock's Gestion (optionnel).
Le surlendemain :

vérifiez que l’opération de remboursement apparaît dans le journal des opérations ;
vérifiez sur votre compte le débit suite au remboursement.
Cette procédure de validation est également applicable au moyen de paiement PayPal.

Étape 5 : démarrer en productionCopier le lien vers Étape 5 : démarrer en production dans le presse-papier
Une fois la validation du passage en production effectuée, ouvrez votre site au public pour permettre à vos clients d’acheter et de payer.

Dans la journée :

surveillez le taux d’acceptation (nombre de responseCode 00 / nombre total de transactions).
vérifiez la nature des refus non bancaires :
problème technique : responseCode 90, 99 ;
fraude : responseCode 34 ;
nombre maximum de tentatives de paiement atteint : responseCode 75 ;
abandon : responseCode 97.
Le lendemain :

vérifiez dans le journal des transactions la présence de toutes les transactions traitées (acceptées et refusées) ;
vérifiez, dans le journal des opérations, les opérations que vous avez effectuées ainsi que les remises (si vous avez choisi cette option du journal).
AnnexesCopier le lien vers Annexes dans le presse-papier
Créer votre compte PayPalCopier le lien vers Créer votre compte PayPal dans le presse-papier
Afin d'utiliser le moyen de paiement PayPal sur votre site Web, vous devez posséder un compte PayPal. Il doit s'agir d'un compte professionnel (le type du compte est choisi lorsque vous vous enregistrez sur http://www.PayPal.com).

Si vous avez plusieurs boutiques actives, nous vous suggérons de créer un compte PayPal pour chacune.

Paramétrer son compte PayPalCopier le lien vers Paramétrer son compte PayPal dans le presse-papier
Sur votre compte PayPal, vous devez, en tant que commerçant, autoriser le prestataire de services de paiement (PSP) à appeler l'API de PayPal.

Attention: les captures des pages PayPal sont données ici à titre indicatif. Il se peut que PayPal modifie ses pages.
Dans votre compte d'entreprise PayPal, allez dans Paramètres du compte, puis Accès à l'API :


screenshot de l'écran PayPal : cliquez sur mettre à jour à côté d'accès API
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
276.20ko

Cliquez sur le lien Solution de paiement pré-intégrée.


 
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
125.79ko

La fenêtre Ajouter de nouveaux droits d'accès à un tiers s'ouvre. Dans le champ textuel, entrez le compte technique Sherlock's sips-gestion-services_api1.worldline.com puis cliquez sur Rechercher.

Sélectionnez les options suivantes :

Utiliser Express Checkout pour traiter les paiements ;
Émettre un remboursement pour une transaction spécifique ;
Traiter les paiements par carte bancaire de vos clients;
Autoriser et collecter vos transactions PayPal ;
Obtenir des informations concernant une transaction en particulier ;
Rechercher dans vos transactions les éléments correspondant à des critères spécifiques ;
Obtenir une autorisation pour les paiements préapprouvés et initier des transactions préapprouvées ;
Utiliser Express Checkout pour traiter les paiements par mobiles.
Cliquez ensuite sur le bouton Ajouter.


 
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
69.93ko

Attention:
Si vous souhaitez dupliquer des transactions, vous devez également sélectionner l'option "Débiter un client sur la base d'une transaction antérieure".

Clé secrèteCopier le lien vers Clé secrète dans le presse-papier
Télécharger la clé secrèteCopier le lien vers Télécharger la clé secrète dans le presse-papier
Afin d'accéder à l'interface Sherlock’s Téléchargement, vous devez au préalable vous connecter au portail Portail Sherlock's via l'URL : https://sherlocks-extranet.secure.lcl.fr avec l'identifiant qui vous a été retourné par Sherlock's lors de l’inscription de votre boutique .


Image de l'écran d'accueil de l'extranet commerçant.
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
48.25ko

Si vous avez un utilisateur permettant d'accéder à plusieurs boutiques, l'onglet "Téléchargement" permettant d'accéder à Sherlock’s Téléchargement est grisé. Pour l'activer, vous devez sélectionner une boutique.

Ensuite allez dans l’onglet "Téléchargement" puis "Gestion des clés" :


image montrant la page de gestion des clés
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
94.69ko

Vous pouvez télécharger votre clé secrète :


Capture d'écran montrant l'icône "téléchargement".
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
88.48ko

Pour plus de détails sur la gestion des clés secrètes, veuillez consulter la documentation Gestion des clés".

Réglementation des paiementsCopier le lien vers Réglementation des paiements dans le presse-papier
La solution Sherlock's est conforme à la règlementation en vigueur définie par CB, Visa et Mastercard.

La sécurisation des paiements (PCI)Copier le lien vers La sécurisation des paiements (PCI) dans le presse-papier
PCI DSS est un standard de sécurité international dont les objectifs sont d’assurer la confidentialité et l’intégrité des données des porteurs de cartes, et ainsi de sécuriser la protection des données carte et des transactions. Vous et les prestataires de paiement sont tenus de s’y conformer, à des degrés divers en fonction de l’importance de leur activité. La solution Sherlock's est certifiée PCI DSS depuis 2006.

En utilisant Sherlock’s Paypage, vous n’avez pas accès aux données du porteur de carte et n’avez pas besoin d’être certifié PCI DSS. Les données carte sont gérées par LCL.

Le choix de la marque lors du paiement (MIF)Copier le lien vers Le choix de la marque lors du paiement (MIF) dans le presse-papier
La solution Sherlock's 2.0 est soumise à la réglementation européenne MIF (JO EU 2015/751 L123 du 19/05/2015). Parmi ces règles, la « sélection de la marque » vous impose de proposer au client porteur d’une carte cobadgée le choix de la marque au moment du paiement, ce qui impacte la page de paiement.

Une carte cobadgée est une carte qui supporte au moins deux marques. La plupart des cartes émises en France sont cobadgées avec CB (carte CB/VISA, CB/MASTERCARD, CB/MAESTRO…).

Ainsi vous devez laisser le choix de la marque au client porteur de ces cartes cobadgées. À titre d’illustration, l’écran ci-dessous présente un exemple de carte cobadgée CB + Visa avec CB en marque par défaut. Le client peut changer la marque en cliquant sur le lien en bas de l’écran.


 
agrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
78.85ko

Note: pour les cartes non cobadgées, aucun choix de marque n’est proposé.
Pour en savoir plusCopier le lien vers Pour en savoir plus dans le presse-papier
Si vous souhaitez implémenter d’autres moyens de paiement ou options, veuillez-vous référer aux documentations associées.

Cette liste n’est pas exhaustive mais vous présente les documents complémentaires pour vous aider à aller plus loin dans la mise en œuvre de Sherlock's.

Guide	Pourquoi le lire ?
Dictionnaire des données	Ce guide vous permet de connaître la définition et l’ensemble de valeurs des champs des connecteurs et journaux.
Présentation fonctionnelle	Ce guide vous permet d’avoir une vue d’ensemble des fonctionnalités de Sherlock's et des options disponibles auxquelles vous pouvez souscrire.
Guide de configuration des fonctionnalités	Ce guide vous explique la mise en œuvre des fonctionnalités Sherlock's.
Description des journaux	Ce guide décrit le contenu des journaux envoyés par Sherlock's.
Personnalisation de Sherlock’s Paypage pour les boutiques	Ce guide vous explique comment personnaliser les pages de paiement afin qu’elles aient une charte graphique similaire au reste de votre site.
OneClick	Ce guide décrit la solution OneClick qui permet à vos clients de payer en un clic sans avoir à ressaisir leurs données cartes.
Sherlock's Message	Ce guide explique comment implémenter la solution Sherlock's message qui vous permet d’envoyer à vos clients une notification de paiement par mail ou par SMS .
Sherlock’s Téléchargement	Ce guide explique comment télécharger la documentation et votre clé secrète via l’extranet Sherlock’s Téléchargement.
Sherlock's Gestion	Ce guide décrit l’ensemble des actions de gestion de caisse que vous pouvez effectuer via Sherlock's Gestion.
Gestion de la lutte contre la fraude – Go-no-Go	Ce guide explique le fonctionnement, la configuration et l’utilisation du moteur de lutte contre la fraude Go-No-Go. Il vous permet de définir les règles d’acceptation fraude que vous souhaitez mettre en place lors du paiement.
Sherlock’s Paypage POST	Ce guide décrit et explique comment implémenter l’intégralité des options du connecteur .
Intégration American Express	Ce guide vous explique comment intégrer les cartes American Express.


Sherlock's Paypage JSON:
IntroductionCopier le lien vers Introduction dans le presse-papier
Sherlock's est une solution de paiement de commerce électronique multicanale sécurisée conforme à la norme PCI DSS. Elle vous permet d’accepter et de gérer des transactions de paiement en prenant en compte les règles métiers liées à votre activité (paiement à la livraison, paiement différé, paiement récurrent, paiement en plusieurs fois, …).

L’objectif du présent document est d’expliquer la mise en œuvre de la solution Sherlock's Paypage JSON jusqu’au démarrage en production.

À qui s’adresse ce documentCopier le lien vers À qui s’adresse ce document dans le presse-papier
Ce document est destiné aux commerçants qui souhaitent souscrire à l’offre Sherlock's et utiliser un connecteur basé sur des échanges HTTPS en mode JSON entre leur site Web et les serveurs de paiement Sherlock's Paypage JSON.

C’est un guide d’implémentation qui s’adresse à votre équipe technique.

Pour avoir une vue d’ensemble de la solution Sherlock's, nous vous conseillons de consulter les documents suivants :

Présentation fonctionnelle
Guide de configuration des fonctionnalités
PrérequisCopier le lien vers Prérequis dans le presse-papier
Une connaissance élémentaire des standards relatifs aux langages de programmation Web pratiqués aujourd’hui, tels que Java, PHP ou .Net, est nécessaire pour développer la connexion à Sherlock's Paypage JSON.

Note: toutes les portions de code de ce document sont fournies à titre d’exemple, il convient de les adapter à votre site Web afin qu’elles soient pleinement exploitables.
Gestion de la clé secrèteCopier le lien vers Gestion de la clé secrète dans le presse-papier
Lors de votre inscription, LCL met à disposition sur le Portail Sherlock's (voir la notice de renouvellement des clés secrètes), une clé secrète qui permet de sécuriser les échanges entre votre site et le serveur Sherlock's.

Vous êtes responsable de sa conservation et devez prendre toutes les mesures pour :

en restreindre l'accès ;
la sauvegarder de manière chiffrée ;
ne jamais la copier sur un disque non sécurisé ;
ne jamais l'envoyer (e-mail, courrier) de manière non sécurisée.
La compromission de la clé secrète (et son utilisation par un tiers malveillant) perturberait le fonctionnement normal de votre boutique, et pourrait notamment générer des transactions et des opérations de caisse injustifiées (des remboursements par exemple).

IMPORTANT: en cas de compromission d’une clé secrète, vous êtes tenu d’en demander au plus vite la révocation puis le renouvellement via le Portail Sherlock's (voir la « notice de renouvellement des clés secrètes »).
C’est la même clé secrète qui est utilisée sur les différents connecteurs Sherlock’s Paypage, Sherlock’s Office, Sherlock’s In-App et Sherlock's Walletpage.

IMPORTANT: une clé secrète est associée à une version. Après avoir obtenu une nouvelle clé secrète, vous devez impérativement modifier votre requête et indiquer la nouvelle version dans le champ keyVersion, sans quoi vous obtiendrez un code réponse 34 (suspicion de fraude).
Comprendre le paiement avec Sherlock's Paypage JSONCopier le lien vers Comprendre le paiement avec Sherlock's Paypage JSON dans le presse-papier
Le principe général d’une cinématique de paiement est le suivant :


image sur le principe général d’une cinématique de paiement
agrandir l'image
télécharger l'image
Télécharger l'image
format :
PNG
taille :
116.30ko

1. Lorsque le client procède au paiement, une requête de paiement doit être envoyée au connecteur Sherlock's Paypage JSON. LCL vous fournit l’URL de ce connecteur. La requête est alors vérifiée, et chiffrée si elle est valable (elle est nommée RedirectionData dans le système). La requête est envoyée au moyen d’un formulaire en mode POST via HTTPS. Toute autre solution capable d’envoyer une requête de cette nature fonctionne également.

2. Le site du commerçant redirige l’application appelante vers les pages de paiement Sherlock's. Le client doit saisir les informations du moyen de paiement pour que le serveur de paiement Sherlock's prenne en charge la transaction. Il convient de noter que les détails du paiement peuvent être saisis directement sur le serveur qui propose le moyen de paiement (par exemple dans le cas de PayPal ou d’un mandat Sepa). À la fin du processus de paiement, qu’il soit réussi ou non, deux réponses sont créées et envoyées à l’adresse URL précisée lors du 1er flux.

Il y a deux notifications de réponses indépendantes :

3. Les réponses manuelles sont envoyées via la méthode HTTP(S) POST par le serveur de paiement à l’URL de réponse manuelle. Cette URL est précisée dans la requête de paiement et est utilisée lorsque le client clique sur le bouton « Continuer » de la page de paiement. Elle est la page de destination vers laquelle le client est redirigé à la fin du paiement. Comme il n’y a aucune garantie que le client clique sur ce bouton, vous n’avez aucune garantie de recevoir la réponse manuelle.

4. Les réponses automatiques sont envoyées indépendamment des réponses manuelles. Elles utilisent également les requêtes HTTP(S) POST envoyées par les serveurs de paiement Sherlock's mais cette fois-ci moyennant l’URL de réponse automatique précisée dans la requête de paiement. Cela signifie que vous recevez la réponse dès que le paiement est effectué dans les pages de paiement Sherlock's. Cependant, en cas d'abandon du client, vous recevez la réponse automatique, environ 15 minutes après la redirection du client sur le serveur de paiement Sherlock's.

IMPORTANT: si vous n'avez pas l'option "Nouvelle tentative de paiement" (voir partie "Nouvelle tentative de paiement dans le document "Guide de configuration des fonctionnalités"), si le paiement a échoué, et dès que le client est redirigé vers votre site Web, il n’est plus possible de revenir aux pages de paiement Sherlock's pour tenter de payer à nouveau ou pour corriger les données de carte. Le rôle de votre site Web est d’initialiser une nouvelle requête de paiement, en commençant par l’appel au connecteur Sherlock’s Paypage.
Démarrer avec Sherlock's Paypage JSON en 5 étapesCopier le lien vers Démarrer avec Sherlock's Paypage JSON en 5 étapes dans le presse-papier
Étape 1 : inscrire la boutiqueCopier le lien vers Étape 1 : inscrire la boutique dans le presse-papier
Afin d’inscrire votre boutique, vous devez remplir le formulaire d’inscription envoyé par LCL et le retourner à ce dernier.

Lors de la saisie du formulaire, vous désignez un contact administratif et un contact technique afin que LCL puisse vous communiquer les informations nécessaires pour démarrer votre boutique.

LCL procède alors à l’enregistrement de la boutique et vous retourne votre identifiant commerçant (merchantId) ainsi que vos identifiants et mots de passe Portail Sherlock's (récupération de la clé secrète et gestion de caisse).

Note: Pour Portail Sherlock's, les informations de connexion sont envoyées au contact administratif.
L’inscription de la boutique n’est pas nécessaire pour commencer à intégrer le connecteur et à tester la connexion sur l’environnement de simulation. Vous pouvez ne demander l’inscription de votre boutique qu’au moment de faire les tests en production.

Étape 2 : effectuer un paiementCopier le lien vers Étape 2 : effectuer un paiement dans le presse-papier
La requête de paiement consiste en un appel vers un service Web REST (JSON) situé sur la plateforme de paiement.

Attention: pour rappel, il est nécessaire d'indiquer, dans l'en-tête de votre message, que les données à traiter sont de type JSON. Vous devez pour cela préciser l'en-tête 'Content-Type: application/json' dans votre message JSON. À défaut vous risquez de recevoir un message d'erreur de ce type :
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html>
    <head>
        <title>415 Unsupported Media Type</title>
    </head>
    <body>
        <h1>Unsupported Media Type</h1>
        <p>The supplied request data is not in a format
acceptable for processing by this resource.</p>
    </body>
</html>
Copy
Générer la requête de paiementCopier le lien vers Générer la requête de paiement dans le presse-papier
Tous les champs nécessaires pour la transaction (voir les détails dans le chapitre « Renseigner les champs de la requête ») doivent être fournis.

Syntaxe de la requêteCopier le lien vers Syntaxe de la requête dans le presse-papier
La requête est construite conformément au format JSON :

{“<nom du champ>” : ”<nom de la valeur>”, “<nom du champ>” : “<nom de la valeur>”, “nom du champ” : “Nom de la valeur” etc., “seal” : “valeur de seal” }
Copy
Exemple d’une requête de paiement d’un montant de 10 euros :

{"amount" : "1000","automaticResponseUrl" : "https://responseurl.com","currencyCode" :
"978","interfaceVersion" : "IR_WS_2.20","keyVersion" : "1","merchantId" :
"000000000000012","normalReturnUrl" : "https://responseurl2.com","orderChannel" :
"INTERNET","transactionReference" : "1232015021717313","seal" :
"858005903b91ae3b3a076e29aca7dc6314c05aa6f929c439ecfce1de17ea7e39"}
Copy
La syntaxe utilisée pour créer une liste en JSON suit la norme. Voici un résumé de cette structure pour les deux principaux types de listes : les listes de champs simples (par ex. chaînes de caractères) et les listes d’objets.

Il est possible d’avoir une liste de valeurs pour un même champ :

…,"nom du champ" : ["valeur1","valeur2"],…
Copy
Exemple avec le champ paymentMeanBrandList valorisé avec VISA et MASTERCARD :

…,"paymentMeanBrandList" : ["VISA","MASTERCARD"],…
Copy
Si un champ contient une liste d’objets complexes, sa représentation est construite conformément au format suivant :

…,“nom du champ” : [{“nom du sous-champ1”:”valeur1”,“nom du sous-champ2”:”valeur2”},{“nom du souschamp1”:”valeur3”, “nom du sous-champ2”:”valeur4”}],…
Copy
Exemple d’une requête de paiement avec une liste d’objets complexes pour le champ shoppingCartDetail contenant deux produits nommés apple et mango :

{"amount" : "1000","automaticResponseUrl" : "https://responseurl.com","currencyCode" :
"978","interfaceVersion" : "IR_WS_2.8","keyVersion" : "1","merchantId" :
"000000000000012","normalReturnUrl" : "https://responseurl2.com","orderChannel" :
"INTERNET","shoppingCartDetail" : {"shoppingCartItemList" : [{"productCode" :
"123","productName" : "apple"},{"productCode" : "456","productName" :
"mango"}],"shoppingCartTotalAmount" : "1000"},"transactionReference" :
"1232015021717313","seal" :
"fac5bc8e5396d77a8b31a2a79a38750feea71b22106a2cec88efa3641a947345"}
Copy
Présence des champs de la requêteCopier le lien vers Présence des champs de la requête dans le presse-papier
Certains champs de la requête de paiement ne sont obligatoires que :

lors de l'utilisation de certains moyens de paiement ; veuillez consulter le guide du moyen de paiement concerné pour savoir quels champs sont obligatoires ;
en fonction de la configuration de votre boutique ; veuillez consulter le Guide de configuration des fonctionnalités pour savoir quels champs sont obligatoires ;
dans certains cas d'usages (ex : paiement récurrent) ; veuillez consulter le Guide de configuration des fonctionnalités pour savoir quels champs sont obligatoires.
Ces champs sont désignés avec la mention « conditionnel ».

Sécuriser la requêteCopier le lien vers Sécuriser la requête dans le presse-papier
La requête contient les paramètres de la transaction et est envoyée par le navigateur Web du client. Il est théoriquement possible pour un pirate d’intercepter la demande et de la modifier avant l’envoi au serveur de paiement.

De ce fait, il est nécessaire de renforcer la sécurité pour assurer l’intégrité des paramètres de la transaction envoyée. Sherlock's répond à ce besoin par un échange de signatures qui permet de vérifier :

l’intégrité des messages requête et réponse ;
l’authentification de l’émetteur et du destinataire car ils se partagent la même clé secrète.
IMPORTANT: si votre clé secrète est compromise, ou si vous supposez que c’est le cas, vous devez impérativement demander son renouvellement en vous connectant à Sherlock’s Téléchargement.
Comment sécuriser la requêteCopier le lien vers Comment sécuriser la requête dans le presse-papier
La sécurisation de la requête est effectuée en calculant la valeur « hashée » conformément aux paramètres de la transaction (donnée Data). Ensuite, la clé secrète y est ajoutée. Toutes les chaînes de caractères sont converties en UTF-8 avant le « hashage ».

L’algorithme de « hashage » génère un résultat irréversible. Lorsqu’un tel message est reçu, le destinataire doit recalculer la valeur « hashée » pour la comparer à celle reçue. Toute différence indique que les données échangées ont été falsifiées ou que le destinataire et l’émetteur ne partagent pas la même clé secrète.

Le résultat doit être envoyé sous forme hexadécimale dans la donnée nommée Seal.

Calcul de la donnée SealCopier le lien vers Calcul de la donnée Seal dans le presse-papier
Algorithme HMAC-SHACopier le lien vers Algorithme HMAC-SHA dans le presse-papier
La valeur de la donnée Seal est calculée comme suit :

concaténation des valeurs des champs de données dans l’ordre alphabétique (respectant le code de caractères ASCII) des noms des champs, sauf pour les champs keyVersion et sealAlgorithm. Donnant la donnée data, mentionnée dans les exemples ci-dessous.
exemple : un champ nommé authorResponseMessage est à positionner avant un champ nommé authorisationId ;
obtention de l’encodage UTF-8 des données du résultat précédent ;
HMAC avec chiffrement SHA256 des octets obtenus avec la clé secrète.
Cette procédure peut être résumée comme suit :

HMAC-SHA256( UTF-8(sortedDataValues), UTF-8(secretKey))
Copy
Attention: par défaut, le sceau est calculé avec l'algorithme HMAC-SHA-256, dont nous recommandons vivement l'utilisation.
Si toutefois vous souhaitiez calculer le sceau avec l'algorithme plus ancien SHA-256, les paramètres d'entrée de la requête doivent contenir le champ sealAlgorithm avec la valeur suivante : “SHA-256”.

Exemples de code Hmac Sha256Copier le lien vers Exemples de code Hmac Sha256 dans le presse-papier
Exemple d’encodage Hmac Sha256 en Php 5
<?php

…

// Seal computation thanks to hash sorted data hash with merchant key

$data_to_send= utf8_encode($data)

$seal=hash_hmac('sha256', $data_to_send, $secretKey);

…
…

?>
Copy
data_to_send et secretKey doivent utiliser un jeu de caractères UTF-8. Référez-vous à la fonction utf8_encode pour la conversion de caractères ISO-8859-1 en UTF-8.

Exemple d’encodage Hmac Sha256 en Java
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class ExampleHMACSHA256 {

/**
 * table to convert a nibble to a hex char.
 */
static final char[] hexChar = {
   '0' , '1' , '2' , '3' ,
   '4' , '5' , '6' , '7' ,
   '8' , '9' , 'a' , 'b' ,
   'c' , 'd' , 'e' , 'f'};

/**
 * Fast convert a byte array to a hex string
 * with possible leading zero.
 * @param b array of bytes to convert to string
 * @return hex representation, two chars per byte.
 */
public static String encodeHexString ( byte[] b )
   {
   StringBuffer sb = new StringBuffer( b.length * 2 );
   for ( int i=0; i<b.length; i++ )
      {
      // look up high nibble char
      sb.append( hexChar [( b[i] & 0xf0 ) >>> 4] );

      // look up low nibble char
      sb.append( hexChar [b[i] & 0x0f] );
      }
   return sb.toString();
   }

/**
 * Computes the seal
 * @param Data the parameters to cipher
 * @param secretKey the secret key to append to the parameters
 * @return hex representation of the seal, two chars per byte.
 */
public static String computeSeal(String data, String secretKey) throws Exception
{
  Mac hmacSHA256 = Mac.getInstance("HmacSHA256");
  SecretKeySpec keySpec = new SecretKeySpec(secretKey.getBytes(), "HmacSHA256");
  hmacSHA256.init(keySpec);

  return encodeHexString(hmacSHA256.doFinal(data.getBytes()));
}

/**
 * @param args
 */
public static void main(String[] args) {
try {
System.out.println (computeSeal("parameters", "key"));
} catch (Exception e) {
e.printStackTrace();
}
}

}
Copy
Exemple d’encodage Hmac Sha256 en .net
(Exemple effectué à l’aide d’un simple formulaire nommé « Form1 » contenant deux champs texte pour saisir data et txtSecretKey, ainsi qu’un autre champ pour afficher lblHEX).

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.Security.Cryptography;

namespace ExampleDotNET
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void cmdGO_Click(object sender, EventArgs e)
        {
            String sChaine = data.Text;
            UTF8Encoding utf8 = new UTF8Encoding();
            Byte[] encodedBytes = utf8.GetBytes(sChaine);

            byte[] shaResult;

            HMAC hmac = new HMAC.Create("HMACSHA256");
            var key = "YourSecretKey";
            hmac.Key = utf8.GetBytes(key);
            hmac.Initialize();

            shaResult = hmac.ComputeHash(encodedBytes);

            lblHEX.Text = ByteArrayToHEX(shaResult);
        }

        private string ByteArrayToHEX(byte[] ba)
        {
            StringBuilder hex = new StringBuilder(ba.Length * 2);
            foreach (byte b in ba)
                hex.AppendFormat("{0:x2}", b);
            return hex.ToString();
        }

    }
}
Copy
Validation du calcul de sealCopier le lien vers Validation du calcul de seal dans le presse-papier
Une fois votre calcul de seal mis en place, voici un exemple de requête vous permettant de vérifier que vous retrouvez bien le bon seal :

{
  "amount": "2500",
  "automaticResponseUrl": "https://automatic-response-url.fr/",
  "normalReturnUrl": "https://normal-return-url/",
  "captureDay": "0",
  "captureMode": "AUTHOR_CAPTURE",
  "currencyCode": "978",
  "customerContact":{
    "email":"customer@email.com"
  },
  "interfaceVersion": "IR_WS_2.22",
  "keyVersion": "1",
  "merchantId": "011223344550000",
  "orderChannel": "INTERNET",
  "orderId": "ORD101",
  "returnContext": "ReturnContext",
  "transactionOrigin": "SO_WEBAPPLI",
  "transactionReference": "TREFEXA2012",
  "seal": "322b943d833417c1570e0a282641e8e29d6a5b968c9b846694b5610e18ab5b81"
}
Copy
Pour la requête ci-dessus, la chaîne concaténée que vous devez calculer est la suivante :

2500https://automatic-response-url.fr/0AUTHOR_CAPTURE978customer@email.comIR_WS_2.22011223344550000https://normal-return-url/INTERNETORD101ReturnContextSO_WEBAPPLITREFEXA2012
Copy
Avec un algorithme de hachage SHA-256 et une clé secrète valant :

secret123
Le seal attendu est :

322b943d833417c1570e0a282641e8e29d6a5b968c9b846694b5610e18ab5b81
Copy
Exemple de formulaire de redirection vers Sherlock’s PaypageCopier le lien vers Exemple de formulaire de redirection vers Sherlock’s Paypage dans le presse-papier
En réponse à cette requête, vous devez recevoir une réponse (également en JSON) contenant les champs suivants :

Nom du champ	Description
redirectionData	Token de la requête à fournir lors de la redirection vers les pages de de paiement.
redirectionStatusCode	Liste des codes réponse possibles.
redirectionStatusMessage	Court message donnant le statut de l’initialisation.
redirectionUrl	URL des pages de paiement Sherlock's vers lesquelles il faut rediriger le client.
redirectionVersion	Version de la redirection.
seal	Seal de sortie.
reponseEncoding	Type d’encodage utilisé dans les réponses.
Si l’initialisation du paiement s’est correctement déroulée, le champ redirectionStatusCode doit être valorisé à « 00 ». Les champs redirectionData, redirectionVersion et redirectionUrl seront également valorisés pour permettre la redirection vers les pages de paiement Sherlock's.

Pour rediriger le client vers les pages de paiement, vous devez implémenter un formulaire de type POST envoyant les deux champs suivants : redirectionData et redirectionVersion. Le formulaire POST devra rediriger le client vers l’URL fournie dans le champ redirectionUrl.

Ci-dessous un exemple de formulaire à soumettre de façon automatique :

<form method="post" action=”value of redirectionURL”>
    <input type="hidden" name="redirectionVersion" value=”value of redirectionVersion”>
    <input type="hidden" name="redirectionData" value=”value of redirectionData”>
  </form>
Copy
Traiter les erreurs lors de l’initialisationCopier le lien vers Traiter les erreurs lors de l’initialisation dans le presse-papier
Tous les champs reçus par Sherlock's Paypage JSON à travers le connecteur font l’objet d’une vérification individuelle. Le tableau ci-dessous présente la liste des codes d’erreur pouvant être reçus lors de cette étape ainsi que les solutions à mettre en œuvre.

redirectionStatusCode	Description
00	Situation normale suivie du processus normal d'affichage des pages de paiement.
03	L’identifiant commerçant ou le contrat acquéreur ne sont pas valides.
12	Les paramètres de la transaction sont invalides. Vérifiez les paramètres de la requête.
30	Le format de la requête est invalide.
34	Problème de sécurité : par ex. le sceau calculé est incorrect.
94	La transaction existe déjà
99	Service temporairement indisponible.
4 cas sont possibles :

RedirectionStatusCode = 00
Ce cas doit être suivi de la redirection de l’utilisateur vers la page de paiement.

RedirectionStatusCode = 03, 12, 30, 34
Ces codes d’erreur indiquent que la requête comporte un problème qui doit être résolu. Le processus de paiement doit alors être interrompu.

RedirectionStatusCode = 94
La référence de transaction a déjà été utilisée. Vous devez réessayer avec une autre référence de transaction.

RedirectionStatusCode = 99
Problème de disponibilité du service de paiement. Vous devez essayer de renvoyer la requête. Il convient d’utiliser une nouvelle référence de transaction pour éviter un code de réponse 94.

Renseigner les champs de la requêteCopier le lien vers Renseigner les champs de la requête dans le presse-papier
La requête et la réponse de la méthode paymentWebInit sont décrites sur cette page dédiée.

Paramétrer la requête de paiementCopier le lien vers Paramétrer la requête de paiement dans le presse-papier
Voici un exemple de paramétrage de la requête de paiement pour chaque fonctionnalité disponible dans Sherlock's Paypage JSON (le détail de ces fonctionnalités est décrit dans le guide de configuration des fonctionnalités).

Affichage dynamique des moyens de paiementCopier le lien vers Affichage dynamique des moyens de paiement dans le presse-papier
Il faut filtrer ceux qui s’afficheront dans la page de sélection des moyens de paiement grâce au champ paymentMeanBrandList :

.. ,"paymentMeanBrandList":["VISA","PAYPAL"],..
Copy
Affichage du ticket par Sherlock'sCopier le lien vers Affichage du ticket par Sherlock's dans le presse-papier
La page de confirmation du paiement affichée par défaut par Sherlock's peut être désactivée. Cette désactivation se fait par le champ paypageData.bypassReceiptPage :

..,"paypageData":{"bypassReceiptPage":"true"},..
Copy
Canal de paiementCopier le lien vers Canal de paiement dans le presse-papier
Pour choisir votre canal de paiement, vous devez remplir le champ orderChannel dans la requête de paiement :

..,"orderChannel":"INTERNET",..
Copy
Paiement en fin de journéeCopier le lien vers Paiement en fin de journée dans le presse-papier
Dans le cas d’un paiement en fin de journée, il suffit de remplir les champs captureMode et captureDay :

..,"captureDay":"0","captureMode":"AUTHOR_CAPTURE",..
Copy
Paiement différéCopier le lien vers Paiement différé dans le presse-papier
Dans le cas d’un paiement à remiser N jours après l’acceptation en ligne, il suffit de remplir les champs captureMode et captureDay (3 jours dans notre exemple) :

..,"captureDay":"3","captureMode":"AUTHOR_CAPTURE",..
Copy
Pour des cas de paiements différés plus complexes, notamment avec des envois multiples ou un envoi au-delà de 6 jours, veuillez vous référer au guide paiement multiple à l'expédition.

Paiement à l’expéditionCopier le lien vers Paiement à l’expédition dans le presse-papier
Dans le cas d’un paiement à l’expédition, la transaction est envoyée en paiement lors votre validation, il faut juste remplir les champs captureMode et captureDay (3 jours de délai possible avant validation dans notre exemple) :

..,"captureDay":"3","captureMode":"VALIDATION",..
Copy
Paiement en plusieurs foisCopier le lien vers Paiement en plusieurs fois dans le presse-papier
Dans le cas d’un paiement en plusieurs échéances liées à une même transaction, il faut renseigner le champ paymentPattern à INSTALMENT et fournir le détail des échéances dans le champ instalmentData (600 € payés en 3 échéances dans notre exemple) :

.."amount":"60000",..,"transactionReference":"tref1",..,"instalmentData":{"amountsList":["10000","20000","30000"],
"],"datesList":["20170504","20170603","20170703"],"number":"3","transactionReferencesList":["tref1","tref2","tref3"]},..,"paymentPattern":"INSTALMENT",…
Copy
Paiement immédiatCopier le lien vers Paiement immédiat dans le presse-papier
Si vous souhaitez un paiement immédiat (disponible uniquement pour certains moyens de paiement), la transaction est payée lors de l’autorisation en ligne :

..,"captureMode":"IMMEDIATE",..
Copy
Acceptation multideviseCopier le lien vers Acceptation multidevise dans le presse-papier
Dans le cas des transactions multidevises le code devise doit être spécifié dans la requête. C’est dans le contrat d’acquisition où est précisée la devise de règlement.

..,"currencyCode":"840",..
Copy
Règlement en devisesCopier le lien vers Règlement en devises dans le presse-papier
L’acceptation et le règlement sont effectués dans la même devise qui doit être spécifiée dans la requête. Le règlement en devises est une option du contrat d’acquisition.

..,"currencyCode":"826",..
Copy
Inscription et paiement OneClickCopier le lien vers Inscription et paiement OneClick dans le presse-papier
Pour un paiement OneClick, l’identifiant du wallet du client doit être renseigné dans le champ merchantWalletId.

..,"merchantWalletId":"1205987",..
Copy
Prestataire agissant pour le compte d’un commerçantCopier le lien vers Prestataire agissant pour le compte d’un commerçant dans le presse-papier
Il faut passer l’identifiant du prestataire dans la requête dans le champ intermediateServiceProvider et utiliser la clé secrète de ce dernier pour calculer la donnée Seal :

..,"intermediateServiceProviderId":"241591",..
Copy
Traiter la réponseCopier le lien vers Traiter la réponse dans le presse-papier
Deux types de réponse sont prévus. Bien que les protocoles, formats et contenus des deux réponses soient exactement les mêmes, elles doivent être gérées de manière différente car elles répondent à deux besoins différents.

Les réponses sont des réponses HTTP(S) POST envoyées aux URL normalReturnUrl (obligatoire - réponse manuelle) et automaticResponseUrl (optionnelle - réponse automatique) précisées dans la requête.

Vous devez mettre en place le système permettant de décoder ces réponses, afin de connaître le résultat de requête.

Les quatre données suivantes sont définies dans les réponses :

Données	Notes/règles
Data	Concaténation des champs en réponse.
Encode	Type d’encodage utilisé pour la donnée Data. Ce champ est valorisé avec le champ responseEncoding de la requête.
Seal	Signature du message réponse.
InterfaceVersion	Version de l’interface du connecteur.
IMPORTANT: Il est important de ne pas trier les données du champ Data pour calculer le Seal de la réponse. Conservez les champs dans l'ordre dans lequel vous les avez reçu.
Si la valeur du champ Encode est “base64” ou “base64url”, la donnée Data doit-être décodée en Base64/Base64Url pour retrouver la chaîne des champs concaténée. La chaîne concaténée est structurée comme suit : clé1=valeur1|clé2=valeur2… Le sceau (donnée Seal) des 2 réponses est « hashé » avec le même algorithme utilisé en entrée et fourni dans le champ sealAlgorithm. Si aucune valeur n’a été définie, la valeur SHA-256 est utilisée par défaut.

IMPORTANT: pour qu’un sceau soit calculé avec l'algorithme HMAC-SHA-256, les paramètres d'entrée de la requête doivent contenir le champ sealAlgorithm avec la valeur suivante : “HMAC-SHA-256”.
La valeur de la donnée Seal est calculée comme suit :

Pour l'algorithme HMAC-SHA :

utilisation de la clé secrète partagée pour générer la variante HMAC du message ;
utilisation de la donnée Data uniquement (encodée si l’option correspondante est choisie) ;
codage UTF-8 des données constituant le résultat de l’opération précédente ;
« Hashage » HMAC-SHA des octets obtenus.
Cette procédure peut être résumée comme suit :

HMAC-SHA256( UTF-8(Data), UTF-8(secretKey))
Copy
Exemple de Seal calculé avec une clé secrète égale à "secret123" et la donnée Data au format POST ci-dessous:

captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=039000254447216|orderChannel=INTERNET|responseCode=00|transactionDateTime=2022-11-14T11:21:12+01:00|transactionReference=SIM20221114112037|keyVersion=1|acquirerResponseCode=00|amount=1000|authorisationId=664865|guaranteeIndicator=N|panExpiryDate=202401|paymentMeanBrand=VISA|paymentMeanType=CARD|customerIpAddress=10.78.106.18|maskedPan=############0600|holderAuthentRelegation=N|holderAuthentStatus=NOT_PARTICIPATING|tokenPan=490700h719850600|transactionOrigin=SIMS|paymentPattern=ONE_SHOT|customerMobilePhone=null|mandateAuthentMethod=null|mandateUsage=null|transactionActors=null|mandateId=null|captureLimitDate=20221114|dccStatus=null|dccResponseCode=null|dccAmount=null|dccCurrencyCode=null|dccExchangeRate=null|dccExchangeRateValidity=null|dccProvider=null|statementReference=null|panEntryMode=MANUAL|walletType=null|holderAuthentMethod=NO_AUTHENT_METHOD|holderAuthentProgram=3DS_V2|paymentMeanId=null|instalmentNumber=null|instalmentDatesList=null|instalmentTransactionReferencesList=null|instalmentAmountsList=null|settlementMode=null|mandateCertificationType=null|valueDate=null|creditorId=null|acquirerResponseIdentifier=null|acquirerResponseMessage=null|paymentMeanTradingName=null|additionalAuthorisationNumber=null|issuerWalletInformation=null|s10TransactionId=6|s10TransactionIdDate=20221114|preAuthenticationColor=null|preAuthenticationInfo=null|preAuthenticationProfile=null|preAuthenticationThreshold=null|preAuthenticationValue=null|invoiceReference=null|s10transactionIdsList=null|cardProductCode=F|cardProductName=VISA CLASSIC|cardProductProfile=C|issuerCode=00000|issuerCountryCode=GRC|acquirerNativeResponseCode=00|settlementModeComplement=null|preAuthorisationProfile=null|preAuthorisationProfileValue=null|preAuthorisationRuleResultList=[{"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},{"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}]|preAuthenticationProfileValue=null|preAuthenticationRuleResultList=null|paymentMeanBrandSelectionStatus=NOT_APPLICABLE|transactionPlatform=PROD|avsAddressResponseCode=null|avsPostcodeResponseCode=null|customerCompanyName=null|customerBusinessName=null|customerLegalId=null|customerPositionOccupied=null|paymentAttemptNumber=1|holderContactEmail=null|installmentIntermediateServiceProviderOperationIdsList=null|holderAuthentType=null|acquirerContractNumber=3863090010|secureReference=null|authentExemptionReasonList=null|paymentAccountReference=a667b63d8bec4fb980106497c53e4|schemeTransactionIdentifier=b4e683c1a6ff4a09a0415116a0a25b401d38c19d24e643078d|guaranteeLimitDateTime=null|paymentMeanDataProvider=null|virtualCardIndicator=N|cardProductUsageLabel=CREDIT|authorisationTypeLabel=TRANSACTION DE PAIEMENT|authorMessageReference=272612|acceptanceSystemApplicationId=142000000001|challengeMode3DS=null|issuingCountryCode=GRC|abortedProcessingStep=null|abortedProcessingLocation=null
Copy
Le Seal que vous devez obtenir est c946655cce0059124b4ad3eb62c0922c51a0a7d8d28a3cf223e4c0da41bbc5b9

Exemple de Seal calculé avec une clé secrète égale à "secret123" et la donnée Data au format JSON ci-dessous:

{"keyVersion":1,"amount":44000,"captureDay":0,"captureMode":"AUTHOR_CAPTURE","currencyCode":"978","customerId":"40813","customerIpAddress":"213.118.246.190","merchantId":"225005049920001","orderAmount":44000,"orderChannel":"INTERNET","responseCode":"97","responseDescription":"Request time-out; transaction refused","transactionDateTime":"2023-03-15.00:39:04+0100","transactionReference":"dd88adfZ1027b40813f40813y1678837075","statementReference":"T7Ft4KKLRA2M11B9","s10TransactionId":"6","s10TransactionIdDate":"20230315","sealAlgorithm":"sha256","transactionPlatform":"PROD","paymentAttemptNumber":2,"preAuthorisationRuleResultList":[{"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},{"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}]}
Copy
Le Seal que vous devez obtenir est 77be1c230491c0d4eef6eaf910f635d42f55c90cd34c5a162c0ef6fcefb3f087

Pour l’algorithme SHA-256 (bien que celui-ci soit la valeur par défaut, cet algorithme n’est plus recommandé à ce jour) :

concaténation de la donnée Data et de la clé secrète (encodée si l’option correspondante est choisie) ;
codage UTF-8 des données constituant le résultat de l’opération précédente ;
« Hashage » SHA256 des octets obtenus.
Cette procédure peut être résumée comme suit :

SHA256( UTF-8(Data+secretKey ) )
Copy
Exemple de Seal calculé avec une clé secrète égale à "secret123" et la donnée Data au format POST ci-dessous:

captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=039000254447216|orderChannel=INTERNET|responseCode=00|transactionDateTime=2022-11-14T11:21:12+01:00|transactionReference=SIM20221114112037|keyVersion=1|acquirerResponseCode=00|amount=1000|authorisationId=664865|guaranteeIndicator=N|panExpiryDate=202401|paymentMeanBrand=VISA|paymentMeanType=CARD|customerIpAddress=10.78.106.18|maskedPan=############0600|holderAuthentRelegation=N|holderAuthentStatus=NOT_PARTICIPATING|tokenPan=490700h719850600|transactionOrigin=SIMS|paymentPattern=ONE_SHOT|customerMobilePhone=null|mandateAuthentMethod=null|mandateUsage=null|transactionActors=null|mandateId=null|captureLimitDate=20221114|dccStatus=null|dccResponseCode=null|dccAmount=null|dccCurrencyCode=null|dccExchangeRate=null|dccExchangeRateValidity=null|dccProvider=null|statementReference=null|panEntryMode=MANUAL|walletType=null|holderAuthentMethod=NO_AUTHENT_METHOD|holderAuthentProgram=3DS_V2|paymentMeanId=null|instalmentNumber=null|instalmentDatesList=null|instalmentTransactionReferencesList=null|instalmentAmountsList=null|settlementMode=null|mandateCertificationType=null|valueDate=null|creditorId=null|acquirerResponseIdentifier=null|acquirerResponseMessage=null|paymentMeanTradingName=null|additionalAuthorisationNumber=null|issuerWalletInformation=null|s10TransactionId=6|s10TransactionIdDate=20221114|preAuthenticationColor=null|preAuthenticationInfo=null|preAuthenticationProfile=null|preAuthenticationThreshold=null|preAuthenticationValue=null|invoiceReference=null|s10transactionIdsList=null|cardProductCode=F|cardProductName=VISA CLASSIC|cardProductProfile=C|issuerCode=00000|issuerCountryCode=GRC|acquirerNativeResponseCode=00|settlementModeComplement=null|preAuthorisationProfile=null|preAuthorisationProfileValue=null|preAuthorisationRuleResultList=[{"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},{"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}]|preAuthenticationProfileValue=null|preAuthenticationRuleResultList=null|paymentMeanBrandSelectionStatus=NOT_APPLICABLE|transactionPlatform=PROD|avsAddressResponseCode=null|avsPostcodeResponseCode=null|customerCompanyName=null|customerBusinessName=null|customerLegalId=null|customerPositionOccupied=null|paymentAttemptNumber=1|holderContactEmail=null|installmentIntermediateServiceProviderOperationIdsList=null|holderAuthentType=null|acquirerContractNumber=3863090010|secureReference=null|authentExemptionReasonList=null|paymentAccountReference=a667b63d8bec4fb980106497c53e4|schemeTransactionIdentifier=b4e683c1a6ff4a09a0415116a0a25b401d38c19d24e643078d|guaranteeLimitDateTime=null|paymentMeanDataProvider=null|virtualCardIndicator=N|cardProductUsageLabel=CREDIT|authorisationTypeLabel=TRANSACTION DE PAIEMENT|authorMessageReference=272612|acceptanceSystemApplicationId=142000000001|challengeMode3DS=null|issuingCountryCode=GRC|abortedProcessingStep=null|abortedProcessingLocation=null
Copy
Le Seal que vous devez obtenir est 8fb7c5b7e972ed5a279629757aeae9885cdfc1fd888e6fc03114064e94bb2bf4

Exemple de Seal calculé avec une clé secrète égale à "secret123" et la donnée Data au format JSON ci-dessous:

{"keyVersion":1,"amount":44000,"captureDay":0,"captureMode":"AUTHOR_CAPTURE","currencyCode":"978","customerId":"40813","customerIpAddress":"213.118.246.190","merchantId":"225005049920001","orderAmount":44000,"orderChannel":"INTERNET","responseCode":"97","responseDescription":"Request time-out; transaction refused","transactionDateTime":"2023-03-15.00:39:04+0100","transactionReference":"dd88adfZ1027b40813f40813y1678837075","statementReference":"T7Ft4KKLRA2M11B9","s10TransactionId":"6","s10TransactionIdDate":"20230315","sealAlgorithm":"sha256","transactionPlatform":"PROD","paymentAttemptNumber":2,"preAuthorisationRuleResultList":[{"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},{"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}]}
Copy
Le Seal que vous devez obtenir est e9aa5be21186a9f9a417b82d1d450792851c849ccc8a2f85136897da29477975

Renseigner l’URL de la réponse manuelleCopier le lien vers Renseigner l’URL de la réponse manuelle dans le presse-papier
L’objectif principal de la réponse manuelle est de rediriger le client vers votre site Web avec le résultat du paiement pour que vous puissiez prendre la bonne décision le concernant. Par exemple, en cas d’erreur, vous pouvez suggérer de retenter le paiement. Dans le cas de paiement réussi, vous pouvez afficher un message de remerciement et commencer à expédier les marchandises.

À la dernière étape, un bouton « Continuer » est affiché sur la page de paiement chez Sherlock's avec un lien de redirection vers votre site. Lorsque le client clique sur ce bouton, le serveur Sherlock's le redirige vers l’adresse URL contenue dans le champ normalReturnUrl fourni dans la requête. La redirection est une requête HTTP(S) POST qui contient les données de la réponse, tels que décrits ci-dessus. Il est de votre responsabilité de récupérer ces paramètres et de vérifier la signature pour ainsi assurer l’intégrité des données de la réponse. De plus, vous êtes responsable d’afficher les messages pertinents (relatifs aux détails de la réponse) à votre client.

Ce champ normalReturnUrl est également utilisé pour tous les résultats de paiement (annulation, refus ...) afin de rediriger vers votre site.

Il est important de noter qu’il est impossible de garantir la réception de la réponse, celle-ci étant envoyée par le navigateur Web du client. Tout d’abord, le client a la possibilité de ne pas cliquer sur le lien. Ensuite, la connexion qu’il utilise peut tout simplement avoir un problème et bloquer l’envoi de cette réponse. Par conséquent, celle-ci ne peut pas constituer la base unique pour vos processus métier.

Renseigner l’URL de la réponse automatiqueCopier le lien vers Renseigner l’URL de la réponse automatique dans le presse-papier
La réponse automatique est envoyée seulement si le champ automaticResponseUrl a été envoyé dans la requête de paiement. Si tel est le cas, le serveur Sherlock's envoie une réponse HTTP(S) POST à l’adresse URL reçue.

Les champs de la réponse automatique sont identiques à ceux de la réponse manuelle. La seule différence entre les deux procédures est que la réponse automatique est envoyée directement par le serveur Sherlock's sans passer par le navigateur Web du client. Par conséquent, elle est bien plus fiable car elle est toujours envoyée. Le serveur Sherlock's n’attend aucune réponse après l’envoi de la réponse automatique.

Il vous appartient de récupérer les différentes données de la réponse, vérifier la signature pour vous assurer de l’intégrité des champs de la réponse et, par conséquent, mettre à jour votre back office.

Attention: la réponse automatique est systématique, asynchrone et renvoyée par le réseau ; elle est par définition dépendante des problèmes techniques potentiels des différents éléments de ce réseau et peut donc parfois être reçue avec un retard plus ou moins conséquent, voire même ne jamais être reçue.
La réponse automatique est transmise en fin de paiement. Toutefois, si votre client abandonne son achat, par exemple en quittant son navigateur, la réponse automatique est transmise lorsque la session utilisateur expire (au bout de 15 minutes d’inactivité). Par conséquent, si votre client abandonne son achat, vous recevrez uniquement la réponse automatique (pas la réponse manuelle), avec un code réponse renseigné à 97, environ 15 à 16 minutes après la redirection du client sur les pages de paiement.

Si une réponse automatique n’est pas reçue au bout de 16 minutes environ, vous pouvez obtenir le résultat d’un paiement en appelant la méthode getTransactionData de l’interface Sherlock’s Office, ou en analysant le contenu du journal des transactions. Vous pouvez également rechercher une transaction et voir son état en utilisant Sherlock's Gestion.

Choisir le format de la réponse : POST ou JSONCopier le lien vers Choisir le format de la réponse : POST ou JSON dans le presse-papier
A partir de l'interfaceVersion HP_3.0 Sherlock's vous envoie la chaîne concaténée de la réponse (champ Data) sous 2 formats au choix :

Le format POST

Ce format POST a la structure suivante : clé1=valeur1|clé2=valeur2…

Exemple d'une réponse en POST avec séparateur "pipe" entre les données

captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=039000254447216
    |orderChannel=INTERNET|responseCode=00|transactionDateTime=2022-11-14T11:21:12+01:00|transactionReference=SIM20221114112037
    |keyVersion=1|acquirerResponseCode=00|amount=1000|authorisationId=664865|guaranteeIndicator=N|panExpiryDate=202401
    |paymentMeanBrand=VISA|paymentMeanType=CARD|customerIpAddress=10.78.106.18|maskedPan=############0600|holderAuthentRelegation=N
    |holderAuthentStatus=NOT_PARTICIPATING|tokenPan=490700h719850600|transactionOrigin=SIMS|paymentPattern=ONE_SHOT
    |customerMobilePhone=null|mandateAuthentMethod=null|mandateUsage=null|transactionActors=null|mandateId=null|captureLimitDate=20221114
    |dccStatus=null|dccResponseCode=null|dccAmount=null|dccCurrencyCode=null|dccExchangeRate=null|dccExchangeRateValidity=null
    |dccProvider=null|statementReference=null|panEntryMode=MANUAL|walletType=null|holderAuthentMethod=NO_AUTHENT_METHOD
    |holderAuthentProgram=3DS_V2|paymentMeanId=null|instalmentNumber=null|instalmentDatesList=null|instalmentTransactionReferencesList=null
    |instalmentAmountsList=null|settlementMode=null|mandateCertificationType=null|valueDate=null|creditorId=null
    |acquirerResponseIdentifier=null|acquirerResponseMessage=null|paymentMeanTradingName=null|additionalAuthorisationNumber=null
    |issuerWalletInformation=null|s10TransactionId=6|s10TransactionIdDate=20221114|preAuthenticationColor=null|preAuthenticationInfo=null
    |preAuthenticationProfile=null|preAuthenticationThreshold=null|preAuthenticationValue=null|invoiceReference=null|s10transactionIdsList=null
    |cardProductCode=F|cardProductName=VISA CLASSIC|cardProductProfile=C|issuerCode=00000|issuerCountryCode=GRC|acquirerNativeResponseCode=00
    |settlementModeComplement=null|preAuthorisationProfile=null|preAuthorisationProfileValue=null
    |preAuthorisationRuleResultList=[{"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},{"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}]
    |preAuthenticationProfileValue=null|preAuthenticationRuleResultList=null|paymentMeanBrandSelectionStatus=NOT_APPLICABLE|transactionPlatform=PROD
    |avsAddressResponseCode=null|avsPostcodeResponseCode=null|customerCompanyName=null|customerBusinessName=null|customerLegalId=null
    |customerPositionOccupied=null|paymentAttemptNumber=1|holderContactEmail=null|installmentIntermediateServiceProviderOperationIdsList=null
    |holderAuthentType=null|acquirerContractNumber=3863090010|secureReference=null|authentExemptionReasonList=null
    |paymentAccountReference=a667b63d8bec4fb980106497c53e4|schemeTransactionIdentifier=b4e683c1a6ff4a09a0415116a0a25b401d38c19d24e643078d
    |guaranteeLimitDateTime=null|paymentMeanDataProvider=null|virtualCardIndicator=N|cardProductUsageLabel=CREDIT|authorisationTypeLabel=TRANSACTION DE PAIEMENT
    |authorMessageReference=272612|acceptanceSystemApplicationId=142000000001|challengeMode3DS=null|issuingCountryCode=GRC|abortedProcessingStep=null|abortedProcessingLocation=null
Copy
Note: La liste d’objets complexes de ce format POST a une structure qui se rapproche du format JSON
(voir § Syntaxe des listes d'objets complexes dans les réponses)

Le format JSON

Le format JSON a la structure suivante : { "clé1" : "valeur1", "clé2" : "valeur2", …}

Note: Le format JSON affiche aisément une liste ou une collection d’objets avec la structure suivante : "listeClient" : [ { "nom" : "nom1", "prenom" : "prenom1",… }, { "nom" : "nom2", "prenom" : "prenom2",… } ]
Exemple d'une réponse en JSON

{
  		"keyVersion": 1, "acquirerResponseCode": "00", "acquirerResponseDescription": "Transaction approved or processed successfully",
  		"amount": 1000, "authorisationId": "858191", "captureDay": 0, "captureMode": "AUTHOR_CAPTURE", "cardScheme": "VISA",
  		"chargeAmount": 0, "currencyCode": "978", "customerIpAddress": "10.78.106.18", "guaranteeIndicator": "N",
  		"holderAuthentRelegation": "N", "holderAuthentStatus": "NOT_PARTICIPATING", "maskedPan": "############0600",
  		"merchantId": "039000254447216", "orderAmount": 1000, "orderChannel": "INTERNET", "panExpiryDate": "202401",
  		"paymentMeanBrand": "VISA", "paymentPattern": "ONE_SHOT", "responseCode": "00", "responseDescription": "Process succeeded",
  		"tokenPan": "490700h719850600", "transactionDateTime": "2022-11-14.11:19:39+0100", "transactionOrigin": "SIMS",
  		"transactionReference": "SIM20221114111757", "captureLimitDate": "20221114", "paymentMeanType": "CARD", "panEntryMode": "MANUAL",
  		"holderAuthentMethod": "NO_AUTHENT_METHOD", "holderAuthentProgram": "3DS_V2", "s10TransactionId": "5", "s10TransactionIdDate": "20221114",
  		"cardProductCode": "F", "cardProductName": "VISA CLASSIC", "cardProductProfile": "C", "issuerCode": "00000", "issuerCountryCode": "GRC",
  		"acquirerNativeResponseCode": "00", "sealAlgorithm": "sha256", "paymentMeanBrandSelectionStatus": "NOT_APPLICABLE",
  		"transactionPlatform": "PROD", "paymentAttemptNumber": 1, "acquirerContractNumber": "3863090010",
  		"schemeTransactionIdentifier": "79e70b862e5942ff86f31951235959a16f45f41f797f48129e",
  		"paymentAccountReference": "945dbb3e0b984bfc896a04c5bc273", "virtualCardIndicator": "N", "cardProductUsageLabel": "CREDIT",
  		"authorisationTypeLabel": "TRANSACTION DE PAIEMENT", "authorMessageReference": "179263", "acceptanceSystemApplicationId": "142000000001",
  		"issuingCountryCode": "GRC", "threeDLiabilityShift": "N", "threeDStatusCode": "NOT_PARTICIPATING", "threeDRelegationCode": "N",
  		"preAuthorisationRuleResultList":[
  		    {"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},
  		    {"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}
  		]
}
Copy
Comportement par défaut à partir de l'interfaceVersion HP_3.0

Le format de la réponse automatique et manuelle est déterminé par le connecteur qui a été utilisé lors des échanges HTTPS entre votre site Web et les serveurs de paiement Sherlock’s Paypage

Tip: Voici un tableau récapitulatif du fonctionnement entre InterfaceVersion HP_3.0 / Connecteur appelé / Format des réponses
Interface Version	Connecteur	Format des réponses
IR_WS_3.x	JSON	JSON (JS_3.x)
HP_3.x	POST	POST (HP_3.x)
IR_WS_3.x	SOAP	POST (HP_3.x)
Choisir les versions des réponses depuis la requête de paiement

Si vous souhaitez contourner ce comportement par défaut il est possible de renseigner depuis la requête de paiement les versions exactes des réponses automatiques et manuelles que vous utilisez.

Le champs de la requête de paiement qui permet de renseigner la version de la réponse automatique est interfaceVersionAutomaticResponse

Le champs de la requête de paiement qui permet de renseigner la version de la réponse manuelle est interfaceVersionNormalResponse

Attention: Si les versions renseignées dans la requête sont incorrectes alors la requête d'initialisation de paiement est en echec (code erreur 30).
Ces deux nouveaux champs interfaceVersionAutomaticResponse et interfaceVersionNormalResponse sont facultatifs mais si une des versions est renseignée l'autre devient obligatoire également. Sinon la requête d'initialisation de paiement est en echec (code erreur 12).

Résoudre les problèmes de réception des réponsesCopier le lien vers Résoudre les problèmes de réception des réponses dans le presse-papier
Ci-dessous, vous trouverez une liste des problèmes les plus couramment observés qui bloquent la réception des réponses automatiques et manuelles. Assurez-vous de les avoir vérifiés avant d’appeler le service d’assistance technique.

Vérifiez si les adresses URL de réponse sont fournies dans la requête et si elles sont valides. Pour ce faire, vous pouvez tout simplement les copier et coller dans votre navigateur.
Les adresses URL fournies doivent être accessibles depuis l’extérieur, c'est-à-dire de l’Internet. Le contrôle d’accès (identifiant/mot de passe ou filtre IP) ou le pare-feu peuvent bloquer l’accès à votre serveur.
L’accès aux adresses URL de réponse doit être confirmé dans le journal des notifications de votre serveur Web.
Si vous utilisez un port non standard, il doit être compris entre 80 et 9999 pour assurer la compatibilité avec Sherlock's.
Il est impossible d’ajouter des paramètres de contexte aux adresses URL de réponse. Certains champs peuvent être néanmoins utilisés, par exemple, les champs orderID ou returnContext sont prévus pour les paramètres supplémentaires. Éventuellement, vous pouvez vous servir du champ sessionId pour retrouver les renseignements sur votre client à la fin du processus de paiement.
Dans certains cas d’erreurs, le serveur Sherlock's n’est pas capable de signer le message de réponse. Cela s’applique, par exemple, à l’erreur « MerchantID inconnu » et au cas où la clé secrète est inconnue de Sherlock's. Pour ces raisons, le serveur de paiement envoie une réponse sans signature dans le champ Seal.

Récupérer les champs des réponsesCopier le lien vers Récupérer les champs des réponses dans le presse-papier
Le contenu des réponses Sherlock’s Paypage automatiques et manuelles est identique. Le contenu peut varier en fonction du résultat (réussi ou autre).

Note: dans les réponses, en fonction de l’état de la transaction et du moyen de paiement choisi, certains champs peuvent être nuls, vides ou non renseignés. Veuillez consulter les documentations des moyens de paiement pour connaître les champs attendus dans les réponses.
La liste des champs de la réponse est disponible sur cette page.

Champs optionnels relatifs aux contrôles de fraudeCopier le lien vers Champs optionnels relatifs aux contrôles de fraude dans le presse-papier
Contenu de preAuthenticationRuleResult
Champ	Version	Commentaires
ruleCode	HP_2.14	
ruleType	HP_2.14	
ruleWeight	HP_2.14	
ruleSetting	HP_2.14	
ruleResultIndicator	HP_2.14	
ruleDetailedInfo	HP_2.14	
Contenu de preAuthorisationRuleResult
Champ	Version	Commentaires
ruleCode	HP_2.14	
ruleType	HP_2.14	
ruleWeight	HP_2.14	
ruleSetting	HP_2.14	
ruleResultIndicator	HP_2.14	
ruleDetailedInfo	HP_2.14	
Syntaxe des listes d'objets complexes dans les réponsesCopier le lien vers Syntaxe des listes d'objets complexes dans les réponses dans le presse-papier
Le format d'une liste d'objets complexes dans les réponses automatiques et manuelles est défini comme suit (en gras) :

..|amount=1000|currencyCode=978|objectNameList=[{"field1":"value1a",
"field2":"value2a","field3":"value3a"…},{"field1":"value1b",
"field2":"value2b","field3":"value3b"}…]|transactionReference=1452687287828|..
Copy
le contenu de la liste est enveloppé dans une paire de crochets [ ] ;
chaque entrée de la liste est enveloppé dans une paire d'accolades { } ;
chaque champ est représenté comme "nomChamp" = "valeurChamp" ;
notez que le nom et la valeur du champ sont tous deux enveloppés dans une paire de doubles guillemets "" ;
les paires de nom/valeur adjacentes sont séparés par une virgule.
Exemple du champ preAuthorisationRuleResultList

Détail des règles fraude exécutées en préautorisation (en gras)

..|amount=1000|currencyCode=978|preAuthorisationRuleResultList=[
{”ruleCode”:"SC",”ruleType”:"NG",”ruleWeight”:"I",”ruleSetting”:"S",
”ruleResultIndicator”:"0",“ruleDetailedInfo”:"TRANS=1:5;
CUMUL=1000:99999900"},{”ruleCode”:"GC",”ruleType”:"NG",”ruleWeight”:
"D",”ruleSetting”:"N",”ruleResultIndicator”:"0",“ruleDetailedInfo”:
""},{”ruleCode”:"CR",”ruleType”:"NG",”ruleWeight”:"D",”ruleSetting”
:"S",”ruleResultIndicator”:"N",“ruleDetailedInfo”:"CARD_COUNTRY=USA"}]
|transactionReference=1452687287828|..
Copy
Analyser la réponse de paiementCopier le lien vers Analyser la réponse de paiement dans le presse-papier
Si vous procédez à une authentification par sceau électronique (seal), vous devez impérativement vérifier que le sceau reçu correspond bien au sceau que vous recalculez avec les champs de la réponse.

Si le sceau reçu ne correspond pas au sceau que vous recalculez, l’état de la transaction est considéré comme inconnu : laissez la transaction en l’état, contactez le support et ne ré-exécutez pas la transaction de manière automatisée.

État	Champs de la réponse	Action à réaliser
Paiement accepté

responseCode = 00

acquirerResponseCode = 00

garanteeIndicator = Y,N,U, vide

Vous pouvez livrer la commande en fonction du niveau de garantie que vous souhaitez (champ garanteeIndicator).

Refus Fraude Sherlock's Go-No-Go

responseCode = 05

complementaryCode = XX

preAuthorisationRuleResultList

Le paiement a été refusé par le moteur de fraude Sherlock's que vous avez configuré.

Ne livrez pas la marchandise. Analysez le détail des règles fraudes exécutées par Sherlock's pour connaître la cause du refus (champ preAuthorisationRuleResultList).

Refus Fraude Sherlock's

Business Score

responseCode = 05

scoreColor = RED, BLACK

scoreValue = X (score de la transaction)

scoreThreshold = X,Y (seuil orange, seuil vert)

Le paiement a été refusé par le moteur de fraude Sherlock's que vous avez configuré

Ne livrez pas la marchandise. Analysez le détail des règles fraudes exécutées par Sherlock's pour connaître la cause du refus (champ preAuthorisationRuleResultList).

Warning Fraude Sherlock's

Business Score

responseCode = 05

scoreColor = ORANGE

scoreValue = X (score de la transaction)

scoreThreshold = X,Y (seuil orange, seuil vert)

Le paiement a été autorisé par l’acquéreur mais le moteur de fraude Sherlock's émet un warning par rapport aux règles que vous avez configurées.

Analysez le détail des règles fraudes exécutées par Sherlock's pour connaître la cause du warning (champ preAuthorisationRuleResultList).

Si transaction non risquée alors acceptez-la avec la fonction acceptChallenge.

Si transaction risquée alors refusez-la avec la fonction refuseChallenge.

Les fonctions acceptChallenge et refuseChallenge sont disponibles sur le Portail Sherlock's et les connecteurs Sherlock’s Office et Sherlock’s Office Batch.

Refus 3-D Secure

reponseCode = 05

holderAuthenStatus = FAILURE

L’authentification du client a échoué, ce n’est pas nécessairement un cas de fraude. Vous pouvez proposer à votre client de payer avec un autre moyen de paiement en générant une nouvelle requête.

Refus bancaire acquéreur

responseCode = 05

acquirerResponseCode = XX

L’autorisation est refusée pour un motif non lié à la fraude.

Vous pouvez proposer à votre client de payer avec un autre moyen de paiement en générant une nouvelle requête.

Repli VADS	
responseCode = 05

acquirerResponseCode = A1

Le paiement a été refusé par l'acquéreur car il manque les données 3-D Secure dans la demande d'autorisation.
Veuillez retenter le paiement avec une cinématique 3-D Secure.
Refus fraude acquéreur

responseCode = 34

acquirerResponseCode = XX

Autorisation refusée pour cause de fraude.

Ne livrez pas la commande.

Refus nombre max essais atteint

responseCode = 75

acquirerResponseCode = XX

L’acheteur a fait plusieurs tentatives toutes échouées car les informations saisies n’étaient pas correctes. Deux possibilités :

Difficulté pour votre client pour renseigner les informations cartes.

Tentative de carding (recherche de numéros de cartes possibles). Prenez contact avec votre client pour définir la suite à donner.

Refus suite problème technique

responseCode = 90, 99

acquirerResponseCode = 90 à 98

Problème technique temporaire lors du traitement de la transaction.

Proposez à votre client de refaire un paiement ultérieurement.

Abandon du paiement	responseCode = 97
acquirerResponseCode = non renseigné

Ne livrez pas la commande
Étape 3 : tester sur l’environnement de simulationCopier le lien vers Étape 3 : tester sur l’environnement de simulation dans le presse-papier
Une fois le développement de la connexion à Sherlock’s Paypage réalisé, vous pouvez effectuer un test sur le serveur Sherlock’s Paypage de simulation.

URL de simu du serveur https://sherlocks-payment-webinit-simu.secure.lcl.fr/rs-services/v2/paymentInit
Pour effectuer ce test, il faut utiliser les identifiants en fonction du mode d’identification des transactions que vous souhaitez :

Table 1. transactionReference généré par Sherlock's
Champ	Valeur
ID du commerçant (merchantId)	002016000000001
Clé secrète (secretKey)	002016000000001_KEY1
Version de la clé (keyVersion)	1
Ce serveur de simulation n’est pas raccordé aux serveurs bancaires réels car sa fonction est de valider la connexion entre votre site Web et le serveur de paiement.

Sherlock’s Paypage simule donc l’appel aux serveurs d’autorisation pour vous permettre de tester les différents résultats d’un paiement.

Il n’est donc pas nécessaire d’utiliser des cartes réelles pour effectuer les tests.

Attention: puisque le merchantId est partagé entre tous les commerçants/prospects, il existe un risque de doublon de transactionReference. Par conséquent, il est vivement recommandé que tous les transactionReference soient préfixés par le nom de la future boutique qui sera utilisée dans l’environnement de production. Cela facilite aussi le support en cas d’appel à l’assistance technique.
Vous utilisez une boutique générique sans personnalisation de la page de paiement. C’est lors de l’étape 4 que vous pouvez personnaliser vos pages de paiements.

Tester des transactions CB, VISA, MASTERCARD, AMEXCopier le lien vers Tester des transactions CB, VISA, MASTERCARD, AMEX dans le presse-papier
Les règles de simulation suivantes s’appliquent :

le numéro de carte (PAN) doit comporter de 15 à 19 chiffres (selon le moyen de paiement utilisé) ;
les six premiers chiffres du PAN déterminent le type de carte, conformément au tableau ci-dessous ;
Type de carte	Début du numéro de carte
AMEX	340000
VPAY	400000
VISA	410000
CB	420000
Cartes co-badgées CB et VISA	430000
Cartes co-badgées CB et VPAY	440000
Cartes co-badgées CB et VISA_ELECTRON	450000
Cartes co-badgées VISA et MASTERCARD	460000
MAESTRO	500000
MASTERCARD	510000
Cartes co-badgées CB et MASTERCARD	520000
Cartes co-badgées CB et MAESTRO	530000
le code réponse Sherlock's (champ responseCode) est calculé à partir des deux derniers chiffres du numéro de carte ;
le code de sécurité (CVV) comporte 3 ou 4 chiffres. Cette valeur est sans importance pour le résultat de la simulation.
Exemple : si vous utilisez le numéro de carte 4100 0000 0000 0005, la carte sera identifiée comme VISA et le paiement sera refusé (code réponse Sherlock's 05).

Note: si le code réponse Sherlock's calculé n’est pas référencé, la transaction est acceptée (respondeCode = 00).
Les cartes co-badgées peuvent être utilisées avec chacune des marques définies dans le tableau.

Toutes les cartes sont enrôlées 3-D Secure, vous êtes redirigé vers le serveur de simulation 3-D Secure sur lequel vous choisissez le résultat désiré de l’authentification 3-D Secure.

Tester des transactions PayPalCopier le lien vers Tester des transactions PayPal dans le presse-papier
Si vous choisissez de tester PayPal, vous êtes redirigé vers le serveur de simulation qui simule les transactions PayPal selon leur résultat du paiement chez PayPal. Ensuite, vous retournez au serveur de paiement qui affiche le ticket avec le résultat du paiement.

Étape 4 : valider le passage en productionCopier le lien vers Étape 4 : valider le passage en production dans le presse-papier
Une fois la connexion de votre site Web à Sherlock's Paypage JSON testée, vous êtes à présent en mesure de valider la connexion à Sherlock's Paypage JSON de production.

Au préalable, nous conseillons d’isoler votre site Web du public pour éviter que des clients ne génèrent des requêtes pendant cette phase de validation.

Si vous souhaitez personnaliser vos pages de paiement et de gestion de wallet, vous pouvez utiliser notre outil Sherlock's CustomPages, permettant de tester et visualiser le rendu des pages. Pour cela, merci de vous référer à la documentation Sherlock's CustomPages afin d’utiliser l’outil.

Pour basculer sur le serveur de production, vous devez changer l’URL pour vous connecter au serveur Sherlock's de production en utilisant les identifiants merchantId, secretKey et keyVersion reçus lors l’inscription.

URL	https://sherlocks-payment-webinit.secure.lcl.fr/rs-services/v2/paymentInit
merchantId	Identifiant de la boutique reçu par mail
SecretKey	Clé secrète que vous récupérez via l’extranet Sherlock’s Téléchargement
keyVersion	Version clé secrète récupérée sur Sherlock’s Téléchargement (logiquement 1 pour la 1ère clé)
Attention: une erreur fréquente est d’oublier un de ces 4 paramètres, ce qui conduit systématiquement à une erreur.
Comment valider le bon fonctionnement en productionCopier le lien vers Comment valider le bon fonctionnement en production dans le presse-papier
Immédiatement :

faites une transaction avec une carte de paiement réelle (si possible la vôtre). Si la transaction est acceptée, elle sera envoyée en banque pour créditer votre compte commerçant et débiter le compte carte ;
vérifiez que vos pages de paiement intègrent vos paramètres de personnalisation ;
consultez la transaction via Sherlock's Gestion à partir du transactionReference.
Le lendemain :

vérifiez la présence de la transaction dans le journal des transactions ;
vérifiez sur votre compte que l’opération a bien été créditée ;
remboursez la transaction via Sherlock's Gestion (optionnel).
Le surlendemain :

vérifiez que l’opération de remboursement apparaît dans le journal des opérations ;
vérifiez sur votre compte le débit suite au remboursement.
Cette procédure de validation est également applicable au moyen de paiement PayPal.

Étape 5 : démarrer en productionCopier le lien vers Étape 5 : démarrer en production dans le presse-papier
Une fois la validation du passage en production effectuée, ouvrez votre site au public pour permettre à vos clients d’acheter et de payer.

Dans la journée :

surveillez le taux d’acceptation (nombre de responseCode 00 / nombre total de transactions).
vérifiez la nature des refus non bancaires :
problème technique : responseCode 90, 99 ;
fraude : responseCode 34 ;
nombre maximum de tentatives de paiement atteint : responseCode 75 ;
abandon : responseCode 97.
Le lendemain :

vérifiez dans le journal des transactions la présence de toutes les transactions traitées (acceptées et refusées) ;
vérifiez, dans le journal des opérations, les opérations que vous avez effectuées ainsi que les remises (si vous avez choisi cette option du journal).

Sherlocks Paypage Post:
ntroductionCopier le lien vers Introduction dans le presse-papier
Sherlock's est une solution de paiement de commerce électronique multicanale sécurisée conforme à la norme PCI DSS. Elle vous permet d’accepter et de gérer des transactions de paiement en prenant en compte les règles métiers liées à votre activité (paiement à la livraison, paiement différé, paiement récurrent, paiement en plusieurs fois, …).

L’objectif du présent document est d’expliquer la mise en œuvre de la solution Sherlock's Paypage POST jusqu’au démarrage en production.

A qui s’adresse ce documentCopier le lien vers A qui s’adresse ce document dans le presse-papier
Ce document est destiné aux commerçants qui souhaitent souscrire à l’offre Sherlock's et utiliser un connecteur basé sur des échanges HTTPS en mode POST entre leur site web et les serveurs de paiement Sherlock's Paypage POST.

C’est un guide d’implémentation qui s’adresse à votre équipe technique.

Pour avoir une vue d’ensemble de la solution Sherlock's, nous vous conseillons de consulter les documents suivants :

Présentation fonctionnelle
Guide de configuration des fonctionnalités
PrérequisCopier le lien vers Prérequis dans le presse-papier
Une connaissance élémentaire des standards relatifs aux langages de programmation Web pratiqués aujourd’hui, tels que Java, PHP ou .Net, est nécessaire pour développer la connexion à Sherlock's Paypage POST.

Note: toutes les portions de code de ce document sont fournies à titre d’exemple, il convient de les adapter à votre site Web afin qu’elles soient pleinement exploitables.
Gestion de la clé secrèteCopier le lien vers Gestion de la clé secrète dans le presse-papier
Lors de votre inscription, LCL met à disposition sur le Portail Sherlock's (voir la notice de renouvellement des clés secrètes), une clé secrète qui permet de sécuriser les échanges entre votre site et le serveur Sherlock's.

Vous êtes responsable de sa conservation et devez prendre toutes les mesures pour :

en restreindre l'accès ;
la sauvegarder de manière chiffrée ;
ne jamais la copier sur un disque non sécurisé ;
ne jamais l'envoyer (e-mail, courrier) de manière non sécurisée.
La compromission de la clé secrète (et son utilisation par un tiers malveillant) perturberait le fonctionnement normal de votre boutique, et pourrait notamment générer des transactions et des opérations de caisse injustifiées (des remboursements par exemple).

IMPORTANT: en cas de compromission d’une clé secrète, vous êtes tenu d’en demander au plus vite la révocation puis le renouvellement via le Portail Sherlock's (voir la « notice de renouvellement des clés secrètes »).
C’est la même clé secrète qui est utilisée sur les différents connecteurs Sherlock’s Paypage, Sherlock’s Office, Sherlock’s In-App et Sherlock's Walletpage.

IMPORTANT: une clé secrète est associée à une version. Après avoir obtenu une nouvelle clé secrète, vous devez impérativement modifier votre requête et indiquer la nouvelle version dans le champ keyVersion, sans quoi vous obtiendrez un code réponse 34 (suspicion de fraude).
Comprendre le paiement avec Sherlock's Paypage POSTCopier le lien vers Comprendre le paiement avec Sherlock's Paypage POST dans le presse-papier
Le principe général d’un processus de paiement est le suivant :


image sur le principe général d’une cinématique de paiement
agrandir l'imageAgrandir l'image
télécharger l'image
Télécharger l'image
format :
png
taille :
119.28ko

1. Lorsque le client procède au paiement, une requête de paiement doit être envoyée au connecteur Sherlock's Paypage POST. LCL vous fournit l’URL de ce connecteur. La requête est alors vérifiée, et chiffrée si elle est valable (elle est nommée RedirectionData dans le système). La requête est envoyée au moyen d’un formulaire en mode POST via HTTPS. Toute autre solution capable d’envoyer une requête de cette nature fonctionne également.

2. Sherlock's Paypage POST redirige l’application appelante vers les pages de paiement Sherlock's. Le client doit saisir les informations du moyen de paiement pour que le serveur de paiement Sherlock's prenne en charge la transaction. Il convient de noter que les détails du paiement peuvent être saisis directement sur le serveur qui propose le moyen de paiement (par exemple dans le cas de PayPal ou d’un mandat Sepa). À la fin du processus de paiement, qu’il soit réussi ou non, deux réponses sont créées et envoyées à l’adresse URL précisée lors du 1er flux.

Il y a deux notifications de réponses indépendantes :

3. Les réponses manuelles sont envoyées via la méthode HTTP(S) POST par le serveur de paiement à l’URL de réponse manuelle. Cette URL est précisée dans la requête de paiement et est utilisée lorsque le client clique sur le bouton « Continuer » de la page de paiement. Elle est la page de destination vers laquelle le client est redirigé à la fin du paiement. Comme il n’y a aucune garantie que le client clique sur ce bouton, vous n’avez aucune garantie de recevoir la réponse manuelle.

4. Les réponses automatiques sont envoyées indépendamment des réponses manuelles. Elles utilisent également les requêtes HTTP(S) POST envoyées par les serveurs de paiement Sherlock's mais cette fois-ci moyennant l’URL de réponse automatique précisée dans la requête de paiement. Cela signifie que vous recevez la réponse dès que le paiement est effectué dans les pages de paiement Sherlock's.

IMPORTANT: si vous n'avez pas l'option "Nouvelle tentative de paiement (voir partie "Nouvelle tentative de paiement dans le document "Guide de configuration des fonctionnalités"), si le paiement a échoué, et dès que le client est redirigé vers votre site Web, il n’est plus possible de revenir aux pages de paiement Sherlock's pour tenter de payer à nouveau ou pour corriger les données de carte. Le rôle de votre site Web est d’initialiser une nouvelle requête de paiement, en commençant par l’appel au connecteur Sherlock’s Paypage.
Démarrer avec Sherlock's Paypage POST en 5 étapesCopier le lien vers Démarrer avec Sherlock's Paypage POST en 5 étapes dans le presse-papier
Étape 1 : inscrire la boutiqueCopier le lien vers Étape 1 : inscrire la boutique dans le presse-papier
Afin d’inscrire votre boutique, vous devez remplir le formulaire d’inscription envoyé par LCL et le retourner à ce dernier.

Lors de la saisie du formulaire, vous désignez un contact administratif et un contact technique afin que LCL puisse vous communiquer les informations nécessaires pour démarrer votre boutique.

LCL procède alors à l’enregistrement de la boutique et vous retourne votre identifiant commerçant (merchantId) ainsi que vos identifiants et mots de passe Portail Sherlock's (récupération de la clé secrète et gestion de caisse).

Note: Pour Portail Sherlock's, les informations de connexion sont envoyées au contact administratif.
L’inscription de la boutique n’est pas nécessaire pour commencer à intégrer le connecteur et à tester la connexion sur l’environnement de simulation. Vous pouvez ne demander l’inscription de votre boutique qu’au moment de faire les tests en production.

Étape 2 : effectuer un paiementCopier le lien vers Étape 2 : effectuer un paiement dans le presse-papier
La requête paiement est envoyée depuis une page de votre site web vers le serveur Sherlock's via un formulaire web avec la méthode POST.

Générer la requête de paiementCopier le lien vers Générer la requête de paiement dans le presse-papier
Trois données obligatoires sont renseignées dans la requête de paiement.

Nom de la donnée	Description
Data	Contient toutes les informations relatives à la transaction.
InterfaceVersion	Définit la version de la requête et de la réponse échangée avec le serveur Sherlock's.
Seal	Utilisé pour valider l’intégrité des données échangées. La donnée Seal est calculée à l’aide de la donnée Data et de la clé secrète.
Des données optionnelles supplémentaires sont disponibles :

Nom de la donnée	Description
Encode	Précise la méthode utilisée pour encoder la donnée Data.
SealAlgorithm	Précise l’algorithme utilisé pour calculer la donnée Seal.
Syntaxe de la donnée DataCopier le lien vers Syntaxe de la donnée Data dans le presse-papier
La donnée Data est construite conformément au format suivant :

<nomChamp1>=<valeurChamp1>|<nomChamp2>=<valeurChamp2>|…|<nomChampN>=<valeurChampN>
Copy
Tous les champs nécessaires pour la transaction (voir les détails dans le dictionnaire de données) doivent être inclus dans la chaîne de caractères. L’ordre des champs n’a pas d’importance.

Exemple d’une requête de paiement de 55 euros :

amount=5500|currencyCode=978|merchantId=011223744550001|normalReturnUrl=http://www.normalreturnurl.com|transactionReference=534654|keyVersion=1
Copy
Il est possible d’avoir une liste de valeurs pour un même champ :

..|nomChamp=valeur1,valeur2, … ,valeurX|…
Copy
Exemple avec le champ paymentMeanBrandList valorisé avec VISA et MASTERCARD :

…|amount=5500|currencyCode=978|merchantId=011223744550001|normalReturnUrl=http://www.normalreturnurl.com|transactionReference=534654[paymentMeanBrandList=VISA,MASTERCARD|keyVersion=1|…
Copy
Si le champ est un container, vous devez utiliser un point entre le nom du container et le nom du champ :

..|Container.nomChamp1=valeurChamp1|container.nomChamp2=valeurChamp2|……
Copy
Exemple pour le champ customerContact contenant l’email moi@email.com et le nom et prénom Jean Dupont du client :

…|customerContact.email=moi@email.com|customerContact.firstname=Jean|customerContact.lastname=Dupont|…
Copy
Si un champ contient une liste d’objets complexes, sa représentation est construite conformément au format suivant :

..|<champ1>=<valeur1>| <nomObjet>.<nomItem= {<nomChampA1>=<valeurChampA1>,<nomChampA2>=<valeurChampA2>}, {<nomChampB1>=<valeurChampB1>,<nomChampB2>=<valeurChampB2>}, {<nomChampC1>=<valeurChampC1>,<nomChampC2>=<valeurChampC2>}| <nomChamp2>=<valeurChamp2>|……
Copy
Exemple d’une requête de paiement avec une liste d’objets complexes pour le champ shoppingCartDetail contenant trois produits nommés apple, mango et pear :

amount=5500|currencyCode=978|merchantId=011223744550001|normalReturnUrl=http://www.normalreturnurl.com
|transactionReference=534654|shoppingCartDetail.shoppingCartItemList={productName=apple,
productDescription=red},{productName=pear,productDescription=green},{productName=mango,productDescription=yellow}|keyVersion=1
Copy
Encodage de la donnée DataCopier le lien vers Encodage de la donnée Data dans le presse-papier
Si la donnée Data comporte des caractères spéciaux (comme par exemple des caractères accentués) alors elle doit être encodée en base64 ou base64Url.

Note: puisque le calcul de la signature se fait avec la donnée Data, il convient de noter que c’est la valeur Data encodée qui est utilisée pour la signature de la requête.
Présence des champs de la requêteCopier le lien vers Présence des champs de la requête dans le presse-papier
Certains champs de la requête de paiement ne sont obligatoires que :

lors de l'utilisation de certains moyens de paiement ; veuillez consulter le guide du moyen de paiement concerné pour savoir quels champs sont obligatoires ;
en fonction de la configuration de votre boutique ; veuillez consulter le Guide de configuration des fonctionnalités pour savoir quels champs sont obligatoires ;
dans certains cas d'usages (ex : paiement récurrent) ; veuillez consulter le Guide de configuration des fonctionnalités pour savoir quels champs sont obligatoires.
Ces champs sont désignés avec la mention « conditionnel ».

Sécuriser la requêteCopier le lien vers Sécuriser la requête dans le presse-papier
La requête contient les paramètres de la transaction et est envoyée par le navigateur Web du client. Il est théoriquement possible pour un pirate d’intercepter la demande et de la modifier avant l’envoi au serveur de paiement.

De ce fait, il est nécessaire de renforcer la sécurité pour assurer l’intégrité des paramètres de la transaction envoyée. Sherlock's répond à ce besoin par un échange de signatures qui permet de vérifier :

l’intégrité des messages requête et réponse ;
l’authentification de l’émetteur et du destinataire car ils se partagent la même clé secrète.
IMPORTANT: si votre clé secrète est compromise, ou si vous supposez que c’est le cas, vous devez impérativement demander son renouvellement en vous connectant à Sherlock’s Téléchargement.
Comment sécuriser la requêteCopier le lien vers Comment sécuriser la requête dans le presse-papier
La sécurisation de la requête est effectuée en calculant la valeur « hashée » conformément aux paramètres de la transaction (donnée Data). Ensuite, la clé secrète y est ajoutée. Toutes les chaînes de caractères sont converties en UTF-8 avant le « hashage ».

L’algorithme de « hashage » génère un résultat irréversible. Lorsqu’un tel message est reçu, le destinataire doit recalculer la valeur « hashée » pour la comparer à celle reçue. Toute différence indique que les données échangées ont été falsifiées ou que le destinataire et l’émetteur ne partagent pas la même clé secrète.

Le résultat doit être envoyé sous forme hexadécimale dans la donnée nommée Seal.

Calcul de la donnée SealCopier le lien vers Calcul de la donnée Seal dans le presse-papier
Algorithme HMAC-SHACopier le lien vers Algorithme HMAC-SHA dans le presse-papier
La valeur de la donnée Seal est calculée comme suit :

Contenu du champ Data envoyé dans le formulaire POST. Donnant la donnée data, mentionnée dans les exemples ci-dessous;
Codage UTF-8 des données constituant le résultat de l’opération précédente
HMAC avec chiffrement SHA256 des octets obtenus avec la clé secrète.
Cette procédure peut être résumée comme suit :

HMAC-SHA256( UTF-8(Data), UTF-8(secretKey))
Copy
Attention: par défaut, le sceau est calculé avec l'algorithme SHA-256.
Pour que le sceau soit calculé avec l'algorithme HMAC-SHA-256, dont nous recommandons vivement l'utilisation, les paramètres d'entrée de la requête doivent contenir le champ sealAlgorithm avec la valeur suivante : “HMAC-SHA-256”.

Exemples de code Hmac Sha256Copier le lien vers Exemples de code Hmac Sha256 dans le presse-papier
Exemple d’encodage Hmac Sha256 en Php 5
<?php

…

// Seal computation thanks to hash sorted data hash with merchant key

$data_to_send= utf8_encode($data)

$seal=hash_hmac('sha256', $data_to_send, $secretKey);

…
…

?>
Copy
data_to_send et secretKey doivent utiliser un jeu de caractères UTF-8. Référez-vous à la fonction utf8_encode pour la conversion de caractères ISO-8859-1 en UTF-8.

Exemple d’encodage Hmac Sha256 en Java
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class ExampleHMACSHA256 {

/**
 * table to convert a nibble to a hex char.
 */
static final char[] hexChar = {
   '0' , '1' , '2' , '3' ,
   '4' , '5' , '6' , '7' ,
   '8' , '9' , 'a' , 'b' ,
   'c' , 'd' , 'e' , 'f'};

/**
 * Fast convert a byte array to a hex string
 * with possible leading zero.
 * @param b array of bytes to convert to string
 * @return hex representation, two chars per byte.
 */
public static String encodeHexString ( byte[] b )
   {
   StringBuffer sb = new StringBuffer( b.length * 2 );
   for ( int i=0; i<b.length; i++ )
      {
      // look up high nibble char
      sb.append( hexChar [( b[i] & 0xf0 ) >>> 4] );

      // look up low nibble char
      sb.append( hexChar [b[i] & 0x0f] );
      }
   return sb.toString();
   }

/**
 * Computes the seal
 * @param Data the parameters to cipher
 * @param secretKey the secret key to append to the parameters
 * @return hex representation of the seal, two chars per byte.
 */
public static String computeSeal(String data, String secretKey) throws Exception
{
  Mac hmacSHA256 = Mac.getInstance("HmacSHA256");
  SecretKeySpec keySpec = new SecretKeySpec(secretKey.getBytes(), "HmacSHA256");
  hmacSHA256.init(keySpec);

  return encodeHexString(hmacSHA256.doFinal(data.getBytes()));
}

/**
 * @param args
 */
public static void main(String[] args) {
try {
System.out.println (computeSeal("parameters", "key"));
} catch (Exception e) {
e.printStackTrace();
}
}

}
Copy
Exemple d’encodage Hmac Sha256 en .net
(Exemple effectué à l’aide d’un simple formulaire nommé « Form1 » contenant deux champs texte pour saisir data et txtSecretKey, ainsi qu’un autre champ pour afficher lblHEX).

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.Security.Cryptography;

namespace ExampleDotNET
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void cmdGO_Click(object sender, EventArgs e)
        {
            String sChaine = data.Text;
            UTF8Encoding utf8 = new UTF8Encoding();
            Byte[] encodedBytes = utf8.GetBytes(sChaine);

            byte[] shaResult;

            HMAC hmac = new HMAC.Create("HMACSHA256");
            var key = "YourSecretKey";
            hmac.Key = utf8.GetBytes(key);
            hmac.Initialize();

            shaResult = hmac.ComputeHash(encodedBytes);

            lblHEX.Text = ByteArrayToHEX(shaResult);
        }

        private string ByteArrayToHEX(byte[] ba)
        {
            StringBuilder hex = new StringBuilder(ba.Length * 2);
            foreach (byte b in ba)
                hex.AppendFormat("{0:x2}", b);
            return hex.ToString();
        }

    }
}
Copy
Validation du calcul de sealCopier le lien vers Validation du calcul de seal dans le presse-papier
Une fois votre calcul de seal mis en place, voici un exemple de requête vous permettant de vérifier que vous retrouvez bien le bon seal :

automaticResponseURL=https://automatic-response-url.fr/|normalReturnURL=https://normal-return-url/|captureDay=0|captureMode=AUTHOR_CAPTURE|merchantId=011223344550000|amount=2500|orderId=ORD101|currencyCode=978|transactionReference=TREFEXA2012|keyVersion=1|transactionOrigin=SO_WEBAPPLI|returnContext=ReturnContext|orderChannel=INTERNET|customerContact.email=customer@email.com
Copy
Pour la requête ci-dessus, avec un algorithme de hachage SHA-256 et une clé secrète valant :

secret123
Copy
Le seal attendu est :

ac2332b57a674aba5b28a03dae677fa2f4c1ae8a349ebbdd6772a098c7f29861
Copy
Algorithme SHA-256Copier le lien vers Algorithme SHA-256 dans le presse-papier
La valeur de la donnée Seal est calculée comme suit :

concaténation de la donnée Data et de la clé secrète (encodée si l’option correspondante est choisie) ;
codage UTF-8 des données constituant le résultat de l’opération précédente ;
« hashage » SHA256 des octets obtenus.
Cette procédure peut être résumée comme suit :

SHA256( UTF-8(Data+secretKey ) )
Copy
Exemples de code Sha256Copier le lien vers Exemples de code Sha256 dans le presse-papier
Exemple d’encodage Sha256 en Php 5
<?php
echo hash('sha256', $data.$secretKey);
?>
Copy
Le jeu de caractères UTF-8 doit être utilisé pour les données Data et secretKey. Pour effectuer une conversion de ISO-8859-1 à UTF-8, faites appel à la fonction utf8_encode.

Exemple d’encodage Sha256 en Java
import java.security.MessageDigest;

public class ExampleSHA256 {

/**
 * table to convert a nibble to a hex char.
 */
static final char[] hexChar = {
   '0' , '1' , '2' , '3' ,
   '4' , '5' , '6' , '7' ,
   '8' , '9' , 'a' , 'b' ,
   'c' , 'd' , 'e' , 'f'};

/**
 * Fast convert a byte array to a hex string
 * with possible leading zero.
 * @param b array of bytes to convert to string
 * @return hex representation, two chars per byte.
 */
public static String encodeHexString ( byte[] b )
   {
   StringBuffer sb = new StringBuffer( b.length * 2 );
   for ( int i=0; i<b.length; i++ )
      {
      // look up high nibble char
      sb.append( hexChar [( b[i] & 0xf0 ) >>> 4] );

      // look up low nibble char
      sb.append( hexChar [b[i] & 0x0f] );
      }
   return sb.toString();
   }

/**
 * Computes the seal
 * @param Data the parameters to cipher
 * @param secretKey the secret key to append to the parameters
 * @return hex representation of the seal, two chars per byte.
 */
public static String computeSeal(String Data, String secretKey) throws Exception
{
  MessageDigest md = MessageDigest.getInstance("SHA-256");
  md.update((Data+secretKey).getBytes("UTF-8"));

  return encodeHexString(md.digest());
}

/**
 * @param args
 */
public static void main(String[] args) {
try {
System.out.println (computeSeal("parameters", "key"));
} catch (Exception e) {
e.printStackTrace();
}
}
}
Copy
Exemple d’encodage Sha256 en .NET
Exemple complété à l’aide d’un simple formulaire appelé « Form 1 » contenant deux champs de texte à renseigner : data, txtSecretKey et un autre à afficher : lblHEX.

using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using System.Security.Cryptography;

namespace ExampleDotNET
{
    public partial class Form1 : Form
    {
        public Form1()
        {
            InitializeComponent();
        }

        private void cmdGO_Click(object sender, EventArgs e)
        {
            String sChaine = data.Text + txtSecretKey.Text;
            UTF8Encoding utf8 = new UTF8Encoding();
            Byte[] encodedBytes = utf8.GetBytes(sChaine);

            byte[] shaResult;
            SHA256 shaM = new SHA256Managed();
            shaResult = shaM.ComputeHash(encodedBytes);

            lblHEX.Text = ByteArrayToHEX(shaResult);
        }

        private string ByteArrayToHEX(byte[] ba)
        {
            StringBuilder hex = new StringBuilder(ba.Length * 2);
            foreach (byte b in ba)
                hex.AppendFormat("{0:x2}", b);
            return hex.ToString();
        }

    }
}
Copy
Traiter les erreurs lors de l’initialisation du paiementCopier le lien vers Traiter les erreurs lors de l’initialisation du paiement dans le presse-papier
Tous les champs reçus par Sherlock's Paypage POST à travers le connecteur font l’objet d’une vérification individuelle. Le tableau ci-dessous présente la liste des messages d’erreur pouvant s’afficher lors de cette étape ainsi que les solutions à mettre en œuvre.

Note: les messages sont affichés sur la plate-forme de simulation pour vous aider à valider l’intégration de votre site Web. Pour des raisons de sécurité, des messages d’erreur beaucoup plus simples sont affichés sur la plate-forme de production. Ex « Erreur lors du traitement de la requête de paiement. Contactez votre commerçant ».
Message	Cause	Solution
Unknown version interface: <version>

La valeur <version> dans le champ InterfaceVersion est inconnue.	Vérifier la version d’interface dans ce guide d’utilisation (la version actuelle est la version HP_2.57).
Invalid keyword: <nomChamp>= <valeur Champ>

Le champ <nomChamp> n’est pas prévu dans la requête de paiement.	Vérifier le nom des champs dans le chapitre ci-dessous et dans le dictionnaire de données.
Invalid field size: <nomChamp>= <valeur Champ>

Le champ <nomChamp> a une longueur incorrecte.	Vérifier la longueur du champ dans le dictionnaire de données.
Invalid field value: <nomChamp >= <valeur Champ>

La valeur du champ <nomChamp> est incorrecte.	Vérifier les valeurs possibles du champ dans le dictionnaire de données.
Mandatory field missing: <nomChamp >

Le champ <nomChamp> est manquant dans la requête de paiement.	Vérifier les champs obligatoires de la requête de paiement dans le chapitre ci-dessous.
Unknown security version: <version>

La valeur <version> du champ keyVersion est inconnue.	Vérifier les versions des clés disponibles dans Sherlock’s Téléchargement.
Invalid signature

La vérification du Seal de la requête de paiement a échoué. Cela peut être dû à un calcul incorrect de la donnée Seal ou à la falsification de certains champs après le calcul de la signature.	Vérifier que le calcul du Seal est effectué comme indiqué dans le chapitre précédent. Si c’est le cas, demander un changement de clé secrète via Sherlock’s Téléchargement car la requête a été falsifiée.
Transaction already processed: <référence de la transaction>

Une requête de paiement avec le même transactionReference a déjà été reçue et prise en charge par les serveurs Sherlock's.	Vérifier si la valeur du champ transactionReference est unique pour la transaction concernée.
<Autres messages>

Dans le cas d’erreurs techniques, d’autres messages différents peuvent s’afficher.	Contacter le service d’assistance technique.
Traiter la réponse aux erreurs d’initialisation du paiementCopier le lien vers Traiter la réponse aux erreurs d’initialisation du paiement dans le presse-papier
En cas d'erreur lors de l'initialisation du paiement, l'envoi d'une réponse manuelle et/ou automatique peut être activé en fonction de votre configuration. Vous devez pour cela contacter l'assistance technique qui activera cette fonctionnalité.

Deux types de réponse sont prévus. Bien que les protocoles, formats et contenus des deux réponses soient exactement les mêmes, elles doivent être gérées de manière différente car elles répondent à deux besoins différents.

Les réponses aux erreurs d’initialisation de paiement sont des réponses HTTP(S) POST envoyées aux URL renseignées au travers des champs manualErrorResponseInitPOST (optionnel) et automaticErrorResponseInitPOST (optionnel) précisées dans la requête.

Si vous souhaitez utiliser ces réponses, vous devez mettre en place le système permettant de les décoder, afin de connaître la raison de l’erreur rencontrée. Les deux données suivantes sont définies dans les réponses :

Nom du champ	Notes/règles
Data	Concaténation des champs en réponse
Seal	Signature du message réponse
La chaîne concaténée est structurée comme suit :

redirectionStatusCode | redirectionStatusMessage | merchantId | transactionReference | transactionId | transactionDate | transactionDateTime | amount | customerId | orderId | customerIpAddress

Voici un exemple de donnée Data :

redirectionStatusCode=12|redirectionStatusMessage=currencyCode contains invalid chars : [abc]|merchantId= 024729465300012|transactionReference= SIM20180118155728|transactionId=12345|transactionDate=20180412|transactionDateTime= 2018-04-12T10:14:31+02:00|amount=1000|customerId=CU-123|orderId=orderId1|customerIpAddress=127.0.0.1
Copy
Cette chaîne concaténée est convertie en UTF-8 avant le « hashage ».

Le sceau (donnée Seal) des 2 réponses est « hashé » avec le même algorithme utilisé en entrée et fourni dans le champ sealAlgorithm. Si aucune valeur n’a été définie, la valeur SHA-256 est utilisée par défaut.

Renseigner l’URL de la réponse manuelle aux erreurs d’initialisation du paiementCopier le lien vers Renseigner l’URL de la réponse manuelle aux erreurs d’initialisation du paiement dans le presse-papier
L’objectif principal de la réponse manuelle aux erreurs d’initialisation de paiement est de rediriger le client vers votre site web avec la raison de l’erreur pour que vous puissiez prendre la bonne décision le concernant. Par exemple, en cas d’erreur sur une donnée renseignée par le client, vous pouvez lui suggérer de retenter le paiement avec un format correct. Dans le cas d’une erreur sur une donnée indépendante du client, vous pouvez l’inviter à vous contacter pour résoudre la situation.

À la première étape, un bouton « Retour » est affiché sur la page d’erreur chez Sherlock's avec un lien de redirection vers votre site. Lorsque le client clique sur ce bouton, le serveur Sherlock's le redirige vers l’adresse URL contenue dans le champ manualErrorResponseInitPOST fourni dans la requête. La redirection est une requête HTTP(S) POST qui contient les données de la réponse, tels que décrits ci-dessus. Il est de votre responsabilité de récupérer ces paramètres et de vérifier la signature pour ainsi assurer l’intégrité des données de la réponse. De plus, vous avez la responsabilité d’afficher les messages pertinents (relatifs aux détails de la réponse) à votre client.

Il est important de noter qu’il est impossible de garantir la réception de la réponse, celle-ci étant envoyée par le navigateur web du client. Tout d’abord, le client a la possibilité de ne pas cliquer sur le lien. Ensuite, la connexion qu’il utilise peut tout simplement avoir un problème et bloquer l’envoi de cette réponse. Par conséquent, celle-ci ne peut pas constituer la base unique pour vos processus métier.

Renseigner l’URL de la réponse automatique aux erreurs d’initialisation du paiementCopier le lien vers Renseigner l’URL de la réponse automatique aux erreurs d’initialisation du paiement dans le presse-papier
La réponse automatique est envoyée seulement si le champ automaticErrorResponseInitPOST a été envoyé dans la requête de paiement. Si tel est le cas, le serveur Sherlock's envoie une réponse HTTP(S) POST à l’adresse URL reçue.

Les champs de la réponse automatique sont identiques à ceux de la réponse manuelle. La seule différence entre les deux procédures est que la réponse automatique est envoyée directement par le serveur Sherlock's sans passer par le navigateur Web du client. Par conséquent, elle est bien plus fiable car elle est toujours envoyée. Le serveur Sherlock's n’attend aucune réponse après l’envoi de la réponse automatique.

Il vous appartient de récupérer les différentes données de la réponse, vérifier la signature pour vous assurer de l’intégrité des champs de la réponse et, par conséquent, mettre à jour votre back office.

Résoudre les problèmes de réception des réponses aux erreurs d’initialisationCopier le lien vers Résoudre les problèmes de réception des réponses aux erreurs d’initialisation dans le presse-papier
Comme pour les réponses manuelle et automatique de paiement, ces réponses peuvent être bloquées. Les mêmes conseils s’appliquent pour résoudre ces problèmes (voir chapitre [Résoudre les problèmes de réception des réponses]).

Récupérer les champs des réponses aux erreurs d’initialisationCopier le lien vers Récupérer les champs des réponses aux erreurs d’initialisation dans le presse-papier
Le contenu des réponses automatique et manuelle aux erreurs d’initialisation de Sherlock’s Paypage est invariable. Quelle que soit l’erreur rencontrée lors de l’initialisation de paiement, la réponse contiendra les champs suivants :

Champ	Commentaires
redirectionStatusCode	
redirectionStatusMessage	
merchantId	idem requête
transactionReference	
transactionId	
transactionDate	
transactionDateTime	
amount	idem requête
customerId	idem requête
orderId	idem requête
customerIpAddress	idem requête
Renseigner les champs de la requêteCopier le lien vers Renseigner les champs de la requête dans le presse-papier
La requête et la réponse de la méthode paymentWebInit sont décrites sur cette page dédiée.

Paramétrer la requête de paiementCopier le lien vers Paramétrer la requête de paiement dans le presse-papier
Voici un exemple de paramétrage de la requête de paiement pour chaque fonctionnalité disponible dans Sherlock's Paypage POST (le détail de ces fonctionnalités est décrit dans le guide de configuration des fonctionnalités).

Affichage dynamique des moyens de paiementCopier le lien vers Affichage dynamique des moyens de paiement dans le presse-papier
Il faut filtrer ceux qui s’afficheront dans la page de sélection des moyens de paiement grâce au champ paymentMeanBrandList :

..|paymentMeanBrandList=VISA,PAYPAL|..
Copy
Affichage du ticket par Sherlock'sCopier le lien vers Affichage du ticket par Sherlock's dans le presse-papier
La page de confirmation du paiement, affichée par défaut par Sherlock's peut être désactivée. Cette désactivation se fait par le champ paypageData.bypassReceiptPage :

..|paypageData.bypassReceiptPage=Y|..
Copy
Canal de paiementCopier le lien vers Canal de paiement dans le presse-papier
Pour choisir votre canal de paiement, vous devez remplir le champ orderChannel dans la requête de paiement :

…|orderChannel= INTERNET|..
Copy
Paiement en fin de journéeCopier le lien vers Paiement en fin de journée dans le presse-papier
Dans le cas d’un paiement en fin de journée, il suffit de remplir les champs captureMode et captureDay :

…|captureDay=0|captureMode=AUTHOR_CAPTURE|..
Copy
Paiement différéCopier le lien vers Paiement différé dans le presse-papier
Dans le cas d’un paiement à remiser N jours après l’acceptation en ligne, il suffit de remplir les champs captureMode et captureDay (3 jours dans notre exemple) :

…|captureDay=3|captureMode=AUTHOR_CAPTURE|..
Copy
Pour des cas de paiements différés plus complexes, notamment avec des envois multiples ou un envoi au-delà de 6 jours, veuillez vous référer au guide paiement multiple à l'expédition.

Paiement à l’expéditionCopier le lien vers Paiement à l’expédition dans le presse-papier
Dans le cas d’un paiement à l’expédition, la transaction est envoyée en paiement lors votre validation, il faut juste remplir les champs captureMode et captureDay (3 jours de délai possible avant validation dans notre exemple) :

…|captureDay=3|captureMode=VALIDATION|..
Copy
Paiement en plusieurs foisCopier le lien vers Paiement en plusieurs fois dans le presse-papier
Dans le cas d’un paiement en plusieurs échéances liées à une même transaction, il faut renseigner le champ paymentPattern à INSTALMENT et fournir le détail des échéances dans le champ instalmentData (600€ payés en 3 échéances dans notre exemple) :

…|amount=60000|…|transactionReference=tref1|…|paymentPattern=INSTALMENT|instalmentData.number
=3|instalmentData.datesList=20170412,20170512,20170612|instalmentData.transactionReferencesList
=tref1,tref2,tref3|instalmentData.amountsList=10000,30000,20000|..
Copy
Paiement immédiatCopier le lien vers Paiement immédiat dans le presse-papier
Si vous souhaitez un paiement immédiat (disponible uniquement pour certains moyens de paiement), la transaction est payée lors de l’autorisation en ligne :

…|captureMode=IMMEDIATE|..
Copy
Acceptation multideviseCopier le lien vers Acceptation multidevise dans le presse-papier
Dans le cas des transactions multidevises le code devise doit être spécifié dans la requête. C’est dans le contrat d’acquisition où est précisée la devise de règlement.

…|currencyCode=840|..
Copy
Règlement en devisesCopier le lien vers Règlement en devises dans le presse-papier
L’acceptation et le règlement sont effectués dans la même devise qui doit être spécifiée dans la requête. Le règlement en devises est une option du contrat d’acquisition.

…|currencyCode=826|..
Copy
Inscription et paiement OneClickCopier le lien vers Inscription et paiement OneClick dans le presse-papier
Pour un paiement OneClick, l’identifiant du wallet du client doit être renseigné dans le champ merchantWalletId.

…|merchantWalletId=1205987|..
Copy
Prestataire agissant pour le compte d’un commerçantCopier le lien vers Prestataire agissant pour le compte d’un commerçant dans le presse-papier
Il faut passer l’identifiant du prestataire dans la requête dans le champ intermediateServiceProvider et utiliser la clé secrète de ce dernier pour calculer la donnée Seal :

..|intermediateServiceProviderId=241591|..
Copy
Traiter la réponseCopier le lien vers Traiter la réponse dans le presse-papier
Deux types de réponse sont prévus. Bien que les protocoles, formats et contenus des deux réponses soient exactement les mêmes, elles doivent être gérées de manière différente car elles répondent à deux besoins différents.

Les réponses sont des réponses HTTP(S) POST envoyées aux URL normalReturnUrl (obligatoire - réponse manuelle) et automaticResponseUrl (optionnelle - réponse automatique) précisées dans la requête.

Vous devez mettre en place le système permettant de décoder ces réponses, afin de connaître le résultat de requête.

Les quatre données suivantes sont définies dans les réponses :

Données	Notes/règles
Data	Concaténation des champs en réponse.
Encode	Type d’encodage utilisé pour la donnée Data. Ce champ est valorisé avec le champ responseEncoding de la requête.
Seal	Signature du message réponse.
InterfaceVersion	Version de l’interface du connecteur.
IMPORTANT: Il est important de ne pas trier les données du champ Data pour calculer le Seal de la réponse. Conservez les champs dans l'ordre dans lequel vous les avez reçu.
Si la valeur du champ Encode est “base64” ou “base64url”, la donnée Data doit-être décodée en Base64/Base64Url pour retrouver la chaîne des champs concaténée. La chaîne concaténée est structurée comme suit : clé1=valeur1|clé2=valeur2… Le sceau (donnée Seal) des 2 réponses est « hashé » avec le même algorithme utilisé en entrée et fourni dans le champ sealAlgorithm. Si aucune valeur n’a été définie, la valeur SHA-256 est utilisée par défaut.

IMPORTANT: pour qu’un sceau soit calculé avec l'algorithme HMAC-SHA-256, les paramètres d'entrée de la requête doivent contenir le champ sealAlgorithm avec la valeur suivante : “HMAC-SHA-256”.
La valeur de la donnée Seal est calculée comme suit :

Pour l'algorithme HMAC-SHA :

utilisation de la clé secrète partagée pour générer la variante HMAC du message ;
utilisation de la donnée Data uniquement (encodée si l’option correspondante est choisie) ;
codage UTF-8 des données constituant le résultat de l’opération précédente ;
« Hashage » HMAC-SHA des octets obtenus.
Cette procédure peut être résumée comme suit :

HMAC-SHA256( UTF-8(Data), UTF-8(secretKey))
Copy
Exemple de Seal calculé avec une clé secrète égale à "secret123" et la donnée Data au format POST ci-dessous:

captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=039000254447216|orderChannel=INTERNET|responseCode=00|transactionDateTime=2022-11-14T11:21:12+01:00|transactionReference=SIM20221114112037|keyVersion=1|acquirerResponseCode=00|amount=1000|authorisationId=664865|guaranteeIndicator=N|panExpiryDate=202401|paymentMeanBrand=VISA|paymentMeanType=CARD|customerIpAddress=10.78.106.18|maskedPan=############0600|holderAuthentRelegation=N|holderAuthentStatus=NOT_PARTICIPATING|tokenPan=490700h719850600|transactionOrigin=SIMS|paymentPattern=ONE_SHOT|customerMobilePhone=null|mandateAuthentMethod=null|mandateUsage=null|transactionActors=null|mandateId=null|captureLimitDate=20221114|dccStatus=null|dccResponseCode=null|dccAmount=null|dccCurrencyCode=null|dccExchangeRate=null|dccExchangeRateValidity=null|dccProvider=null|statementReference=null|panEntryMode=MANUAL|walletType=null|holderAuthentMethod=NO_AUTHENT_METHOD|holderAuthentProgram=3DS_V2|paymentMeanId=null|instalmentNumber=null|instalmentDatesList=null|instalmentTransactionReferencesList=null|instalmentAmountsList=null|settlementMode=null|mandateCertificationType=null|valueDate=null|creditorId=null|acquirerResponseIdentifier=null|acquirerResponseMessage=null|paymentMeanTradingName=null|additionalAuthorisationNumber=null|issuerWalletInformation=null|s10TransactionId=6|s10TransactionIdDate=20221114|preAuthenticationColor=null|preAuthenticationInfo=null|preAuthenticationProfile=null|preAuthenticationThreshold=null|preAuthenticationValue=null|invoiceReference=null|s10transactionIdsList=null|cardProductCode=F|cardProductName=VISA CLASSIC|cardProductProfile=C|issuerCode=00000|issuerCountryCode=GRC|acquirerNativeResponseCode=00|settlementModeComplement=null|preAuthorisationProfile=null|preAuthorisationProfileValue=null|preAuthorisationRuleResultList=[{"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},{"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}]|preAuthenticationProfileValue=null|preAuthenticationRuleResultList=null|paymentMeanBrandSelectionStatus=NOT_APPLICABLE|transactionPlatform=PROD|avsAddressResponseCode=null|avsPostcodeResponseCode=null|customerCompanyName=null|customerBusinessName=null|customerLegalId=null|customerPositionOccupied=null|paymentAttemptNumber=1|holderContactEmail=null|installmentIntermediateServiceProviderOperationIdsList=null|holderAuthentType=null|acquirerContractNumber=3863090010|secureReference=null|authentExemptionReasonList=null|paymentAccountReference=a667b63d8bec4fb980106497c53e4|schemeTransactionIdentifier=b4e683c1a6ff4a09a0415116a0a25b401d38c19d24e643078d|guaranteeLimitDateTime=null|paymentMeanDataProvider=null|virtualCardIndicator=N|cardProductUsageLabel=CREDIT|authorisationTypeLabel=TRANSACTION DE PAIEMENT|authorMessageReference=272612|acceptanceSystemApplicationId=142000000001|challengeMode3DS=null|issuingCountryCode=GRC|abortedProcessingStep=null|abortedProcessingLocation=null
Copy
Le Seal que vous devez obtenir est c946655cce0059124b4ad3eb62c0922c51a0a7d8d28a3cf223e4c0da41bbc5b9

Exemple de Seal calculé avec une clé secrète égale à "secret123" et la donnée Data au format JSON ci-dessous:

{"keyVersion":1,"amount":44000,"captureDay":0,"captureMode":"AUTHOR_CAPTURE","currencyCode":"978","customerId":"40813","customerIpAddress":"213.118.246.190","merchantId":"225005049920001","orderAmount":44000,"orderChannel":"INTERNET","responseCode":"97","responseDescription":"Request time-out; transaction refused","transactionDateTime":"2023-03-15.00:39:04+0100","transactionReference":"dd88adfZ1027b40813f40813y1678837075","statementReference":"T7Ft4KKLRA2M11B9","s10TransactionId":"6","s10TransactionIdDate":"20230315","sealAlgorithm":"sha256","transactionPlatform":"PROD","paymentAttemptNumber":2,"preAuthorisationRuleResultList":[{"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},{"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}]}
Copy
Le Seal que vous devez obtenir est 77be1c230491c0d4eef6eaf910f635d42f55c90cd34c5a162c0ef6fcefb3f087

Pour l’algorithme SHA-256 (bien que celui-ci soit la valeur par défaut, cet algorithme n’est plus recommandé à ce jour) :

concaténation de la donnée Data et de la clé secrète (encodée si l’option correspondante est choisie) ;
codage UTF-8 des données constituant le résultat de l’opération précédente ;
« Hashage » SHA256 des octets obtenus.
Cette procédure peut être résumée comme suit :

SHA256( UTF-8(Data+secretKey ) )
Copy
Exemple de Seal calculé avec une clé secrète égale à "secret123" et la donnée Data au format POST ci-dessous:

captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=039000254447216|orderChannel=INTERNET|responseCode=00|transactionDateTime=2022-11-14T11:21:12+01:00|transactionReference=SIM20221114112037|keyVersion=1|acquirerResponseCode=00|amount=1000|authorisationId=664865|guaranteeIndicator=N|panExpiryDate=202401|paymentMeanBrand=VISA|paymentMeanType=CARD|customerIpAddress=10.78.106.18|maskedPan=############0600|holderAuthentRelegation=N|holderAuthentStatus=NOT_PARTICIPATING|tokenPan=490700h719850600|transactionOrigin=SIMS|paymentPattern=ONE_SHOT|customerMobilePhone=null|mandateAuthentMethod=null|mandateUsage=null|transactionActors=null|mandateId=null|captureLimitDate=20221114|dccStatus=null|dccResponseCode=null|dccAmount=null|dccCurrencyCode=null|dccExchangeRate=null|dccExchangeRateValidity=null|dccProvider=null|statementReference=null|panEntryMode=MANUAL|walletType=null|holderAuthentMethod=NO_AUTHENT_METHOD|holderAuthentProgram=3DS_V2|paymentMeanId=null|instalmentNumber=null|instalmentDatesList=null|instalmentTransactionReferencesList=null|instalmentAmountsList=null|settlementMode=null|mandateCertificationType=null|valueDate=null|creditorId=null|acquirerResponseIdentifier=null|acquirerResponseMessage=null|paymentMeanTradingName=null|additionalAuthorisationNumber=null|issuerWalletInformation=null|s10TransactionId=6|s10TransactionIdDate=20221114|preAuthenticationColor=null|preAuthenticationInfo=null|preAuthenticationProfile=null|preAuthenticationThreshold=null|preAuthenticationValue=null|invoiceReference=null|s10transactionIdsList=null|cardProductCode=F|cardProductName=VISA CLASSIC|cardProductProfile=C|issuerCode=00000|issuerCountryCode=GRC|acquirerNativeResponseCode=00|settlementModeComplement=null|preAuthorisationProfile=null|preAuthorisationProfileValue=null|preAuthorisationRuleResultList=[{"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},{"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}]|preAuthenticationProfileValue=null|preAuthenticationRuleResultList=null|paymentMeanBrandSelectionStatus=NOT_APPLICABLE|transactionPlatform=PROD|avsAddressResponseCode=null|avsPostcodeResponseCode=null|customerCompanyName=null|customerBusinessName=null|customerLegalId=null|customerPositionOccupied=null|paymentAttemptNumber=1|holderContactEmail=null|installmentIntermediateServiceProviderOperationIdsList=null|holderAuthentType=null|acquirerContractNumber=3863090010|secureReference=null|authentExemptionReasonList=null|paymentAccountReference=a667b63d8bec4fb980106497c53e4|schemeTransactionIdentifier=b4e683c1a6ff4a09a0415116a0a25b401d38c19d24e643078d|guaranteeLimitDateTime=null|paymentMeanDataProvider=null|virtualCardIndicator=N|cardProductUsageLabel=CREDIT|authorisationTypeLabel=TRANSACTION DE PAIEMENT|authorMessageReference=272612|acceptanceSystemApplicationId=142000000001|challengeMode3DS=null|issuingCountryCode=GRC|abortedProcessingStep=null|abortedProcessingLocation=null
Copy
Le Seal que vous devez obtenir est 8fb7c5b7e972ed5a279629757aeae9885cdfc1fd888e6fc03114064e94bb2bf4

Exemple de Seal calculé avec une clé secrète égale à "secret123" et la donnée Data au format JSON ci-dessous:

{"keyVersion":1,"amount":44000,"captureDay":0,"captureMode":"AUTHOR_CAPTURE","currencyCode":"978","customerId":"40813","customerIpAddress":"213.118.246.190","merchantId":"225005049920001","orderAmount":44000,"orderChannel":"INTERNET","responseCode":"97","responseDescription":"Request time-out; transaction refused","transactionDateTime":"2023-03-15.00:39:04+0100","transactionReference":"dd88adfZ1027b40813f40813y1678837075","statementReference":"T7Ft4KKLRA2M11B9","s10TransactionId":"6","s10TransactionIdDate":"20230315","sealAlgorithm":"sha256","transactionPlatform":"PROD","paymentAttemptNumber":2,"preAuthorisationRuleResultList":[{"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},{"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}]}
Copy
Le Seal que vous devez obtenir est e9aa5be21186a9f9a417b82d1d450792851c849ccc8a2f85136897da29477975

Renseigner l’URL de la réponse manuelleCopier le lien vers Renseigner l’URL de la réponse manuelle dans le presse-papier
L’objectif principal de la réponse manuelle est de rediriger le client vers votre site Web avec le résultat du paiement pour que vous puissiez prendre la bonne décision le concernant. Par exemple, en cas d’erreur, vous pouvez suggérer de retenter le paiement. Dans le cas de paiement réussi, vous pouvez afficher un message de remerciement et commencer à expédier les marchandises.

À la dernière étape, un bouton « Continuer » est affiché sur la page de paiement chez Sherlock's avec un lien de redirection vers votre site. Lorsque le client clique sur ce bouton, le serveur Sherlock's le redirige vers l’adresse URL contenue dans le champ normalReturnUrl fourni dans la requête. La redirection est une requête HTTP(S) POST qui contient les données de la réponse, tels que décrits ci-dessus. Il est de votre responsabilité de récupérer ces paramètres et de vérifier la signature pour ainsi assurer l’intégrité des données de la réponse. De plus, vous êtes responsable d’afficher les messages pertinents (relatifs aux détails de la réponse) à votre client.

Ce champ normalReturnUrl est également utilisé pour tous les résultats de paiement (annulation, refus ...) afin de rediriger vers votre site.

Il est important de noter qu’il est impossible de garantir la réception de la réponse, celle-ci étant envoyée par le navigateur Web du client. Tout d’abord, le client a la possibilité de ne pas cliquer sur le lien. Ensuite, la connexion qu’il utilise peut tout simplement avoir un problème et bloquer l’envoi de cette réponse. Par conséquent, celle-ci ne peut pas constituer la base unique pour vos processus métier.

Renseigner l’URL de la réponse automatiqueCopier le lien vers Renseigner l’URL de la réponse automatique dans le presse-papier
La réponse automatique est envoyée seulement si le champ automaticResponseUrl a été envoyé dans la requête de paiement. Si tel est le cas, le serveur Sherlock's envoie une réponse HTTP(S) POST à l’adresse URL reçue.

Les champs de la réponse automatique sont identiques à ceux de la réponse manuelle. La seule différence entre les deux procédures est que la réponse automatique est envoyée directement par le serveur Sherlock's sans passer par le navigateur Web du client. Par conséquent, elle est bien plus fiable car elle est toujours envoyée. Le serveur Sherlock's n’attend aucune réponse après l’envoi de la réponse automatique.

Il vous appartient de récupérer les différentes données de la réponse, vérifier la signature pour vous assurer de l’intégrité des champs de la réponse et, par conséquent, mettre à jour votre back office.

Attention: la réponse automatique est systématique, asynchrone et renvoyée par le réseau ; elle est par définition dépendante des problèmes techniques potentiels des différents éléments de ce réseau et peut donc parfois être reçue avec un retard plus ou moins conséquent, voire même ne jamais être reçue.
La réponse automatique est transmise en fin de paiement. Toutefois, si votre client abandonne son achat, par exemple en quittant son navigateur, la réponse automatique est transmise lorsque la session utilisateur expire (au bout de 15 minutes d’inactivité). Par conséquent, si votre client abandonne son achat, vous recevrez uniquement la réponse automatique (pas la réponse manuelle), avec un code réponse renseigné à 97, environ 15 à 16 minutes après la redirection du client sur les pages de paiement.

Si une réponse automatique n’est pas reçue au bout de 16 minutes environ, vous pouvez obtenir le résultat d’un paiement en appelant la méthode getTransactionData de l’interface Sherlock’s Office, ou en analysant le contenu du journal des transactions. Vous pouvez également rechercher une transaction et voir son état en utilisant Sherlock's Gestion.

Choisir le format de la réponse : POST ou JSONCopier le lien vers Choisir le format de la réponse : POST ou JSON dans le presse-papier
A partir de l'interfaceVersion HP_3.0 Sherlock's vous envoie la chaîne concaténée de la réponse (champ Data) sous 2 formats au choix :

Le format POST

Ce format POST a la structure suivante : clé1=valeur1|clé2=valeur2…

Exemple d'une réponse en POST avec séparateur "pipe" entre les données

captureDay=0|captureMode=AUTHOR_CAPTURE|currencyCode=978|merchantId=039000254447216
    |orderChannel=INTERNET|responseCode=00|transactionDateTime=2022-11-14T11:21:12+01:00|transactionReference=SIM20221114112037
    |keyVersion=1|acquirerResponseCode=00|amount=1000|authorisationId=664865|guaranteeIndicator=N|panExpiryDate=202401
    |paymentMeanBrand=VISA|paymentMeanType=CARD|customerIpAddress=10.78.106.18|maskedPan=############0600|holderAuthentRelegation=N
    |holderAuthentStatus=NOT_PARTICIPATING|tokenPan=490700h719850600|transactionOrigin=SIMS|paymentPattern=ONE_SHOT
    |customerMobilePhone=null|mandateAuthentMethod=null|mandateUsage=null|transactionActors=null|mandateId=null|captureLimitDate=20221114
    |dccStatus=null|dccResponseCode=null|dccAmount=null|dccCurrencyCode=null|dccExchangeRate=null|dccExchangeRateValidity=null
    |dccProvider=null|statementReference=null|panEntryMode=MANUAL|walletType=null|holderAuthentMethod=NO_AUTHENT_METHOD
    |holderAuthentProgram=3DS_V2|paymentMeanId=null|instalmentNumber=null|instalmentDatesList=null|instalmentTransactionReferencesList=null
    |instalmentAmountsList=null|settlementMode=null|mandateCertificationType=null|valueDate=null|creditorId=null
    |acquirerResponseIdentifier=null|acquirerResponseMessage=null|paymentMeanTradingName=null|additionalAuthorisationNumber=null
    |issuerWalletInformation=null|s10TransactionId=6|s10TransactionIdDate=20221114|preAuthenticationColor=null|preAuthenticationInfo=null
    |preAuthenticationProfile=null|preAuthenticationThreshold=null|preAuthenticationValue=null|invoiceReference=null|s10transactionIdsList=null
    |cardProductCode=F|cardProductName=VISA CLASSIC|cardProductProfile=C|issuerCode=00000|issuerCountryCode=GRC|acquirerNativeResponseCode=00
    |settlementModeComplement=null|preAuthorisationProfile=null|preAuthorisationProfileValue=null
    |preAuthorisationRuleResultList=[{"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},{"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}]
    |preAuthenticationProfileValue=null|preAuthenticationRuleResultList=null|paymentMeanBrandSelectionStatus=NOT_APPLICABLE|transactionPlatform=PROD
    |avsAddressResponseCode=null|avsPostcodeResponseCode=null|customerCompanyName=null|customerBusinessName=null|customerLegalId=null
    |customerPositionOccupied=null|paymentAttemptNumber=1|holderContactEmail=null|installmentIntermediateServiceProviderOperationIdsList=null
    |holderAuthentType=null|acquirerContractNumber=3863090010|secureReference=null|authentExemptionReasonList=null
    |paymentAccountReference=a667b63d8bec4fb980106497c53e4|schemeTransactionIdentifier=b4e683c1a6ff4a09a0415116a0a25b401d38c19d24e643078d
    |guaranteeLimitDateTime=null|paymentMeanDataProvider=null|virtualCardIndicator=N|cardProductUsageLabel=CREDIT|authorisationTypeLabel=TRANSACTION DE PAIEMENT
    |authorMessageReference=272612|acceptanceSystemApplicationId=142000000001|challengeMode3DS=null|issuingCountryCode=GRC|abortedProcessingStep=null|abortedProcessingLocation=null
Copy
Note: La liste d’objets complexes de ce format POST a une structure qui se rapproche du format JSON
(voir § Syntaxe des listes d'objets complexes dans les réponses)

Le format JSON

Le format JSON a la structure suivante : { "clé1" : "valeur1", "clé2" : "valeur2", …}

Note: Le format JSON affiche aisément une liste ou une collection d’objets avec la structure suivante : "listeClient" : [ { "nom" : "nom1", "prenom" : "prenom1",… }, { "nom" : "nom2", "prenom" : "prenom2",… } ]
Exemple d'une réponse en JSON

{
  		"keyVersion": 1, "acquirerResponseCode": "00", "acquirerResponseDescription": "Transaction approved or processed successfully",
  		"amount": 1000, "authorisationId": "858191", "captureDay": 0, "captureMode": "AUTHOR_CAPTURE", "cardScheme": "VISA",
  		"chargeAmount": 0, "currencyCode": "978", "customerIpAddress": "10.78.106.18", "guaranteeIndicator": "N",
  		"holderAuthentRelegation": "N", "holderAuthentStatus": "NOT_PARTICIPATING", "maskedPan": "############0600",
  		"merchantId": "039000254447216", "orderAmount": 1000, "orderChannel": "INTERNET", "panExpiryDate": "202401",
  		"paymentMeanBrand": "VISA", "paymentPattern": "ONE_SHOT", "responseCode": "00", "responseDescription": "Process succeeded",
  		"tokenPan": "490700h719850600", "transactionDateTime": "2022-11-14.11:19:39+0100", "transactionOrigin": "SIMS",
  		"transactionReference": "SIM20221114111757", "captureLimitDate": "20221114", "paymentMeanType": "CARD", "panEntryMode": "MANUAL",
  		"holderAuthentMethod": "NO_AUTHENT_METHOD", "holderAuthentProgram": "3DS_V2", "s10TransactionId": "5", "s10TransactionIdDate": "20221114",
  		"cardProductCode": "F", "cardProductName": "VISA CLASSIC", "cardProductProfile": "C", "issuerCode": "00000", "issuerCountryCode": "GRC",
  		"acquirerNativeResponseCode": "00", "sealAlgorithm": "sha256", "paymentMeanBrandSelectionStatus": "NOT_APPLICABLE",
  		"transactionPlatform": "PROD", "paymentAttemptNumber": 1, "acquirerContractNumber": "3863090010",
  		"schemeTransactionIdentifier": "79e70b862e5942ff86f31951235959a16f45f41f797f48129e",
  		"paymentAccountReference": "945dbb3e0b984bfc896a04c5bc273", "virtualCardIndicator": "N", "cardProductUsageLabel": "CREDIT",
  		"authorisationTypeLabel": "TRANSACTION DE PAIEMENT", "authorMessageReference": "179263", "acceptanceSystemApplicationId": "142000000001",
  		"issuingCountryCode": "GRC", "threeDLiabilityShift": "N", "threeDStatusCode": "NOT_PARTICIPATING", "threeDRelegationCode": "N",
  		"preAuthorisationRuleResultList":[
  		    {"ruleCode":"VI","ruleType":"NG","ruleWeight":"I","ruleSetting":"S","ruleResultIndicator":"0","ruleDetailedInfo":"TRANS=1:3;CUMUL=24999:200000"},
  		    {"ruleCode":"RCode","ruleType":"RType","ruleWeight":"RWeight","ruleSetting":"RSetting","ruleResultIndicator":"RIndicator","ruleDetailedInfo":"DetailedInfo"}
  		]
}
Copy
Comportement par défaut à partir de l'interfaceVersion HP_3.0

Le format de la réponse automatique et manuelle est déterminé par le connecteur qui a été utilisé lors des échanges HTTPS entre votre site Web et les serveurs de paiement Sherlock’s Paypage

Tip: Voici un tableau récapitulatif du fonctionnement entre InterfaceVersion HP_3.0 / Connecteur appelé / Format des réponses
Interface Version	Connecteur	Format des réponses
IR_WS_3.x	JSON	JSON (JS_3.x)
HP_3.x	POST	POST (HP_3.x)
IR_WS_3.x	SOAP	POST (HP_3.x)
Choisir les versions des réponses depuis la requête de paiement

Si vous souhaitez contourner ce comportement par défaut il est possible de renseigner depuis la requête de paiement les versions exactes des réponses automatiques et manuelles que vous utilisez.

Le champs de la requête de paiement qui permet de renseigner la version de la réponse automatique est interfaceVersionAutomaticResponse

Le champs de la requête de paiement qui permet de renseigner la version de la réponse manuelle est interfaceVersionNormalResponse

Attention: Si les versions renseignées dans la requête sont incorrectes alors la requête d'initialisation de paiement est en echec (code erreur 30).
Ces deux nouveaux champs interfaceVersionAutomaticResponse et interfaceVersionNormalResponse sont facultatifs mais si une des versions est renseignée l'autre devient obligatoire également. Sinon la requête d'initialisation de paiement est en echec (code erreur 12).

Résoudre les problèmes de réception des réponsesCopier le lien vers Résoudre les problèmes de réception des réponses dans le presse-papier
Ci-dessous, vous trouverez une liste des problèmes les plus couramment observés qui bloquent la réception des réponses automatiques et manuelles. Assurez-vous de les avoir vérifiés avant d’appeler le service d’assistance technique.

Vérifiez si les adresses URL de réponse sont fournies dans la requête et si elles sont valides. Pour ce faire, vous pouvez tout simplement les copier et coller dans votre navigateur.
Les adresses URL fournies doivent être accessibles depuis l’extérieur, c'est-à-dire de l’Internet. Le contrôle d’accès (identifiant/mot de passe ou filtre IP) ou le pare-feu peuvent bloquer l’accès à votre serveur.
L’accès aux adresses URL de réponse doit être confirmé dans le journal des notifications de votre serveur Web.
Si vous utilisez un port non standard, il doit être compris entre 80 et 9999 pour assurer la compatibilité avec Sherlock's.
Il est impossible d’ajouter des paramètres de contexte aux adresses URL de réponse. Certains champs peuvent être néanmoins utilisés, par exemple, les champs orderID ou returnContext sont prévus pour les paramètres supplémentaires. Éventuellement, vous pouvez vous servir du champ sessionId pour retrouver les renseignements sur votre client à la fin du processus de paiement.
Dans certains cas d’erreurs, le serveur Sherlock's n’est pas capable de signer le message de réponse. Cela s’applique, par exemple, à l’erreur « MerchantID inconnu » et au cas où la clé secrète est inconnue de Sherlock's. Pour ces raisons, le serveur de paiement envoie une réponse sans signature dans le champ Seal.

Récupérer les champs des réponsesCopier le lien vers Récupérer les champs des réponses dans le presse-papier
Le contenu des réponses Sherlock’s Paypage automatiques et manuelles est identique. Le contenu peut varier en fonction du résultat (réussi ou autre).

Note: dans les réponses, en fonction de l’état de la transaction et du moyen de paiement choisi, certains champs peuvent être nuls, vides ou non renseignés. Veuillez consulter les documentations des moyens de paiement pour connaître les champs attendus dans les réponses.
La liste des champs de la réponse est disponible sur cette page.

Champs optionnels relatifs aux contrôles de fraudeCopier le lien vers Champs optionnels relatifs aux contrôles de fraude dans le presse-papier
Contenu de preAuthenticationRuleResult
Champ	Version	Commentaires
ruleCode	HP_2.14	
ruleType	HP_2.14	
ruleWeight	HP_2.14	
ruleSetting	HP_2.14	
ruleResultIndicator	HP_2.14	
ruleDetailedInfo	HP_2.14	
Contenu de preAuthorisationRuleResult
Champ	Version	Commentaires
ruleCode	HP_2.14	
ruleType	HP_2.14	
ruleWeight	HP_2.14	
ruleSetting	HP_2.14	
ruleResultIndicator	HP_2.14	
ruleDetailedInfo	HP_2.14	
Syntaxe des listes d'objets complexes dans les réponsesCopier le lien vers Syntaxe des listes d'objets complexes dans les réponses dans le presse-papier
Le format d'une liste d'objets complexes dans les réponses automatiques et manuelles est défini comme suit (en gras) :

..|amount=1000|currencyCode=978|objectNameList=[{"field1":"value1a",
"field2":"value2a","field3":"value3a"…},{"field1":"value1b",
"field2":"value2b","field3":"value3b"}…]|transactionReference=1452687287828|..
Copy
le contenu de la liste est enveloppé dans une paire de crochets [ ] ;
chaque entrée de la liste est enveloppé dans une paire d'accolades { } ;
chaque champ est représenté comme "nomChamp" = "valeurChamp" ;
notez que le nom et la valeur du champ sont tous deux enveloppés dans une paire de doubles guillemets "" ;
les paires de nom/valeur adjacentes sont séparés par une virgule.
Exemple du champ preAuthorisationRuleResultList

Détail des règles fraude exécutées en préautorisation (en gras)

..|amount=1000|currencyCode=978|preAuthorisationRuleResultList=[
{”ruleCode”:"SC",”ruleType”:"NG",”ruleWeight”:"I",”ruleSetting”:"S",
”ruleResultIndicator”:"0",“ruleDetailedInfo”:"TRANS=1:5;
CUMUL=1000:99999900"},{”ruleCode”:"GC",”ruleType”:"NG",”ruleWeight”:
"D",”ruleSetting”:"N",”ruleResultIndicator”:"0",“ruleDetailedInfo”:
""},{”ruleCode”:"CR",”ruleType”:"NG",”ruleWeight”:"D",”ruleSetting”
:"S",”ruleResultIndicator”:"N",“ruleDetailedInfo”:"CARD_COUNTRY=USA"}]
|transactionReference=1452687287828|..
Copy
Analyser la réponse de paiementCopier le lien vers Analyser la réponse de paiement dans le presse-papier
Si vous procédez à une authentification par sceau électronique (seal), vous devez impérativement vérifier que le sceau reçu correspond bien au sceau que vous recalculez avec les champs de la réponse.

Si le sceau reçu ne correspond pas au sceau que vous recalculez, l’état de la transaction est considéré comme inconnu : laissez la transaction en l’état, contactez le support et ne ré-exécutez pas la transaction de manière automatisée.

État	Champs de la réponse	Action à réaliser
Paiement accepté

responseCode = 00

acquirerResponseCode = 00

garanteeIndicator = Y,N,U, vide

Vous pouvez livrer la commande en fonction du niveau de garantie que vous souhaitez (champ garanteeIndicator).

Refus Fraude Sherlock's Go-No-Go

responseCode = 05

complementaryCode = XX

preAuthorisationRuleResultList

Le paiement a été refusé par le moteur de fraude Sherlock's que vous avez configuré.

Ne livrez pas la marchandise. Analysez le détail des règles fraudes exécutées par Sherlock's pour connaître la cause du refus (champ preAuthorisationRuleResultList).

Refus Fraude Sherlock's

Business Score

responseCode = 05

scoreColor = RED, BLACK

scoreValue = X (score de la transaction)

scoreThreshold = X,Y (seuil orange, seuil vert)

Le paiement a été refusé par le moteur de fraude Sherlock's que vous avez configuré

Ne livrez pas la marchandise. Analysez le détail des règles fraudes exécutées par Sherlock's pour connaître la cause du refus (champ preAuthorisationRuleResultList).

Warning Fraude Sherlock's

Business Score

responseCode = 05

scoreColor = ORANGE

scoreValue = X (score de la transaction)

scoreThreshold = X,Y (seuil orange, seuil vert)

Le paiement a été autorisé par l’acquéreur mais le moteur de fraude Sherlock's émet un warning par rapport aux règles que vous avez configurées.

Analysez le détail des règles fraudes exécutées par Sherlock's pour connaître la cause du warning (champ preAuthorisationRuleResultList).

Si transaction non risquée alors acceptez-la avec la fonction acceptChallenge.

Si transaction risquée alors refusez-la avec la fonction refuseChallenge.

Les fonctions acceptChallenge et refuseChallenge sont disponibles sur le Portail Sherlock's et les connecteurs Sherlock’s Office et Sherlock’s Office Batch.

Refus 3-D Secure

reponseCode = 05

holderAuthenStatus = FAILURE

L’authentification du client a échoué, ce n’est pas nécessairement un cas de fraude. Vous pouvez proposer à votre client de payer avec un autre moyen de paiement en générant une nouvelle requête.

Refus bancaire acquéreur

responseCode = 05

acquirerResponseCode = XX

L’autorisation est refusée pour un motif non lié à la fraude.

Vous pouvez proposer à votre client de payer avec un autre moyen de paiement en générant une nouvelle requête.

Repli VADS	
responseCode = 05

acquirerResponseCode = A1

Le paiement a été refusé par l'acquéreur car il manque les données 3-D Secure dans la demande d'autorisation.
Veuillez retenter le paiement avec une cinématique 3-D Secure.
Refus fraude acquéreur

responseCode = 34

acquirerResponseCode = XX

Autorisation refusée pour cause de fraude.

Ne livrez pas la commande.

Refus nombre max essais atteint

responseCode = 75

acquirerResponseCode = XX

L’acheteur a fait plusieurs tentatives toutes échouées car les informations saisies n’étaient pas correctes. Deux possibilités :

Difficulté pour votre client pour renseigner les informations cartes.

Tentative de carding (recherche de numéros de cartes possibles). Prenez contact avec votre client pour définir la suite à donner.

Refus suite problème technique

responseCode = 90, 99

acquirerResponseCode = 90 à 98

Problème technique temporaire lors du traitement de la transaction.

Proposez à votre client de refaire un paiement ultérieurement.

Abandon du paiement	responseCode = 97
acquirerResponseCode = non renseigné

Ne livrez pas la commande
Étape 3 : tester sur l’environnement de simulationCopier le lien vers Étape 3 : tester sur l’environnement de simulation dans le presse-papier
Une fois le développement de la connexion à Sherlock’s Paypage réalisé, vous pouvez effectuer un test sur le serveur Sherlock’s Paypage de simulation.

URL de simu du serveur https://sherlocks-payment-webinit-simu.secure.lcl.fr/paymentInit
Pour effectuer ce test, il faut utiliser les identifiants en fonction du mode d’identification des transactions que vous souhaitez :

Table 1. transactionReference généré par Sherlock's
Champ	Valeur
ID du commerçant (merchantId)	002016000000001
Clé secrète (secretKey)	002016000000001_KEY1
Version de la clé (keyVersion)	1
Ce serveur de simulation n’est pas raccordé aux serveurs bancaires réels car sa fonction est de valider la connexion entre votre site Web et le serveur de paiement.

Sherlock’s Paypage simule donc l’appel aux serveurs d’autorisation pour vous permettre de tester les différents résultats d’un paiement.

Il n’est donc pas nécessaire d’utiliser des cartes réelles pour effectuer les tests.

Attention: puisque le merchantId est partagé entre tous les commerçants/prospects, il existe un risque de doublon de transactionReference. Par conséquent, il est vivement recommandé que tous les transactionReference soient préfixés par le nom de la future boutique qui sera utilisée dans l’environnement de production. Cela facilite aussi le support en cas d’appel à l’assistance technique.
Vous utilisez une boutique générique sans personnalisation de la page de paiement. C’est lors de l’étape 4 que vous pouvez personnaliser vos pages de paiements.

Tester des transactions CB, VISA, MASTERCARD, AMEXCopier le lien vers Tester des transactions CB, VISA, MASTERCARD, AMEX dans le presse-papier
Les règles de simulation suivantes s’appliquent :

le numéro de carte (PAN) doit comporter de 15 à 19 chiffres (selon le moyen de paiement utilisé) ;
les six premiers chiffres du PAN déterminent le type de carte, conformément au tableau ci-dessous ;
Type de carte	Début du numéro de carte
AMEX	340000
VPAY	400000
VISA	410000
CB	420000
Cartes co-badgées CB et VISA	430000
Cartes co-badgées CB et VPAY	440000
Cartes co-badgées CB et VISA_ELECTRON	450000
Cartes co-badgées VISA et MASTERCARD	460000
MAESTRO	500000
MASTERCARD	510000
Cartes co-badgées CB et MASTERCARD	520000
Cartes co-badgées CB et MAESTRO	530000
le code réponse Sherlock's (champ responseCode) est calculé à partir des deux derniers chiffres du numéro de carte ;
le code de sécurité (CVV) comporte 3 ou 4 chiffres. Cette valeur est sans importance pour le résultat de la simulation.
Exemple : si vous utilisez le numéro de carte 4100 0000 0000 0005, la carte sera identifiée comme VISA et le paiement sera refusé (code réponse Sherlock's 05).

Note: si le code réponse Sherlock's calculé n’est pas référencé, la transaction est acceptée (respondeCode = 00).
Les cartes co-badgées peuvent être utilisées avec chacune des marques définies dans le tableau.

Toutes les cartes sont enrôlées 3-D Secure, vous êtes redirigé vers le serveur de simulation 3-D Secure sur lequel vous choisissez le résultat désiré de l’authentification 3-D Secure.

Tester des transactions iDealCopier le lien vers Tester des transactions iDeal dans le presse-papier
Si vous choisissez de tester iDeal, vous serez redirigé vers le serveur de simulation qui simule les transactions iDeal selon leur montant. Ensuite, vous retournerez au serveur de paiement qui affiche le ticket avec le résultat de la transaction.

Règles de simulation d’un paiement iDeal :

Montant de la transaction	Réponse de iDeal
2,00 EUR	Transaction annulée
3,00 EUR	Transaction expirée
4,00 EUR	Transaction non réalisée
5,00 EUR	Échec de la transaction
Autres cas	Transaction OK
Tester des transactions PayPalCopier le lien vers Tester des transactions PayPal dans le presse-papier
Si vous choisissez de tester PayPal, vous êtes redirigé vers le serveur de simulation qui simule les transactions PayPal selon leur résultat du paiement chez PayPal. Ensuite, vous retournez au serveur de paiement qui affiche le ticket avec le résultat du paiement.

Étape 4 : valider le passage en productionCopier le lien vers Étape 4 : valider le passage en production dans le presse-papier
Une fois la connexion de votre site Web à Sherlock's Paypage POST testée, vous êtes à présent en mesure de valider la connexion à Sherlock's Paypage POST de production.

Au préalable, nous conseillons d’isoler votre site Web du public pour éviter que des clients ne génèrent des requêtes pendant cette phase de validation.

Si vous souhaitez personnaliser vos pages de paiement et de gestion de wallet, vous pouvez utiliser notre outil Sherlock's CustomPages, permettant de tester et visualiser le rendu des pages. Pour cela, merci de vous référer à la documentation Sherlock's CustomPages afin d’utiliser l’outil.

Pour basculer sur le serveur de production, vous devez changer l’URL pour vous connecter au serveur Sherlock's de production en utilisant les identifiants merchantId, secretKey et keyVersion reçus lors l’inscription.

URL	https://sherlocks-payment-webinit.secure.lcl.fr/paymentInit
merchantId	Identifiant de la boutique reçu par mail
SecretKey	Clé secrète que vous récupérez via l’extranet Sherlock’s Téléchargement
keyVersion	Version clé secrète récupérée sur Sherlock’s Téléchargement (logiquement 1 pour la 1ère clé)
Attention: une erreur fréquente est d’oublier un de ces 4 paramètres, ce qui conduit systématiquement à une erreur.
Comment valider le bon fonctionnement en productionCopier le lien vers Comment valider le bon fonctionnement en production dans le presse-papier
Immédiatement :

faites une transaction avec une carte de paiement réelle (si possible la vôtre). Si la transaction est acceptée, elle sera envoyée en banque pour créditer votre compte commerçant et débiter le compte carte ;
vérifiez que vos pages de paiement intègrent vos paramètres de personnalisation ;
consultez la transaction via Sherlock's Gestion à partir du transactionReference.
Le lendemain :

vérifiez la présence de la transaction dans le journal des transactions ;
vérifiez sur votre compte que l’opération a bien été créditée ;
remboursez la transaction via Sherlock's Gestion (optionnel).
Le surlendemain :

vérifiez que l’opération de remboursement apparaît dans le journal des opérations ;
vérifiez sur votre compte le débit suite au remboursement.
Cette procédure de validation est également applicable au moyen de paiement PayPal.

Étape 5 : démarrer en productionCopier le lien vers Étape 5 : démarrer en production dans le presse-papier
Une fois la validation du passage en production effectuée, ouvrez votre site au public pour permettre à vos clients d’acheter et de payer.

Dans la journée :

surveillez le taux d’acceptation (nombre de responseCode 00 / nombre total de transactions).
vérifiez la nature des refus non bancaires :
problème technique : responseCode 90, 99 ;
fraude : responseCode 34 ;
nombre maximum de tentatives de paiement atteint : responseCode 75 ;
abandon : responseCode 97.
Le lendemain :

vérifiez dans le journal des transactions la présence de toutes les transactions traitées (acceptées et refusées) ;
vérifiez, dans le journal des opérations, les opérations que vous avez effectuées ainsi que les remises (si vous avez choisi cette option du journal).
Pour compléter cette lecture, nous vous recommandons
Conseillé
Développeurs Personnalisation des pages
Sherlock's Paypage iFrame
Documentation fonctionnelle, technique et guides utilisateurs pour vous aider à intégrer la solution de paiement en ligne Sherlock's.

Ouvrir ce document dans un nouvel onglet Sherlock's Paypage iFrame
Facultatif
Développeurs Personnalisation des pages
Personnalisation des pages de paiement (Paypage)
Documentation fonctionnelle, technique et guides utilisateurs pour vous aider à intégrer la solution de paiement en ligne Sherlock's.
