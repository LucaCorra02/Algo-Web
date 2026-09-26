#import "../template.typ": *

= Nozioni di base

Compresso = conosco la distribuzione dei dati e posso comprimere i dati.

Succinte = ho meno conoscenza e minimizzo i dati nel minor spazio possibile, sfruttando il teorema di Shannon. Le operazioni hanno lo stesso costo delle strutture dati tradizionali. Per distinguere tutti gli alberi binari con $n$ vertici servono circa $log_2(4^n) = 2n$ bit.

Le rappresentazioni classiche si dicono ridondanti: usano più di $2n$ bit, cioè più bit del necessario. La rappresentazione succinta è quella che usa il minor numero di bit possibile.

Le strutture che vedremo hanno operazioni in tempo costante: il tempo non dipende da quanti dati inseriamo, ma da altri parametri, come la probabilità di errore.

#note()[
  Il compromesso è *l'immutabilità delle strutture* (strutture statiche). Non si possono modificare: se voglio aggiungere un elemento, devo ricostruire la struttura da zero.
]

== Grafi

Un grafo è $G = <N, A, s, t>$, dove due funzioni $s$ e $t$ vanno da $A$ a $N$ e collegano un arco a un nodo. In questo modo possiamo rappresentare archi paralleli (con lo stesso nodo di partenza e di arrivo), così da rappresentare pagine collegate più volte.

Si tratta quindi di multigrafi.

La funzione $sigma: A -> A$ è la funzione di inversione degli archi:
$
  sigma^2 = 1 "(identità)" \\
  s theta sigma = t "se prendo un arco, lo giro e ne considero la sorgente, ottengo il target"
$
In questo modo possiamo invertire gli archi in un grafo orientato. Nel corso considereremo anche grafi non orientati, grazie alla funzione di inversione. Gli archi sono quindi un insieme di coppie non ordinate di nodi.

- *indegree* = numero di vertici che entrano in un nodo
$
  d^-(x) = |{a in A: t(a) = x}|\
$
#note()[
  È una misura più difficile da manipolare: dobbiamo farci seguire da molte persone.
]
- *outdegree* = numero di vertici che escono da un nodo
$
  d^+(x) = |{a in A: s(a) = x}|\
$
Se il grafo non è orientato, questi due valori coincidono grazie alla funzione di inversione degli archi.

I successori sono i nodi raggiungibili da un nodo $x$ tramite un arco $a$ in un solo passo. I predecessori sono i nodi dai quali si raggiunge $x$ tramite un arco $a$ in un solo passo.

Definiamo *path* una sequenza di archi che collega due nodi $x$ e $y$ in un grafo. Un path può essere rappresentato come una sequenza di archi $a_1, a_2, ..., a_k$ tale che $t(a_i) = s(a_{i+1})$ per ogni $i = 1, ..., k - 1$. La lunghezza del path è il numero di archi che lo compongono (i vertici del cammino possono ripetersi).

#note()[
  Gli archi in entrata e gli archi in uscita nel Web sono molto diversi. Conoscere i successori (seguire i link) è molto facile, mentre conoscere i predecessori è molto difficile: devo fare crawling di tutto il Web per sapere chi collega chi, ottenere man mano le liste di adiacenza e invertirle. In questo modo, però, ottengo progressivamente liste di adiacenza che coprono una parte molto piccola del Web.
]

*Raggiungibilità*: se esiste un path da $x$ a $y$, diciamo che $y$ è raggiungibile da $x$.

*Componenti fortemente connesse*: relazione di equivalenza tra i vertici: $x tilde y$ se sono co-raggiungibili, cioè se ciascuno dei due è raggiungibile dall'altro. Se il grafo è orientato, possiamo considerare anche la funzione inversa sugli archi. La relazione deve avere le seguenti proprietà:
- _riflessiva_: $x tilde x$, per il cammino vuoto;
- _simmetrica_: $x tilde y$ implica $y tilde x$: se esiste un path da $x$ a $y$, deve esistere anche un path da $y$ a $x$;
- _transitiva_: $x tilde y$ e $y tilde z$ implicano $x tilde z$: se esiste un path da $x$ a $y$ e da $y$ a $z$, allora esiste un path da $x$ a $z$.

Le classi di equivalenza della relazione sono le componenti fortemente connesse. Se sono all'interno di una certa classe, posso arrivare da un qualsiasi nodo a qualsiasi altro nodo della classe. Se sono in classi diverse, può essere possibile passare da una classe all'altra, ma non viceversa. L'algoritmo di Tarjan trova le componenti fortemente connesse in tempo lineare. Nei grafi orientati si parla di componenti fortemente connesse; nei grafi non orientati, invece, la relazione coincide con quella delle componenti connesse, che sono fisicamente separate e tra le quali non posso passare.

//TODO: aggiungere immagine di un grafo con le componenti fortemente connesse

#note()[
  Il problema del crawling non dipende da dove partiamo (raggiungiamo sempre una buona parte del Web), ma è una questione di *tempo*: quanto tempo ci metto a fare crawling di tutto il Web?
]

Una componente *debolmente connessa* è una componente connessa del grafo non orientato ottenuto considerando anche la funzione di inversione degli archi: gli archi possono essere girati in modo da ignorarne l'orientamento.

*Distanza in un grafo*: lunghezza del path più corto (ce ne può essere più di uno) tra due nodi $x$ e $y$. Se non esiste un path tra i due nodi, la distanza è $infinity$.
#warning()[
  La distanza non è una metrica in generale: nei grafi orientati non è necessariamente simmetrica e, se $x$ e $y$ sono in componenti diverse, la distanza è $infinity$. In un grafo non orientato e connesso, invece, la distanza è una metrica. La disuguaglianza triangolare vale anche considerando $infinity$ come valore esteso:
]
vale infatti la disuguaglianza triangolare:
$
  d(x,y) <= d(x,z) + d(z, y)
$
Il cammino minimo deve essere al più lungo quanto un cammino che passa per un nodo $z$.
// TODO: aggiungere immagine
