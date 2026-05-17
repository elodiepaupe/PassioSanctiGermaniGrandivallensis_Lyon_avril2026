# =========================
# 0. Installation / chargement 
# =========================

# install.packages("textreuse")
library(textreuse)

# =========================
# 1. Paramètres à renseigner pour définir l'analyse
# =========================

dir_corpus <- "/Users/elodiepaupe/Documents/Corpus22_MGH/R_analyse_corpusMerovingien"
# permet d'éviter les fichiers parasites du corpus, par exemple les .csv issus d'autres analyses
pattern_fichiers <- "_lemma_lasla_clean\\.txt$"

# Nom exact du fichier cible à comparer avec tout le corpus
# le nom réel du fichier sur le disque avec l'extension .txt
fichier_cible <- "Vita_Silvestri_lemma_lasla_clean.txt"

# Identifiant interne utilisé par textreuse
# dans le corpus textreuse, les noms sont utilisés sans l'extension .txt
id_cible <- gsub("\\.txt$", "", basename(fichier_cible))

n_gram <- 3L
seuil_similarite <- 0.0001
nb_paires_max <- 500L

# ATTENTION
# l'alignement local est beaucoup plus coûteux en mémoire
# on limite donc fortement le nombre d'alignements réellement lancés
nb_alignements_max <- 500L

dir_sortie <- file.path(dir_corpus, "resultats_textreuse")
if (!dir.exists(dir_sortie)) {
  dir.create(dir_sortie, recursive = TRUE)
}

# Sous-dossier spécifique pour le texte cible
dir_sortie_cible <- file.path(
  dir_sortie,
  paste0("comparaison_", id_cible)
)
if (!dir.exists(dir_sortie_cible)) {
  dir.create(dir_sortie_cible, recursive = TRUE)
}

# =========================
# 2. Lister uniquement les fichiers voulus
# =========================

fichiers <- list.files(
  path = dir_corpus,
  pattern = pattern_fichiers,
  full.names = TRUE
)

if (length(fichiers) < 2) {
  stop("Il faut au moins 2 fichiers *_lemma_lasla_clean.txt dans le dossier.")
}

cat("Nombre de fichiers trouvés :", length(fichiers), "\n")
print(basename(fichiers))

# Vérification de la présence du fichier cible dans le corpus
if (!(fichier_cible %in% basename(fichiers))) {
  stop("Le fichier cible n'a pas été trouvé dans le corpus.")
}

# =========================
# 3. Contournement du bug de TextReuseCorpus
# =========================

myTextReuseCorpus <- function(..., n = 3L) {
  mc <- match.call()
  if (!is.null(mc$n)) {
    mc$n <- eval.parent(mc$n)
  }
  mc[[1]] <- quote(textreuse::TextReuseCorpus)
  eval.parent(mc)
}

# =========================
# 4. Construire le corpus
# =========================

corpus <- myTextReuseCorpus(
  paths = fichiers,
  tokenizer = tokenize_ngrams,
  n = n_gram,
  keep_tokens = TRUE,
  progress = FALSE
)

cat("Corpus chargé :", length(corpus), "documents\n")

# Pour avoir des noms lisibles
# Attention: textreuse utilise ici des identifiants sans extension .txt
names(corpus) <- basename(names(corpus))
print(names(corpus))

# Vérification que l'identifiant cible existe bien dans le corpus textreuse
if (!(id_cible %in% names(corpus))) {
  cat("\n===== DIAGNOSTIC =====\n")
  cat("Identifiant cible recherché :", id_cible, "\n")
  cat("Exemples de noms présents dans le corpus :\n")
  print(head(names(corpus), 20))
  stop("L'identifiant cible n'a pas été trouvé dans les noms internes du corpus textreuse.")
}

# =========================
# 5. Similarité du texte cible contre tout le corpus
# - on évite pairwise_compare(), qui calcule toute la matrice et qui coûte beaucoup trop de capacité de calcul
# - on compare seulement le texte cible à chaque autre texte
# =========================

resultats_similarite <- data.frame(
  texte1 = character(),
  texte2 = character(),
  similarite = numeric(),
  stringsAsFactors = FALSE
)

autres_textes <- setdiff(names(corpus), id_cible)

cat("\nCalcul des similarités pour le texte cible :", id_cible, "\n")
cat("Nombre de comparaisons à effectuer :", length(autres_textes), "\n")

for (i in seq_along(autres_textes)) {
  nom_autre <- autres_textes[i]
  
  cat("\n----------------------------\n")
  cat("Comparaison", i, "sur", length(autres_textes), "\n")
  cat("Texte cible :", id_cible, "\n")
  cat("Texte comparé :", nom_autre, "\n")
  
  sim <- jaccard_similarity(corpus[[id_cible]], corpus[[nom_autre]])
  
  resultats_similarite <- rbind(
    resultats_similarite,
    data.frame(
      texte1 = id_cible,
      texte2 = nom_autre,
      similarite = sim,
      stringsAsFactors = FALSE
    )
  )
}

# Tri décroissant par similarité
resultats_similarite <- resultats_similarite[order(-resultats_similarite$similarite), ]

write.csv(
  resultats_similarite,
  file = file.path(dir_sortie_cible, "01_similarites_texte_cible_vs_corpus.csv"),
  row.names = FALSE
)

cat("\nTable des similarités enregistrée.\n")
print(head(resultats_similarite, 20))

# =========================
# 6. Sélection des paires candidates - l. 25 pour la quantification
# =========================

candidats <- resultats_similarite[
  resultats_similarite$similarite >= seuil_similarite,
]

if (nrow(candidats) == 0) {
  write.csv(
    candidats,
    file = file.path(dir_sortie_cible, "02_paires_candidates.csv"),
    row.names = FALSE
  )
  stop("Aucune paire candidate trouvée pour le fichier cible au-dessus du seuil.")
}

candidats <- head(candidats, nb_paires_max)

write.csv(
  candidats,
  file = file.path(dir_sortie_cible, "02_paires_candidates.csv"),
  row.names = FALSE
)

cat("Nombre de paires candidates retenues pour le texte cible :", nrow(candidats), "\n")
print(candidats)

# =========================
# 7. Fonction utilitaire
# =========================

nom_propre <- function(x) {
  x <- gsub("\\.txt$", "", x)
  x <- gsub("[^A-Za-z0-9_-]", "_", x)
  x
}

# =========================
# 8. Alignement local
# align_local() peut être très gourmand en mémoire
# on limite donc le nombre d'alignements - l. 30 pour la quantitié
# =========================

candidats_alignement <- head(candidats, nb_alignements_max)

cat("\nNombre d'alignements qui seront réellement lancés :", nrow(candidats_alignement), "\n")

resume_alignements <- data.frame(
  texte1 = character(),
  texte2 = character(),
  similarite = numeric(),
  score_alignement = numeric(),
  statut = character(),
  stringsAsFactors = FALSE
)

for (i in seq_len(nrow(candidats_alignement))) {
  t1 <- candidats_alignement$texte1[i]
  t2 <- candidats_alignement$texte2[i]
  sim <- candidats_alignement$similarite[i]
  
  cat("\n============================\n")
  cat("Alignement", i, "sur", nrow(candidats_alignement), "\n")
  cat("Texte 1 :", t1, "\n")
  cat("Texte 2 :", t2, "\n")
  cat("Similarité :", sim, "\n")
  
  res_align <- tryCatch({
    aln <- align_local(corpus[[t1]], corpus[[t2]])
    
    score <- NA_real_
    if (is.list(aln) && "score" %in% names(aln)) {
      score <- aln$score
    }
    
    fichier_sortie_txt <- file.path(
      dir_sortie_cible,
      paste0(
        "alignement_",
        sprintf("%02d", i), "_",
        nom_propre(t1), "__VS__",
        nom_propre(t2), ".txt"
      )
    )
    
    sink(fichier_sortie_txt)
    cat("Texte 1 :", t1, "\n")
    cat("Texte 2 :", t2, "\n")
    cat("Similarité Jaccard :", sim, "\n\n")
    cat("===== STRUCTURE DE L'OBJET ALIGNEMENT =====\n")
    str(aln)
    cat("\n\n===== CONTENU DE L'OBJET ALIGNEMENT =====\n")
    print(aln)
    sink()
    
    fichier_sortie_rds <- file.path(
      dir_sortie_cible,
      paste0(
        "alignement_",
        sprintf("%02d", i), "_",
        nom_propre(t1), "__VS__",
        nom_propre(t2), ".rds"
      )
    )
    
    saveRDS(aln, fichier_sortie_rds)
    
    # Libération explicite de la mémoire pour éviter une interruption précoce du script
    rm(aln)
    gc()
    
    list(score = score, statut = "ok")
  }, error = function(e) {
    gc()
    list(score = NA_real_, statut = paste("erreur :", conditionMessage(e)))
  })
  
  resume_alignements <- rbind(
    resume_alignements,
    data.frame(
      texte1 = t1,
      texte2 = t2,
      similarite = sim,
      score_alignement = res_align$score,
      statut = res_align$statut,
      stringsAsFactors = FALSE
    )
  )
  
  # Libération supplémentaire
  gc()
}

write.csv(
  resume_alignements,
  file = file.path(dir_sortie_cible, "03_resume_alignements.csv"),
  row.names = FALSE
)

cat("\nTous les alignements sont terminés.\n")
cat("Résultats enregistrés dans :", dir_sortie_cible, "\n")

cat("\n===== TEXTE CIBLE =====\n")
cat("Nom du fichier sur disque :", fichier_cible, "\n")
cat("Identifiant dans textreuse :", id_cible, "\n")

cat("\n===== PAIRES CANDIDATES POUR LE TEXTE CIBLE =====\n")
print(candidats)

cat("\n===== PAIRES EFFECTIVEMENT ALIGNÉES =====\n")
print(candidats_alignement)

cat("\n===== RÉSUMÉ DES ALIGNEMENTS =====\n")
print(resume_alignements)