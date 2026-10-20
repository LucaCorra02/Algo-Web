#import "../template.typ": *

= Information retrieval

Per permettere l'information retrieval, ossia la ricerca di documenti o pagine web per parole chiave, è necessario costruire un indice inverso. *A ogni voce* dell'indice (che rappresenta un termine o token del vocabolario) *viene associata la lista dei documenti* in cui tale termine compare.

Per costruirlo si parte da una collezione di documenti e si procede per passi:

+ *Estrazione del testo:* si estrae il testo da ogni documento. In questa prima descrizione si considera il testo senza struttura (testo plain), cioè senza distinguere titoli, paragrafi o altri campi.
+ *Tokenizzazione:* si divide il testo in unità elementari, generalmente parole o altri token. La codifica dei caratteri (per esempio UTF-8) permette di rappresentare correttamente il testo in memoria, ma non risolve da sola il problema della segmentazione, che dipende fortemente dalla lingua e dalle convenzioni adottate. Per esempio, in alcune lingue asiatiche non si può assumere che gli spazi separino sempre le parole.
+ *Elaborazione del vocabolario:* si decide quali trasformazioni lessicali applicare ai token e si assegna un identificativo univoco a ciascun termine distinto del vocabolario.
+ *Costruzione delle liste:* per ogni token si registrano l'identificativo del documento in cui compare e, se necessario, il numero di occorrenze e le relative posizioni nel documento. Queste registrazioni costituiscono le *liste di affissione* (*posting list*) dell'indice.

== Preparazione dei token

Le scelte effettuate durante la preparazione dei token influenzano sia lo *spazio occupato* dall'indice sia la *qualità dei risultati* restituiti. È fondamentale definirle prima di costruire l'indice e applicare esattamente le stesse regole sia ai documenti in fase di indicizzazione sia alle query in fase di ricerca.

=== Normalizzazione

La normalizzazione *rende uniformi* forme superficiali diverse che si vogliono trattare come equivalenti. Alcuni esempi classici sono convertire tutte le lettere in minuscolo (*case folding*), uniformare i diversi tipi di apostrofi o rimuovere determinati segni diacritici (come gli accenti).

La punteggiatura può essere separata, rimossa o mantenuta a seconda delle query che si vogliono supportare; spazi e tabulazioni normalmente delimitano i token, ma possono avere un significato specifico in presenza di dati strutturati. Anche emoji e simboli speciali possono costituire token validi se risultano rilevanti per la collezione.

#warning()[
  
]

La normalizzazione è un'operazione potenzialmente distruttiva: se due forme distinte vengono ricondotte allo stesso token, una ricerca successiva non sarà più in grado di distinguerle (per esempio, in italiano, rimuovere gli accenti unifica "è" ed "e", oppure "meta" e "metà"). In generale, una normalizzazione aggressiva tende a favorire il *richiamo* (*recall*, trovare più documenti potenzialmente rilevanti) ma può ridurre la *precisione* (*precision*, evitare documenti non pertinenti).

=== Stemming e lemmatizzazione

Lo *stemming* riduce una parola a una forma base (detta *radice* o *stem*) ottenuta mediante regole euristiche di troncamento dei suffissi. Per esempio, nel vocabolario inglese si possono ricondurre le forme plurali o le forme verbali in `-ing` a una radice comune. La radice ottenuta non è necessariamente una parola valida della lingua: in italiano, per esempio, le parole "albero" e "alberi" vengono troncate nella radice comune `"alber"`.

In alternativa, si può ricondurre ciascuna forma flessa alla sua forma lessicale canonica, o *lemma* (processo di *lemmatizzazione*): in italiano, per esempio, le diverse forme coniugate di un verbo vengono ricondotte all'infinito, e i sostantivi al singolare. A differenza dello stemming, la lemmatizzazione richiede solitamente un dizionario e un'analisi morfologica/contestuale.

Queste trasformazioni aiutano a trovare varianti morfologiche della stessa parola, ma possono anche fondere termini che sarebbe utile mantenere distinti. La scelta dipende dalla lingua, dalla natura della collezione e dal compromesso desiderato tra precisione, richiamo e spazio occupato.

=== Stopword

Le *stopword* sono parole estremamente frequenti nella lingua, spesso con funzione puramente grammaticale, come articoli, congiunzioni e preposizioni. In alcuni sistemi vengono rimosse per ridurre drasticamente la dimensione dell'indice; in altri vengono invece mantenute. Conservarle è indispensabile, per esempio, per supportare con precisione le ricerche di frasi esatte (*phrase query*, es. `"essere o non essere"`) e le query di prossimità. La decisione dipende dalle funzionalità richieste dal motore di ricerca e dall'efficacia delle tecniche di compressione disponibili.

#note()[
  Un *hapax legomenon* (al plurale *hapax legomena*) è un termine che compare una sola volta all'interno di un'intera collezione di documenti. Un termine così raro può essere un nome proprio specifico o una parola altamente informativa, ma può anche derivare da un errore di battitura o da rumore introdotto durante l'estrazione del testo. Non va quindi eliminato automaticamente: la sua utilità dipende dallo specifico caso d'uso.
]

== Liste di affissione (Posting list)

Al termine della scansione dei documenti si ottiene un insieme di terne del tipo `<token(id), documento, posizione>`, che vengono successivamente ordinate e raggruppate per termine.

Per ogni termine $t$ del vocabolario si memorizza una *lista di affissione* (*posting list*) ordinata per identificativo crescente del documento. A seconda della complessità delle interrogazioni da supportare, ogni elemento della lista (affissione o *posting*) può contenere informazioni diverse:

+ *Solo documento:* contiene unicamente l'identificativo del documento (*puntatore documentale*). È la rappresentazione più compatta e consente di sapere in quali documenti compare il termine (sufficiente per query booleane semplici).
+ *Documento e conteggio:* oltre all'identificativo del documento, memorizza il numero di occorrenze del termine in quel documento (necessario per calcolare punteggi di rilevanza basati sulla frequenza, come TF/IDF o BM25).
+ *Documento, conteggio e posizioni:* aggiunge anche la lista delle posizioni (espresse come indice di parola) in cui il termine compare all'interno del documento. Queste informazioni permettono di risolvere query di frase e di prossimità, ma aumentano sensibilmente lo spazio occupato dall'indice.

Le posizioni associate a un singolo termine non bastano, da sole, a ricostruire l'intero documento originale, ma servono a verificare dove compare quel termine e come è disposto rispetto agli altri termini dell'interrogazione.

Nel contesto delle liste di affissione si distinguono due grandezze fondamentali:
+ La *frequenza* (o *document frequency*, $f$): è il numero di documenti distinti della collezione in cui il termine $t$ compare (ovvero la lunghezza della sua posting list). Talvolta con frequenza totale (*collection frequency*) ci si riferisce invece alla somma totale delle occorrenze di $t$ in tutta la collezione.
+ Il *conteggio* (o *numero di occorrenze* / *term frequency* locale): è il numero di volte in cui il termine $t$ appare all'interno di uno specifico documento $d$.

== Codifica e compressione delle liste di affissione

Le posting list sono ordinate e contengono sequenze di numeri interi strettamente crescenti (sia per gli identificativi dei documenti, sia per le posizioni all'interno di uno stesso documento). Invece di memorizzare ogni valore per intero, conviene codificare le differenze tra valori consecutivi, dette *scarti* o *gap*. Poiché gli scarti sono numeri molto più piccoli dei valori assoluti (specialmente per i termini frequenti), richiedono molti meno bit se rappresentati tramite *codici privi di prefissi* per gli interi (come il codice unario, $gamma$ e $delta$ di Elias, o i codici di Golomb).

#note()[
  *Nota sulle convenzioni di codifica negli esempi:* Nelle dispense i codici istantanei ($gamma$, $delta$, unario) sono definiti sui numeri naturali a partire da $0$ (usando la *rappresentazione binaria ridotta* di $x$, ovvero la scrittura binaria di $x+1$ privata del bit più significativo). Tuttavia, quando si codificano quantità che per natura sono strettamente positive (interi $v >= 1$, come i conteggi o i gap tra elementi distinti), il valore $0$ non può mai verificarsi: si associa quindi al valore $v >= 1$ la parola di codice corrispondente all'indice $v - 1$ (così $1 mapsto "1"$, $2 mapsto "010"$, $3 mapsto "011"$, $4 mapsto "00100"$ in $gamma$, ecc.). Per questo motivo, il primo documento o la prima posizione (che potrebbero valere $0$) vengono incrementati di $1$ prima della codifica, portando il dominio in $[1, infinity)$, mentre i gap successivi (essendo differenze tra valori strettamente crescenti) sono già $>= 1$ e non richiedono alcun incremento.
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

  Le posizioni sono strettamente crescenti all'interno di ciascun documento e si codificano anch'esse tramite gap, azzerando il calcolo a ogni nuovo documento. Analogamente ai documenti, poiché la prima posizione può essere $0$, aggiungiamo $1$ solo alla prima posizione di ciascuna lista, mentre le differenze successive sono già strettamente positive ($>= 1$):

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

Le scelte di codifica possono variare per identificativi, conteggi e posizioni (ad esempio, per conteggi e frequenze si usa spesso $gamma$ per via dell'alta presenza di *hapax legomena*, mentre per le posizioni si preferisce $delta$). È essenziale che la fase di scrittura e quella di lettura dell'indice adottino esattamente le stesse convenzioni: ordine dei campi, codici impiegati e gestione degli offset sul primo valore.


== Modello bernoulliano delle liste di affissione

Per scegliere il codice più adatto a comprimere i gap tra i documenti è utile adottare un modello statistico che ne descriva la distribuzione.

Consideriamo una collezione di $N$ documenti e un termine che compare in $f$ documenti. Il *modello bernoulliano* assume che il termine compaia in ciascun documento in modo indipendente con probabilità costante $p = f / N$. Possiamo immaginare il processo come il lancio ripetuto di una moneta sbilanciata $N$ volte:
- Con probabilità $p = f / N$ esce *testa*: il termine è presente nel documento.
- Con probabilità $1 - p$ esce *croce*: il termine non è presente nel documento.

Il valore atteso del numero di teste su $N$ lanci è esattamente $N dot p = f$.

//riguardare
Sotto questa ipotesi di indipendenza, la distanza (gap) tra un documento che contiene il termine e il successivo corrisponde al numero di lanci necessari per ottenere una nuova testa: dobbiamo cioè osservare $k$ croci consecutive (documenti che non contengono il termine) seguite da una testa (documento che lo contiene).

La probabilità di osservare una sequenza di $k$ croci ($k >= 0$) seguite da una testa segue una *distribuzione geometrica*:
$
  Pr["gap" = k] = (1 - p)^k p
$
(Se si misura lo scarto come differenza strettamente positiva $x = k + 1 >= 1$ tra gli indici dei documenti, la formula si scrive equivalentemente come $(1-p)^(x-1) p$).

Se la posting list è molto densa (termine molto frequente), la probabilità $p$ sarà alta e $(1 - p)$ sarà bassa, rendendo molto probabili gap piccoli. Viceversa, per termini rari ($p$ piccola), i gap saranno mediamente molto grandi.

Poiché sappiamo che la distribuzione associata al *codice di Golomb* è proprio una distribuzione geometrica, il codice di Golomb risulta la scelta teoricamente ottima per comprimere i gap dei documenti nel modello bernoulliano (scegliendo il modulo ottimo $b = ceil(- log(2-p) / log(1-p))$ in funzione di $p$).

#note()[
  Nel caso particolare in cui $p = 1/2$, la distribuzione geometrica diventa $1 / 2^(k+1)$ (con modulo $b = 1$) e il codice di Golomb coincide esattamente con il *codice unario*.
]

#note()[
  *Limiti del modello e ordinamento dei documenti:* Assumere che una parola compaia in ciascun documento in maniera totalmente indipendente (basandosi solo sulla frequenza globale $f$) è un'assunzione molto forte e spesso irrealistica. La validità del modello bernoulliano dipende fortemente dall'ordine assegnato agli identificativi dei documenti. Se i documenti sono numerati in *ordine di visita del crawler* (ordine di *crawl*), pagine web dello stesso sito o tematicamente correlate avranno identificativi vicini: una parola legata al "calcio", ad esempio, tenderà a comparire a grappoli (*cluster*) in documenti adiacenti, generando molti gap piccolissimi seguiti da lunghi vuoti. Questa forte correlazione locale allontana la distribuzione reale da quella geometrica teorica (che si osserverebbe invece se i documenti fossero permutati casualmente).
]

== Leggere il bit stream

In fase di interrogazione dell'indice, la decodifica dei codici privi di prefissi è un'operazione puramente sequenziale: i codici sono concatenati senza separatori in un flusso continuo di bit (*bit stream*). Leggere il file dal disco bit a bit sarebbe estremamente inefficiente; per questo motivo si mantiene in memoria centrale una finestra sul file, detta *bit buffer* (tipicamente una parola di memoria a 32 o 64 bit), e si eseguono le operazioni di decodifica direttamente sui registri della CPU.

Procedere bit a bit può andar bene solo per codici semplicissimi come l'unario (tramite istruzioni hardware che contano gli zeri iniziali), ma per codici più articolati ($gamma$, $delta$, Golomb) la decodifica manuale passo-passo richiede troppe istruzioni e diramazioni (*branch*). La soluzione consiste nell'utilizzare delle *tabelle di lookup* (*lookup table*) precalcolate che permettono di decodificare in un solo colpo i simboli più frequenti.

//riguardare
=== Decodifica tramite tabelle di lookup

Per capire il funzionamento, immaginiamo di costruire una tabella indicizzata da prefissi di lunghezza fissa pari a $k$ bit (ad esempio, con $k = 4$ bit avremo una tabella di $2^4 = 16$ righe, una per ogni possibile configurazione di 4 bit da `0000` a `1111`; nella pratica si usano solitamente tabelle da $k = 16$ bit, cioè di $2^16 = 65536$ righe).

Ogni riga della tabella corrisponde a ciò che "vediamo" ispezionando i primi $k$ bit del nostro buffer e memorizza due informazioni:
+ *Il valore decodificato* (oppure un valore speciale di *escape* / flag se il codice è più lungo di $k$ bit e non è contenuto interamente nel prefisso).
+ *Il numero di bit consumati* (cioè la lunghezza effettiva della parola di codice appena riconosciuta, ossia i bit da scartare).

Ad esempio, supponendo di voler decodificare il codice $gamma$ con una tabella a $4$ bit:
- Se i primi 4 bit sono `1011`, il primo simbolo è `1` (che codifica il valore $0$ ed è lungo $1$ bit): la riga `1011` della tabella conterrà quindi `(valore = 0, bit da scartare = 1)`.
- Se i primi 4 bit sono `0110`, il prefisso inizia con `011` (che codifica il valore $2$ ed è lungo $3$ bit): la riga `0110` conterrà `(valore = 2, bit da scartare = 3)`.
- Se i primi 4 bit sono `0010`, la parola di codice $gamma$ è lunga $5$ bit e non entra nella finestra da $4$ bit: la riga conterrà un codice di *escape* che indica di procedere con la decodifica manuale (oppure di leggere i bit successivi).

Per decodificare un intero dal *bit stream* si procede quindi così:
+ *Ispezione (Peek):* si leggono i primi $k$ bit presenti in cima alla parola di memoria (*bit buffer*) senza ancora rimuoverli, usandoli come indice per accedere alla tabella.
+ *Lookup e Shift:* si recupera dalla tabella il valore decodificato e si effettua uno scorrimento (*shift*) del buffer di un numero di posizioni pari ai bit da scartare (ad esempio 1 o 3 bit), preparando il buffer per la lettura del codice successivo. Se il buffer si svuota sotto una certa soglia, viene ricaricato dal flusso in memoria.

Questa tecnica funziona estremamente bene anche con i codici parametrici e universali: poiché le parole di codice corte sono statisticamente le più frequenti (rappresentano i gap piccoli), una tabella di dimensione ragionevole (es. $2^16$ voci) riesce a coprire la stragrande maggioranza della distribuzione, relegando la decodifica manuale a pochissimi casi rari.

#note()[
  *Vantaggio dell'ordinamento Big-Endian:* Mantenere il *bit stream* e il buffer in formato *big-endian* (leggendo i bit dal più significativo al meno significativo, ovvero da sinistra a destra) offre un importante vantaggio architetturale per la *cache* della CPU. Infatti, tutti i codici molto corti e frequenti (ad esempio il codice `1` di lunghezza 1, che ha come prefisso `1xxx...`) condividono i bit più significativi: nella tabella di lookup, tutte le combinazioni che iniziano per `1` (o per `01`, ecc.) occupano blocchi di indici numericamente contigui o strutturalmente raggruppati, migliorando la località spaziale e riducendo i *cache miss* rispetto a layout in cui i bit significativi del prefisso sono sparsi.
]
