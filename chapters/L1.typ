#import "../template.typ": *

= Introduzione

Compresso = conosco la distribuzione dei dati. Posso comprimeri i dati

Succinte = meno conoscenza, minimizzo i dati nel minor spazio possibile sfruttando il teorema di Shannon. Le operazioni hanno lo stesso costo delle strutture dati tradizionali. Per distingure tutti gli alberi binari con $n$ vertici servono $log(2^n) = 2n$ bit.

Le rappresentazione classiche si dicono ridondanti $> 2n "bit"$, usano più bit del necessario. La rappresentazione succinta è quella che usa il minor numero di bit possibile.

Le strutture che vedremo sono a tempo costante, non dipendono da quanti dati ci mettiamo dentro ma da altri parametri come la probabilità di errore.

#note()[
  Il compromesso è *l'immutabilità delle strutture* (strutture statiche). Non si possono modificare, se voglio aggiungere un elemento devo ricostruire la struttura da zero.
]

== Grafi

Grafo $G=<N,A,s,t>$ dove due funzioni $s$ e $t$ vanno da $A->N$ ovvero collegano un arco con un nodo. In questo modo possiamo andare a rappresentare archi paralleli (stesso nodo di partenza e arrivo) in modo da rappresentare pagine linkate più volte.

Sono multigrafi

La funzione $sigma: A -> A$ è la funzione di inversione degli archi:
$
  sigma^2 = 1 "identità"\
  S theta sigma = T "se prenfo un arco lo giro e faccio la sorgente è uguale a prendere il target"
$
In questo modo possiamo inventire gli archi in caso di grafo orientato (nel corso solo grafi non orientati grazie alla funzione di inversione). Gli archi sono quuindi un insieme di coppie non ordinato di nodi.

- *indegree* = numero di vertici che entrano in un nodo
$
  d^-(x) = |{a in A: t(a) = x}|\
$
#note()[
  Misura ppiù difficile da manipolare, dobbiamo farci seguire da tente persone.
]
- *outdegree* = numero di vertici che escono da un nodo
$
  d^+(x) = |{a in A: s(a) = x}|\
$
Se il grafo non è orientato essi coincidono grazie alla funzione di inversione degli archi.

I successori sono i nodi raggiungibili da un nodo $x$ tramite un arco $a$ in un solo passo. I predecessori sono i nodi che raggiungono $x$ tramite un arco $a$ in un solo passo.

Definiamo come *path* un insieme di archi che collegano due nodi $x$ e $y$ in un grafo. Un path può essere rappresentato come una sequenza di archi $a_1, a_2, ..., a_k$ tale che $t(a_i) = s(a_{i+1})$ per ogni $i=1,...,k-1$. La lunghezza del path è il numero di archi che lo compongono (i vertici del cammino possono ripetersi).

#note()[
  Gli archi in entrata e gli archi in uscita in web sono molto diversi. Sapere i successori (segui i link) è molto facile ma sapere i predecessori è molto difficile, devo fare crawling di tutto il web per sapere chi linka chi in modo da ottenere le liste di adiacenza man mano e invertile (ho mano mano delle liste di adiacenza che coprano una parte del web molto piccola)
]

*Raggiungibilita*: Se esiste un path da $x$ a $y$ diciamo che $y$ è raggiungibile da $x$.

*Componenti fortemente connesse*: Relazione di equivalenza tra i vertici $x tilde y$ se sono co-raggiungibili. Se il grafo è orientato possiamo ricavare la relazione con la funzione inversa sugli archi. Deve avere le seguenti proprietà:
- _riflessiva_: $x tilde x$ cammino vuoto
- _simmetrica_: $x tilde y$ implica $y tilde x$ se esiste un path da $x$ a $y$ allora esiste un path da $y a x$ (grafo orientato)
- _transitiva_: $x tilde y$ e $y tilde z$ implica $x tilde z$ se esiste un path da $x$ a $y$ e da $y$ a $z$ allora esiste un path da $x$ a $z$

La relazione di equivalenza ha delle classi di equivalenza che sono le componenti fortemente connesse. Se sono all'interno di una certa classe posso arrivare da un qualsiasi nodo a qualsiasi altro nodo della classe. Se sono in classi diverse può essere che posso passare da una classe all'altra ma non viceversa. (algoritmo di Tarjan per trovare le componenti fortemente connesse in tempo lineare). Questo concetto è solo dei grafi orientati, per i grafi non orientato le componenti sconnesse sono fisicamente separate e non posso passare da una componente all'altra.

//TODO: aggiungere immagine di un grafo con le componenti fortemente connesse

#note()[
  Il problema del crawling non è da dove partiamo (raggiungiamo sempre una buona parte del web) ma è una questione di *tempo* (quanto tempo ci metto a fare crawling di tutto il web).
]

Componente *debolmente connessa*: Considera la funzione di inversione degli archi e il grafo orientato, gli archi possono essere girati in modo da ottenere un grafo non orientato.

*Distanza in un grafo*: lunghezza del path più corto (c'è ne possono essere più di uno) tra due nodi $x$ e $y$. Se non esiste un path tra i due nodi la distanza è $infinity$.
#warning()[
  La distanza non è una metrica perché non soddisfa la disuguaglianza triangolare. Se $x$ e $y$ sono in componenti diverse la distanza è $infinity$ e quindi non vale la disuguaglianza triangolare. Vale solo se non è orientato
]
vale la distanza triangolare: 
$
  d(x,y) <= d(x,z) + d(z, y)
$
il minimo cammino deve essere al più uguale o più corto di un cammino che passa per un nodo $z$.
// TODO: aggiungere immagine