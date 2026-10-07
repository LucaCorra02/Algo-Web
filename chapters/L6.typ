#import "../template.typ": *

Esistono diversi approcci per assegnare un URL a un agente, tutti basati su funzioni di hash pseudoaleatorie. L'obiettivo è quello di ottenere una distribuzione bilanciata e controvariante, in modo che l'aggiunta o la rimozione di agenti non stravolga le assegnazioni preesistenti. Le tecniche più comuni sono:
- *Permutazioni aleatorie* (Knuth / Fisher-Yates)
- *Min hashing*
- *Hashing coerente* (Consistent Hashing, Karger STOC)

== Permutazioni aleatorie (Knuth / Fisher-Yates)

Questa prima idea (utilizzata ad esempio nell'implementazione di Google Guava) assume l'esistenza di uno spazio *$P$* che comprenda tutti i possibili agenti. Si assume inoltre l'esistenza di un *algoritmo distribuito* per cui ogni agente sa in ogni istante quali sono gli agenti effettivamente "vivi" ($A subset.eq P$).

Dato un URL $u$, l'agente responsabile viene scelto nel seguente modo:
1. Si prende $u$ e se ne calcola l'hash.
2. Si utilizza questo valore come seme per inizializzare un generatore di numeri pseudocasuali (PRNG).
3. Con il generatore si costruisce una *permutazione aleatoria uniforme* di tutti i possibili agenti $P$.

  #note()[
    Una permutazione aleatoria uniforme è una sequenza di tutti gli elementi di $P$ in cui ogni possibile ordinamento ha la stessa probabilità di essere generato.
  ]


4. Il *primo* elemento appartenente all'insieme degli agenti vivi $A$ che compare nella permutazione è l'agente incaricato.

#example(title: "Comportamento in caso di aggiunta")[
  - Agenti possibili: $n = 6$ (da $0$ a $5$)
  - Agenti attivi $A = {2, 3}$
  - Permutazione generata per l'URL $u$: `5 1 2 3 4 0`
  - Il primo elemento della permutazione presente in $A$ è il `2` $->$ L'agente incaricato è il *2*.

  Se in un secondo momento si aggiunge l'agente `1`, lo stesso URL $u$ verrà assegnato a quest'ultimo, in quanto precede il `2` nella permutazione. Gli assegnamenti si spostano quindi *solo* verso gli agenti nuovi, preservando il carico preesistente e garantendo la *controvarianza*.
]

=== Generazione tramite Knuth o Fisher-Yates
Per generare questa permutazione si utilizza un algoritmo lineare nello spazio e nel tempo $|P|$:
- Si inizializza un vettore ordinato con gli elementi di $P$.
- Per ogni posizione $i$, si calcola una posizione successiva casuale $j = i + op("rand")(|P| - i)$ (senza mai guardare le precedenti) e si scambiano gli elementi in $i$ e $j$.

#note[
  In realtà, *non è necessario completare* l'intera *permutazione*. È sufficiente fare lo *swap* sequenzialmente fino a quando non si trova il primo elemento appartenente ad $A$. Il numero medio di iterazioni necessarie (shuffle) è proporzionale al rapporto tra la dimensione del vettore e il numero di agenti attualmente vivi: $(|P|) / (|A|)$
]

== Min hashing

Il secondo approccio utilizza una singola funzione di hash aleatoria a due argomenti $ h: U times A -> 2^k "con" k <= 64 "comune a tutti" $

Dato un URL $u$, l'agente assegnato è quello che *minimizza* il valore dell'hash:
$ op("argmin")_(a in A) h(u, a) $

Questa tecnica è *bilanciata* (se $h$ è casuale) e *controvariante*. Se all'insieme degli agenti si *aggiunge* un nodo, gli unici URL che cambiano assegnatario sono quelli per cui il nuovo nodo produce un valore di hash strettamente minore di tutti quelli degli agenti preesistenti. Se si *rimuove* un agente, cambiano assegnatario solo gli URL che erano assegnati a lui. Tutte le altre assegnazioni restano stabili.

#warning(title: "Gestione delle collisioni")[
  Cosa succede se ci sono due minimi uguali? *Non esiste un singolo `argmin`*. Si assume quindi un ordine totale sull'insieme $A$ e si prende l'agente più piccolo tra i due. A meno di collisioni, è come se stessimo generando una permutazione aleatoria degli agenti e prendendo il primo.
]

*Analisi delle prestazioni:*
- *Spazio:* Costante $O(1)$ (basta tenere traccia del valore minimo).
- *Tempo:* Lineare $O(|A|)$ (è necessario valutare l'hash per ogni agente attivo).

#warning(title: "Non confondere i due \"min hash\"")[
  Il *min hashing* per distribuire il carico ($min_(a in A) h(u, a)$) è una tecnica diversa dal *MinHash* di Broder per stimare la similarità di Jaccard: hanno in comune solo l'idea di prendere il minimo di valori di hash.
]


== Hashing coerente (Consistent Hashing, Karger STOC)

L'hashing coerente mappa gli URL e gli agenti all'interno di un cerchio unitario (l'intervallo $[0, 1)$).

Funzionamento:
1. Per ogni agente si precalcola un numero fisso di *repliche* (tipicamente $300/400$) e le si piazza sul cerchio usando un generatore di numeri casuali inizializzato con l'identificatore dell'agente.

2. Il posizionamento di queste repliche *frammenta il cerchio* in numerosi segmenti, ognuno assegnato alla replica successiva in senso orario.

3. Preso un URL $u$, se ne calcola l'hash $h(u)$ per trovare un punto sul cerchio unitario.

4. L'URL viene assegnato all'agente corrispondente alla *prima replica* che si incontra (ovvero l'agente proprietario del segmento in cui cade $h(u)$).

#figure(
  caption: [Hashing coerente: l'hash di un URL individua un punto sull'anello e la ricerca prosegue in senso orario fino alla prima replica, che determina l'agente responsabile.],
)[
  #cetz.canvas({
    import cetz.draw: *

    let border = (paint: black, thickness: 1.4pt)
    let node-border = (paint: black, thickness: 0.9pt)
    let arrow = (paint: black, thickness: 1.1pt)
    let url = (paint: red.darken(20%), thickness: 1.3pt)

    let center = (4.0, 4.6)
    let points = (
      // Tutti i punti hanno distanza 2.1 dal centro dell'anello.
      (4.0, 6.7),
      (5.05, 6.418),
      (5.819, 5.65),
      (6.1, 4.6),
      (5.819, 3.55),
      (5.05, 2.782),
      (4.0, 2.5),
      (2.95, 2.782),
      (2.181, 3.55),
      (1.9, 4.6),
      (2.181, 5.65),
      (2.95, 6.418),
    )

    // Gli intervalli sono colorati con il colore della replica successiva.
    line(points.at(0), points.at(1), stroke: (paint: gray, thickness: 1pt))
    line(points.at(1), points.at(2), stroke: (paint: gray, thickness: 1pt))
    line(points.at(2), points.at(3), stroke: (paint: gray, thickness: 1pt))
    line(points.at(3), points.at(4), stroke: (paint: gray, thickness: 1pt))
    line(points.at(4), points.at(5), stroke: (paint: gray, thickness: 1pt))
    line(points.at(5), points.at(6), stroke: (paint: gray, thickness: 1pt))
    line(points.at(6), points.at(7), stroke: (paint: gray, thickness: 1pt))
    line(points.at(7), points.at(8), stroke: (paint: gray, thickness: 1pt))
    line(points.at(8), points.at(9), stroke: (paint: gray, thickness: 1pt))
    line(points.at(9), points.at(10), stroke: (paint: gray, thickness: 1pt))
    line(points.at(10), points.at(11), stroke: (paint: gray, thickness: 1pt))
    line(points.at(11), points.at(0), stroke: (paint: gray, thickness: 1pt))
    circle(center, radius: 2.05, stroke: border)

    // Repliche virtuali colorate come nell'esempio: A, B, C e D.
    let nodes = (
      (points.at(0), "A", yellow),
      (points.at(1), "C", green),
      (points.at(2), "A", yellow),
      (points.at(3), "B", red),
      (points.at(4), "C", green),
      (points.at(5), "D", blue),
      (points.at(6), "A", yellow),
      (points.at(7), "B", red),
      (points.at(8), "C", green),
      (points.at(9), "D", blue),
      (points.at(10), "B", red),
      (points.at(11), "A", yellow),
    )
    for node in nodes {
      circle(node.at(0), radius: 0.32, fill: node.at(2), stroke: node-border)
      content(node.at(0), text(size: 9pt)[#node.at(1)])
    }

    // Due URL di esempio: l'hash cade sul cerchio e la ricerca continua
    // in senso orario fino alla prima replica.
    circle((5.45, 6.0), radius: 0.12, fill: red, stroke: arrow)
    content((6.95, 6.85), text(size: 8pt)[*hash(key1)*])
    line((6.2, 6.7), (5.48, 6.05), stroke: arrow, mark: (end: "stealth"))
    content((7.6, 6.5), text(size: 7pt)[prima replica successiva: *A*])
    content((7.25, 6.1), text(size: 7pt)[URL assegnato ad *A*])

    circle((2.0, 4.1), radius: 0.09, fill: red, stroke: arrow)
    content((0.1, 2.45), text(size: 8pt)[*hash(key2)*])
    line((.95, 2.25), (1.9, 4), stroke: arrow, mark: (end: "stealth"))
    content((0.1, 2.05), text(size: 7pt)[prima replica successiva: *D*])
    content((0.1, 1.68), text(size: 7pt)[URL assegnato a *D*])

    line((4.2, 7.4), (4.85, 7.25), stroke: arrow, mark: (end: "stealth"))
    content((3.2, 7.4), text(size: 10pt)[senso orario])
  })
]

Il *bilanciamento* viene *risolto inserendo molte repliche*: Esse permettono di ridurre la varianza delle dimensioni dei segmenti, rendendoli tendenzialmente unitari. All'aggiunta di un nuovo agente, le sue repliche andranno a "spezzare" segmenti preesistenti; l'URL associato a quel frammento verrà mappato sul nuovo agente senza intaccare le parti restanti.

=== Implementazione

Per implementare il cerchio si memorizzano le posizioni delle repliche sotto forma di interi in un dizionario ordinato e bilanciato (come un B-Tree). Dato l'hash $h(u)$, si cerca il *minimo maggiorante* (operazione di *upper-bound*) per determinare l'agente.

- Il tempo di ricerca è *logaritmico* rispetto al numero totale di repliche nel dizionario.

- Aggiungere o togliere un elemento da $A$ richiede tempo logaritmico $O(log|A|)$ (a differenza dei casi precedenti che richiedevano tempo costante), in quanto è necessario inserire o rimuovere tutte le repliche dell'agente.

== Tolleranza ai guasti: individuare i successivi responsabili

A livello pratico è fondamentale sapere quale agente in passato era responsabile di un URL (per verificare se è già stato crawlato) o quale sarebbe il futuro responsabile nel caso in cui l'attuale crashi.

Tutti e tre i metodi permettono di trovare i *$k$ precedenti o successivi agenti* responsabili:
- *Permutazioni aleatorie:* È sufficiente progredire nello shuffle, cercando l'elemento successivo valido nell'insieme $A$.

- *Min hashing:* Si deve tenere traccia dei *valori minimi progressivi* (il minimo assoluto, il secondo classificato, ecc.).

- *Hashing coerente:* Basta continuare a procedere in senso orario sul cerchio fino a giungere alla replica di un *nuovo* agente (essendoci molteplici repliche per agente, potrebbero essere necessari più passi per "scartare" i duplicati dell'agente ignorato).

#note(title: "Osservazione sulla distribuzione effettiva")[
  In tutti i metodi descritti c'è una componente *pseudoaleatoria*. Questo fa sì che la distribuzione degli URL agli agenti non sia matematicamente "perfetta", ma segua una *distribuzione binomiale negativa*. Dato il grande numero di elementi in gioco, tuttavia, il risultato approssima in modo eccellente una distribuzione bilanciata.

  In tutti i metodi visti possono esserci delle *collisioni*. Tuttavia, possono essere risolte stabilendo un ordine di priorità tra gli agenti (ad esempio, l'ordine alfabetico dei loro identificatori). In questo modo, in caso di collisione, si assegna l'URL all'agente con priorità più alta.
]

= Compressione

Nei sistemi reali, i crawler si occupano di scaricare una serie di documenti per poi estrarne gli *shingles* e i *termini* importanti appartenenti al contesto, che verranno infine indicizzati.
L'obiettivo finale è quello di proporre all'utente i documenti pertinenti in base alle parole chiave (query) inserite. Questi documenti, identificati da ID numerici (DocID), formano liste ordinate in ordine crescente (*posting lists*).

#note(title: "Rappresentazione dei Gap")[
  Come si rappresenta una lista in modo efficace?
  La lista indicizzata non salva gli interi completi, ma i *gap* (gli scarti tra un documento e il successivo), che verranno poi risistemati e sommati in fase di lettura. L'obiettivo è quello di avere numeri piccoli da codificare, specialmente in caso di liste dense dove la distanza tra due ID consecutivi è minima.
]

Ma come si scrivono sequenze di numeri in pochissimo spazio (livello bit)? A tal scopo si introducono i *codici*.

== Codici istantanei

Per definire un codice istantaneo è fondamentale introdurre l'ordinamento per prefisso.
Un codice è un insieme $C subset.eq 2^*$, cioè un insieme (al più numerabile) di parole binarie.

Definiamo l'*ordinamento per prefissi* delle sequenze in $2^*$ come segue:
$
  x prec.eq y <==> exists z | y = x z
$
In altri termini, $x prec.eq y$ *se e solo se* $x$ è un prefisso di $y$.

Date due parole, esse sono:
- *Confrontabili*: se $x$ è prefisso di $y$ (o viceversa).
- *Inconfrontabili*: in caso contrario.

Un *codice privo di prefissi* (o a *decodifica istantanea*) è un codice in cui non esistono due stringhe distinte in cui una sia prefisso dell'altra. Tutte le parole del codice sono a due a due *inconfrontabili*.

#informally(title: "Proprietà della decodifica")[
  Il grandissimo vantaggio dei codici istantanei è che esiste *un solo modo* di leggere e partizionare una determinata sequenza di bit. Leggendo il flusso di bit uno ad uno, sappiamo immediatamente quando una codeword termina, permettendoci di concatenare numeri adiacenti in memoria senza separatori espliciti e decodificandoli senza alcuna ambiguità.
]

=== Codice istantaneo completo

Un codice istantaneo è detto *completo* (o non ridondante) se, per ogni possibile parola binaria in $2^*$, la parola è confrontabile con *almeno* una parola del codice.

#note()[
  La conseguenza fondamentale è che, una volta che un codice istantaneo è diventato completo, *non è* più *possibile estenderlo*: non posso inserire nuove parole senza violare e distruggere la proprietà di decodifica istantanea.
]


