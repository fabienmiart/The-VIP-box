import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
from tkinter import Tk, filedialog

# Ouvrir une boîte de dialogue pour sélectionner le fichier CSV
root = Tk()
root.withdraw()
nom_fichier = filedialog.askopenfilename(title="Sélectionnez un fichier CSV", filetypes=[("Fichiers CSV", "*.csv")])

if not nom_fichier:
    exit()

# Charger le fichier CSV
donnees = pd.read_csv(nom_fichier)

# Sélectionner la colonne X avec le plus grand nombre de lignes
colonne_max = donnees.columns[donnees.applymap(lambda x: isinstance(x, (int, float))).all(axis=0)].max()

# Renommer la colonne X sélectionnée en "Plant lenght"
donnees['Plant lenght'] = donnees[colonne_max]

# Supprimer toutes les autres colonnes commençant par X
colonnes_a_supprimer = [colonne for colonne in donnees.columns if colonne.startswith('X')]
donnees = donnees.drop(colonnes_a_supprimer, axis=1)

# Créer une plot map
nombre_colonnes_X = len(donnees.columns) - 1
x_values = np.linspace(0, nombre_colonnes_X - 1, len(donnees['Plant lenght']))

plt.figure(figsize=(12, 8))

# Utiliser une seule instance d'imshow pour combiner les kymographes
plt.imshow(
    [donnees[colonne_Y].values for colonne_Y in donnees.columns[1:]],
    cmap='viridis',
    aspect='auto',
    extent=[0, len(donnees.columns[1:]), len(donnees.columns[1:]), 0],  # Inverser les axes
    origin='upper'  # Spécifier l'origine en haut à gauche
)

# Ajouter une rotation de 90° vers la gauche
plt.xticks([])  # Supprimer les graduations de l'axe des abscisses
plt.yticks(rotation=90)  # Rotation de l'axe des ordonnées
plt.ylabel('Number of slice')  # Renommer l'axe des ordonnées

plt.colorbar()
plt.title('Combined Kymograph')

# Enregistrer la figure générée dans le même dossier que le fichier sélectionné
nom_fichier_sans_extension = nom_fichier.rsplit('.', 1)[0]  # Supprimer l'extension .csv
nom_figure = f"{nom_fichier_sans_extension}_kymograph.png"
plt.savefig(nom_figure)

# Afficher le graphique
plt.show()

# Fermer la fenêtre de la boîte de dialogue
root.destroy()

