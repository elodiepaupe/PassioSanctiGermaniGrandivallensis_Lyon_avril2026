# 1. Configuration

from pathlib import Path
import os
import re
import sys
import shutil
import subprocess

# ===== À ADAPTER =====
INPUT_DIR = Path("**chemin du dossier où se trouvent les fichiers à lemmatiser**")
OUTPUT_DIR = Path("**chemin du dossier où enregistrer les fichiers lemmatisés**")

# dossier temporaire pour les fichiers normalisés
TMP_DIR = OUTPUT_DIR / "_tmp_lasla"

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
TMP_DIR.mkdir(parents=True, exist_ok=True)

print("INPUT_DIR :", INPUT_DIR)
print("OUTPUT_DIR:", OUTPUT_DIR)

# 2. Fonctions utilisées
# Normalisation: réduction des espaces multiples, suppression des retours à la ligne

def read_file(path: Path) -> str:
    for enc in ("utf-8", "utf-8-sig", "latin-1", "cp1252"):
        try:
            return path.read_text(encoding=enc)
        except UnicodeDecodeError:
            continue
    raise ValueError(f"Impossible de lire {path}")

def normalize_spaces(text: str) -> str:
    text = re.sub(r"\s+", " ", text)
    return text.strip()

def prepare_temp_input(src_path: Path) -> Path:
    text = read_file(src_path)
    text = normalize_spaces(text)
    tmp_path = TMP_DIR / src_path.name
    tmp_path.write_text(text, encoding="utf-8")
    return tmp_path

def run_lasla_cli(txt_path: Path):
    cmd = ["pie-extended", "tag", "lasla", str(txt_path)]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result

def show_result(result):
    print("RETURN CODE:", result.returncode)
    print("\nSTDOUT (début):\n")
    print(result.stdout[:4000])
    print("\nSTDERR:\n")
    print(result.stderr[:4000])

from typing import List

def extract_lemmas_from_pie_file(pie_path) -> List[str]:
    lemmas = []

    with open(pie_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    if not lines:
        return lemmas

    # ignorer l'en-tête
    for line in lines[1:]:
        line = line.strip()
        if not line:
            continue

        cols = line.split("\t")
        if len(cols) >= 2:
            lemma = cols[1].strip().lower()
            if lemma and lemma != "_":
                lemmas.append(lemma)

    return lemmas

# 3. Production sur tout le dossier
# La suite du code parcourt tous les fichiers .txt et envoie chaque fichier à LASLA. Seule la deuxième colonne est extraite (le lemme) et le tout est enregistré dans le dossier défini avec l'extension _lemma.txt

from tqdm import tqdm

txt_files = sorted(INPUT_DIR.glob("*.txt"))

for path in tqdm(txt_files, desc="Lemmatisation LASLA", unit="fichier"):
    # affichage optionnel du fichier en cours
    tqdm.write(f"→ {path.name}")

    # préparer le fichier temporaire d'entrée
    tmp_path = prepare_temp_input(path)

    # lancer LASLA
    result = run_lasla_cli(tmp_path)

    if result.returncode != 0:
        tqdm.write(f"[ERREUR] {path.name}")
        tqdm.write(result.stderr)
        continue

    # récupérer le fichier -pie.txt produit
    pie_output = tmp_path.with_name(tmp_path.stem + "-pie.txt")

    if not pie_output.exists():
        tqdm.write(f"[ERREUR] sortie LASLA introuvable pour {path.name}")
        continue

    # extraire les lemmes
    lemmas = extract_lemmas_from_pie_file(pie_output)

    # écrire le fichier final directement dans OUTPUT_DIR
    out_path = OUTPUT_DIR / f"{path.stem}_lemma_lasla.txt"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(" ".join(lemmas))

    tqdm.write(f"✔ Sauvé : {out_path.name}")

    # nettoyage
    try:
        tmp_path.unlink()
    except:
        pass

    try:
        pie_output.unlink()
    except:
        pass

print("✅ Terminé")
