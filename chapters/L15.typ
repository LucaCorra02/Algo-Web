#import "../template.typ": *

= Introduzione e Obiettivo: Funzioni Statiche vs Dizionari

Il nostro obiettivo è mappare i termini nel loro rango per poter risolvere le interrogazioni in modo efficiente. Utilizzare una tabella di hash tradizionale occuperebbe troppo spazio.

Lo scopo principale è costruire strutture dati che memorizzino questa mappa *senza memorizzare le chiavi*. Esiste una differenza fondamentale:
- *Memorizzare una funzione* è diverso da *memorizzare un dizionario*.
- Il *dizionario* può dirci se la chiave è presente o meno nell'insieme.
- La *funzione statica* ha il solo scopo di restituire il valore associato per gli elementi appartenenti all'insieme; se interroghiamo la struttura con una chiave esterna all'insieme, il risultato è del tutto imprevedibile.

== Rappresentazione di una funzione statica
Supponiamo di avere $x in U$ e una funzione $f : X -> 2^b$. Vogliamo costruire una struttura dati statica (chiamata così perché dipende interamente da $f$). Questa funzione possiede un metodo `get` che, dato un elemento dell'universo $U$, restituisce un vettore di bit.

Se interroghiamo la struttura su un elemento $x$, il risultato deve essere $f(x)$, mentre non ci interessa il comportamento sul resto di $U$. Questo ci svincola dal dover memorizzare l'intero insieme $X$.

- Spazio teorico minimo: $log((|U|)/(|X|))$
- Spazio per l'output: $|X| b$

L'obiettivo è eliminare il termine dipendente da $|U|$ (che è molto grande) evitando di memorizzare esplicitamente l'insieme $X$.

== Utilizzo pratico
Ponendo $b = log(|T|)$, possiamo mappare ogni termine nel suo rango utilizzando $|T| log(|T|)$ bit.

= Costruzione della Funzione Statica (Sistemi Lineari e XOR)

L'idea per costruire la funzione è utilizzare un insieme di funzioni hash aleatorie. Vogliamo spendere in memoria solo i bit strettamente necessari per l'output.

Prendiamo due funzioni hash aleatorie che mappano dall'universo $U$ a un intero $m$ fissato, tale che $m > |X|$ (con $n$ chiavi):
- $g : U -> m$
- $h : U -> m$

Scriviamo il sistema aleatorio utilizzando il gruppo abeliano dato dallo XOR bit a bit (in $ZZ_2$, dove non servono coefficienti numerici oltre a $0$ e $1$):

$ v_(g(x)) xor v_(h(x)) = f(x) quad forall x in X $

Prendiamo la variabile $v$ indicizzata da $g(x)$ e quella indicizzata da $h(x)$, imponendo che il loro XOR dia la costante $f(x)$. A sinistra abbiamo le variabili, a destra la costante.

La struttura finale consisterà in:
1. Le due funzioni hash $g$ e $h$.
2. Un vettore di $m$ bit (la soluzione del sistema).

Per calcolare $f(x)$, prendiamo $g(x)$ e $h(x)$, guardiamo le posizioni corrispondenti nel vettore di bit e facciamo lo XOR tra di loro. Lo XOR può teoricamente fallire, ma esistono tecniche specifiche per risolverlo. Il vettore occupa $m b$ bit; l'obiettivo è ridurre $m$ affinché sia il più vicino possibile a $n$.

#note()[
  Dato che si tratta di una funzione statica, se interroghiamo la struttura con una chiave $z in.not X$, il risultato sarà imprevedibile. La struttura garantisce il comportamento corretto solo con la promessa che $x in X$. Se mantenuta in cache, questa struttura è nettamente più veloce di una tabella di hash per memorizzare associazioni chiave-valore.
]

== Esempio passo-passo: query con vettore e XOR

#example()[
  *Scenario:* Vogliamo memorizzare $f("cane") = 42$ usando un vettore $v$ di $m = 8$ celle da $b$ bit ciascuna, con due funzioni hash $g$ e $h$.

  *Fase di costruzione:*

  Supponiamo che le funzioni hash producano:
  $ g("cane") = 2 quad h("cane") = 5 $

  Dobbiamo soddisfare l'equazione:
  $ v[2] xor v[5] = 42 $

  Una soluzione possibile è $v[2] = 0$, $v[5] = 42$ (oppure qualunque coppia il cui XOR valga $42$). Le celle rimanenti $v[0], v[1], v[3], v[4], v[6], v[7]$ vengono usate da altre chiavi o lasciate a $0$.

  *Fase di query (dato $x = "cane"$):*

  + Calcoliamo $g("cane") = 2$ e $h("cane") = 5$.
  + Leggiamo $v[2]$ e $v[5]$ dal vettore.
  + Restituiamo $v[2] xor v[5] = 0 xor 42 = 42 = f("cane")$. ✓

  *Chiave esterna (es. $x = "pippo"$):* Se $g("pippo") = 3$ e $h("pippo") = 5$, otteniamo $v[3] xor v[5]$, che è un valore casuale non significativo. La struttura *non* garantisce nulla per chiavi fuori da $X$.
]

//immagine

= Risolubilità del Sistema e Teoria dei Grafi

Perché il sistema è risolvibile? Se $m$ è abbastanza grande, il sistema ammette soluzione.

Possiamo visualizzare il sistema come un grafo con $m$ nodi (variabili) in cui ogni chiave rappresenta un collegamento (lato) tra due nodi. Costruiamo il grafo inserendo tutte le chiavi.

#example()[
  *Esempio di grafo associato a un sistema lineare:*
  Siano $X = \{k_1, k_2, k_3\}$ tre chiavi e $m = 4$ variabili nel vettore ($v_0, v_1, v_2, v_3$). Supponiamo che le funzioni hash associno:
  - $k_1 -> g(k_1)=1, quad h(k_1)=2 -> v_1 xor v_2 = f(k_1)$
  - $k_2 -> g(k_2)=2, quad h(k_2)=3 -> v_2 xor v_3 = f(k_2)$
  - $k_3 -> g(k_3)=1, quad h(k_3)=3 -> v_1 xor v_3 = f(k_3)$

  Nel grafo corrispondente, i nodi sono $\{0, 1, 2, 3\}$ e i lati sono i collegamenti $\{1,2\}$, $\{2,3\}$ e $\{1,3\}$. Il nodo $0$ risulta isolato (variabile libera, sarà posta a $0$).

  //immagine
]

== L'Esfoliazione (Peeling)
L'idea consiste nel rimuovere iterativamente le foglie dal grafo (vertici con grado $<= 1$). La foglia non compare in nessun'altra equazione, quindi la rimuoviamo mettendo da parte la chiave corrispondente in una pila. Scannerizzando la pila in ordine inverso, troviamo equazioni che contengono ogni volta una singola variabile libera.

Il problema principale è la presenza di cicli: il grafo deve essere aciclico affinché il sistema sia triangolarizzabile (e quindi risolvibile in modo lineare).

#note()[
  Esfoliare è un'operazione lineare, il che rappresenta un enorme vantaggio per la triangolarizzazione del sistema.
]

#warning()[
  Dobbiamo ricordarci di memorizzare con un bit l'informazione sulla variabile dell'equazione che era una foglia.
]

== Esempio passo-passo: Esfoliazione (Peeling)

#example(title: "Caso con ciclo — peeling fallisce")[
  Consideriamo il grafo dell'esempio precedente con nodi $\{0, 1, 2, 3\}$ e lati $k_1: (1,2)$, $k_2: (2,3)$, $k_3: (1,3)$. I gradi iniziali sono:

  #table(
    columns: (auto, auto, auto),
    align: center,
    table.header([*Nodo*], [*Grado*], [*Note*]),
    [$0$], [$0$], [isolato → *foglia*],
    [$1$], [$2$], [collegato a $k_1$, $k_3$],
    [$2$], [$2$], [collegato a $k_1$, $k_2$],
    [$3$], [$2$], [collegato a $k_2$, $k_3$],
  )

  *Step 1 — Foglia isolata:*
  - Il nodo $0$ ha grado $0$ (foglia). Non è associato ad alcun lato, quindi è una *variabile libera*.
  - Mettiamo $0$ in cima alla pila: `STACK = [v₀]`. Rimuoviamo il nodo $0$ dal grafo.

  *Step 2 — Nessuna nuova foglia (ciclo!):*
  - I nodi $1$, $2$, $3$ hanno tutti grado $2$: il grafo $1$-$2$-$3$ è un *triangolo* (ciclo di lunghezza 3).
  - Il peeling si *blocca*: il sistema non è triangolarizzabile con questo grafo.
  - Conclusione: occorre *riprovare* con un nuovo seed per le funzioni hash, oppure aumentare $m$.
]

//immagine

#example(title: "Caso senza cicli — peeling completo")[
  Supponiamo $m = 5$, chiavi $k_1: (0,1)$, $k_2: (1,2)$, $k_3: (3,4)$.

  I gradi iniziali sono: nodo $0$→$1$, nodo $1$→$2$, nodo $2$→$1$, nodo $3$→$1$, nodo $4$→$1$.

  #table(
    columns: (auto, auto, auto, auto),
    align: center,
    table.header([*Step*], [*Azione*], [*Stack*], [*Grafo rimanente*]),
    [1], [Nodo $0$ (grado 1) → push $k_1$, grado nodo $1$ scende a 1], [`[k₁]`], [$1$-$2$, $3$-$4$],
    [2], [Nodo $2$ (grado 1) → push $k_2$, grado nodo $1$ scende a 0], [`[k₁,k₂]`], [$3$-$4$],
    [3], [Nodo $1$ (grado 0) → variabile libera], [`[k₁,k₂,v₁]`], [$3$-$4$],
    [4], [Nodo $3$ (grado 1) → push $k_3$], [`[k₁,k₂,v₁,k₃]`], [vuoto],
    [5], [Nodo $4$ (grado 0) → variabile libera], [`[k₁,k₂,v₁,k₃,v₄]`], [—],
  )
]

#example(title: "Risoluzione greedy dallo stack")[
  Estraendo dalla pila in ordine LIFO, ogni equazione ha una sola incognita:
  + $v[4] = 0$ (variabile libera → assegniamo $0$)
  + Da $k_3$: $v[3] xor v[4] = f(k_3)$ → $v[3] = f(k_3) xor 0 = f(k_3)$ ✓
  + $v[1] = 0$ (variabile libera → assegniamo $0$)
  + Da $k_2$: $v[1] xor v[2] = f(k_2)$ → $v[2] = f(k_2) xor 0 = f(k_2)$ ✓
  + Da $k_1$: $v[0] xor v[1] = f(k_1)$ → $v[0] = f(k_1) xor 0 = f(k_1)$ ✓

  Il vettore $v$ è ora completamente determinato: la funzione statica è costruita.
]

== Procedura di Risoluzione (Greedy)
La procedura visita il grafo seguendo le foglie. Risolvendo in modo *greedy* le equazioni dallo stack dall'alto verso il basso, assegniamo i valori a tutte le variabili. Nelle variabili che rimangono libere (non cardine) mettiamo $0$, poiché non necessarie.

#note()[
  *Trucco informatico:* Nella rappresentazione del grafo, invece di mantenere liste di vicini, facciamo lo XOR di tutte le liste insieme. Poiché lo XOR di un elemento con se stesso è zero, man mano che rimuoviamo i vertici aggiorniamo il valore tramite XOR ottenendo direttamente ciò che serve. Il grafo viene rappresentato semplicemente con un vettore di interi.
]

#note()[
  *Nota terminologica:* Nella teoria dei grafi standard, $m$ indica i lati e $n$ i vertici (anche se a volte si inverte la notazione, l'importante è ricordarsi la distinzione concettuale).
]

== La Soglia di Erdős-Rényi
Se il numero di vertici è sufficientemente più grande del numero di lati (grafo sparso), il grafo è aciclico. Per i grafi, se $n >= (2 + epsilon) m$, la probabilità che il grafo sia aciclico è data da:

$ ( sqrt(epsilon (2 + epsilon)) ) / ( 1 + epsilon ) $

Ad esempio, si usa spesso un fattore come $2.09$ per avere circa il $30\%$ di probabilità. Facendo $3$ o $4$ tentativi in media troviamo un grafo aciclico valido.

Il costo della struttura è quindi il numero di variabili moltiplicato per $b$: $(2 + epsilon) n b$. Avere un grafo esfoliabile significa trovarsi di fronte a una foresta. Strutture di questo tipo hanno una costruzione probabilistica ma una risposta deterministica.

#note()[
  La probabilità di successo è positiva, indipendente da $m$ e $n$, e limitata inferiormente da una costante positiva.
]

= Ottimizzazione con gli Ipergrafi (3 Funzioni di Hash)

Come possiamo ridurre il fattore $(2 + epsilon) n b$? Estendendo il modello a tre funzioni di hash:

$ v_(g(x)) xor v_(h(x)) xor v_(c(x)) = f(x) quad forall x in X $

In questo caso utilizziamo *ipergrafi*. Le foglie diventano i vertici coinvolti in un solo iperlato.

#example()[
  *Rappresentazione con gli ipergrafi (3 hash) — passo per passo:*

  Siano $X = \{k_1, k_2\}$ due chiavi e $m = 6$ nodi. Le tre funzioni hash producono:
  - $k_1$: $g(k_1)=0,$ $h(k_1)=2,$ $c(k_1)=4$ → equazione: $v[0] xor v[2] xor v[4] = f(k_1)$
  - $k_2$: $g(k_2)=1,$ $h(k_2)=3,$ $c(k_2)=5$ → equazione: $v[1] xor v[3] xor v[5] = f(k_2)$

  Ogni chiave forma un *iperlato triangolare* che collega 3 nodi. Con 2 funzioni hash sarebbe bastato 1 lato tra 2 nodi, ma serviva un $m$ molto più grande.

  //immagine

  *Peeling sull'ipergrafo:*
  + Un nodo è *foglia* se appartiene a un solo iperlato.
  + Rimuoviamo l'iperlato, aggiorniamo i gradi dei 3 nodi coinvolti.
  + La variabile libera è quella a cui corrispondeva il nodo foglia.
  + La risoluzione XOR ora coinvolge 3 variabili: $v["foglia"] = f(k) xor v["altro_1"] xor v["altro_2"]$.

  Con questo schema la soglia di esfoliabilità scende a $approx 1.22$, portando il costo a circa $1.23 |X| b$.
]

Con gli ipergrafi a 3 funzioni, la soglia per l'esfoliabilità scende a $1.22$, portando il costo a circa $1.23 |X| b$.

L'utilizzo di $3$ funzioni è la soluzione ideale, poiché con $4$ funzioni la situazione peggiora. Superata la soglia di esfoliazione non abbiamo più una garanzia di probabilità strettamente positiva, ma la certezza asintotica ("quasi sempre"). Con mille chiavi, solitamente funziona al primo colpo.

#note()[
  *Soglie:* Le soglie di risolubilità sono più basse di quelle di esfoliabilità. Al crescere di $k$ (numero di funzioni hash), la risolubilità diventa sempre più facile, l'esfoliazione diventa più difficile. Aumentare il numero di funzioni aumenta però gli accessi in memoria e la complessità di risoluzione del sistema lineare.
]

= Applicazioni e Dizionari Compatti

Useremo questo approccio per mappare le parole nel loro rango. Tuttavia, se l'utente inserisce una parola non valida (es. "pippo"), dobbiamo sapere se fa parte dell'indice, altrimenti otterremmo risultati imprevedibili.

== Aggiunta di Firme (Fingerprints)
Per trasformare la funzione statica in un dizionario, aggiungiamo delle *firme*:
1. Prendiamo una buona funzione di hash e memorizziamo in un vettore le firme per ciascun termine.
2. Quando arriva una chiave $x$, calcoliamo $f(x)$ (la funzione statica) e controlliamo se $F(f(x)) = S(x)$.

#example()[
  *Esempio passo-passo di query con firme (Fingerprints):*

  //immagine

  *Caso 1 — Chiave valida* ($x = "cane" in X$):
  + Calcoliamo la funzione statica: $f("cane") = 12$ (il rango di "cane" nell'indice).
  + Leggiamo la firma memorizzata: $F[12]$ dal vettore delle firme.
  + Calcoliamo la firma della chiave: $S("cane")$ tramite una funzione hash crittografica.
  + Confronto: $F[12] == S("cane")$ → *vero* ✓ → la chiave è nell'insieme $X$.

  *Caso 2 — Chiave non valida* ($x = "pippo" in.not X$):
  + Calcoliamo $f("pippo")$ → restituisce un valore casuale, es. $7$.
  + Leggiamo $F[7]$ (firma di qualche altra parola, es. "gatto").
  + Calcoliamo $S("pippo")$.
  + Confronto: $F[7] != S("pippo")$ → *falso* ✗ → la chiave non è nell'insieme $X$.

  La probabilità di falso positivo è $2^(-b)$: scegliendo $b = 64$ bit per le firme, è trascurabile.
]

Questo costa uno spazio proporzionale alla lunghezza dei termini, ma molto meno di una tabella di hash tradizionale.

La funzione statica deve restituire una permutazione di $n$ (nel range $0 ... n$), diventando così una *Funzione di Hash Minimale Perfetta* (MPH), in particolare monotona.

== Filtri di Bloom Statici e Dizionari Compatti
Se vogliamo solo l'identità insiemistica senza recuperare l'output della funzione statica:
- Possiamo costruire un filtro di Bloom statico o un dizionario statico associando a ogni chiave un hash crittografico $S(x)$.
- La funzione statica mappa ogni chiave nella sua firma. Se interroghiamo con una chiave non presente, $g(x)$ restituirà un vettore casuale di $b$ bit.
- Confrontando $g(x)$ con la firma crittografica $S(x)$, possiamo determinare con altissima probabilità se la chiave appartiene all'insieme originario.

Questo approccio permette di scendere a circa $1.44 n b$ o addirittura $1.01 n b$ bit (valori utilizzati attualmente in sistemi come RocksDB), ottenendo un dizionario statico valutabile in tempo costante e molto più compatto di un filtro di Bloom tradizionale.

#note()[
  *Nota concettuale:* $S(x)$ (la funzione hash/firma) è un algoritmo, mentre $G(X)$ è la struttura dati che memorizza effettivamente le informazioni.
]
