#import "../template.typ": *

#theorem()[
  Se prendiamo una matrice non negativa $A$, allora A rappresenta un grafo fortemente connesso (se prendiamo gli elementi di $A$ come archi del grafo). Formalmente:
  $
    forall i,j space exists k: A^k_(i,j) > 0
  $
  Allora:
  1. Esiste un autovalore positivo dominante di moltiplicità uno
  2. L'autovettore associato è estremamente positivo

  #note()[
    A noi interessa che c'è un vettore con tuti i segni uguali. Il vettore che scelgo per rappresentare il grafo deve avere lo stesso segno, altrimenti si scambiano i versi del grafo.

    Gli autovettori sono estremamente ortogonali, se c'è ne uno tutto positivo allora gli altri hanno per fornza segni diversi.
  ]
]
Data una matrice M del web facciamo $1 * M$ ovvero conto quanti siti mi puntano (il numero di archi entranti). Se facessi il prodotto a destra sto sommando le righe, ovvero ottengo l'out-degree.

Se moltiplichiamo l'in degree per M, vado a sommare gli in degree dei predecessori, ottenendo un punteggio più raffinato:
$
  "in"_"deg" M = 1 M^2
$
Se trovo un vettore $v M = lambda v$ posso usare il vettore $v$ come punteggio di importanza dei siti. Se faccio l'operazione più volte ottengo un punteggio scalato di una costante $lambda$. Se applichiamo la procedura all'infinito otteniamo l'autovettore dominante:
$
  1 M^k / (||1 M^k||) -> "vet dominante"
$
la norma serve in quanto dobbiamo scalare il vettore per far convergere la procedura. In pratica stiamo facendo un *power method*, che converge all'autovettore dominante.

In maniera esplicita partiamo da un vettore v. Lo scriviamo come combinazione lineare di eignevettori:
//riguardare
$
  v M^k = (sum_i alpha_i theta_i) M^k = sum_i alpha_i lambda_i^k v_i = sum_i a_i l n^k
$
mttiamo gli autovalori in ordine decrescente di modulo. Allora il termine dominante è quello con l'autovalore di modulo maggiore, e quindi:
$
  a_0 lambda_0^k v_0 + sum_(i>0) a_i lambda_i^k v_i \
  "raccogliamo" lambda_0^k \
  = lambda_0^k (a_0 v_0) + sum_(i>0) a_i (lambda_i/lambda_0)^k v_i \
  "siccome" |lambda_0| > |lambda_i|, "allora il limite per k->infinito"\
  = lambda_0^k (a_0 v_0)
$
iterando il procedimento di $k$ otteniamo un vettore che converge all'autovettore dominante.

#warning()[
  Affinchè questa procedura funzioni il vettore iniziale $v$ deve avere una componente non nulla nella direzione dell'autovettore dominante. In pratica, basta prendere un vettore iniziale di tutti uni
]

Se prendiamo un flip flop (un grafo ciclilo), con matrice 0 1, 1 0. in questo caso abbiamo due autovalori (1 e -1) dominanti, quindi il metodo non converge.

#note()[
  Esiste un rapporto tra le operazioni matriciali e discrete esprimibili sui grafi:
  - prodotto riga per colonna a sinistra: Se abbiamo la matrice di adiacenza di un grafo e moltiplichiamo un vettore, questo equivae a guardare gli archi entranti e sommare i pesi dei vicini entranti. La matrice di adicienza (una colonna) agisc come selettore di vertici, prende solo i predecessori e somma i pesi dei vicini entranti.

  - prodotto riga per colonna a destra: Gli uni della marice di adiacenza agiscono come selettore dei successori. Il risultato è pesare il grado con la somma dei pesi dei successori.

  - Prodotto matrice per se stessa:

    Esempio con matrice:
    $
      mat(
        0, 1, 0, 1;
        0, 0, 1, 1;
        0, 1, 0, 1;
        1, 1, 0, 0
      )
    $
    In questo prodotto scalare troviamo un uno da sommare, significa che c'è un arco dal nodo della riga al nodo della colonna. Contiamo il numero di cammini di lunghezza due tra il nodo della riga e il nodo della colonna.

    Esempio con colonna 3 e riga 1. Mi chiedo se c'è un cammino da 1 in 2 e uno che va da 2 in 3 e c'è. Quindi conto uno. C'è esattamente un cammino di lunghezza due da 1 a 3.

    Quindi A_k contiene il numero di cammini di lunghezza k tra i vertici del grafo i e j.

    $
      forall i,j space exists k: A^k_(i,j) > 0
    $
    per ogni vertice i e j esiste un cammino di lunghezza k che collega i a j. Questo significa che il grafo è fortemente connesso.
]


== Autovettore centralità (Eigenvector centrality)

Data una matrice $M$ usiamo come punteggio assegnato ai vertici un autovettore $v$ associato al autovalore dominante $lambda$:
$
  v M = lambda_0 v
$
se il grafo è fortemente connesso, allora l'autovettore dominante è unico e positivo. In questo caso il punteggio di importanza dei vertici è dato da un autovettore positivo.

== Indice di segley

Si vorrebbe valutare il prestigio di ogni nodo del grafo tramite una definizione ricorsiva. Il punteggio di un nodo dipende dalla somma dei punteggi dei nodi che lo hanno raccomandato. Non è risolubile. Tuttavia se un nodo raccomanda tutti i nodi esso non deve contare come un nodo con tanta reputazione.
$
  S_i = sum_(j in N(i)) S_j / d_j
$
$j$ invia la sua aura a tutti i suoi vicini ma la manda in maniera equa. Dividiamo quindi per il grado del nodo da cui proviene il tuo prestigio. In modo tale gente che raccomanda tutti non conti tanto.

#warning()[
  é spettrale in quando sommando sui predecessori stiamo facendo un prodotto vettore per matrice a sinistra. Tuttavia ogni riga della matrice deve essere divisa per l'out-degree del nodo.  Questo richiede che ogni riga sia divisa per la somma ovvero nomrlizzazione in norma L_1:
  $
    s = s hat(A)
  $
  diventa quindi un euquazione di autovettore. Dove l'autovalore è 1. Inoltre esiste sempre un atuovettore per l'autovalore 1. In quanto se moliplichiamo a destra per la matrice normalizzata un vettore di tutti uni
]

=== Catene di markov

Una catena è definita da uno stato iniziale e una matrice di adiacienza. Lo stato effettivo della catena è un vettore di probabilità. La matrice di adiacenza deve essere normalizzata in modo tale che la somma delle righe sia 1. In questo caso la matrice diventa una matrice stocastica.

Se moltiplico il vettore di probabilità a sinistra (uno per i vari vertici) e su una matrice colonna ho le probabilità di entrata del nodo che sto considerando. Quando ho fatto tutto il prodotto riga per colonna ho la probabilità di essere nello stato 0,1,2 se adesso c'è una determinata configurazione di probabilità. In pratica sto facendo un passo della catena di markov.

Lo stato stabil della catena è nel limite di visitare un nodo seguendo le indicazioni della matrice di transizione. Contando il numero di volte che visito un nodo e dividendo per il numero di passi, ottengo la probabilità di visitare quel nodo. In questo caso lo stato stabile è l'autovettore dominante della matrice di transizione $pi M = pi$.

Questo modello si riflette nel random surfer. Parte da una pagine qualunque e visita dei siti in maniera equiprobabile, contanto quante volte visito una pagina. Otteniamo un punteggio proporzionale alla stabilità della centralità dell'autovettore.

Cosa succede se il grafo *non è fortemente connesso*? Qualunque visitatore dopo un po di tempo entra in una componente fortemente conessa e non riesce più a uscire. Tuttavia è impossibile che ci siano dei punteggi negativi, quindi l'autovettore dominante esiste ma non è unico. Inoltre hanno tutti valore zero nelle componenti non terminatli

Seely si può usare solo su grafi fortemente connessi.



