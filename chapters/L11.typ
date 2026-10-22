#import "../template.typ": *

= Information retrieval

Per permettere l'information retrieval, ossia la ricerca di documenti o pagine web per parole chiave, è necessario costruire un indice inverso. *A ogni voce* dell'indice (che rappresenta un termine o token del vocabolario) *viene associata la lista dei documenti* in cui tale termine compare.

Per costruirlo si parte da una collezione di documenti e si procede per passi:

+ *Estrazione del testo:* si estrae il testo da ogni documento. In questa prima descrizione si considera il testo senza struttura (testo plain), cioè senza distinguere titoli, paragrafi o altri campi.
+ *Tokenizzazione:* si divide il testo in unità elementari, generalmente parole o altri token. La codifica dei caratteri (per esempio UTF-8) permette di rappresentare correttamente il testo in memoria, ma non risolve da sola il problema della segmentazione, che dipende fortemente dalla lingua e dalle convenzioni adottate. Per esempio, in alcune lingue asiatiche non si può assumere che gli spazi separino sempre le parole.
+ *Elaborazione del vocabolario:* si decide quali trasformazioni lessicali applicare ai token e si assegna un identificativo univoco a ciascun termine distinto del vocabolario.
+ *Costruzione delle liste:* per ogni token si registrano l'identificativo del documento in cui compare e, se necessario, il numero di occorrenze e le relative posizioni nel documento. Queste registrazioni costituiscono le *liste di affissione* (*posting list*) dell'indice.

L'unità informativa fondamentale memorizzata nell'istanza dell'indice è una *terna*: `(documento, posizione, token)`. Tutte queste informazioni devono essere memorizzate in forma compressa e in modo da garantire operazioni di ricerca ad altissima velocità.

== Preparazione dei token

Le scelte effettuate durante la preparazione dei token influenzano sia lo *spazio occupato* dall'indice sia la *qualità dei risultati* restituiti. È fondamentale definirle prima di costruire l'indice e applicare esattamente le stesse regole sia ai documenti in fase di indicizzazione sia alle query in fase di ricerca.

=== Tokenizzazione e Politiche di Numerazione
- *Complessità linguistica:* Con i linguaggi europei la divisione in token è relativamente semplice, mentre con le lingue orientali la segmentazione risulta estremamente complessa.
- *Gestione della punteggiatura e spazi:* La punteggiatura viene tipicamente indicizzata, mentre gli spazi vengono scartati.
- *Politica di numerazione:* A ogni token viene assegnato un identificativo numerico distinto. È possibile decidere di non indicizzare un segno di interpunzione (come la virgola) ma di mantenerne la numerazione, oppure viceversa. *Non lasciare "buchi" nella numerazione* consente una compressione migliore della struttura, a scapito però di una perdita di informazioni o di flessibilità.

=== Normalizzazione

La normalizzazione *rende uniformi* forme superficiali diverse che si vogliono trattare come equivalenti. Alcuni esempi classici sono convertire tutte le lettere in minuscolo (*case folding*), uniformare i diversi tipi di apostrofi o rimuovere determinati segni diacritici (come gli accenti).

La punteggiatura può essere separata, rimossa o mantenuta a seconda delle query che si vogliono supportare; spazi e tabulazioni normalmente delimitano i token, ma possono avere un significato specifico in presenza di dati strutturati. Anche emoji e simboli speciali possono costituire token validi se risultano rilevanti per la collezione.

#warning()[
  La normalizzazione è un'operazione *potenzialmente distruttiva*: se due forme distinte vengono ricondotte allo stesso token, una ricerca successiva non sarà più in grado di distinguerle (per esempio, in italiano, rimuovere gli accenti unifica "è" ed "e", oppure "meta" e "metà"). In generale, una normalizzazione aggressiva tende a favorire il *richiamo* (*recall*, trovare più documenti potenzialmente rilevanti) ma può ridurre la *precisione* (*precision*, evitare documenti non pertinenti).
]

=== Stemming e lemmatizzazione

Lo *stemming* riduce una parola a una forma base (detta *radice* o *stem*) ottenuta mediante *regole euristiche* di troncamento dei suffissi. Per esempio, nel vocabolario inglese si possono ricondurre le forme plurali o le forme verbali in `-ing` a una radice comune.

#warning()[
  La radice ottenuta *non è necessariamente una parola valida* della lingua: in italiano, per esempio, le parole "albero" e "alberi" vengono troncate nella radice comune `"alber"`.
]

In alternativa, si può ricondurre ciascuna forma flessa alla sua forma lessicale canonica, o *lemma* (processo di *lemmatizzazione*): in italiano, per esempio, le diverse forme coniugate di un verbo vengono ricondotte all'infinito, e i sostantivi al singolare. A differenza dello stemming, la lemmatizzazione *richiede solitamente un dizionario* e un'analisi morfologica/contestuale.

Queste trasformazioni aiutano a trovare varianti morfologiche della stessa parola, ma possono anche fondere termini che sarebbe utile mantenere distinti. La scelta dipende dalla lingua, dalla natura della collezione e dal compromesso desiderato tra precisione, richiamo e spazio occupato.

#warning(title: "Evoluzione dello Stemming")[
  Con i motori di ricerca globali, mantenere traccia dello stemming per tutte le lingue del mondo è diventato estremamente complesso e oneroso. *Ad oggi, nei motori di ricerca moderni, nessuno fa più stemming pesante*.
]

=== Stopword e Hapax Legomena

Le *stopword* sono parole estremamente frequenti nella lingua, spesso con funzione puramente grammaticale, come articoli, congiunzioni e preposizioni. 
- In passato, a causa di risorse limitate, venivano scartate per ridurre drasticamente la dimensione dell'indice.
- *Oggi si indicizza tutto:* le risorse di calcolo attuali permettono di gestirle senza problemi, e *conservarle è indispensabile*, per esempio, per supportare con precisione le *ricerche di frasi esatte* (*phrase query*, es. `"essere o non essere"`) e le query di prossimità. La decisione dipende dalle funzionalità richieste dal motore di ricerca e dall'efficacia delle tecniche di compressione disponibili.

#note()[
  Un *hapax legomenon* (al plurale *hapax legomena*) è un termine che compare una sola volta all'interno di un'intera collezione di documenti. Un termine così raro può essere un nome proprio specifico o una parola altamente informativa, ma può anche derivare da un errore di battitura o da rumore introdotto durante l'estrazione del testo. *Non va quindi eliminato automaticamente:* la sua utilità dipende dallo specifico caso d'uso e dal contesto (es. biblioteca strutturata vs web aperto, dove gli errori di battitura possono far esplodere le voci del vocabolario).
]

== Liste di affissione (Posting list)

Al termine della scansione dei documenti si ottiene un insieme di terne del tipo:
$ <"token(id)", "documento", "posizione"> $
essi vengono successivamente ordinate e raggruppate per termine. Per ogni termine $t$ del vocabolario si memorizza una *lista di affissione* (*posting list*) ordinata per identificativo crescente del documento. A seconda della complessità delle interrogazioni da supportare, ogni elemento della lista (affissione o *posting*) può contenere informazioni diverse:

+ *Solo documento:* contiene unicamente l'identificativo del documento (*puntatore documentale*). È la rappresentazione più compatta e consente di sapere in quali documenti compare il termine (sufficiente per query booleane semplici).
+ *Documento e conteggio:* oltre all'identificativo del documento, memorizza il numero di occorrenze del termine in quel documento (necessario per calcolare punteggi di rilevanza basati sulla frequenza, come TF/IDF o BM25).
+ *Documento, conteggio e posizioni:* aggiunge anche la lista delle posizioni (espresse a indice) in cui il termine compare all'interno del documento. Queste informazioni permettono di risolvere query di frase e di prossimità, ma aumentano sensibilmente lo spazio occupato dall'indice.

Nel contesto delle liste di affissione si distinguono due grandezze fondamentali:
+ La *frequenza* (o *document frequency*, $f$): è il numero di documenti distinti della collezione in cui il termine $t$ compare (ovvero la lunghezza della sua posting list). Talvolta con frequenza totale (*collection frequency*) ci si riferisce invece alla somma totale delle occorrenze di $t$ in tutta la collezione.

+ Il *conteggio* (o *numero di occorrenze* / *term frequency* locale): è il numero di volte in cui il termine $t$ appare all'interno di uno specifico documento $d$.

Rispetto alla frequenza globale, si distinguono:
- *Frequenza piccola -> Liste sparse:* I termini compaiono in pochissimi documenti (es. gli *hapax*).
- *Frequenza grande -> Liste dense:* I termini compaiono in una moltitudine di documenti (es. le *stopword*).

#note(title: "Proprietà di compressione")[
  Le liste *dense* si comprimono molto meglio rispetto a quelle sparse, poiché la regolarità e la ridondanza dei dati consentono algoritmi di compressione dei bit più efficienti.
]

== Codifica e compressione delle liste di affissione

Le posting list *sono ordinate* e contengono sequenze di numeri interi strettamente crescenti (sia per gli identificativi dei documenti, sia per le posizioni all'interno di uno stesso documento). Invece di memorizzare ogni valore per intero, conviene codificare le differenze tra valori consecutivi, dette *scarti* o *gap*. Poiché gli scarti sono numeri molto più piccoli dei valori assoluti (specialmente per i termini frequenti), richiedono molti meno bit se rappresentati tramite *codici privi di prefissi* per gli interi (come il codice unario, $gamma$ e $delta$ di Elias, o i codici di Golomb).

#note()[
  Nelle dispense i codici istantanei ($gamma$, $delta$, unario) sono definiti sui numeri naturali a partire da $0$ (usando la *rappresentazione binaria ridotta* di $x$, ovvero la scrittura binaria di $x+1$ privata del bit più significativo). Tuttavia, quando si codificano quantità che per natura sono strettamente positive (interi $v >= 1$, come i conteggi o i gap tra elementi distinti), il valore $0$ non può mai verificarsi: si associa quindi al valore $v >= 1$ la parola di codice corrispondente all'indice $v - 1$. Per questo motivo, il primo documento o la prima posizione (che potrebbero valere $0$) vengono incrementati di $1$ prima della codifica, portando il dominio in $[1, infinity)$, mentre i gap successivi (essendo differenze tra valori strettamente crescenti) sono già $>= 1$ e non richiedono alcun incremento.
]

#example(title: "Codifica di liste di affissione con i soli documenti tramite Elias gamma")[
  Consideriamo il termine `ciao`, presente nei documenti con identificativi $0, 3, 7$ e $11$.

  + La lista di affissione è ordinata: `<0, 3, 7, 11>`.
  + Calcoliamo i gap: il primo valore resta $0$ e per i successivi calcoliamo le differenze tra valori consecutivi, ottenendo `<0, 3, 4, 4>`.
  + Poiché usiamo la codifica $gamma$ sugli interi positivi ($>= 1$), trasliamo solo il primo valore (che può essere $0$) aggiungendo $1$: otteniamo `<1, 3, 4, 4>`.
  + Codifichiamo ciascun valore con Elias $gamma$ e concateniamo i codici.

  *Codifica concatenata dei bit:*

  $
    overbrace("1", "doc 0") quad
    overbrace("011", "doc 3") quad
    overbrace("00100", "doc 7") quad
    overbrace("00100", "doc 11")
  $

  La decodifica legge sequenzialmente il flusso di bit e ricostruisce i valori `<1, 3, 4, 4>`; sottraendo $1$ solo al primo valore si riottengono i gap originali `<0, 3, 4, 4>`, dai quali si ricostruiscono gli identificativi dei documenti cumulando le differenze (somme prefisse): `<0, 3, 7, 11>`.
]

#example(title: "Codifica di liste di affissione con documenti in gamma e numeri di occorrenze in unario")[
  Consideriamo ora la stessa lista di affissione arricchita con il numero di occorrenze (conteggi) per ciascun documento:

  #raw(
    "Documento 0: occorrenze = 1\nDocumento 3: occorrenze = 4\nDocumento 7: occorrenze = 1\nDocumento 11: occorrenze = 1",
    block: true,
    lang: "text",
  )

  + I gap dei documenti codificati in $gamma$ sono gli stessi dell'esempio precedente (`1`, `011`, `00100`, `00100`).
  + Codifichiamo i conteggi $c >= 1$ con il codice unario (costituito da $c-1$ zeri seguiti da un $1$, cioè della forma $0^*1$), ottenendo: `<1, 0001, 1, 1>`.
  + Inframmezziamo (interleaving) il codice di ciascun documento con il relativo conteggio:

  $
    overbrace("1" quad "1", "doc 0") quad
    overbrace("011" quad "0001", "doc 3") quad
    overbrace("00100" quad "1", "doc 7") quad
    overbrace("00100" quad "1", "doc 11")
  $
]

#example(
  title: "Codifica di liste di affissione con documenti in gamma, conteggi in unario e posizioni in delta",
)[
  Aggiungiamo infine le posizioni in cui il termine compare all'interno di ciascun documento:

  #raw(
    "Documento 0: occorrenze = 1, posizioni = <0>\nDocumento 3: occorrenze = 4, posizioni = <3, 4, 20, 22>\nDocumento 7: occorrenze = 1, posizioni = <10>\nDocumento 11: occorrenze = 1, posizioni = <20>",
    block: true,
    lang: "text",
  )

  Le posizioni sono *strettamente crescenti all'interno di ciascun documento* e si codificano anch'esse tramite gap, azzerando il calcolo a ogni nuovo documento. Analogamente ai documenti, poiché la prima posizione può essere $0$, aggiungiamo $1$ solo alla prima posizione di ciascuna lista, mentre le differenze successive sono già strettamente positive ($>= 1$):

  + Per il documento 0: la posizione `<0>` diventa `<1>` (in $delta$: `1`).
  + Per il documento 3: le posizioni `<3, 4, 20, 22>` hanno gap `<3, 1, 16, 2>`, che incrementando il primo elemento diventano `<4, 1, 16, 2>` (in $delta$: `01100`, `1`, `001010000`, `0100`).
  + Per il documento 7: `<10>` diventa `<11>` (in $delta$: `00100011`).
  + Per il documento 11: `<20>` diventa `<21>` (in $delta$: `001010101`).

  *Codifica complessiva (documento in $gamma$, conteggio in unario, posizioni in $delta$):*

  $
    overbrace("1" quad "1" quad "1", "doc 0")
    quad
    overbrace("011" quad "0001" quad "01100" quad "1" quad "001010000" quad "0100", "doc 3")
    quad\
    overbrace("00100" quad "1" quad "00100011", "doc 7")
    quad
    overbrace("00100" quad "1" quad "001010101", "doc 11")
  $
]

#note()[
  La scelta della codifica può essere differente per identificativi, conteggi e posizioni (ad esempio, per conteggi e frequenze si usa spesso $gamma$ per via dell'alta presenza di *hapax legomena*, mentre per le posizioni si preferisce $delta$). È essenziale che la fase di scrittura e quella di lettura dell'indice adottino esattamente le stesse convenzioni: ordine dei campi, codici impiegati, delimitatori strutturali e gestione degli offset sul primo valore.
]

#warning(title: "Regola di coerenza dei codici")[
  È possibile mischiare e combinare qualsiasi tipo di codice (Unario, Gamma, Delta, ecc.) per il conteggio, l'ID o le posizioni, purché in fase di lettura e scrittura vengano impiegati *esattamente gli stessi codici e le stesse convenzioni strutturali*.
]

== Modello bernoulliano delle liste di affissione

Per scegliere il codice più adatto a comprimere i gap tra i documenti è utile adottare un *modello statistico* che ne descriva la distribuzione.

Consideriamo una collezione di $N$ documenti e un termine che compare in $f$ documenti. Il *modello bernoulliano* assume che il termine compaia in ciascun documento in modo *indipendente* con probabilità costante *$p = f / N$*. Possiamo immaginare il processo come il lancio ripetuto di una moneta sbilanciata $N$ volte:
- Con probabilità $p = f / N$ esce *testa*: il termine è presente nel documento.
- Con probabilità $1 - p$ esce *croce*: il termine non è presente nel documento.

Il valore atteso del numero di teste su $N$ lanci è esattamente $N dot p = f$.

Sotto questa ipotesi di indipendenza, la distanza (*gap*) tra un documento che contiene il termine e il successivo *corrisponde al numero di lanci necessari per ottenere una nuova testa*: dobbiamo cioè osservare $k$ croci consecutive (documenti che non contengono il termine) seguite da una testa (documento che lo contiene). La *probabilità di osservare una sequenza di $k$ croci* ($k >= 0$) seguite da una testa segue una *distribuzione geometrica*:
$
  Pr["gap" = k] = (1 - p)^k p
$
#note()[
  Se si misura lo scarto come differenza strettamente positiva $x = k + 1 >= 1$ tra gli indici dei documenti, la formula si scrive equivalentemente come $(1-p)^(x-1) p$.
]

Se la posting list è *molto densa* (termine molto frequente), la probabilità $p$ sarà alta e $(1 - p)$ sarà bassa, rendendo molto *probabili gap piccoli*. Viceversa, per termini rari ($p$ piccola), i gap saranno mediamente molto grandi.

Poiché sappiamo che la distribuzione associata al *codice di Golomb* è proprio una distribuzione geometrica, il codice di Golomb risulta la scelta teoricamente ottima per comprimere i gap dei documenti nel modello bernoulliano. Ovviamente scegliendo il modulo ottimo in funzione di $p$:
$
  b = ceil(- log(2-p) / log(1-p))
$

#note()[
  Nel caso particolare in cui $p = 1/2$, la distribuzione geometrica diventa $1 / 2^(k+1)$ (con modulo $b = 1$) e il codice di Golomb coincide esattamente con il *codice unario*.
]

#warning(title: "Limiti del modello e ordinamento dei documenti")[
  Assumere che una parola compaia in ciascun documento in maniera totalmente *indipendente* (basandosi solo sulla frequenza globale $f$) è un'assunzione molto forte e spesso irrealistica.

  La validità del modello bernoulliano dipende fortemente dall'ordine assegnato agli identificativi dei documenti. Se i documenti sono numerati in *ordine di visita del crawler* (ordine di *crawl*), pagine web dello stesso sito o tematicamente correlate avranno identificativi vicini: una parola legata al "calcio", ad esempio, tenderà a comparire a grappoli (*cluster*) in documenti adiacenti, generando molti gap piccolissimi seguiti da lunghi vuoti.

  Questa forte correlazione locale allontana la distorsione reale da quella geometrica teorica (che si osserverebbe invece se i documenti fossero permutati casualmente).
]

== Leggere il bit stream

In fase di interrogazione dell'indice, la decodifica dei codici privi di prefissi è un'operazione puramente *sequenziale*: i codici sono concatenati senza separatori in un flusso continuo di bit (*bit stream*). Leggere il file dal disco bit a bit sarebbe estremamente inefficiente; per questo motivo si mantiene in memoria centrale una finestra sul file, detta *bit buffer* (tipicamente una parola di memoria a 32 o 64 bit), e si eseguono le operazioni di decodifica direttamente sui registri della CPU.

Procedere bit a bit può andar bene solo per codici semplicissimi come l'unario (tramite istruzioni hardware che contano gli zeri iniziali), ma per codici più articolati ($gamma$, $delta$, Golomb) la decodifica manuale passo-passo richiede troppe istruzioni e diramazioni (*branch*). La soluzione consiste nell'utilizzare delle *tabelle di lookup* (*lookup table*) precalcolate (spesso costruite su blocchi di bit fissi da 8, 12 o 16 bit) che permettono di decodificare in un solo colpo i simboli più frequenti.

=== Decodifica tramite tabelle di lookup

Per capire il funzionamento, immaginiamo di costruire una tabella indicizzata da prefissi di lunghezza fissa pari a $k = 4$ bit: avremo una tabella di $2^4 = 16$ righe, una per ogni possibile configurazione di 4 bit da `0000` a `1111` (nella pratica si usano solitamente tabelle da $k = 8, 12$ o $16$ bit).

Ogni riga della tabella corrisponde a ciò che "vediamo" ispezionando i primi $4$ bit del nostro buffer e memorizza due informazioni:
+ *Il valore decodificato* (oppure un valore speciale di *escape*, es. `-1`, se il codice inizia con troppi zeri ed è più lungo di $4$ bit).
+ *Il numero di bit da scartare* (cioè la lunghezza effettiva della parola di codice appena riconosciuta, di cui fare lo *shift*).

Ricordando le prime parole del codice $gamma$ di Elias (convenzione su $\NN$: $0 mapsto "1"$, $1 mapsto "010"$, $2 mapsto "011"$, $3 mapsto "00100"$, ecc.), tutti i codici per $x >= 3$ sono lunghi almeno $5$ bit e non entrano nella finestra da $4$ bit. La tabella di lookup a $4$ bit per il codice $gamma$ avrà quindi esattamente questa struttura:

#figure(
  table(
    columns: (auto, auto, auto, auto),
    align: (center + horizon, center + horizon, center + horizon, left + horizon),
    inset: 3pt,
    stroke: 0.5pt + luma(180),
    fill: (x, y) => if y == 0 { luma(230) } else if y <= 4 { rgb("#ffebee") } else if y <= 6 {
      rgb("#e3f2fd")
    } else if y <= 8 { rgb("#e8f5e9") } else { rgb("#fff8e1") },
    [*Indice (4 bit)*], [*Valore letto*], [*Bit da scartare (Shift)*], [*Spiegazione del pattern*],
    [`0000`], [`ESCAPE (-1)`], [`0` (o manuale)], [Inizia con `00...` (codice lungo $>= 5$ bit)],
    [`0001`], [`ESCAPE (-1)`], [`0` (o manuale)], [Inizia con `00...` (codice lungo $>= 5$ bit)],
    [`0010`], [`ESCAPE (-1)`], [`0` (o manuale)], [Inizia con `0010...` (manca il 5° bit)],
    [`0011`], [`ESCAPE (-1)`], [`0` (o manuale)], [Inizia con `0011...` (manca il 5° bit)],
    [`0100`], [*1*], [*3*], [Prefisso *`010`* ($x=1$, 3 bit) + `0` del prossimo codice],
    [`0101`], [*1*], [*3*], [Prefisso *`010`* ($x=1$, 3 bit) + `1` del prossimo codice],
    [`0110`], [*2*], [*3*], [Prefisso *`011`* ($x=2$, 3 bit) + `0` del prossimo codice],
    [`0111`], [*2*], [*3*], [Prefisso *`011`* ($x=2$, 3 bit) + `1` del prossimo codice],
    [`1000` .. `1111` \ _(8 righe)_], [*0*], [*1*], [Prefisso *`1`* ($x=0$, 1 bit) + `xxx` (3 bit successivi ignorati)],
  ),
  caption: [Tabella di lookup a $4$ bit per la decodifica di Elias $gamma$. Nota come le 8 righe da `1000` a `1111` siano tutte contigue in fondo alla tabella.\
  Le prime non vengono lette perchè iniziano con troppi zeri, la parola è più lunga della capacità della finestra
  ],
)

Per decodificare una sequenza dal *bit stream* si procede quindi in due passi ciclici:
+ *Ispezione (Peek):* si leggono i primi $4$ bit in cima al *bit buffer* (senza rimuoverli) usandoli come indice della tabella.
+ *Lookup e Shift:* si legge il valore corrispondente e si fa scorrere (*shift* a sinistra) il buffer del numero di bit indicato nella seconda colonna.

#figure(
  block(
    width: 100%,
    inset: 10pt,
    radius: 4pt,
    stroke: 0.5pt + luma(200),
    fill: luma(250),
    [
      #set text(size: 9.5pt)
      *Passo 1: Decodifica del primo simbolo*
      #v(4pt)
      #grid(
        columns: (auto, 1fr),
        column-gutter: 14pt,
        align: (left + horizon, left + horizon),
        table(
          columns: (20pt, 20pt, 20pt, 20pt, 20pt, 20pt, 20pt, 20pt),
          align: center + horizon,
          fill: (x, y) => if x == 0 { rgb("#ffe082") } else if x < 4 { rgb("#fff8e1") } else { white },
          stroke: (x, y) => if x < 4 { 1.2pt + rgb("#f57f17") } else { 0.5pt + gray },
          [*1*], [`0`], [`1`], [`1`], [`0`], [`1`], [`0`], [`1`],
        ),
        [
          + *Peek (4 bit):* leggo `1011` (evidenziati).
          + *Lookup[`1011`]:* valore = *0*, bit da scartare = *1*.
          + *Shift:* butto via 1 bit (`1`) e scorro a sinistra.
        ],
      )
      #v(8pt)
      #line(length: 100%, stroke: 0.5pt + luma(200))
      #v(8pt)
      *Passo 2: Decodifica del secondo simbolo (dopo shift di 1 bit)*
      #v(4pt)
      #grid(
        columns: (auto, 1fr),
        column-gutter: 14pt,
        align: (left + horizon, left + horizon),
        table(
          columns: (20pt, 20pt, 20pt, 20pt, 20pt, 20pt, 20pt, 20pt),
          align: center + horizon,
          fill: (x, y) => if x < 3 { rgb("#a5d6a7") } else if x == 3 { rgb("#e8f5e9") } else { white },
          stroke: (x, y) => if x < 4 { 1.2pt + rgb("#2e7d32") } else { 0.5pt + gray },
          [*0*], [*1*], [*1*], [`0`], [`1`], [`0`], [`1`], [`...`],
        ),
        [
          + *Peek (4 bit):* leggo `0110`.
          + *Lookup[`0110`]:* valore = *2*, bit da scartare = *3*.
          + *Shift:* butto via 3 bit (`011`) e scorro a sinistra.
        ],
      )
      #v(8pt)
      #line(length: 100%, stroke: 0.5pt + luma(200))
      #v(8pt)
      *Passo 3: Decodifica del terzo simbolo (dopo shift di 3 bit)*
      #v(4pt)
      #grid(
        columns: (auto, 1fr),
        column-gutter: 14pt,
        align: (left + horizon, left + horizon),
        table(
          columns: (20pt, 20pt, 20pt, 20pt, 20pt, 20pt, 20pt, 20pt),
          align: center + horizon,
          fill: (x, y) => if x < 3 { rgb("#90caf9") } else if x == 3 { rgb("#e3f2fd") } else { white },
          stroke: (x, y) => if x < 4 { 1.2pt + rgb("#1565c0") } else { 0.5pt + gray },
          [*0*], [*1*], [`0`], [`1`], [`...`], [`...`], [`...`], [`...`],
        ),
        [
          + *Peek (4 bit):* leggo `0101`.
          + *Lookup[`0101`]:* valore = *1*, bit da scartare = *3*.
          + *Shift:* butto via 3 bit (`010`) e scorro a sinistra.
        ],
      )
    ],
  ),
  caption: [Simulazione passo-passo sul flusso di bit `10110101...` (che contiene i codici concatenati `1` $mapsto 0$, `011` $mapsto 2$, `010` $mapsto 1$):],
)

Questa tecnica funziona molto bene anche con i codici parametrici: poiché le parole di codice corte sono statisticamente le più frequenti (rappresentano i gap piccoli), una tabella di dimensione standard riesce a coprire quasi l'intera distribuzione empirica, ricorrendo all'*escape* solo in casi rarissimi.

#note()[
  *Vantaggio dell'ordinamento Big-Endian:* Come si vede chiaramente nella Tabella 1, leggere il flusso in *big-endian* fa sì che i codici più frequenti siano raggruppati in blocchi contigui nella tabella (ad esempio, tutte le configurazioni che iniziano con `1` occupano le righe adiacenti da `1000` a `1111`). Questo raggruppamento spaziale permette di sfruttare al meglio le linee di *cache* della CPU, riducendo i *cache miss*.
]