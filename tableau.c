#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// Fonction pour comparer deux entiers (utilisée par qsort)
int compare(const void *a, const void *b) {
    return (*(int*)a - *(int*)b);
}

// Fonction pour générer et retourner un tableau de n valeurs aléatoires triées
int* generateSortedRandomArray(int n) {
    int *arr = (int*)malloc(n * sizeof(int));
    if (!arr) {
        printf("Erreur d'allocation de mémoire.\n");
        exit(1);
    }

    // Remplir le tableau avec des valeurs aléatoires
    for (int i = 0; i < n; i++) {
        arr[i] = rand() % (n*10);  // Génère des nombres entre 0 et 999
    }

    // Trier le tableau
    qsort(arr, n, sizeof(int), compare);

    return arr;
}

int main() {
    srand(time(0));  // Initialiser le générateur de nombres aléatoires

    int n = 500;  // Par exemple, pour un tableau de taille 10
    int *arr = generateSortedRandomArray(n);

    // Afficher le tableau trié
    for (int i = 0; i < n; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");

    // Libérer la mémoire allouée pour le tableau
    free(arr);

    return 0;
}