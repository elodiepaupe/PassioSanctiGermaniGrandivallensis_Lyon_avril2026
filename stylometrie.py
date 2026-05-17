import os
import numpy as np
import pandas as pd
import nltk
import matplotlib.pyplot as plt
from sklearn.feature_extraction.text import CountVectorizer
from scipy.cluster.hierarchy import linkage, dendrogram
from scipy.spatial.distance import pdist

# Télécharger les ressources NLTK
nltk.download("punkt")

# Dictionnaire des mesures de distance à tester : 
# Pour Manhattan, nous utilisons 'cityblock' 
distance_metrics = {
    "Euclidean": "euclidean",
    "Manhattan": "cityblock",
    "Cosine": "cosine",
    "Chebyshev": "chebyshev"
}

# Définir le dossier contenant les fichiers texte
corpus_dir = "**ici le chemin vers votre dossier**"
files = [f for f in os.listdir(corpus_dir) if f.endswith(".txt")]

# Fonction pour lire un fichier texte
def read_file(filepath):
    with open(filepath, "r", encoding="utf-8") as file:
        return file.read()

# Charger les textes depuis le dossier
texts = {file: read_file(os.path.join(corpus_dir, file)) for file in files}

# Construire une matrice de fréquences de mots (limité à 500 mots les plus fréquents)
vectorizer = CountVectorizer(max_features=500, stop_words="english")
X = vectorizer.fit_transform(texts.values()).toarray()

# Convertir en DataFrame
df_freq = pd.DataFrame(X, index=files, columns=vectorizer.get_feature_names_out())

# Générer et afficher les dendrogrammes pour chaque mesure de distance
for name, metric in distance_metrics.items():
    # Calculer la matrice de distances avec pdist
    dist_matrix = pdist(df_freq, metric=metric)
    # Utiliser la méthode de liaison "average" pour construire la hiérarchie
    linkage_matrix = linkage(dist_matrix, method="average")
    
    plt.figure(figsize=(18,12))
    dendrogram(linkage_matrix, labels=files, leaf_rotation=90, leaf_font_size=10)
    plt.title(f"Dendrogramme - Distance: {name}")
    plt.xlabel("Textes")
    plt.ylabel("Distance")
    plt.tight_layout()

    # • Sauvegarder au format SVG 
    output_path = os. path.join(output_dir, f"dendrogramme_(name). svg") 
    plt.savefig(output_path, format="svg") 
    plt.show()
