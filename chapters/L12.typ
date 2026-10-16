#import "../template.typ": *

== Indici invertiti e liste di affissione

Consideriamo un insieme di documenti $D$ e un insieme di termini $T$. Per rispondere a una query booleana o a una query per parola chiave, dobbiamo sapere, per ogni termine $t$, in quali documenti esso compare.

L'idea centrale dell'indice invertito è costruire una mappa:
$
  t -> P(t)
$
Dove $P(t)$ è la lista dei documenti in cui compare il termine $t$. Questa struttura prende il nome di *lista di affissione* o *postings list*.

In pratica, la rappresentazione più usata è un array di termini associato a un range e a un puntatore: per ogni termine si memorizza il suo blocco di documenti e la posizione iniziale della relativa lista di affissione. In questo modo, la ricerca di un termine diventa un accesso diretto alla sua struttura associata.

#note()[
  La lista dei termini non serve solo per costruire il range: può essere anche usata per supportare ricerche per prefissi, ordinamenti per frequenza, oppure per individuare rapidamente una sottocollezione di termini.
]

== Compressione e accesso alle liste

Per evitare di usare in modo inefficiente memoria e puntatori, le liste di affissione sono spesso memorizzate in modo *compresso*.

Se un documento contiene un termine molte volte, non è necessario memorizzare tutte le occorrenze, ma solo il fatto che il termine compare in quel documento. In forma più generale, si può memorizzare una sequenza di documenti ordinata crescente:
$
  P(t) = [d_1, d_2, ..., d_k]
$

Il problema è che, per leggere l'$i$-esimo elemento della lista compressa, in generale devo leggere tutti i precedenti. In altre parole, il costo di accesso random non è costante.

Per limitare questo problema si usa un *indice campionato*:
- si salva uno snapshot ogni $q$ elementi;
- si memorizza il valore e la loro posizione;
- per trovare un elemento si usa un accesso binario nel campione, seguito da una scansione locale nel blocchetto.

Il costo tipico è:
$
  O(log (f / q)) + O(q)
$
con $f$ numero di elementi della lista e $q$ dimensione del campione.

#example()[
  Se una lista di affissione è molto lunga, conviene memorizzare solo alcune posizioni campione. In questo modo si riescono a ottenere accessi efficienti senza perdere la possibilità di scorrere direttamente gli elementi in ordine.
]

== Risoluzione delle interrogazioni

Le query vengono modellate come funzioni:
$
  R: D × Q -> R
$
Dove:
- $D$ è l'insieme dei documenti;
- $Q$ è l'insieme delle query, costruite da atomi stringa e operatori booleani;
- $R$ è l'insieme dei risultati.

Una query booleana è formata da:
- presenza di un termine;
- negazione ($¬ q$);
- congiunzione ($q_1 and q_2$);
- disgiunzione ($q_1 or q_2$).

In altre parole, possiamo scrivere:
$
  q_0, q_1 in Q => q_0 and q_1, q_0 or q_1
$
$
  q in Q => ¬ q
$

#note(title: "Operatori booleani")[
  Le query booleane si risolvono costruendo l'insieme delle liste di affissione dei termini coinvolti e poi combinando gli insiemi di documenti tramite intersezione, unione e complemento.
]

== DAAT e TAAT

Esistono due approcci principali per la valutazione di query.

=== TAAT (Term-at-a-time)

In TAAT si valuta un termine alla volta, accumulando progressivamente il risultato della query. L'algoritmo esamina in sequenza la lista di affissione di un termine e aggiorna lo stato corrente.

Questo approccio è stato storico: in collezioni molto piccole è stato molto efficiente e, con opportune ottimizzazioni, può anche dar luogo a algoritmi quasi sublineari.

=== DAAT (Document-at-a-time)

In DAAT si valuta invece un documento alla volta: per ogni documento si controlla se soddisfa la query e, in caso affermativo, lo si emette come risultato.

Questo approccio cerca di fare il minimo lavoro possibile su documenti non rilevanti e è tipico delle implementazioni moderne per il Web, soprattutto quando si usano strategie di terminazione precoce.

#note()[
  Nel Web, le raccolte sono troppo grandi per essere mantenute in RAM in modo completo. Per questa ragione, i motori moderni preferiscono un comportamento *lazy* (pigro): non calcolano sempre tutti i risultati in anticipo, ma li producono man mano e si fermano appena hanno abbastanza risposte per la pagina attuale.
]

#warning()[
  I motori di ricerca oggi usano spesso terminazione precoce: se i risultati già mostrati sono abbastanza buoni, l'algoritmo smette di andare avanti.
]

== Algoritmo eager / solerte

Nell'approccio eager si costruisce esplicitamente il risultato finale, spesso usando vettori e merge. L'idea fondamentale è la seguente:

- l'output viene costruito in un vettore dedicato;
- per la negazione si crea un nuovo vettore copiando tutti gli elementi esclusi dal set negativo;
- per l'intersezione si fa un merge lineare di due liste ordinate;
- se una lista è molto corta e l'altra molto lunga, si può usare una ricerca binaria del vettore piccolo all'interno di quello grande.

=== Galloping search

La *galloping search* è una variante della ricerca binaria che parte con passi piccoli e poi raddoppia la distanza quando si va alla ricerca del valore corretto. In alcuni casi è più efficiente della ricerca binaria classica perché migliora il comportamento locale sui vettori ordinati.

#note()[
  Se due liste sono ordinate e la lista più piccola non è molto lunga, un approccio con ricerca binaria all'interno della lista grande può essere molto efficace. Quando si trova il primo valore, gli altri valori successivi sono spesso raggruppati vicino al primo risultato.
]

== Intersezioni con più di due termini

Quando una query contiene più termini, ci sono molte possibili associatività:
$
  (a or b) or (c or d)
$
oppure
$
  ((a or b) or c) or d
$

Il trucco è il seguente: si valutano prima i vettori più piccoli, perché sono i più convenienti da usare come filtro per quelli più grandi. In pratica, la strategia ottimale è sempre:

1. ordinare le liste in base alla loro lunghezza;
2. intersecare le più piccole prima;
3. usare i risultati intermedi per restringere le liste più grandi.

#note(title: "Unione")[
  Per l'unione di più liste ordinate si usa generalmente un *k-way merge* o un merge multivia. La struttura di supporto è una coda con priorità (heap) che tiene in cima l'elemento più piccolo tra tutte le liste attive.
]

Nell'algoritmo, per ogni lista si mantiene un puntatore all'inizio. Si inseriscono i valori correnti nello heap e, fino a quando il minimo è uguale al valore appena considerato, si emette un solo risultato e si fanno avanzare i puntatori delle liste coinvolte.

== Algoritmo lazy

Nell'approccio lazy non si calcola l'insieme completo prima dell'output. Si produce invece il risultato in modo incrementale, emettendo un risultato alla volta e usando un *next* pigro. Questo rende la valutazione molto efficiente quando la query è grande o quando è sufficiente un numero limitato di risultati.

=== NOT

La negazione può essere vista come una lista con un operatore `next` che restituisce il successivo elemento del complemento.

=== UNION

Per l'unione lazy si usa un meccanismo simile al k-way merge, ma con avanzamenti ai passi successivi in modo opportuno. Non è sempre necessario avanzare tutte le liste subito: molte volte conviene lasciare una lista in attesa e procedere solo quando il suo valore diventa rilevante.

=== INTERSEZIONE

L'intersezione lazy usa l'operatore *minimo dei maggioranti*.

Dato un valore $x$ e una lista $L$, il minimo dei maggioranti (minimump exceeding or equal) è il più piccolo elemento di $L$ che è maggiore o uguale a $x$.

Se si trova un maggiorante, allora il valore non appartiene alla lista; se invece il valore coincide con il candidato in tutte le liste, allora è parte dell'intersezione.

In pratica, per ogni lista si fa avanzare il puntatore fino a trovare il minimo maggiore o uguale al candidato corrente. Se il valore è confrontabile in tutte le liste, allora si accetta il documento; altrimenti si riparte da capo con un nuovo candidato.

#example()[
  Sia $a = [2,5,9]$ e $b = [3,4,9]$. Per intersecare i due insiemi in modo lazy, si confronta il candidato attuale con la lista $b$ e si usa `min-mag` per saltare i valori troppo piccoli. Quando tutti e due i puntatori si trovano sullo stesso valore, l'elemento viene emesso nello output.
]

== Skip e operazioni lazy su OR

L'operatore `skip` è fondamentale nelle strutture lazy. Il suo scopo è far avanzare rapidamente un puntatore fino a quando il valore corrente è inferiore a quello che stiamo processando.

Per l'unione lazy, si usa una coda con priorità e si fa skip sulle liste fino a quando il minimo dell'heap è strettamente maggiore del valore corrente. In questo modo si evitan confronti inutili e si riduce il lavoro del motore di query.

#note()[
  Se la query è della forma $a and (b or c)$, l'albero della query porta le operazioni lazy a propagarsi prima sull'OR e poi sull'AND. In altre parole, la semantica lazy rispetta la struttura logica della query, ma evitando di computare precedentemente elementi inutili.
]
