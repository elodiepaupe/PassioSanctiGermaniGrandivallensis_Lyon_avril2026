# PassioSanctiGermaniGrandivallensis_Lyon_avril2026
Documents relatifs à la présentation donnée le 29 avril 2026

## Introduction au XML-TEI
Élodie Paupe (éd.), _Introduction à la philologie numérique_, Neuchâtel: Université de Neuchâtel, 2020, [https://github.com/elodiepaupe/UNINE_edition-numerique](https://github.com/elodiepaupe/UNINE_edition-numerique).

## Documents
* Présentation au format PDF
* Exemplier au format docx

## Ressources
Pour utiliser les scripts python, il est nécessaire d'installer un environnement virtuel sur son ordinateur portable. Les explications en ligne sont nombreuses. Pour éviter cette installation, on peut utiliser des éditeurs compilateurs en ligne, comme https://colab.research.google.com/?hl=fr

* Ressource en ligne pour transformer un fichier xml-tei en édition bilingue: [TEI Critical Apparatus Toolbox](https://teicat.huma-num.fr/index.php), par Marjorie Burghart, MA, MSc, PhD.
* Script python pour la lemmatisation avec le modèle LASLA (nécessite un environnement python 3.7 au maximum) 
* Script R avec package _textreuse_ pour comparer un document au format .txt avec d'autres documents .txt contenus dans un seul fichier. Paramètres à modifier:
    * l. 24 n_gram: comparaison par groupes de 2, 3, 5, etc. mots
    * l.25 seuil_similiarité (calcul selon la similarité de jaccard), une bonne valeur pour commencer: 0.03
    * l.26 nb_paires_max: le script se concentre sur les meilleures paires
* [Script python pour la stylométrie](stylometrie.py). Le script calcule la proximité entre les textes au format .txt d'un dossier selon 5 distances utilisées en stylométrie. Les paramètres à modifier figurent au début du script.
