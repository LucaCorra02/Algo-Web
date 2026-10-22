#import "../template.typ": *

== Osservazioni preliminari e accesso alle sequenze compresse

Quando si analizza una sequenza compressa (come una lista di affissione), l'accesso diretto all'$i$-esimo elemento non è supportato nativamente in tempo costante, poiché la compressione impedisce di saltare linearmente ai dati precedenti senza una decodifica sequenziale.

Per superare questo limite e gestire interrogazioni complesse in modo efficiente, si ricorre a due strumenti:

- L'operazione di *greatest upperbound* (minimo dei maggioranti / massimo dei minoranti), definita come la capacità di individuare rapidamente il *primo elemento della lista maggiore o uguale a un dato valore target $i$*.

#example[
  Dato il target $i$, si cerca il primo elemento della lista tale per cui $"elemento" >= i$.
]

- Una struttura d'appoggio, la *skip table*, che permette di raggiungere rapidamente l'intorno del punto cercato.

=== Tecnica di campionamento (Skip Table)

Per eseguire questa ricerca in tempi ridotti, si affianca alla lista di affissione una struttura di supporto: un parametro di campionamento $q$ che suddivide la sequenza a intervalli regolari.

- Si memorizza una tabella esplicita contenente i valori campionati ed i relativi puntatori.
- Per ciascun puntatore campionato, viene registrata l'esatta posizione all'interno del *bit stream*.


#note[
  Più $q$ è grande, più il campionamento è lasso (tabella più compatta, scansione locale più lunga); più $q$ è piccolo, più il campionamento è fitto (tabella grande, accesso più diretto).
]

Grazie a questa struttura, l'algoritmo procede in due fasi:

1. Ricerca binaria all'interno della tabella dei campioni per individuare il minore dei maggioranti.
2. Scansione sequenziale locale limitata all'interno del blocco di bit individuato.

Il costo computazionale complessivo risulta pari a:
$
  underbrace(O(log(f/q)), "ricerca binaria sui campioni") + underbrace(O(q), "scansione del blocco")
$
dove $f$ è la lunghezza totale della lista e $q$ la dimensione del campione.

#align(center)[
  #image("../assets/skip_table.png")
]

#note[
  La medesima tecnica può essere impiegata per ricavare l'$i$-esimo elemento, sebbene il suo utilizzo principale resti legato a campionamenti statistici e misurazioni di prestazione.
]

=== Architettura fisica dell'indice su disco
Un indice invertito completo (come quello adottato dai motori di ricerca su larga scala) è costituito dai seguenti componenti logici memorizzati su disco:

#align(center)[
  #image("../assets/architettura_indice.png")
]

Per recuperare la lista di affissione:
1. Si individua il termine, se ne estrae l'id (rango) tramite la mappa;
2. Dal rango si ottiene il puntatore al valore più vicino;
3. i accede all'indice per avviare la lettura sequenziale.

#note[
  Nei sistemi distribuiti o frammentati (es. architetture Web), l'indice è suddiviso in più porzioni, rendendo necessario coordinare molteplici liste di puntatori.
]

== Information Retrieval System (IRS)

Formalmente, un Information Retrieval System è modellato come una *funzione di ranking* che mappa una coppia di documento e query in un numero reale:
$ R : D times Q -> RR $
Dove $D$ è la collezione documentale e $Q$ l'insieme delle interrogazioni. Il sistema assegna a ogni documento un *punteggio di pertinenza*: 

- un punteggio *nullo* ($0$) indica estraneità e il documento viene scartato;
- i punteggi *positivi* definiscono la graduatoria (*rango*) dei risultati.

Il linguaggio di interrogazione $Q$ è composto da atomi (stringhe) combinati tramite *operatori logici*:
- Congiunzione: $q_0 and q_1$
- Disgiunzione: $q_0 or q_1$
- Negazione: $not q$

=== Semantica Insiemistica

La semantica delle query *booleane* si basa sugli insiemi di documenti:

- La semantica di un termine base $["Termine"]$ corrisponde alla sua lista di affissioni (l'insieme dei documenti in cui compare). Se il termine non è indicizzato, restituisce l'insieme vuoto.

#note[
  - $[q_0 or q_1] = [q_0] union [q_1]$

  - $[q_0 and q_1] = [q_0] inter [q_1]$

  - $[not q] = D \\ [q]$ (Complemento rispetto all'intera collezione)

  #align(center)[
    #image("../assets/semantica_insiemistica.png")
  ]
]

=== TAAT vs DAAT

Le strategie implementative fondamentali per la risoluzione delle query si dividono in due categorie:

1. *TAAT (Term-At-A-Time):*
  - Elabora *un termine alla volta*, esaminando per intero la sua posting list prima di passare al termine successivo e accumulando i risultati intermedi (usa quindi le intersezioni *eager*).
  #note[ Ottimale per collezioni di piccole dimensioni, come nel caso di cataloghi di biblioteche. ]

2. *DAAT (Document-At-A-Time):*
  - Risolve la query valutando un documento alla volta attraverso tutte le liste coinvolte. È un approccio intrinsecamente *pigro* (lazy) che esegue il minimo sforzo computazionale indispensabile.
  - Nei motori Web moderni è lo standard obbligato per abilitare tecniche di terminazione precoce (*early termination*).

#align(center)[
  #image("../assets/taat_vs_daat.png")
]

== Valutazione Eager (Solerte)

Nella valutazione eager (solerte) si alloca esplicitamente un vettore in memoria per calcolare e memorizzare l'intero risultato della computazione.

- *Complemento (NOT):* Si alloca un vettore della dimensione dei documenti esclusi (meno i documenti di $[q]$)e si compila con il set complementare.

#align(center)[
  #image("../assets/eager_not.png")
]

- *Intersezione (AND):* Si confrontano gli indici mediante un merge lineare in tempo $O(n)$.

#align(center)[
  #image("../assets/eager_and_merge.png")
]

- *Caso ottimizzato (Lista corta + Lista lunga):* Se una lista è notevolmente più ridotta dell'altra, si preferisce effettuare una ricerca dicotomica (binaria) degli elementi della lista corta all'interno di quella lunga.

#align(center)[
  #image("../assets/corta_lunga.png")
]

=== Galloping Search

La *galloping search* è una variante della ricerca binaria ottimizzata per sfruttare la vicinanza locale dei risultati sul bordo sinistro:

- Si parte dall'inizio dell'array procedendo a passi di ampiezza raddoppiata (galoppo) fino a superare il valore di interesse.

- Raggiunto il limite, si effettua una ricerca ristretta (es. lineare o binaria) nell'intervallo circoscritto.

#align(center)[
  #image("../assets/galloping.png")
]

=== Ottimizzazione delle intersezioni multiple

Quando si elaborano congiunzioni multiple, la strategia ottimale prevede di:

1. Ordinare le liste in ordine crescente di frequenza (lunghezza).

2. Partire dalla lista più corta per filtrare progressivamente i candidati tramite argomenti sempre più restrittivi.

3. Posticipare il lavoro oneroso sulle liste dense solo quando il numero di candidati residui è ridotto al minimo.

#align(center)[
  #image("../assets/intersezioni_multiple.png")
]

=== Unione (OR) con Coda di Priorità (Min-Heap)

Per l'unione di più liste ordinate si utilizza un *k-way merge* basato su una coda di priorità indiretta (*min-heap*).

#align(center)[
  #image("../assets/or_kway_merge.png")
]

== Valutazione Lazy (Pigra)

Nell'approccio lazy l'insieme dei risultati non viene precalcolato. Si utilizzano iteratori dotati di operatori di avanzamento (`next`) e di salto (`skip`) per produrre i risultati in modo incrementale.

- *COMPLEMENTO (NOT) lazy:* Iteratore con operatore `next` che calcola pigramente il complemento a partire da un contatore iniziale.

#align(center)[
  #image("../assets/lazy_not.png")
]

- *UNIONE (OR) lazy:* Coda di priorità indiretta basata su iteratori `next` anziché su vettori statici.

- *INTERSEZIONE (AND) lazy (Minimo dei maggioranti / Min-Mag):* Si sfruttano iteratori con `next` e `skip` (replica semi-pigra).

#align(center)[
  #image("../assets/lazy_and_skip.png")
]

- *Algoritmo greedy:* Dato un candidato iniziale $x$ ricavato dalla prima lista, si invocano i minimi dei maggioranti sulle altre liste. Se i puntatori convergono sullo stesso documento $z$, questo viene emesso; in caso contrario, il processo riparte aggiornando il candidato con il nuovo massimo riscontrato.

#align(center)[
  #image("../assets/lazy_and_flusso.png")
]

#note[
  *Punto chiave:* Grazie all'operatore `skip`, anche saltando porzioni consistenti di liste, si preserva l'invariante di correttezza senza perdere alcun documento valido.
]

== Implementazione dei Skip su Operazioni Composte

L'integrazione dell'operazione di `skip` sulle strutture composte gestisce i salti in base alla gerarchia degli operatori logici:

- *Skip su congiunzioni (AND / link-sections):* Per effettuare uno *skip-to* non è necessario saltare in parallelo su tutte le liste. Si avanza in modo lazy il candidato (o l'iteratore) per cui il salto è più efficiente; raggiunto il nuovo valore, si riavvia l'algoritmo di allineamento (Min-Mag), che riallinea gli iteratori delle altre liste.

- *Skip su disgiunzioni (OR):* Si applica il salto sulla lista in cima all'heap (*top*) fino a quando il suo valore soddisfa la soglia richiesta.

#align(center)[
  #image("../assets/skip_or.png")
]

- *Skip su negazioni (NOT):* L'iteratore del complemento viene adattato per avanzare direttamente oltre il punto saltato.

#align(center)[
  #image("../assets/skip_not.png")
]

#align(center)[
  #image("../assets/albero_query_skip.png")
]