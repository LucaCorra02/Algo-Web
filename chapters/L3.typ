#import "../template.typ": *

= Database NoSQL

I database NoSQL, sono *dizionari parzialmente o totalmente su disco* che, invece di utilizzare lo standard SQL, gestiscono i dati tramite coppie *chiave-valore*.

L'utilizzo di un database NoSQL risolve i classici problemi delle Hash Table:

- *Nessuna riallocazione*: La memoria non viene mai riallocata dinamicamente.
- *Cache fissa*: Non ci sono sorprese legate alla saturazione improvvisa della RAM.
- *Scalabilità*: Man mano che il database si riempie, le prestazioni degradano gradualmente (anziché collassare).

== Implementazioni principali

- BerkeleyDB: Usa Hash table e B-tree *parzialmente su disco*, sfruttando la RAM come cache.
- BigTable / LevelDB / RocksDB: Famiglia di database basati sull'architettura *LSM-Tree*, ottimizzati per scritture massive. RocksDB è usato da CommonCrawler.

#informally(title: "Trucco per il Crawling con Priorità")[
  Se vogliamo implementare un crawler che segua delle priorità, possiamo sfruttare le proprietà di *ordinamento automatico* dei database NoSQL.

  Inserendo la priorità come parte della chiave, il database mantiene automaticamente gli URL in ordine. In questo modo:

  - Il carico computazionale sul nostro codice è *pari a zero*.
  - Sfruttiamo le politiche di *caching intelligenti* del database.
  - Possiamo estrarre gli URL *già in ordine di importanza*.
]

= LSM-Tree (Log-Structured Merge-Tree)

Gli *LSM-Tree* sono strutture dati per dizionari mantenuti parzialmente su disco. Le loro proprietà fondamentali sono:

- Le *scritture sono solamente sequenziali*.
- I *dati su disco sono immutabili*.

Queste caratteristiche li rendono estremamente efficienti per moli enormi di dati.

== Struttura gerarchica

La struttura è divisa in livelli:

- Livello 0 (RAM): Allocazione fissa in memoria centrale. Ospita un dizionario ordinato (solitamente un *Red-Black tree* o un *B-tree*).
- Livelli successivi (Disco): Costituiti da *file di log*, ovvero dizionari chiave-valore ordinati e immutabili.

Ogni livello su disco ha una dimensione base che cresce di un *fattore moltiplicativo* rispetto al precedente, e un'elasticità $alpha$ (es. possono raggiungere il doppio della dimensione base) per assorbire dinamicamente i dati prima di forzare uno scarico verso il basso.

#warning(title: "Duplicazione delle Chiavi")[
  In un LSM-Tree la stessa chiave può comparire in *più livelli contemporaneamente*, poiché una chiave recente nei livelli alti potrebbe non essere ancora stata fusa con una versione precedente finita nei livelli bassi.

  *Vince sempre il valore nel livello più alto.*
]

== Operazioni principali

=== Lettura

La ricerca è *lineare e progressiva*: si parte dalla RAM e si scende di livello in livello, fermandosi non appena si trova la chiave desiderata.

Poiché si parte dall'alto, il primo valore trovato è garantito essere l'*ultimo inserito*. Spesso i livelli più bassi risiedono su hardware differenti o più lenti, poiché vengono letti e modificati raramente.

=== Scrittura e Fusioni (Scarico)

+ Si aggiunge la coppia chiave-valore nel *Livello 0* (RAM).
+ Se la RAM si riempie, si scarica il suo contenuto su disco e lo si *fonde* con il Livello 1. Essendo entrambi ordinati, la fusione è rapidissima. In caso di chiavi comuni, *vince quella proveniente dalla RAM*.
+ Se il Livello 1 eccede la sua dimensione massima (inclusa l'elasticità $alpha$), una parte delle sue chiavi viene estratta e fusa con il Livello 2.
+ La procedura continua *a cascata*, creando se necessario nuovi livelli inferiori. Più si scende, più le operazioni di fusione diventano rare.

=== Cancellazione e Lapidi (Tombstones)

Non si può eliminare fisicamente una chiave all'istante, a causa della possibile *duplicazione nei livelli inferiori*.

Si inserisce invece la stessa chiave con un valore speciale arbitrario noto come *lapide* (_tombstone_):

- In fase di *lettura*: se si incontra una lapide, il processo si ferma e la chiave viene considerata assente.
- Quando una lapide *raggiunge l'ultimo livello* a seguito di varie fusioni, può essere finalmente rimossa per non saturare la struttura.

#note(title: "Compattamento in Background")[
  Le operazioni di fusione non avvengono quasi mai bloccando gli inserimenti (sincronamente). Il database lancia dei *thread concorrenti* che compattano la struttura in background, verificando che:

  - Non ci siano troppe copie della stessa chiave.
  - Le lapidi giunte a fine vita vengano rimosse.
]

== Ottimizzazioni Ingegneristiche

I livelli su disco vengono generalmente *segmentati* in file più piccoli, permettendo fusioni più flessibili e *concorrenti*. Per accelerare l'accesso a questi segmenti si usano due strutture ausiliarie:

- *Filtro di Bloom*: Associato a ogni segmento. Essendo a *bassa precisione*, occupa pochissima memoria. Se il filtro dice "no", si salta a priori l'accesso al disco.
- *Indice sparso* (Campionamento): Memorizza le posizioni di un sottoinsieme di chiavi (es. 1 ogni 1000). Se il filtro di Bloom dice "sì", si usa l'indice per *circoscrivere l'area del disco* in cui cercare, procedendo poi con una ricerca binaria o lineare.

#example(title: "Flusso di una Lettura Ottimizzata")[
  + Si consulta il *Filtro di Bloom* del segmento.
  + Se risponde *"no"* $arrow$ la chiave non è nel segmento, si salta.
  + Se risponde *"sì"* $arrow$ si usa l'*Indice sparso* per trovare il punto approssimativo.
  + Si esegue una *ricerca binaria o lineare* nell'area circoscritta del disco.
]

== Skip-List (Curiosità implementativa)

#note()[
  Non fa parte dell'esame, pura curiosità
]

La *Skip-List* è la struttura dati spesso utilizzata per mantenere il dizionario in RAM (Livello 0). È considerata la "sorella" delle tabelle di hash, con l'aggiunta di un *fattore probabilistico*.

Alla base vi è una classica *lista concatenata ordinata*, su cui vengono erette delle "torrette" di puntatori.

#example(title: "Costruzione probabilistica delle torrette")[
  Per ogni nodo inserito si lancia una moneta (distribuzione geometrica con probabilità $p = 1/2$).

  - Finché esce *testa*, la "torretta" del nodo si alza di un piano.
  - Ogni piano punta al prossimo nodo con una torretta *alta almeno quanto la sua*.

  In questo modo, l'altezza massima (e quindi lo spazio aggiuntivo occupato) rimane limitata in media al *doppio del numero delle chiavi*.
]

*Ricerca e Aggiornamento:* Si parte dal livello più alto della prima torretta. Se la chiave cercata è minore si scende di un livello, se è maggiore si salta al nodo puntato. I salti iniziali sono enormi, poi diventano sempre più precisi: ricorda la *discesa di una scala*.

- Il tempo di ricerca è *logaritmico*.
- Durante un aggiornamento si usa uno *stack* per tracciare i nodi attraversati, così da riallacciare correttamente i puntatori delle torrette.

= Crawler Offline

Un approccio meno responsive, ma molto più semplice da implementare per effettuare una *visita in ampiezza (BFS)* mantenendo costante l'uso della memoria centrale, è il *crawler offline*.

== I tre file del sistema

Il sistema mantiene in ogni istante tre file:

- $Z$: File degli URL già visitati o attualmente in frontiera. Mantenuto *ordinato lessicograficamente*.
- $F$: La *Frontiera*, ovvero il file degli URL ancora da visitare. Mantenuto in *ordine cronologico di scoperta*.
- $A$: File temporaneo ad *accumulo*, limitato in dimensione e residente in RAM.

== Funzionamento: Procedura di Scarico

Durante il crawl, si pescano gli URL da visitare da $F$ e si inseriscono i nuovi URL scoperti in $A$. Quando $A$ si riempie (o $F$ si svuota), si esegue la seguente operazione di fusione:

+ Si *ordina* $A$ e si rimuovono i duplicati interni, generando $A'$. Nei sistemi reali questo viene fatto con framework distribuiti come *MapReduce* o *Hadoop*.
+ Si *fondono sequenzialmente* $Z$ e $A'$ per creare il nuovo file globale $Z'$. Essendo entrambi pre-ordinati, l'operazione è un rapido *scanning lineare*.
+ Durante la fusione, tutti gli URL in $A'$ *non presenti* in $Z$ vengono accodati in fondo alla frontiera $F$.
+ Si *svuota* $A$ e il ciclo ricomincia.

#informally(title: "Il ruolo complementare di Z e A")[
  In questo paradigma:

  - $A$ funge da *"memoria a breve termine"* per le nuove scoperte.
  - $Z$ agisce come un *filtro di Bloom esatto su disco*: il suo unico scopo durante la fusione è dirci con assoluta certezza se un URL in $A'$ è un duplicato globale o se è davvero inedito e merita di essere accodato alla frontiera $F$.
]

#warning(title: "Perdita dell'ordine BFS")[
  L'ordinamento lessicografico del file $A$ distrugge irreversibilmente l'*ordine temporale* di scoperta degli URL, che è il requisito fondamentale per garantire una vera visita in ampiezza (BFS).
]

#note(title: "Soluzione: Indice Ordinale e Firme")[
  *Recupero del BFS:* Insieme all'URL in $A$, si salva la sua *posizione ordinale* di scoperta originaria. Prima di accodare gli URL promossi in $F$, li si riordina in base a questo indice numerico.

  *Ottimizzazione dello spazio:* Per evitare che il file $Z$ esploda in dimensioni, non vi si salvano le stringhe di testo degli URL, ma solo le loro *firme* (hash a 64 bit). La fusione sequenziale avviene calcolando e confrontando le firme di $A'$ con quelle di $Z$.
]