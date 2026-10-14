#import "../template.typ": *

#import "../template.typ": *

= Information retrieval

== Indice inverso

Per permettere l'information retrieval, ossia la ricerca di documenti o pagine web per parole chiave, è necessario costruire
un indice inverso. A ogni indice (che rappresenta un termine o token) viene associata la lista dei documenti in cui compare.

Per costruirlo si parte da una collezione di documenti e si procede per passi.

+ Si estrae il testo da ogni documento. In questa prima descrizione si considera il testo senza struttura, cioè senza distinguere
titoli, paragrafi o altri campi.
+ Si tokenizza il testo: lo si divide in unità, generalmente parole o altri token. La codifica dei caratteri, per esempio
UTF-8, permette di rappresentare il testo; non risolve però da sola la segmentazione, che dipende dalla lingua e dalle convenzioni
adottate. Per esempio, in alcune lingue non si può assumere che gli spazi separino sempre le parole.
+ Si decide quali trasformazioni applicare ai token e si assegna un identificativo a ciascun termine distinto del vocabolario.
+ Per ogni token si registrano il documento in cui compare e, se necessario, la sua posizione nel documento. Le registrazioni
costituiscono le posting list dell'indice.

== Preparazione dei token

Le scelte di preparazione influenzano sia lo spazio occupato dall'indice sia la qualità dei risultati. Conviene definirle
prima di costruire l'indice e applicare le stesse regole sia ai documenti sia alle query.

=== Normalizzazione

La normalizzazione rende uniformi forme che si vogliono trattare come equivalenti. Alcuni esempi sono convertire le lettere
in minuscolo, uniformare gli apostrofi o rimuovere determinati segni diacritici. La punteggiatura può essere separata, rimossa
o mantenuta, a seconda delle query che si vogliono supportare; spazi e tabulazioni normalmente delimitano i token, ma possono
avere significato in dati strutturati. Anche emoji e simboli possono essere token se sono rilevanti per la collezione.

La normalizzazione è potenzialmente distruttiva: se due forme vengono ricondotte allo stesso token, una ricerca successiva
potrebbe non distinguerle. Per esempio, ignorare gli accenti può favorire il richiamo ma ridurre la precisione.

=== Stemming

Lo stemming riduce una parola a una forma ottenuta con regole di troncamento. Per esempio, nell'vocabolario inglese si può
ricondurre forme plurali o forme in `-ing` a una radice comune. La radice ottenuta non è necessariamente una parola corretta.

Si può anche cercare di ricondurre le forme flesse alla loro forma lessicale, o lemma (lemmatizzazione).

In italiano, per esempio, diverse forme coniugate di un verbo possono essere ricondotte all'infinito.
Oppure le parole 'albero' e 'alberi' possono diventare 'alber'.

Queste trasformazioni aiutano a trovare varianti della stessa parola, ma possono anche unire termini che sarebbe utile distinguere.
La scelta dipende dalla lingua, dalla collezione e dal compromesso desiderato tra precisione e spazio occupato;

=== Stopword

Le stopword sono parole molto frequenti, spesso grammaticali, come articoli e preposizioni. In alcuni sistemi vengono rimosse
per ridurre la dimensione dell'indice; in altri vengono mantenute. Conservarle è utile, per esempio, per le ricerche di frasi
e di prossimità. La decisione dipende dalle funzionalità richieste e dalle tecniche di compressione disponibili.

#note()[
  Un hapax legomenon è un termine che compare una sola volta in una collezione di documenti. Un termine raro può essere
  un nome proprio o una parola significativa, ma può anche derivare da un errore di battitura o da rumore nell'estrazione
  del testo. Non va quindi eliminato automaticamente: la sua utilità dipende dal caso d'uso.
]

== Liste di Affissione (Posting list)
A questo punto si ritrova un'insieme di terne del tipo `<token(id) , documento, posizione>`, che vengono raggruppate per
token/termine.

Per ogni termine $t$ si memorizza una lista di affissione ordinata per identificativo del documento. A seconda delle query
da supportare, ogni affissione può contenere informazioni diverse:

+ *Solo documento:* l'identificativo del documento. È la rappresentazione più semplice e consente di sapere dove compare
il termine.
+ *Documento e conteggio:* oltre al documento, il numero di occorrenze del termine in quel documento.
+ *Documento, conteggio e posizioni:* anche le posizioni delle occorrenze nel documento. Queste permettono query di frase
e di prossimità, ma aumentano lo spazio occupato.

Le posizioni di un singolo termine non bastano a ricostruire tutto il documento: servono invece a verificare dove compare
quel termine e come è disposto rispetto agli altri termini indicizzati.

Si distinguono alcuni valori utili:

+ La *frequenza* è il numero totale di occorrenze di $t$ in tutti i documenti.
+ L' *occorrenza* è il numero di volte in cui appare $t$ nel documento $d$.

== Codifica e Compressione delle liste di affissione

Le posting list sono in genere ordinate e contengono numeri crescenti. Invece di memorizzare ogni identificativo per intero,
si possono codificare le differenze tra valori consecutivi, ossia i *gap*. Numeri più piccoli richiedono spesso meno bit.


#example(title: "Codifica di liste di affissione con i soli documenti tramite Elias gamma")[
  Consideriamo il termine `ciao`, presente nei documenti con identificativi 0, 3, 7 e 11.

  + La lista di affissione è ordinata: `<0, 3, 7, 11>`.
  + Calcoliamo i gap: il primo valore è 0 e poi facciamo le differenze tra valori consecutivi. Otteniamo `<0, 3, 4, 4>`.
  + Elias gamma codifica interi positivi, non zero. Per trattare il primo gap, pari a zero, aggiungiamo 1 solo a quello: `<1, 3, 4, 4>`.
  + Codifichiamo ciascun valore con Elias gamma e concateniamo i codici.

  *Codifica concatenata dei bit:*

  $
    overbrace("1", "doc 0") quad
    overbrace("011", "doc 3") quad
    overbrace("00100", "doc 7") quad
    overbrace("00100", "doc 11")
  $

  La decodifica ricostruisce i valori `<1, 3, 4, 4>`; sottraendo 1 solo al primo valore si ottengono i gap originali `<0, 3, 4, 4>`, dai quali
  si ricostruiscono gli identificativi cumulando le differenze: `<0, 3, 7, 11>`.
]

#example(title: "Codifica di liste di affissione con documenti in gamma e numeri di occorrenze in unario")[

  Consideriamo ora la lista di affissione con il numero di occorrenze per documento:

  ```text
  Documento 0: occorrenze = 1
  Documento 3: occorrenze = 4
  Documento 7: occorrenze = 1
  Documento 11: occorrenze = 1
  ```

  + I gap dei documenti in gamma sono gli stessi dell'esempio precedente.
  + Codifichiamo i conteggi con il codice unario $0^*1$, ottenendo: `<1, 0001, 1, 1>`.

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

  ```text
  Documento 0: occorrenze = 1, posizioni = <0>
  Documento 3: occorrenze = 4, posizioni = <3, 4, 20, 22>
  Documento 7: occorrenze = 1, posizioni = <10>
  Documento 11: occorrenze = 1, posizioni = <20>
  ```

  Le posizioni sono crescenti all'interno di ciascun documento e si possono codificare con gap, azzerando il calcolo per
  ogni nuovo documento. Per rappresentare anche una prima posizione pari a 0 usando codici per interi positivi, aggiungiamo
  1 solo alla prima posizione di ciascuna lista; le differenze successive sono già positive.

  + Per il documento 0, `0` diventa `1`.
  + Per il documento 3, `<3, 4, 20, 22>` diventa `<4, 1, 16, 2>`.
  + Per il documento 7, `<10>` diventa `<11>`; per il documento 11, `<20>` diventa `<21>`.

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

Le scelte di codifica possono essere diverse per identificativi, conteggi e posizioni. È essenziale che la costruzione e la lettura dell'indice usino le stesse convenzioni: ordine dei campi, codici impiegati, offset, confini delle liste e modo di rappresentare il primo valore.


== Modello bernoulliano delle liste di affissioni

Dato un insieme di documenti $n$, se prendo una moneta di peso $f/n$ e la tiro $n$ volte mi esce testa $f$ volte più volte. Se esce testa il termine compare , altrimenti no. Il valore atteso è $f$.

La moneta va testa con $p$ e croce con $1-p$. Se vogliamo rappresentate la distribuzione dei gap dobbiamo usare golom, in quanto tale distribuzione è una geometrica $(1-p)^k p$

//riguardare
Dove (1-p)^k p rappresenta la probabilità di trovarte un gap di lunghezza $k$. Se la lista è molto densa, la probabilità p sarà molto alta, mentre (1-p) sarà molto bassa.

#note()[
  Ad esempio con p = 1/2 otteniamo il codice unario.
]

La frequenza $f$ è la probabilità che un termine compare in un documeto è $p$. Devo fare $k$ crosci e una testa.

#note()[
  La precisione dipende dall'ordine dei documenti. Solo sulla base della frequenza assumere che ogni parola compare in un documento in maniera indipendente è un assunzione molto forte. L'indice è preciso se i documenti sono in ordine di crwal, una parola sul calcio compare ad altre parole vicine sul calcio in questo modo.
]

== Leggere il bit stream

Tutte le operazioni realative ai codici sono sequenziali, andiamo a leggere un bit stram bit a bit. Inoltre tutte le operazioni vengono eseguite su una parola di memoria (buffer stream).

In questo caso va bene ma solamente per l'unario, gli altri richidono più operazione. La soluzione è usare delle tabelle di lookup che contengono i simboli più frequenti.

//riguardare

Creiamo una tablla di 16 righe con tutti i bit pattern che possiamo trovare li dentro con $4$ bit. per ognuni riga leggiamo il bit letto e quanto è grande. Tipo (0 e il codic eè lungo 3 bit, 1 il codice è lungo 3,) e un carattere di escape quando non riusciamo a leggere un bit. La seconda colonna rappresenta i bit da buttare.

Per leggere un codice:
- prendiamo i 4 bit per capire quando è grande
- leggiamo dalla tabella e faccio uno shit

La tablla indica le operazioni da fare in base alla parola di memoria che stiamo considerando nel bit stram. Ci indica come ottenere la parola originale.

Funziona molto bene con i codici parametrici. Solitamente la tabella è sufficiente per coprire l'intera distribuzione.

#note()[
  Il vantaggio di leggere big endian è che le tabelle di lookup vengono utilizzate meglio dalla cache, ci sono meno cache miss in quanto quelli più frequenti (1 inziale) sono tutti vicini
]
