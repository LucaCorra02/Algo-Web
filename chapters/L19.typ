#import "../template.typ": *

= Calcolo iterativo della centralità su grafi di grandi dimensioni

Per calcolare misure di centralità spettrale (come l'*eigenvector centrality*, l'indice di *Seeley* o il *PageRank*) su grafi di dimensioni web, non basta contare i link in entrata: l'importanza di un nodo dipende ricorsivamente dal punteggio dei nodi che lo puntano. Si parte quindi da un vettore di punteggi iniziale $x^(0)$ (ad esempio inizializzato uniformemente) e lo si aggiorna iterativamente fino a convergenza calcolando $x^(k+1)$ a partire da $x^(k)$.

Nel modello di *Seeley* (e nella componente principale del PageRank), ogni nodo distribuisce equamente il proprio punteggio tra i suoi successori. Il punteggio del nodo $i$ al passo $k+1$ è dato da:
$
  x_i^(k+1) = sum_(j in N^-(i)) frac(x_j^(k), d^+(j))
$
dove $N^-(i)$ è l'insieme dei *predecessori* di $i$ (nodi che hanno un arco diretto verso $i$) e $d^+(j)$ è l'*out-degree* (grado uscente, ovvero il numero di successori) del nodo $j$, supponendo $d^+(j) > 0$.

Nel caso completo del *PageRank*, si introduce il fattore di smorzamento (_damping factor_) $alpha in (0, 1)$ e il teletrasporto uniforme per gestire i nodi pozzo (_dangling nodes_) e garantire l'ergodicità:
$
  x^(k+1) = x^(k) (alpha P + (1 - alpha) frac(1, n) bold(1) bold(1)^T)
$
dove $P$ è la matrice stocastica di transizione del grafo ($P_(j i) = 1 / d^+(j)$ se esiste l'arco $j -> i$).

#note(title: "Risolutori di sistemi lineari vs Metodo delle potenze")[
  Invece di applicare semplicemente il metodo delle potenze ($x^(k+1) = alpha x^(k) P + dots$), il problema dell'autovettore dominante per PageRank può essere riformulato come il sistema lineare $(I - alpha P^T) x = frac(1 - alpha, n) bold(1)$. Questo permette di utilizzare risolutori numerici iterativi per sistemi lineari (come _Gauss-Seidel_, _Jacobi_ o metodi di sottospazio di Krylov) che spesso convergono in meno iterazioni rispetto all'iterazione semplice.
]

== Gestione della memoria e rappresentazione su disco

Quando il grafo è troppo grande per risiedere interamente in memoria centrale (RAM), la matrice di adiacenza viene memorizzata su disco in forma linearizzata (liste di adiacenza compresse): per ogni nodo si salvano il suo grado e la lista dei suoi successori (grafo diretto) oppure dei suoi predecessori (grafo trasposto o _reverse_).

Indipendentemente dal fatto che su disco siano memorizzati i successori o i predecessori, il calcolo dell'iterazione successiva è sempre possibile, ma cambia radicalmente il pattern di accesso alla memoria e al disco:

- *Approccio Push (scansione per successori / "spargere"):* se sul disco sono memorizzate le liste dei successori, si legge sequenzialmente ogni nodo $j$ e il suo out-degree $d^+(j)$ direttamente dal file del grafo, e si *sparge* (accumula) la quantità $x_j^(k) / d^+(j)$ nelle celle $x_i^(k+1)$ corrispondenti a ciascun successore $i in N^+(j)$.
  - _Vantaggio:_ non serve mantenere in RAM il vettore degli out-degree $d^+$, poiché il grado uscente di $j$ è noto nel momento stesso in cui si legge la sua lista di successori da disco.
  - _Svantaggio:_ il vettore destinazione $x^(k+1)$ subisce scritture ad accesso casuale (_random access_). Deve quindi risiedere interamente in RAM ed è soggetto a conflitti di scrittura (_race condition_) in caso di esecuzione multi-thread.

- *Approccio Pull (scansione per predecessori / "raccogliere"):* se sul disco è memorizzato il grafo trasposto (liste dei predecessori), si visita sequenzialmente ogni nodo $i$ e si *raccoglie* la somma dei contributi $x_j^(k) / d^+(j)$ da tutti i suoi predecessori $j in N^-(i)$.
  - _Vantaggio:_ il valore finale di $x_i^(k+1)$ viene calcolato interamente in un'unica passata locale e può essere scritto direttamente su disco in *streaming sequenziale*, senza dover mantenere il vettore $x^(k+1)$ in RAM.
  - _Svantaggio:_ poiché visitando il nodo $i$ conosciamo i suoi predecessori $j$ ma non il loro grado uscente, nel caso di Seeley e PageRank siamo obbligati a mantenere in RAM anche il *vettore degli out-degree* $d^+$ oltre al vettore corrente $x^(k)$ (a differenza dell'*eigenvector centrality* semplice, dove $x_i^(k+1) = sum_(j in N^-(i)) x_j^(k)$ non divide per il grado).

#figure(
  cetz.canvas({
    import cetz.draw: *

    // Titoli
    content((2.2, 3.2), [*Modalità Push (Successori)*])
    content((8.8, 3.2), [*Modalità Pull (Predecessori)*])

    // --- PUSH ---
    circle((0.8, 1.5), radius: 0.45, fill: blue.lighten(85%), stroke: blue, name: "j")
    content("j", [$j$])
    content((0.8, 0.7), text(size: 8pt)[legge $x_j^(k), d^+(j)$])

    circle((3.6, 2.4), radius: 0.4, fill: orange.lighten(85%), stroke: orange, name: "i1")
    content("i1", [$i_1$])
    circle((3.6, 1.5), radius: 0.4, fill: orange.lighten(85%), stroke: orange, name: "i2")
    content("i2", [$i_2$])
    circle((3.6, 0.6), radius: 0.4, fill: orange.lighten(85%), stroke: orange, name: "i3")
    content("i3", [$i_3$])

    line("j.east", "i1.west", mark: (end: ">"), stroke: blue)
    line("j.east", "i2.west", mark: (end: ">"), stroke: blue)
    line("j.east", "i3.west", mark: (end: ">"), stroke: blue)
    content((2.2, 2.3), text(size: 8pt, fill: blue)[$+ x_j^(k)/d^+(j)$])
    content((2.2, 0.0), text(size: 8.5pt)[_Sparge in posizioni sparse di $x^(k+1)$_])

    // Linea divisoria
    line((5.5, -0.2), (5.5, 3.4), stroke: (paint: gray, dash: "dashed"))

    // --- PULL ---
    circle((7.2, 2.4), radius: 0.4, fill: blue.lighten(85%), stroke: blue, name: "p1")
    content("p1", [$j_1$])
    circle((7.2, 1.5), radius: 0.4, fill: blue.lighten(85%), stroke: blue, name: "p2")
    content("p2", [$j_2$])
    circle((7.2, 0.6), radius: 0.4, fill: blue.lighten(85%), stroke: blue, name: "p3")
    content("p3", [$j_3$])

    circle((10.0, 1.5), radius: 0.45, fill: green.lighten(85%), stroke: green.darken(20%), name: "i")
    content("i", [$i$])
    content((10.0, 0.7), text(size: 8pt)[scrive $x_i^(k+1)$])

    line("p1.east", "i.west", mark: (end: ">"), stroke: green.darken(20%))
    line("p2.east", "i.west", mark: (end: ">"), stroke: green.darken(20%))
    line("p3.east", "i.west", mark: (end: ">"), stroke: green.darken(20%))
    content((8.8, 0.0), text(size: 8.5pt)[_Raccoglie in $x_i^(k+1)$ (scrittura sequenziale)_])
  }),
  caption: [Confronto tra l'aggiornamento *Push* (scansione della lista dei successori di $j$) e l'aggiornamento *Pull* (scansione della lista dei predecessori di $i$).],
)

#note(title: "Occupazione in RAM durante l'iterazione Pull")[
  Poiché per calcolare il passo $k+1$ non si devono sovrascrivere i punteggi del passo $k$, in modalità *Pull* single-thread teniamo in RAM $x^(k)$ e $d^+$ in sola lettura, mentre scriviamo $x^(k+1)$ direttamente su disco un valore alla volta tramite un buffer sequenziale. Terminata l'iterazione, il file su disco diventa il nuovo vettore $x^(k+1)$ da caricare per il passo successivo. Se invece la RAM è capiente o si opera in multi-threading senza coordinamento su disco, entrambi i vettori $x^(k)$ e $x^(k+1)$ vengono allocati in memoria centrale.
]

== Calcolo parallelo e multi-threading

Per sfruttare il *multi-threading* senza incorrere in costose sincronizzazioni (lock o operazioni atomiche sulle celle del vettore), è fondamentale disporre del grafo in *forma reverse* (liste dei predecessori, approccio *Pull*):

1. *Assenza di conflitti di scrittura:* lo spazio dei nodi viene partizionato in blocchi disgiunti assegnati a thread diversi. Ogni thread legge in sola lettura le strutture condivise ($x^(k)$ e $d^+$) e scrive esclusivamente nelle celle del proprio blocco di nodi destinazione $i$.
2. *Bilanciamento dinamico del carico:* il lavoro richiesto per calcolare il nuovo punteggio del nodo $i$ è direttamente proporzionale al suo *in-degree* $d^-(i) = |N^-(i)|$. Nei grafi reali (con distribuzioni dei gradi _heavy-tailed_), alcuni nodi hanno milioni di predecessori e altri pochissimi. Assegnando dinamicamente piccoli blocchi di nodi ai thread non appena terminano il blocco precedente, si bilancia il carico tra i core.
3. *Scrittura in posizione:* poiché i thread terminano i blocchi in ordine non deterministico, non possono semplicemente accodare a uno stream su disco, ma devono scrivere il risultato nella cella (in RAM o all'offset su file) corrispondente all'indice del nodo $i$.


= Valutazione dei sistemi di reperimento dell'informazione

Come possiamo stabilire oggettivamente se un modello di ranking (ad esempio *BM25*) funziona meglio di un altro (come il semplice conteggio delle frequenze *TF* o *TF-IDF*)?

Per valutare e confrontare sperimentalmente due motori di ricerca (_Information Retrieval_) occorre costruire un *benchmark* (o _test collection_, come quelle della conferenza *TREC*) composto da tre elementi:
1. una collezione di documenti $D$;
2. un corpus rappresentativo di interrogazioni (query) $Q$;
3. dei *giudizi di rilevanza* (_ground truth_), tipicamente annotati da esperti umani, che stabiliscono per ogni query $q in Q$ quali documenti sono pertinenti. Nel caso di rilevanza binaria, l'insieme dei documenti rilevanti per la query $q$ è indicato come $R_q subset.eq D$.

#informally(title: "Costi dei benchmark e segnali impliciti dagli utenti")[
  Far valutare manualmente migliaia di documenti a degli esperti umani è estremamente costoso. Per questo motivo in ambito accademico e industriale si tende a riutilizzare gli stessi dataset di test, col rischio di _overfitting_ sul benchmark (un motore ottimo potrebbe ottenere punteggi bassi solo perché recupera documenti validi che non erano stati giudicati nel test).

  Nei motori commerciali si integrano quindi segnali impliciti ricavati dai *log di interazione degli utenti*: si osserva su quali risultati l'utente clicca e il cosiddetto _dwell time_ (quanto tempo trascorre sulla pagina prima di tornare indietro alla pagina dei risultati). Singolarmente il clic è un dato rumoroso e impreciso, ma aggregato su milioni di query fornisce un'indicazione statistica molto forte.
]

== Precisione, Richiamo e $F_1$-score

Fissata una query $q in Q$, sia $R_q subset.eq D$ l'insieme dei documenti rilevanti e $A_q subset.eq D$ l'insieme dei documenti restituiti in risposta dal sistema. Definiamo due metriche fondamentali su insiemi non ordinati:

- *Precisione (_Precision_):* misura la frazione di documenti rilevanti sul totale dei documenti restituiti dal sistema (quante delle risposte date sono effettivamente corrette):
  $
    P_q = frac(|A_q inter R_q|, |A_q|)
  $
- *Richiamo (_Recall_):* misura la frazione di documenti rilevanti restituiti dal sistema sul totale dei documenti rilevanti esistenti nell'intera collezione:
  $
    R_q = frac(|A_q inter R_q|, |R_q|)
  $

Un protocollo di valutazione deve definire i casi degeneri: se $|A_q| = 0$ la precisione non è definita (spesso posta convenzionalmente a $0$ o $1$ a seconda del protocollo), mentre se $|R_q| = 0$ il richiamo non è definito.

*Il compromesso (_trade-off_) tra precisione e richiamo:* le due metriche sono naturalmente in tensione tra loro. Se costruiamo un motore estremamente conservativo che restituisce un unico documento di cui siamo certissimi, avremo $P_q = 100%$, ma un richiamo $R_q = 1 / |R_q| approx 0%$. Viceversa, restituendo l'intera collezione ($A_q = D$) otteniamo banalmente $R_q = 100%$, ma la precisione crolla a zero. Man mano che si estende il richiamo aggiungendo risultati, la precisione tende inevitabilmente a scendere:

- *Contesti orientati al Richiamo:* nella ricerca brevettuale, legale o medica, è fondamentale non perdere alcun documento esistente (richiamo prossimo a $1$), accettando una precisione più bassa e scorrendo liste lunghe.
- *Contesti orientati alla Precisione:* nella ricerca Web moderna, dove ci sono migliaia di pagine rilevanti ma l'utente guarda solo la prima schermata, il problema si sposta interamente sulla *precisione nei primi risultati*.

=== Valutazione a cutoff $k$ ($P@k$ e $R@k$)

Poiché i motori moderni restituiscono liste ordinate, si fissa a priori una soglia di troncamento (*cutoff*) $k$ (ad esempio $k = 10$ o $k = 20$) e si indica con $A_q^(k)$ l'insieme dei primi $k$ documenti restituiti:
$
  "P@k" = frac(|A_q^(k) inter R_q|, k), quad
  "R@k" = frac(|A_q^(k) inter R_q|, |R_q|)
$
Nota che in $"P@k"$ il denominatore è sempre $k$: se il sistema restituisce meno di $k$ documenti, i posti mancanti vengono penalizzati come non rilevanti.

=== Media armonica ($F_1$-score)

Per riassumere precisione e richiamo in un unico valore scalare in $[0, 1]$, si utilizza il punteggio *$F_1$*, definito come la *media armonica* tra $P$ e $R$ (calcolabile anche a cutoff $k$):
$
  F_1 = frac(2, frac(1, P) + frac(1, R)) = 2 dot frac(P dot R, P + R)
$

#warning(title: "Perché non usare la media aritmetica?")[
  Usare la media aritmetica $(P + R) / 2$ per combinare precisione e richiamo è una pessima idea. Un sistema triviale che restituisce l'intero database di milioni di pagine ha $R = 1$ e $P approx 0$: la media aritmetica gli assegnerebbe un ottimo $0.5$ ($50%$) nonostante il motore sia del tutto inutile! La *media armonica*, invece, è fortemente sbilanciata verso il minimo dei due valori: se $P = 0$ oppure $R = 0$, allora $F_1 = 0$. Per ottenere un $F_1$ alto è necessario che sia la precisione sia il richiamo siano contemporaneamente elevati.
]

== Metriche sensibili all'ordine su un corpus di query

Le metriche $P@k$ e $R@k$ trattano i primi $k$ risultati come un insieme non ordinato: avere un unico documento rilevante in posizione $1$ oppure in posizione $k$ produce esattamente la stessa $P@k$. Per premiare i sistemi che mettono i risultati migliori nelle prime posizioni si usano metriche sensibili al rango (_rank_).

=== Reciprocal Rank (RR) e Mean Reciprocal Rank (MRR)

In task specifici come il _known-item search_ o il _named page finding_ (in cui l'utente cerca una singola pagina web precisa, come la homepage di un'università, o una risposta secca), conta solo la posizione del *primo* documento rilevante trovato.

Dato $"rank"_q$ come la posizione del primo documento rilevante per la query $q$ (con $"rank"_q = oo$ se nessun documento rilevante viene trovato), il *Reciprocal Rank* è:
$
  "RR"(q) = frac(1, "rank"_q)
$
Se il primo risultato rilevante è in $1^a$ posizione il punteggio è $1$, in $2^a$ posizione è $0.5$, in $3^a$ è $0.33$, e così via. Mediando su tutte le interrogazioni del corpus $Q$ si ottiene il *Mean Reciprocal Rank (MRR)*:
$
  "MRR" = frac(1, |Q|) sum_(q in Q) frac(1, "rank"_q)
$

=== Average Precision (AP) e Mean Average Precision (MAP)

Quando per una query esistono molteplici documenti rilevanti, vogliamo valutare l'intera classifica. L'*Average Precision (AP)* scorre la lista dei risultati e, ogni volta che incontra un documento rilevante in posizione $k$, calcola la precisione fino a quel punto ($"P@k"$), facendo poi la media su tutti i documenti rilevanti della collezione $R_q$:
$
  "AP"(q) = frac(1, |R_q|) sum_(k=1)^n "P@k" dot "rel"_q(k)
$
dove $"rel"_q(k) in {0, 1}$ vale $1$ se il documento in posizione $k$ è rilevante e $0$ altrimenti (i documenti rilevanti mai restituiti dal sistema contribuiscono con $0$ alla somma ma pesano nel denominatore $|R_q|$).

Geometricamente, se tracciamo i punti $("R@k", "P@k")$ ad ogni documento rilevante recuperato, l'Average Precision rappresenta l'*area sottesa alla curva Precisione-Richiamo* (un'approssimazione discreta dell'integrale $integral_0^1 P(R) dif R$). Essa misura quanto rapidamente degrada la qualità del motore man mano che si scende nella lista: un motore ideale che posiziona tutti gli $|R_q|$ documenti rilevanti nelle prime $|R_q|$ posizioni mantiene $"P@k" = 1$ ovunque e descrive un rettangolo di area unitaria $("AP" = 1$).

#figure(
  cetz.canvas({
    import cetz.draw: *

    let ox = 1.0
    let oy = 0.8
    let w = 6.5
    let h = 3.8

    // Area sottesa (rettangoli AP corrispondenti ai punti rilevanti k=1, 3, 6, 10)
    // R = 0.2 (P=1.0), R = 0.4 (P=0.67), R = 0.6 (P=0.5), R = 0.8 (P=0.4)
    rect((ox, oy), (ox + 0.2 * w, oy + 1.0 * h), fill: blue.lighten(88%), stroke: none)
    rect((ox + 0.2 * w, oy), (ox + 0.4 * w, oy + 0.67 * h), fill: blue.lighten(88%), stroke: none)
    rect((ox + 0.4 * w, oy), (ox + 0.6 * w, oy + 0.5 * h), fill: blue.lighten(88%), stroke: none)
    rect((ox + 0.6 * w, oy), (ox + 0.8 * w, oy + 0.4 * h), fill: blue.lighten(88%), stroke: none)

    // Curva del motore ideale (Precisione sempre 1)
    line((ox, oy + h), (ox + w, oy + h), (ox + w, oy), stroke: (paint: green.darken(20%), dash: "dashed", thickness: 1.2pt))
    content((ox + 0.72 * w, oy + h + 0.28), text(size: 8pt, fill: green.darken(25%))[Motore ideale ($"AP" = 1$)])

    // Assi cartesiani
    line((ox, oy), (ox + w + 0.5, oy), mark: (end: ">"), stroke: 1pt)
    line((ox, oy), (ox, oy + h + 0.5), mark: (end: ">"), stroke: 1pt)

    content((ox + w / 2, oy - 0.55), text(size: 9pt)[*Richiamo ($R$)*])
    content((ox - 1.25, (oy + h) / 2), text(size: 9pt)[*Precisione ($P$)*])

    // Tacche asse X e Y
    for r in (0.2, 0.4, 0.6, 0.8, 1.0) {
      line((ox + r * w, oy - 0.08), (ox + r * w, oy + 0.08))
      content((ox + r * w, oy - 0.25), text(size: 7.5pt)[#r])
    }
    for p in (0.5, 1.0) {
      line((ox - 0.08, oy + p * h), (ox + 0.08, oy + p * h))
      content((ox - 0.35, oy + p * h), text(size: 7.5pt)[#p])
    }

    // Punti campionati (k=1..10, rilevanti in pos 1, 3, 6, 10 su |R_q|=5)
    let pts = (
      (ox + 0.2 * w, oy + 1.00 * h), // k=1 (R)
      (ox + 0.2 * w, oy + 0.50 * h), // k=2 (N)
      (ox + 0.4 * w, oy + 0.67 * h), // k=3 (R)
      (ox + 0.4 * w, oy + 0.50 * h), // k=4 (N)
      (ox + 0.4 * w, oy + 0.40 * h), // k=5 (N)
      (ox + 0.6 * w, oy + 0.50 * h), // k=6 (R)
      (ox + 0.6 * w, oy + 0.43 * h), // k=7 (N)
      (ox + 0.6 * w, oy + 0.38 * h), // k=8 (N)
      (ox + 0.6 * w, oy + 0.33 * h), // k=9 (N)
      (ox + 0.8 * w, oy + 0.40 * h), // k=10 (R)
    )
    line(..pts, stroke: (paint: gray, thickness: 0.9pt))

    let rel-pts = (
      (ox + 0.2 * w, oy + 1.00 * h, [$k=1$]),
      (ox + 0.4 * w, oy + 0.67 * h, [$k=3$]),
      (ox + 0.6 * w, oy + 0.50 * h, [$k=6$]),
      (ox + 0.8 * w, oy + 0.40 * h, [$k=10$]),
    )
    for pt in rel-pts {
      circle((pt.at(0), pt.at(1)), radius: 0.09, fill: blue, stroke: blue)
      content((pt.at(0) + 0.25, pt.at(1) + 0.22), text(size: 7.5pt, fill: blue)[#pt.at(2)])
    }
  }),
  caption: [Curva Precisione-Richiamo con $|R_q| = 5$ e documenti rilevanti trovati nelle posizioni $k in {1, 3, 6, 10}$ (pallini blu). L'area azzurra corrisponde all'Average Precision.],
)

La *Mean Average Precision (MAP)* è la media aritmetica delle Average Precision su tutto il corpus di query $Q$ (escludendo eventuali query con $R_q = emptyset$):
$
  "MAP" = frac(1, |Q|) sum_(q in Q) "AP"(q)
$

#example(title: "Calcolo di P@k, R@k, RR e AP")[
  Supponiamo che per una query $q$ esistano nella collezione $|R_q| = 5$ documenti rilevanti e che il motore restituisca una top-$6$ in cui i documenti in posizione $1, 3, 6$ sono rilevanti ($"R"$) e quelli in posizione $2, 4, 5$ non lo sono ($"N"$):
  $
    ["1: R", quad "2: N", quad "3: R", quad "4: N", quad "5: N", quad "6: R"]
  $
  - *Cutoff $k=6$:* abbiamo $"P@6" = 3 / 6 = 0.5$ e $"R@6" = 3 / 5 = 0.6$.
  - *Reciprocal Rank:* poiché il primo documento rilevante è in posizione $1$, $"RR"(q) = 1 / 1 = 1$.
  - *Average Precision:* sommiamo le precisioni calcolate nei punti in cui compare una $"R"$ ($k = 1, 3, 6$, con $"P@1" = 1/1$, $"P@3" = 2/3$, $"P@6" = 3/6$) e dividiamo per $|R_q| = 5$:
    $
      "AP"(q) = frac(1, 5) (frac(1, 1) + frac(2, 3) + frac(3, 6)) = frac(1, 5) dot 2.167 = 0.433
    $
]

== Rilevanza graduata: DCG e NDCG

Nella realtà la rilevanza non è quasi mai puramente binaria: un documento può essere _irrilevante_ ($0$), _marginalmente utile_ ($1$), _pertinente_ ($2$) o _perfetto_ ($3$). Quando ad ogni documento in posizione $i$ è associato un punteggio di rilevanza non negativo $r_i >= 0$, utilizziamo il *Discounted Cumulative Gain (DCG)*.

L'idea è sommare il guadagno (_gain_) di rilevanza di ciascun documento penalizzandolo con un *fattore di sconto logaritmico* legato alla sua posizione $i$ nella classifica (più un documento è in basso, meno è probabile che l'utente lo veda). Esistono due formulazioni standard per il $"DCG@k"$:
$
  "DCG@k" = sum_(i=1)^k frac(r_i, log_2(i + 1))
  quad "oppure" quad
  "DCG@k" = sum_(i=1)^k frac(2^(r_i) - 1, log_2(i + 1))
$
La seconda formulazione (esponenziale nel guadagno) enfatizza molto più fortemente i documenti altamente rilevanti rispetto a quelli mediocri.

#note(title: "Perché il DCG non è confrontabile tra query diverse?")[
  Il valore assoluto del DCG non ha un limite superiore fissato: dipende sia dal numero di documenti rilevanti disponibili per quella specifica query, sia dalla scala dei voti assegnati. Una query "facile" con decine di documenti perfetti avrà un DCG molto più alto di una query "difficile" con un solo documento rilevante, anche se il motore ha lavorato benissimo su entrambe. Non è quindi sensato mediare direttamente il DCG su un corpus di query senza prima normalizzarlo.
]

=== Normalized Discounted Cumulative Gain (NDCG)

Per riportare il punteggio nell'intervallo $[0, 1]$ e renderlo confrontabile tra query diverse, si divide il $"DCG@k"$ ottenuto dal sistema per l'*Ideal DCG ($"IDCG@k"$)*, ovvero il massimo DCG teoricamente ottenibile per quella query ordinando i documenti noti in ordine decrescente di rilevanza:
$
  "NDCG@k" = frac("DCG@k", "IDCG@k")
$

*Come si calcola l'IDCG su collezioni enormi?* In teoria, per conoscere il vero ordinamento ideale su tutto il Web dovremmo conoscere la rilevanza di ogni singola pagina esistente, il che è impossibile. In pratica, si risolve il problema in due modi complementari:
1. Si fissa un cutoff ristretto (tipicamente $k = 10$, ovvero $"NDCG@10"$) e si ordinano in modo decrescente i migliori $k$ documenti presenti nei giudizi di rilevanza del benchmark per quella query.
2. Nel caso semplificato in cui la rilevanza sia binaria ($r_i in {0, 1}$) e si assuma che per ogni query esistano nella collezione almeno $k$ documenti rilevanti, il fattore di normalizzazione $"IDCG@k"$ diventa una costante fissata a priori uguale per tutte le query:
$
  "IDCG@k" = sum_(i=1)^k frac(1, log_2(i + 1))
$

#example(title: "Calcolo di DCG@3 e NDCG@3")[
  Supponiamo che per una query i primi $3$ documenti restituiti dal sistema abbiano giudizi di rilevanza $r = [2, 0, 3]$ e che nella collezione valutata i tre migliori documenti per quella query abbiano rilevanza ideale $r^"ideal" = [3, 2, 1]$. Usando la formula lineare $r_i / log_2(i+1)$:
  $
    "DCG@3" &= frac(2, log_2(2)) + frac(0, log_2(3)) + frac(3, log_2(4)) = frac(2, 1) + 0 + frac(3, 2) = 3.5 \
    "IDCG@3" &= frac(3, log_2(2)) + frac(2, log_2(3)) + frac(1, log_2(4)) = 3 + frac(2, 1.585) + 0.5 = 4.762 \
    "NDCG@3" &= frac("DCG@3", "IDCG@3") = frac(3.5, 4.762) approx 0.735
  $
]

#note(title: "Riepilogo: quale metrica scegliere?")[
  Nessuna metrica è universalmente superiore alle altre; la scelta dipende dal task applicativo e dai giudizi di rilevanza disponibili:
  - *$P@k$ e $R@k$*: valutano quanti documenti rilevanti compaiono nei primi $k$ risultati, ignorando il loro ordine interno.
  - *MRR*: ideale quando all'utente basta trovare *un solo* risultato corretto il più in alto possibile (es. _named page finding_, _question answering_).
  - *MAP*: valuta la qualità complessiva dell'intero ranking con giudizi di rilevanza *binari*.
  - *NDCG\@k*: è lo standard per i motori di ricerca Web moderni quando si dispone di giudizi di rilevanza *graduati* (multi-livello) e interessa la qualità della prima pagina di risultati.
]