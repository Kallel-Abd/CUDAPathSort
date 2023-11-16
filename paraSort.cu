#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <assert.h>

//Compile
//nvcc paraSort.cu -o DQ


// Function that catches the error 
void testCUDA(cudaError_t error, const char *file, int line)  {
	if (error != cudaSuccess) {
	   printf("There is an error in file %s at line %d\n", file, line);
       exit(EXIT_FAILURE);
	} 
}

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

bool isSorted(int arr[], int n) {
    for (int i = 1; i < n; i++) {
        if (arr[i-1] > arr[i]) {
            return false; // Si un élément précédent est supérieur à un élément suivant, le tableau n'est pas trié
        }
    }
    return true; // Si nous avons parcouru tout le tableau sans trouver d'éléments non triés
}


// Has to be defined in the compilation in order to get the correct value 
// of the macros __FILE__ and __LINE__
#define testCUDA(error) (testCUDA(error, __FILE__ , __LINE__))

__global__ void mergeSmall_k(int* A ,int sizeA, int* B,int sizeB, int* M){
    assert(sizeA+sizeB <= 1024);
    
    int i = threadIdx.x;
    int Kx, Ky, Px, Py;
    if (i >= sizeA) {
        Kx = i - sizeA;
        Ky = sizeA;
        Px = sizeA;
        Py = i - sizeA;
    } else {
        Kx = 0;
        Ky = i;
        Px = i;
        Py = 0;
    }

    while (1) {
        int offset = abs(Ky - Py) / 2;
        int Qx = Kx + offset;
        int Qy = Ky - offset;

        if (Qy >= 0 && Qx <= sizeB && (Qy == sizeA || Qx == 0 || A[Qy] > B[Qx - 1])) {
            if (Qx == sizeB || Qy == 0 || A[Qy - 1] <= B[Qx]) {
                if (Qy < sizeA && (Qx == sizeB || A[Qy] <= B[Qx])) {
                    M[i] = A[Qy];
                } else {
                    M[i] = B[Qx];
                }
                break;
            } else {
                Kx = Qx + 1;
                Ky = Qy - 1;
            }
        } else {
            Px = Qx - 1;
            Py = Qy + 1;
        }
    }
}

int main(){
    int *a, *b, *m, *aGPU, *bGPU, *mGPU, sizeA, sizeB;
    float TimeVar;
    cudaEvent_t start, stop;
    testCUDA(cudaEventCreate(&start));
    testCUDA(cudaEventCreate(&stop));

    sizeA = sizeB = 120;
    int sizeM = sizeA + sizeB;

    // Initialisez le générateur de nombres aléatoires
    srand(time(NULL));

    printf("Generating A and B :\n");
    a = generateSortedRandomArray(sizeA);
    b = generateSortedRandomArray(sizeB);
    m = (int*)malloc(sizeM * sizeof(int)); // Allocation de mémoire pour m
    if (!m) {
        printf("Erreur d'allocation de mémoire pour m.\n");
        exit(1);
    }
    if (isSorted(a,sizeA)){
        printf("A is sorted of size = %d\n",sizeA);
    }
    if (isSorted(b,sizeB)){
        printf("B is sorted of size = %d\n",sizeB);
    }

	testCUDA(cudaMalloc(&aGPU,sizeA*sizeof(int)));
	testCUDA(cudaMalloc(&bGPU,sizeB*sizeof(int)));
	testCUDA(cudaMalloc(&mGPU,sizeM*sizeof(int)));

	testCUDA(cudaEventRecord(start,0));

    testCUDA(cudaMemcpy(aGPU, a, sizeA*sizeof(int),	cudaMemcpyHostToDevice)); 
    testCUDA(cudaMemcpy(bGPU, b, sizeB*sizeof(int),	cudaMemcpyHostToDevice));
    printf("Sorting A and B to M ...\n"); 
    mergeSmall_k<<< 1,sizeM >>>(aGPU,sizeA,bGPU,sizeB,mGPU);

    testCUDA(cudaMemcpy(m, mGPU, sizeM*sizeof(int),	cudaMemcpyDeviceToHost));
    if (isSorted(m,sizeM)){
        printf("M is sorted\n");
    }
	
	testCUDA(cudaEventRecord(stop,0));
	testCUDA(cudaEventSynchronize(stop));
	testCUDA(cudaEventElapsedTime(&TimeVar, start, stop));
	testCUDA(cudaEventDestroy(start));
	testCUDA(cudaEventDestroy(stop));
	testCUDA(cudaFree(aGPU));
	testCUDA(cudaFree(bGPU));
	testCUDA(cudaFree(mGPU));
	free(a);	
    free(b);	
    free(m); // Libération de la mémoire pour m

    printf("Processing time when using malloc: %f s\n", 0.001f * TimeVar);
    
    return 0;
}