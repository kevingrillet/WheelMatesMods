# Tweaks

Statut : préparation uniquement. Aucun `Scripts/main.lua`, aucune entrée dans le
manifeste pour le moment. Implémenter Tweaks après validation en jeu des POC
renommés et de leurs bibliothèques partagées.

## Objectif de la première version

À terme, Tweaks sera le seul module fonctionnel à activer, avec les bibliothèques
`shared`. Les POC resteront des outils de validation indépendants, désactivés dans
ce profil final pour éviter les raccourcis et overlays en double. Le nettoyage de
ModKit devra être repris par Tweaks avant de pouvoir désactiver aussi ModKit.
**WallHack est reporté à une version ultérieure.**

| Fonction | Comportement prévu |
| --- | --- |
| Coordonnées | Afficher/masquer une ligne compacte par joueur : `P1 XYZ 123 / 456 / 789` (unités Unreal, cm) |
| Tableau | Afficher/masquer les objets manquants chargés ; tri par type puis distance croissante, ou distance seule |
| Compas | Afficher/masquer une ligne par joueur : type, direction, distance 3D en mètres et delta de hauteur signé |
| TP cible | Aller à un point d'approche de la cible sélectionnée pour le joueur concerné |
| TP retour | Revenir à la position précédant le dernier TP réussi de ce joueur |

Le tableau, le compas et le TP utilisent la même sélection par joueur. Le TP reste
utilisable lorsque les overlays sont masqués. Les coordonnées et le compas seront
plus compacts dans Tweaks ; les POC conservent leur présentation actuelle pendant
cette phase de validation.

## Cibles et rafraîchissement

- Mode initial : objet manquant le plus proche, distance 3D propre à chaque joueur.
- Prévoir dès la première version un mode manuel « cible suivante » qui boucle de
  la dernière à la première. La sélection manuelle reste stable lorsqu'on se
  déplace ; une commande permet de revenir au mode automatique « plus proche ».
- En manuel, parcourir un ordre stable (type, identifiant de session), indépendant
  du tri visuel par distance. Conserver la cible par identité, jamais par indice
  d'une liste retriée. Si elle disparaît, avancer vers la suivante encore valide.
- Prévoir un rafraîchissement manuel distinct : relire les acteurs et la sauvegarde
  active, retirer les objets collectés et intégrer les nouveaux objets chargés.
- Rafraîchir automatiquement les candidats à cadence modérée (point de départ :
  une seconde), indépendamment du calcul des distances et du rendu du HUD.
  Partager un seul scan entre les joueurs ; éviter les scans globaux à chaque frame.
- Sur chargement de map et changement d'identité du monde : vider les candidats,
  les sélections et les retours TP immédiatement. Reprendre le scan lorsque le
  monde et les joueurs sont disponibles ; rattacher les overlays au nouveau HUD.
- Vérifier à nouveau la validité de la cible au moment du TP. Sans candidat,
  afficher « aucune cible chargée » et ne pas déplacer le joueur.

Le calcul du plus proche existe déjà dans `WMNavigation`. Le mode manuel complète
ce mécanisme et permet de choisir une autre cible lorsqu'un accès est peu pratique.

## Périmètre des objets

`WMCollectibles` expose les Gears chargés et les objets narratifs absents de la
sauvegarde active. Il expose aussi les mini-jeux chargés avec le statut `Loaded` :
leur complétion n'est pas établie, ils ne doivent donc pas devenir des « manquants »
ni des cibles automatiques. Une sauvegarde indisponible donne `Unknown`, jamais
une liste inventée d'objets narratifs manquants.

Ce n'est pas un catalogue complet de la map : les zones non chargées ne sont pas
couvertes. Le statut des Gears conserve l'hypothèse du POC (chargé = manquant) ;
une identification persistante fiable reste à étudier. Ne pas réintroduire les
filtres de visibilité ou de monde par acteur qui avaient éliminé des cibles valides.

## Raccourcis proposés, non implémentés

La même touche de fonction désigne la même action partout : `Ctrl+Fn` pour le
joueur 1, `Ctrl+Shift+Fn` pour le joueur 2. Les bascules d'affichage, le tri et le
mode de ciblage sont indépendants pour chaque joueur.

| Action | Joueur 1 | Joueur 2 |
| --- | --- | --- |
| Coordonnées | `Ctrl+F1` | `Ctrl+Shift+F1` |
| Tableau | `Ctrl+F2` | `Ctrl+Shift+F2` |
| Compas | `Ctrl+F3` | `Ctrl+Shift+F3` |
| Alterner le tri type/distance et distance seule | `Ctrl+F4` | `Ctrl+Shift+F4` |
| TP cible | `Ctrl+F5` | `Ctrl+Shift+F5` |
| Retour | `Ctrl+F6` | `Ctrl+Shift+F6` |
| Rafraîchir | `Ctrl+F8` | `Ctrl+Shift+F8` |
| Cible suivante, passage en manuel | `Ctrl+F10` | `Ctrl+Shift+F10` |
| Revenir au mode automatique | `Ctrl+F12` | `Ctrl+Shift+F12` |

Le numéro du joueur correspond à l'indice LocalPlayers et au libellé du HUD :
joueur 1 = indice 1 (écran droit observé), joueur 2 = indice 2 (écran gauche observé).
Un refresh relit le catalogue partagé, mais préserve le mode et la sélection de
l'autre joueur tant que sa cible reste valide. Les deux variantes utilisent le
même scan partagé ; elles ne créent pas deux catalogues.

Valider les raccourcis en jeu. Les POC et diagnostics seront désactivés dans le
profil Tweaks, notamment pour libérer `Ctrl+F4`, `Ctrl+Shift+F4` et `Ctrl+F8`.
Le POC TP adopte dès maintenant les paires F5/F6 ; les POC d'affichage conservent
pour cette phase leurs bascules globales. Toutes les commandes individuelles du
futur Tweaks suivront la convention ci-dessus.

## Téléportation et retour

La position de retour est celle précédant le dernier TP réussi, pas le point de
spawn ni le début d'une série de TP. Un échec conserve le retour précédent ; un
retour réussi le consomme. Un changement de map ou un reload le supprime.

`WMTeleport` reprend ce comportement déjà testé. Le POC utilise toujours son point
fixe RiftX. Pour Tweaks, définir et valider un point d'approche adapté à chaque type
de cible : un décalage générique ne garantit ni sol praticable ni absence de
collision. Le placement du véhicule et les collisions restent à vérifier en jeu.

## Préparation et validation avant implémentation

Les anciens modules et leurs diagnostics portent maintenant le préfixe `POC`.
Le manifeste conserve leur activation actuelle ; aucun runtime Tweaks n'est chargé.

Les contrats et responsabilités partagés sont décrits dans
[shared](../shared/README.md). Les POC appellent déjà ces bibliothèques : collecte,
coordonnées, navigation, TP/retour, runtime, overlays et restauration du rendu.
Les diagnostics restent des sondes indépendantes, utiles pour confronter les
résultats aux objets Unreal bruts.

1. Redémarrer le jeu après le renommage des dossiers pour repartir d'un chargement
   propre. Les prochains changements de `shared` se testent avec un reload complet.
2. Vérifier coordonnées et compas sur les deux écrans, seuls et ensemble, puis
   après `Ctrl+R` et un changement de map.
3. Vérifier le tableau console avant/après collecte et pendant un chargement.
4. Vérifier TP RiftX et retour pour les deux joueurs, ainsi que l'invalidation du
   retour après changement de map et reload.
5. Confirmer les POC avec `shared`, puis implémenter les fonctions de Tweaks décrites
   ici et tester sélection automatique, cycle manuel, rafraîchissement et HUD compact.

Les tests automatisés couvrent le modèle Lua/UE4SS ; ils ne remplacent pas cette
validation dans le moteur du jeu.
