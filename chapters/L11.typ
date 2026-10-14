#import "../template.typ": *


= Indici

L'obbiettivo è quello di costruire l'indice inverso, dato il testo mi da la pagina. Si tratta di un idea piuttosto antica (dai greci).

Assumiamo che abbiamo estratto il testo delle pagine. Da qui vogliamo creare dei segmenti di caratteri (assumiamo che sappiamo la codifica dei caratteri come UTF-8). Da qui vogliamo andare a creare dei *Token* che rappresentano la nostra unità minima di indicizzazione.

Una volta separati i token andiamo ad assegnare un indice sequenzaile a ciasun token. Per ogni token abbiamo una terna, la posizione del documento del token, l'indice del token e il token.

Solitamente prima ad un token vengono applicare *normalizzazione* e *stemming*:
- La normalizzazione è un processo che permette di rendere i token più uniformi, ad esempio trasformando tutte le lettere in minuscolo, rimuovendo la punteggiatura e gli accenti.

  #warning()[
    Si tratta di un operazione distruttiva, una volta normalizzato non potremmo più sapere se il token originale era papà o papa.
  ]

- Lo stemming invece riduce le parole alla loro radice, permettendo di raggruppare varianti della stessa parola sotto un unico token. Ad esempio goverment e goverments diventano goverment. Anche lo stemming è un operazione distruttiva. Con i motori di ricerca che sono diventati multilingia lo stemming è diventato più arduo in quanto ogni lingua ha le sue regole.

  #note()[
    Lo stemming si faceva molto perchè le liste erano molto più dense. Ad oggi il problema dello spazio non è più così rilevante e quindi lo stemming viene usato meno.
  ]

Più i documenti associati ad un termini sono numerosi più il termine viene compresso bene. Meno normalizziamo abbiamo più precisione ma ci serve anche più tempo per la normalizzazione

#note()[
  Le stop word non vengono più rimosse, in quanto permettono di avere una maggiore precisione. Ad esempio se cerco "to be or not to be" voglio che mi vengano restituiti i documenti che contengono questa frase e non tutti i documenti che contengono "be" o "not".
]

è possibile che in tutti i documenti che abbiamo un token capiti una sola volta, questo fenomeno è detto *hapax legomena*. Essi hanno una forte influnza nella struttura dell'indice ma hanno un significato molto basso (spesso errori di battitura). Per questo motivo vengono spesso rimossi dall'indice.

== Liste di affisioni

Una lista di affisioni è una lista di coppie (termine, lista di documenti) che rappresenta l'indice inverso. La lista di documenti può essere rappresentata in vari modi, ad esempio come una lista di interi (gli ID dei documenti) o come una lista di coppie (ID del documento, frequenza del termine nel documento).

#note()[
  Una lista di affissioni che contiene gli indici dei documenti è il minimo sindacale per costuire un indice inverso.
]

Altre liste di affisioni possono contenere informazioni aggiuntive. Contiene ad esempio il documento in cui compare il token e una lista di tuple in qui è contenuto quante volte compare il token e le posizioni all'interno del documento.

//aggiungere esempio

#note()[
  Se memorizziamo le posizioni dei termini, possiamo risalire all'intera collezione di documenti. Non possiamo aspettarci che esso si comprima meglio della collezione di documenti originale.
]


Possiamo ridurre il numero di token dell'indicizzazione sulla base di informazioni statistiche senza guardare la semantica dle token. Ad esempio se la frequenza è sotto ad 1/2 lo rimuoviamo. Le liste di compressione degli apax sono molto difficili da comprimere.

Chiamiamo con:
- frequenza il numero di document i in cui compare il token
- conteggio: proprità della fissione, considerando un certo termine e il documento in cui compare, è quante volte compare il termine in quel documento.

Considerando gli indici dei documento in cui un certo termine compare possiamo scrivere il primo indice cosi com'è, gli altri li memorizziamo come differenza rispetto al precedente. Questo permette di ridurre il numero di bit necessari per memorizzare gli indici dei documenti.

#example()[
  Ciao -> 0,3,7,11
  -> 0,3-0,7-3,11-7
  A questo punto posso scriverlo in gamma:
  1 | 00100 | 00101 | 00101
]

Supponiamo ora di avere una lista di affisione che contiene l'indice del documento e la frequenza del termine in quel documento. A questo punto possiamo scegliere un codice per i conteggi e mischiare tra di loro i due codici. Leggere una lista di affisioni "mista" è possibile in quanto in un qualsiasi istante sappiamo il codice che stiamo leggendo.

#note()[
  è possibile avere uno schema variabile in base alla distribuzione dei dati.
]

=== Indice con tutte le informazioni


Essendo una *sequenza monotona crescente* andremo a memorizzare dei gap sia per le posizionid del documento che sia per gli indici della posiziona del documento.

Inoltre la scelta del codice è dinamica in quanto per le indici delle posizioni del documento la distribuzione dei dati non è prevedibile. Se abbiamo 4 posizioni dobbiamo memorizzare 4 interi scritti in delta (solitamente viene usato questo codice generale)

#example()[
  Se abbiamo una lista:
  $<0,1,<0>>, <3,4,<3,5,20,22>, <7,1,<10>>, <11,1,<20>>$

  dove indica la frequenza e le posizioni nel documento
]

#note()[
  per ricostruire la lista di affissioni dibbiamo leggere il bit stream in maniera sequenziale, in quanto dobbiamo capire quando finisce la codifica con un codice rispetto ad un altra.
]

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
