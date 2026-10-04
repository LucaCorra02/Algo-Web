#import "../template.typ": *

= Tecniche di distribuzione del carico

Consideriamo una situazione in cui bisogna coordinare un insieme $A$ di agenti indipendenti che effettuano attività di crawling. Assumiamo che gli agenti siano identici e abbiano a disposizione le stesse risorse. L'obiettivo è quello di dividere il carico (gli URL da analizzare) tra gli agenti in base a criteri precisi.

Definiamo una funzione di assegnazione $delta_A : U -> A$ che, dato l'universo degli URL $U$ e l'insieme degli agenti $A$, assegna a ciascun URL uno specifico agente responsabile. 

Vogliamo che questa funzione rispetti due proprietà fondamentali:

+ *Bilanciamento*: Il carico deve essere diviso equamente. Ogni agente deve gestire all'incirca lo stesso numero di URL:
  $|delta_A^(-1)| approx (|U|)/(|A|)$

+ *Controvarianza*: L'assegnazione deve essere resiliente alle variazioni del numero di agenti. Formalmente, preso un insieme di agenti $B supset.eq A$ e un agente $a in A$:
  $delta_B (a)^(-1) subset.eq delta_A (a)^(-1)$

#informally(title: "Controvarianza")[
  Dal punto di vista insiemistico: se aumenta il numero di agenti (da $A$ a $B$), l'insieme degli URL gestito da un agente preesistente può solo diminuire o rimanere uguale. I nuovi URL andranno unicamente ai nuovi agenti, senza stravolgere gli assegnamenti precedenti.
]

#note(title: "Insiemi di agenti statici")[
  Nel caso semplice in cui l'insieme degli agenti sia *fisso*, è sufficiente numerarli da $0$ ad $n$ e applicare una semplice funzione di hash: l'agente assegnato sarà $h(u) mod |A|$. Tuttavia, se l'insieme varia nel tempo, l'hashing semplice perde completamente la coerenza, causando la ridistribuzione di quasi tutto il carico.
]

== Permutazioni aleatorie (Knuth / Fisher-Yates)

Questa prima idea (utilizzata ad esempio nell'implementazione di Google Guava) assume l'esistenza di uno spazio $P$ che comprenda tutti i possibili agenti. Si assume inoltre l'esistenza di un algoritmo distribuito per cui ogni agente sa in ogni istante quali sono gli agenti effettivamente "vivi" ($A subset.eq P$).

Dato un URL $u$, l'agente responsabile viene scelto nel seguente modo:
1. Si prende $u$ e se ne calcola l'hash.
2. Si utilizza questo valore come seme per inizializzare un generatore di numeri pseudocasuali (PRNG).
3. Con il generatore si costruisce una permutazione aleatoria uniforme di tutti i possibili agenti $P$.
4. Il *primo* elemento appartenente all'insieme degli agenti vivi $A$ che compare nella permutazione è l'agente incaricato.

#example(title: "Comportamento in caso di aggiunta")[
  - Agenti possibili: $n = 6$ (da $0$ a $5$)
  - Agenti attivi $A = {2, 3}$
  - Permutazione generata per l'URL $u$: `5 1 2 3 4 0`
  - Il primo elemento della permutazione presente in $A$ è il `2` $->$ L'agente incaricato è il *2*.

  Se in un secondo momento si aggiunge l'agente `1`, lo stesso URL $u$ verrà assegnato a quest'ultimo, in quanto precede il `2` nella permutazione. Gli assegnamenti si spostano quindi *solo* verso le "cose nuove", preservando il carico preesistente e garantendo la controvarianza.
]

=== Generazione tramite Knuth o Fisher-Yates
Per generare questa permutazione si utilizza un algoritmo lineare nello spazio e nel tempo $|P|$:
- Si inizializza un vettore ordinato con gli elementi di $P$.
- Per ogni posizione $i$, si calcola una posizione successiva casuale $j = i + op("rand")(|P| - i)$ (senza mai guardare le precedenti) e si scambiano gli elementi in $i$ e $j$.

#note[
  In realtà, non è necessario completare l'intera permutazione. È sufficiente fare lo *swap* sequenzialmente fino a quando non si trova il primo elemento appartenente ad $A$. Il numero medio di iterazioni necessarie (shuffle) è proporzionale al rapporto tra la dimensione del vettore e il numero di agenti attualmente vivi.
]

== Min hashing

Il secondo approccio utilizza una singola funzione di hash aleatoria a due argomenti $h: U times A -> 2^k$ (con $k <= 64$), comune a tutti.

Dato un URL $u$, l'agente assegnato è quello che *minimizza* il valore dell'hash:
$ op("argmin")_(a in A) h(u, a) $

#warning(title: "Gestione delle collisioni")[
  Cosa succede se ci sono due minimi uguali? Non esiste un singolo `argmin`. Si assume quindi un ordine totale sull'insieme $A$ e si prende il più piccolo dei due. A meno di collisioni, è come se stessimo generando una permutazione aleatoria degli agenti e prendendo il primo.
]

*Analisi delle prestazioni:*
- *Spazio:* Costante $O(1)$ (basta tenere traccia del valore minimo).
- *Tempo:* Lineare $O(|A|)$ (è necessario valutare l'hash per ogni agente attivo).
- *Dinamicità:* In caso di nuovo agente, cambiano di posto solo quegli URL per cui il nuovo agente genera un valore di hash inferiore rispetto al minimo precedente. Gli spostamenti avvengono unicamente verso il nuovo agente.

== Hashing coerente (Consistent Hashing, Karger STOC)

L'hashing coerente mappa gli URL e gli agenti all'interno di un cerchio unitario (l'intervallo $[0, 1)$).

1. Per ogni agente si precalcola un numero fisso di *repliche* (tipicamente $300/400$) e le si piazza sul cerchio usando un generatore di numeri casuali inizializzato con l'identificatore dell'agente. 
2. Il posizionamento di queste repliche frammenta il cerchio in numerosi segmenti, ognuno assegnato alla replica successiva in senso orario.
3. Preso un URL $u$, se ne calcola l'hash $h(u)$ per trovare un punto sul cerchio unitario.
4. L'URL viene assegnato all'agente corrispondente alla *prima replica* che si incontra (ovvero l'agente proprietario del segmento in cui cade $h(u)$).

La questione del bilanciamento viene risolta inserendo molte repliche: questo riduce la varianza delle dimensioni dei segmenti, rendendoli tendenzialmente unitari. All'aggiunta di un nuovo agente, le sue repliche andranno a "spezzare" segmenti preesistenti; l'URL associato a quel frammento verrà mappato sul nuovo agente senza intaccare le parti restanti.

*Implementazione:* 
Per implementare il cerchio si memorizzano le posizioni delle repliche sotto forma di interi in un dizionario ordinato e bilanciato (come un B-Tree). Dato l'hash $h(u)$, si cerca il *minimo maggiorante* (operazione di *upper-bound*) per determinare l'agente.

- Il tempo di ricerca è *logaritmico* rispetto al numero totale di repliche nel dizionario.
- Aggiungere o togliere un elemento da $A$ richiede tempo logaritmico $O(log|A|)$ (a differenza dei casi precedenti che richiedevano tempo costante).

=== Tolleranza ai guasti: individuare i successivi responsabili
Nella pratica reale, è fondamentale sapere chi in passato era responsabile di un URL (per verificare se è già stato crawlato) o quale sarebbe il prossimo agente responsabile nel caso in cui l'attuale crashi. 

Tutti e tre i metodi permettono di trovare i $k$ precedenti o successivi agenti responsabili:
- *Permutazioni aleatorie:* È sufficiente progredire nello shuffle, cercando l'elemento successivo valido nell'insieme $A$.
- *Min hashing:* Si deve tenere traccia dei valori minimi progressivi (il minimo assoluto, il secondo classificato, ecc.).
- *Hashing coerente:* Basta continuare a procedere in senso orario sul cerchio fino a giungere alla replica di un *nuovo* agente (essendoci molteplici repliche per agente, potrebbero essere necessari più passi per "scartare" i duplicati dell'agente ignorato).

#note(title: "Osservazione sulla distribuzione effettiva")[
  In tutti i metodi descritti c'è una componente pseudoaleatoria. Questo fa sì che la distribuzione degli URL agli agenti non sia matematicamente "perfetta", ma segua una *distribuzione binomiale negativa*. Dato il grande numero di elementi in gioco, tuttavia, il risultato approssima in modo eccellente una distribuzione bilanciata.
]

= Compressione

Nei sistemi reali, i crawler si occupano di scaricare una serie di documenti per poi estrarne gli *shingles* e i *termini* importanti appartenenti al contesto, che verranno infine indicizzati. 
L'obiettivo finale è quello di proporre all'utente i documenti pertinenti in base alle parole chiave (query) inserite. Questi documenti, identificati da ID numerici (DocID), formano liste ordinate in ordine crescente (posting lists).

#note(title: "Rappresentazione dei Gap")[
  Come si rappresenta una lista in modo efficace? 
  La lista indicizzata non salva gli interi completi, ma i *gap* (gli scarti tra un documento e il successivo), che verranno poi risistemati e sommati in fase di lettura. L'obiettivo è quello di avere numeri piccoli da codificare, specialmente in caso di liste dense dove la distanza tra due ID consecutivi è minima.
]

Ma come si scrivono sequenze di numeri in pochissimo spazio (livello bit)? A tal scopo si introducono i codici.

== Codici istantanei

Per definire un codice istantaneo è fondamentale introdurre l'ordinamento per prefisso.
Un codice è un insieme $C subset.eq 2^*$, cioè un insieme (al più numerabile) di parole binarie.

Definiamo l'*ordinamento per prefissi* delle sequenze in $2^*$ come segue:
$x prec.eq y <==> exists z | y = x z$
In altri termini, $x prec.eq y$ se e solo se $x$ è un prefisso di $y$.

Date due parole, esse sono:
- *Confrontabili*: se $x$ è prefisso di $y$ (o viceversa).
- *Inconfrontabili*: in caso contrario.

Un *codice privo di prefissi* (o a *decodifica istantanea*) è un codice in cui non esistono due stringhe distinte in cui una sia prefisso dell'altra. Tutte le parole del codice sono a due a due *inconfrontabili*.

#informally(title: "Proprietà della decodifica")[
  Il grandissimo vantaggio dei codici istantanei è che esiste un solo modo di leggere e partizionare una determinata sequenza di bit. Leggendo il flusso di bit uno ad uno, sappiamo immediatamente quando una codeword termina, permettendoci di concatenare numeri adiacenti in memoria senza separatori espliciti e decodificandoli senza alcuna ambiguità.
]

=== Codice istantaneo completo

Un codice istantaneo è detto *completo* (o non ridondante) se, per ogni possibile parola binaria in $2^*$, la parola è confrontabile con *almeno* una parola del codice. 
La conseguenza fondamentale è che, una volta che un codice istantaneo è diventato completo, non è più possibile estenderlo: non posso inserire nuove parole senza violare e distruggere la proprietà di decodifica istantanea.