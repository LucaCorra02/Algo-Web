#import "../template.typ": *

= Database NoSQL

I database NoSQL, sono *dizionari parzialmente o totalmente su disco* che, invece di utilizzare lo standard SQL, gestiscono i dati tramite coppie *chiave-valore*.

L'utilizzo di un database NoSQL risolve i classici problemi delle Hash Table:
- *Nessuna riallocazione*: La memoria non viene mai riallocata dinamicamente.
- *Cache fissa*: Non ci sono sorprese legate alla saturazione improvvisa della RAM.
- *Scalabilità*: Man mano che il database si riempie, le prestazioni degradano gradualmente (anziché collassare).

== Implementazioni principali

- `BerkeleyDB`: Usa Hash table e B-tree *parzialmente su disco*, sfruttando la RAM come cache.
- `BigTable / LevelDB / RocksDB`: Famiglia di database basati sull'architettura *LSM-Tree*, ottimizzati per scritture massive. `RocksDB` è usato da `CommonCrawler`.

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

#figure(caption: [Schema semplificato di un LSM-Tree.])[
  #cetz.canvas({
    import cetz.draw: *

    rect((3.2, 7.5), (10.8, 10.2), radius: 0.12, fill: luma(96%), stroke: 1pt + gray)
    content((7, 9.65), text(size: 8pt)[*Memtable (RAM)*])
    circle((6.2, 8.85), radius: 0.22, fill: rgb("fffcc7"), stroke: 1pt + black)
    circle((5.45, 8.25), radius: 0.22, fill: rgb("fffcc7"), stroke: 1pt + black)
    circle((6.95, 8.25), radius: 0.22, fill: rgb("fffcc7"), stroke: 1pt + black)
    circle((6.95, 7.65), radius: 0.22, fill: rgb("fffcc7"), stroke: 1pt + black)
    line((6.05, 8.68), (5.6, 8.42), stroke: 1pt + gray)
    line((6.35, 8.68), (6.8, 8.42), stroke: 1pt + gray)
    line((6.95, 8.03), (6.95, 7.88), stroke: 1pt + gray)

    line((1.2, 7.05), (13.8, 7.05), stroke: (paint: gray, thickness: 1pt, dash: "dashed"))
    content((0.2, 7.25), text(size: 7pt)[Memoria])
    content((0.2, 6.7), text(size: 7pt)[Disco])

    content((1.2, 5.95), text(size: 8pt)[*Level 0*])
    for x in (3.2, 6.3, 9.4) {
      rect((x, 5.15), (x + 2.3, 6.55), radius: 0.12, fill: rgb("fff0f0"), stroke: 1pt + gray)
      for dx in (0.5, 1.35) {
        for dy in (5.55, 6.05) {
          rect((x + dx, dy), (x + dx + 0.38, dy + 0.32), radius: 0.08, fill: rgb("fffcc7"), stroke: 1pt + black)
        }
      }
    }

    content((1.2, 3.7), text(size: 8pt)[*Level 1*])
    for x in (2.5, 7.4) {
      rect((x, 2.75), (x + 4.2, 4.65), radius: 0.12, fill: rgb("fff0f0"), stroke: 1pt + gray)
      for dx in (0.45, 1.35, 2.25, 3.15) {
        for dy in (3.15, 3.85) {
          rect((x + dx, dy), (x + dx + 0.38, dy + 0.32), radius: 0.08, fill: rgb("fffcc7"), stroke: 1pt + black)
        }
      }
    }

    content((1.2, 1.25), text(size: 8pt)[*Level 2*])
    rect((2.5, 0.35), (13.6, 2.05), radius: 0.12, fill: rgb("fff0f0"), stroke: 1pt + gray)
    for dx in (0.45, 1.35, 2.25, 3.15, 4.05, 4.95, 5.85, 6.75, 7.65, 8.55, 9.45, 10.35) {
      for dy in (0.75, 1.4) {
        rect((2.5 + dx, dy), (2.5 + dx + 0.38, dy + 0.3), radius: 0.08, fill: rgb("fffcc7"), stroke: 1pt + black)
      }
    }

    line((7, 7.45), (7, 6.65), stroke: 1pt + gray, mark: (end: "stealth"))
    line((7, 5.05), (5.7, 4.75), stroke: 1pt + gray, mark: (end: "stealth"))
    line((7, 5.05), (9.3, 4.75), stroke: 1pt + gray, mark: (end: "stealth"))
    line((4.6, 2.6), (6.3, 2.15), stroke: 1pt + gray, mark: (end: "stealth"))
    line((9.4, 2.6), (8.1, 2.15), stroke: 1pt + gray, mark: (end: "stealth"))
  })
]

La figura mostra il flusso tipico delle scritture. Le nuove coppie chiave-valore entrano nella *Memtable*, una struttura ordinata e modificabile mantenuta in RAM. Quando raggiunge la soglia di capienza, viene congelata e trasformata in una o più *SSTable* del Livello 0.

Le SSTable sono file ordinati e immutabili: per questo non vengono modificate direttamente. Le frecce indicano le fusioni (*compaction*) verso livelli progressivamente più bassi. Ogni livello contiene più dati del precedente, ma viene riscritto meno frequentemente; durante una fusione, le versioni più recenti delle chiavi sostituiscono quelle obsolete.

#warning(title: "Duplicazione delle Chiavi")[
  In un LSM-Tree la stessa chiave può comparire in *più livelli contemporaneamente*, poiché una chiave recente nei livelli alti potrebbe non essere ancora stata fusa con una versione precedente finita nei livelli bassi.

  *Vince sempre il valore nel livello più alto.*
]

== Operazioni principali

=== Lettura

La ricerca è *lineare e progressiva*: si parte dalla RAM e si scende di livello in livello, fermandosi non appena si trova la chiave desiderata. Le tabelle di un certo livello vengono scandite dalla più recente alla più vecchia.

Poiché si parte dall'alto, il primo valore trovato è garantito essere l'*ultimo inserito*. Spesso i livelli più bassi risiedono su hardware differenti o più lenti, poiché vengono letti e modificati raramente.

=== Scrittura e Fusioni (Scarico)

Supponiamo di voler inserire una nuova coppia chiave-valore. Il flusso tipico è il seguente:
+ Si aggiunge la coppia chiave-valore nel *Livello 0* (RAM).
+ Se la RAM si riempie, si scarica il suo contenuto su disco e lo si *fonde* con il Livello 1. Essendo entrambi ordinati, la fusione è rapidissima. In caso di chiavi comuni, *vince quella proveniente dalla RAM*.
+ Se il Livello 1 eccede la sua dimensione massima (inclusa l'elasticità $alpha$), una parte delle sue chiavi viene estratta e fusa con il Livello 2.
+ La procedura continua *a cascata*, creando se necessario nuovi livelli inferiori. Più si scende, più le operazioni di fusione diventano rare.

=== Cancellazione e Lapidi (Tombstones)

#warning()[
  Non si può eliminare fisicamente una chiave all'istante, a causa della possibile *duplicazione nei livelli inferiori*.
]

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
- *Filtro di Bloom*: Associato a ogni segmento. Essendo a *bassa precisione*, occupa pochissima memoria. Se il filtro dice _no_, si salta a priori l'accesso al disco.

- *Indice sparso* (Campionamento): Memorizza le posizioni di un sottoinsieme di chiavi (es. 1 ogni 1000). Se il filtro di Bloom dice _sì_, si usa l'indice per *circoscrivere l'area del disco* in cui cercare, procedendo poi con una ricerca binaria o lineare.

#example(title: "Flusso di una Lettura Ottimizzata")[
  + Si consulta il *Filtro di Bloom* del segmento.
  + Se risponde *$mr("no")$* $arrow$ la chiave non è nel segmento, si salta.
  + Se risponde *$mg("sì")$* $arrow$ si usa l'*Indice sparso* per trovare il punto approssimativo.
  + Si esegue una *ricerca binaria o lineare* nell'area circoscritta del disco.
]

== Skip-List (Non in esame)

La *Skip-List* è la struttura dati spesso utilizzata per mantenere il dizionario in RAM (Livello 0). È considerata la _"sorella"_ delle tabelle di hash, con l'aggiunta di un *fattore probabilistico*. Alla base vi è una classica *lista concatenata ordinata*, su cui vengono erette delle _"torrette"_ di puntatori.

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
Per risolvere questo problema ci sono due strategie principali:

- *Recupero del BFS:* Insieme all'URL in $A$, si salva la sua *posizione ordinale* di scoperta originaria. Prima di accodare gli URL promossi in $F$, li si riordina in base a questo indice numerico.

- *Ottimizzazione dello spazio:* Per evitare che il file $Z$ esploda in dimensioni, non vi si salvano le stringhe di testo degli URL, ma solo le loro *firme* (hash a 64 bit). La fusione sequenziale avviene calcolando e confrontando le firme di $A'$ con quelle di $Z$.
