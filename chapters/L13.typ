#import "../template.typ": *

== Classi randomizzate e derandomizzazione

Un algoritmo randomizzato può prendere decisioni diverse sulla stessa istanza d'input in base alla sequenza di bit casuali utilizzata durante l'esecuzione.
Le classi di complessità seguenti raggruppano i problemi di decisione risolvibili da algoritmi randomizzati, imponendo vincoli sulle risorse di calcolo e sulla probabilità di errore.
Nel seguito consideriamo algoritmi che operano in *tempo polinomiale* oppure in *spazio logaritmico*, dove lo spazio di lavoro è $O(log(n))$ rispetto alla dimensione $n$ dell'input.

La distinzione principale riguarda il tipo di errore ammesso dall'algoritmo:

- *BPP* (*Bounded-error Probabilistic Polynomial time*): algoritmi in tempo polinomiale che, su ogni istanza, forniscono la risposta corretta con probabilità almeno $2/3$. L'errore è *bilaterale* (*two-sided error*): l'algoritmo può sbagliare sia sulle istanze positive (input "sì") sia su quelle negative (input "no").
- *RP* (*Randomized Polynomial time*): algoritmi in tempo polinomiale con errore *unilaterale* (*one-sided error*):
  - sugli input "no", l'algoritmo rifiuta sempre (probabilità di accettazione $0$);
  - sugli input "sì", l'algoritmo accetta con probabilità almeno $2/3$.
  Gli unici errori possibili sono quindi i *falsi negativi*, mentre non possono verificarsi falsi positivi.
- *BPL* (*Bounded-error Probabilistic Logspace*): analogo della classe BPP, ma con spazio di lavoro limitato a $O(log(n))$ (e tempo polinomiale).
- *RL* (*Randomized Logspace*): analogo della classe RP, ma con spazio di lavoro limitato a $O(log(n))$ (e tempo polinomiale).
- *L* (*Logspace*): classe dei problemi decidibili *deterministicamente* in spazio logaritmico $O(log(n))$, senza ricorrere a bit casuali.

#note[
  La soglia di successo $2/3$ (ossia probabilità di errore al più $1/3$) è puramente convenzionale: eseguendo più ripetizioni indipendenti dell'algoritmo sullo stesso input e restituendo la risposta di maggioranza (per BPP/BPL) o l'OR logico delle risposte (per RP/RL), la probabilità di errore decresce esponenzialmente e può essere ridotta a piacere.
  Tale amplificazione della probabilità mantiene lo spazio di lavoro logaritmico sia in BPL sia in RL, poiché basta un contatore di $O(log(n))$ bit per tenere traccia degli esiti delle ripetizioni.
]

Poiché un algoritmo deterministico è un caso particolare di algoritmo randomizzato (che non legge bit casuali) e un algoritmo con errore unilaterale è un caso particolare di algoritmo con errore bilaterale, valgono immediatamente le seguenti catene di inclusioni:
$ L subset.eq "RL" subset.eq "BPL" quad "e" quad L subset.eq P subset.eq "RP" subset.eq "BPP" $

#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    // Diagramma delle inclusioni
    rect((0, 1.8), (1.1, 2.6), radius: 4pt, fill: luma(240))
    content((0.55, 2.2), [$L$])

    line((1.1, 2.35), (1.9, 2.7), mark: (end: ">"))
    rect((1.9, 2.4), (3.1, 3.1), radius: 4pt, fill: rgb("#e3f2fd"))
    content((2.5, 2.75), [$"RL"$])

    line((3.1, 2.75), (3.9, 2.75), mark: (end: ">"))
    rect((3.9, 2.4), (5.1, 3.1), radius: 4pt, fill: rgb("#bbdefb"))
    content((4.5, 2.75), [$"BPL"$])

    line((1.1, 2.05), (1.9, 1.65), mark: (end: ">"))
    rect((1.9, 1.3), (3.1, 2.0), radius: 4pt, fill: rgb("#e8f5e9"))
    content((2.5, 1.65), [$"RP"$])

    line((3.1, 1.65), (3.9, 1.65), mark: (end: ">"))
    rect((3.9, 1.3), (5.1, 2.0), radius: 4pt, fill: rgb("#c8e6c9"))
    content((4.5, 1.65), [$"BPP"$])
  })
]

=== Il problema della derandomizzazione (BPL, RP e BPP)

*Derandomizzare* una classe di complessità significa sostituire un algoritmo randomizzato con uno completamente *deterministico*, preservando i medesimi limiti sulle risorse (tempo o spazio):

- *Derandomizzare BPL e RL in spazio logaritmico*: consisterebbe nel dimostrare che la casualità può essere eliminata mantenendo spazio $O(log(n))$, ovvero che $"BPL" = "RL" = L$.
  Questa uguaglianza rappresenta un obiettivo teorico e *non* un risultato dimostrato: sappiamo che $L subset.eq "RL" subset.eq "BPL"$, ma rimane un problema aperto stabilire se valgano le uguaglianze.
- *Derandomizzare BPP e RP in tempo polinomiale*:
  - Dimostrare $"BPP" = P$ significherebbe provare che ogni problema risolvibile in tempo polinomiale con errore limitato ammette un algoritmo deterministico polinomiale. In tal caso la correttezza sarebbe garantita su ogni esecuzione senza dipendere da una sequenza "fortunata" di bit casuali.
  - Dimostrare $"RP" = P$ eliminerebbe la casualità dagli algoritmi con errore unilaterale, riconoscendo deterministicamente anche gli input "sì" oltre agli input "no". Tuttavia, provare $"RP" = P$ non basterebbe da solo a implicare $"BPP" = P$, poiché BPP ammette errori su entrambi i lati.

== Frasi e Prossimità nelle Query Booleane

#note[
  *Richiamo sull'intersezione pigra (`skip to` nell'operatore AND)*: quando si calcola l'AND tra più liste di affissione ordinate $L_0, L_1, dots, L_(k-1)$, conviene procedere in modo *pigro* (*lazy*). Si avanza il candidato solo sulla lista successiva tramite `skip to`, evitando di toccare e far avanzare le liste ancora più a destra finché non si ottiene un match effettivo tra le prime liste.
]

Un'interrogazione booleana classica con il solo operatore `AND` verifica unicamente che tutti i termini richiesti compaiano nello stesso documento, ma ignora la loro distanza reciproca.
#example[
  Se cerchiamo `"romeo" AND "giulietta"` tramite una semplice intersezione delle liste di documenti, potremmo recuperare un documento molto lungo in cui la parola *"romeo"* compare nella prima pagina e *"giulietta"* nell'ultima, senza che vi sia alcuna relazione semantica diretta.
]

Per ottenere risultati più pertinenti e ridurre l'insieme dei documenti candidati quando questo è troppo grande, estendiamo il linguaggio booleano con due nuovi atomi basati sulle *liste posizionali* (gli indici delle posizioni occupate dai termini all'interno di ciascun documento):
1. *Frasi* ($t_0, t_1, dots, t_(k-1)$): i termini devono comparire nel documento *consecutivamente* e nell'ordine specificato.
2. *Prossimità* ($(t_0, t_1, dots, t_(k-1)) tilde l$): tutti i $k$ termini devono comparire nel documento entro una finestra (intervallo) di ampiezza massima $l$, *in qualunque ordine*.

=== Ricerca di Frasi

Data la frase $t_0, t_1, dots, t_(k-1)$, l'algoritmo opera in tre passi:

1. *Intersezione a livello di documento*: si esegue un `AND` booleano classico per individuare un documento $d$ in cui compaiono tutti i termini $t_0, dots, t_(k-1)$.

#let primary-color = rgb("1e3a8a")
#let secondary-color = rgb("0284c7")
#let highlight-color = rgb("dc2626")
#let box-bg = rgb("f1f5f9")
#let match-bg = rgb("fef08a")

#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    // Stili
    let post-box(x, y, label-t, docs, w: 5) = {
      content((x, y), align(right)[*#label-t:*], anchor: "east")
      rect((x + 0.3, y - 0.35), (x + 0.3 + w, y + 0.35), fill: box-bg, stroke: 0.5pt + luma(120), radius: 3pt)
      content((x + 0.5, y), text(size: 9pt)[#docs], anchor: "west")
    }

    post-box(0, 1.6, [$t_0$], [doc $3$, *doc $12$*, doc $45$, doc $78$])
    post-box(0, 0.8, [$t_1$], [*doc $12$*, doc $24$, doc $45$, doc $99$])
    post-box(0, 0.0, [$t_2$], [doc $7$, *doc $12$*, doc $45$, doc $110$])

    // Freccia verso intersezione
    line((5.5, 0.8), (6.9, 0.8), mark: (end: ">"), stroke: 1.2pt + primary-color)

    // Risultato AND
    rect((7.0, 0.3), (10.2, 1.3), fill: rgb("dbeafe"), stroke: 1pt + secondary-color, radius: 4pt)
    content((8.6, 0.8), align(center)[
      #text(weight: "bold", size: 9pt, fill: primary-color)[Documento comune:]\
      #text(weight: "bold", size: 11pt, fill: highlight-color)[$d = 12$]
    ])
  })
]

2. *Recupero delle liste posizionali*: per il documento candidato $d$, si estraggono le liste ordinate delle posizioni $P_0, P_1, dots, P_(k-1)$ dei rispettivi termini.

#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    let draw-array(y, name, items, highlight-idx) = {
      content((-0.4, y), align(right)[*#name:*], anchor: "east")
      let x = 0.0
      let w = 0.9
      let h = 0.6
      for (i, val) in items.enumerate() {
        rect(
          (x, y - h / 2),
          (x + w, y + h / 2),
          fill: white,
          stroke: 0.7pt + luma(100),
          radius: 2pt,
        )
        content((x + w / 2, y), text(weight: "regular")[#val])
        x += w + 0.25
      }
    }

    draw-array(1.6, [$P_0$ ($t_0$)], (3, 15, 42, 88), 1)
    draw-array(0.8, [$P_1$ ($t_1$)], (8, 16, 31, 55), 1)
    draw-array(0.0, [$P_2$ ($t_2$)], (17, 40, 71, 95), 0)

    content(
      (6.2, 0.8),
      align(left)[
        #text(size: 8.5pt, style: "italic", fill: luma(80))[
          Posizioni consecutive:\
          $15 -> 16 -> 17$\
          ($p, p+1, p+2$)
        ]
      ],
      anchor: "west",
    )
  })
]

3. *Scorrimento virtuale (shift) e intersezione*: affinché i termini formino una frase a partire dalla posizione $p$, il termine $t_0$ deve trovarsi in $p$, $t_1$ in $p+1$, e in generale $t_i$ in $p+i$. Di conseguenza, basta considerare per ogni termine $t_i$ una *lista virtuale scalata indietro* di $i$ posizioni (sottraendo $i$ a ciascun elemento di $P_i$ al volo durante la lettura) ed eseguire una normale intersezione (`AND`) tra le liste scalate.


#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    let w = 0.85
    let h = 0.55
    let gap = 0.25

    // Disegna la lista originale, l'operazione di shift e la lista virtuale
    let draw-shift-row(y, label-orig, label-shift, orig-items, shift-val, highlight-idx) = {
      // Lista originale
      content((-0.3, y), align(right)[*#label-orig:*], anchor: "east")
      let x = 0.0
      for (i, val) in orig-items.enumerate() {
        let is-match = (i == highlight-idx)
        rect((x, y - h / 2), (x + w, y + h / 2), fill: luma(248), stroke: 0.5pt + luma(160), radius: 2pt)
        content((x + w / 2, y), text(size: 9pt, fill: if is-match { highlight-color } else { black })[#val])
        x += w + gap
      }

      // Etichetta operazione
      content(
        (5, y + 0.2),
        align(center)[#text(size: 8.5pt, weight: "bold", fill: primary-color)[$- #shift-val$]],
        anchor: "center",
      )
      line((4.7, y), (5.5, y), mark: (end: ">"), stroke: 0.8pt + primary-color)

      // Lista virtuale
      content((5.8, y), align(left)[*#label-shift:*], anchor: "west")
      let xv = 7.1
      for (i, val) in orig-items.enumerate() {
        let is-match = (i == highlight-idx)
        let shifted = val - shift-val
        rect(
          (xv, y - h / 2),
          (xv + w, y + h / 2),
          fill: if is-match { match-bg } else { white },
          stroke: if is-match { 1.3pt + highlight-color } else { 0.6pt + luma(120) },
          radius: 2pt,
        )
        content((xv + w / 2, y), text(size: 9pt, weight: if is-match { "bold" } else { "regular" })[#shifted])
        xv += w + gap
      }
    }

    // Tre termini e relative operazioni
    draw-shift-row(2.2, [$P_0$], [$P'_0$], (3, 15, 42, 88), 0, 1)
    draw-shift-row(1.1, [$P_1$], [$P'_1$], (8, 16, 31, 55), 1, 1)
    draw-shift-row(0.0, [$P_2$], [$P'_2$], (17, 40, 71, 95), 2, 0)

    // Risultato dell'intersezione
    line((9.2, -0.4), (9.2, -1.1), mark: (end: ">"), stroke: 1.2pt + primary-color)

    rect((6.8, -2.3), (12, -1.2), fill: rgb("dcfce7"), stroke: 1.2pt + rgb("16a34a"), radius: 4pt)
    content((9.4, -1.8), align(center)[
      #text(size: 9.5pt, weight: "bold", fill: rgb("15803d"))[
        $P'_0 inter P'_1 inter P'_2 = { 15 }$\
        Trovata frase a partire da $p = 15$!
      ]
    ])
  })
]

In questa fase non si utilizzano solitamente *skip table* sulle liste di posizioni, ma una semplice intersezione sequenziale è già sufficientemente rapida.

#note()[
  *Frasi con buco (wildcard `*`)*: se la frase contiene un carattere jolly che rappresenta una parola qualsiasi (es. `Romeo * Giulietta`), basta scalare i termini successivi al buco di una posizione aggiuntiva (nell'esempio, la lista di `Giulietta` viene scalata indietro di $2$ anziché di $1$).
]

=== Operatore di Prossimità

Consideriamo la query $(t_0, t_1, dots, t_(k-1)) tilde l$, che richiede che tutti i $k$ termini compaiano entro un intervallo di lunghezza al più $l$, ossia nell'intervallo $[p_"min", p_"max"]$, con $p_"max" - p_"min" + 1 <= l$
(oppure $p_"max" - p_"min" <= l$ a seconda della convenzione adottata).

Un approccio ingenuo che enumerasse tutte le possibili $k$-uple di posizioni dal prodotto cartesiano delle $k$ liste per poi verificare la distanza avrebbe complessità polinomiale $O(n^k)$ nel numero di occorrenze $n$ (ad esempio cubica $O(n^3)$ per $k = 3$ termini), risultando impraticabile.

Per ottenere un algoritmo *lineare* nel numero totale di occorrenze $n$, ci limitiamo a enumerare i soli *intervalli minimali*.

#note[
  *Differenza tra intervallo minimale e intervallo minimo*:
  - Un intervallo $[u, v]$ che contiene tutti i $k$ termini è *minimale* (rispetto alla relazione di inclusione $subset.eq$) se non esiste alcun sotto-intervallo stretto $[u', v'] subset [u, v]$ che contenga anch'esso tutti i $k$ termini.
  - Un intervallo è *minimo* se ha la lunghezza assoluta $v - u$ più piccola possibile tra tutti gli intervalli validi del documento.

  Poiché l'inclusione tra intervalli è un ordine parziale e non totale, *ogni intervallo minimo è anche minimale, ma non vale il viceversa*: ad esempio, un documento può contenere due intervalli minimali disgiunti o parzialmente sovrapposti di lunghezza $3$ e $4$; il primo è sia minimale sia minimo, mentre il secondo è minimale ma non minimo.
]

==== Proprietà degli intervalli minimali e Algoritmo

Un intervallo minimale è univocamente determinato dal suo *estremo sinistro* (non possono esistere due intervalli minimali distinti che iniziano nella stessa posizione, altrimenti uno sarebbe contenuto nell'altro).
Di conseguenza, in un documento con $n$ occorrenze complessive dei termini della query esistono al più $n$ intervalli minimali.


L'algoritmo enumera gli intervalli candidati procedendo come una fusione (`OR`) delle $k$ liste di posizioni tramite una *coda con priorità indiretta* (min-heap) di dimensione $k$:

1. *Inizializzazione*: si inserisce nella coda di priorità la prima occorrenza di ciascuna delle $k$ liste posizionali e si inizializza una variabile `max` al valore massimo tra queste $k$ posizioni iniziali.

#let col-primary = rgb("1e3a8a")
#let col-accent = rgb("dc2626")
#let col-success = rgb("16a34a")
#let col-heap-bg = rgb("e0f2fe")
#let col-ptr = rgb("f97316")
#let col-window-bg = rgb("fef08a")

#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    let w = 0.8
    let h = 0.5
    let gap = 0.2

    // Helper per disegnare liste con puntatore sulla prima cella
    let draw-list(y, name, items) = {
      content((-0.4, y), align(right)[*#name:*], anchor: "east")
      for (i, val) in items.enumerate() {
        let x = i * (w + gap)
        let is-first = (i == 0)
        rect(
          (x, y - h / 2),
          (x + w, y + h / 2),
          fill: if is-first { col-window-bg } else { white },
          stroke: if is-first { 1.2pt + col-ptr } else { 0.6pt + luma(150) },
          radius: 2pt,
        )
        content((x + w / 2, y), text(size: 8.5pt, weight: if is-first { "bold" } else { "regular" })[#val])
      }
      // Freccia puntatore sulla prima occorrenza
      line((w / 2, y + 0.55), (w / 2, y + 0.3), mark: (end: ">"), stroke: 1.2pt + col-ptr)
    }

    draw-list(2.2, [$P_0$], (2, 18, 45, 90))
    draw-list(1.2, [$P_1$], (10, 25, 60))
    draw-list(0.2, [$P_2$], (5, 14, 33, 80))

    // Freccia verso min-heap
    line((4.2, 1.2), (5.1, 1.2), mark: (end: ">"), stroke: 1.2pt + col-primary)

    // Visualizzazione Min-Heap
    rect((5.3, -0.25), (9.8, 2.6), fill: col-heap-bg, stroke: 1pt + rgb("0284c7"), radius: 4pt)
    content((7.55, 2.3), text(weight: "bold", size: 9pt, fill: col-primary)[Min-Heap (dim $k=3$)])

    // Cella Top (minimo)
    rect((6.8, 1.3), (8.3, 1.9), fill: rgb("fee2e2"), stroke: 1.3pt + col-accent, radius: 3pt)
    content((7.55, 1.6), text(weight: "bold", size: 9pt, fill: col-accent)[2 #text(size: 7pt)[(da $P_0$)]])
    content((8.4, 1.6), text(size: 8pt, weight: "bold", fill: col-accent)[#sym.arrow.l top], anchor: "west")

    // Altri due nodi del heap
    rect((6.8, 1.2), (8.3, 0.6), fill: rgb("ffedd5"), stroke: 1.2pt + col-ptr, radius: 3pt)
    content((7.55, 0.9), text(weight: "bold", size: 8pt, fill: col-ptr)[10 #text(size: 6.5pt)[(da $P_1$)]])
    content((8.4, 0.9), text(size: 8pt, weight: "bold", fill: col-accent)[#sym.arrow.l max], anchor: "west")

    rect((6.8, 0.5), (8.3, -0.1), fill: white, stroke: 0.8pt + luma(120), radius: 3pt)
    content((7.55, 0.2), text(size: 8pt)[5 #text(size: 6.5pt)[(da $P_2$)]])
  })
]

2. *Invariante*: ad ogni passo, la coda contiene esattamente una posizione per ciascuno dei $k$ termini; l'elemento in cima alla coda (`top`) rappresenta l'estremo sinistro corrente, mentre `max` rappresenta l'estremo destro. L'intervallo `[top, max]` contiene quindi sicuramente tutti i $k$ termini.

3. *Avanzamento*: si estrae la lista corrispondente al `top`, la si fa avanzare alla sua occorrenza successiva $p_"next"$, la si reinserisce nella coda e si aggiorna $max = max(max, p_"next")$.

#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    let w = 0.8
    let h = 0.5
    let gap = 0.2

    // 1. Scorrimento sulla lista sorgente (P_0)
    content((-0.4, 1.3), align(right)[*Puntatore $P_0$:*], anchor: "east")
    let p0-items = (2, 18, 45, 90)
    for (i, val) in p0-items.enumerate() {
      let x = i * (w + gap)
      rect(
        (x, 1.3 - h / 2),
        (x + w, 1.3 + h / 2),
        fill: if i == 0 { rgb("fee2e2") } else if i == 1 { col-window-bg } else { white },
        stroke: if i == 1 { 1.3pt + col-success } else { 0.6pt + luma(150) },
        radius: 2pt,
      )
      content((x + w / 2, 1.3), text(size: 8.5pt, weight: if i <= 1 { "bold" } else { "regular" })[#val])
    }

    // Arco di avanzamento puntatore da 2 a 18
    bezier((w / 2, 1.6), (w + gap + w / 2, 1.6), (0.9, 2.8), stroke: 1.2pt + col-ptr, mark: (end: ">"))
    content((0.9, 2.5), text(size: 7.5pt, weight: "bold", fill: col-ptr)[avanza: $p_"next" = 18$])

    // Freccia
    line((4.2, 1.3), (5.1, 1.3), mark: (end: ">"), stroke: 1.2pt + col-primary)

    // Visualizzazione Min-Heap
    rect((5.3, -0.25), (9.8, 2.6), fill: col-heap-bg, stroke: 1pt + rgb("0284c7"), radius: 4pt)
    content((7.55, 2.3), text(weight: "bold", size: 9pt, fill: col-primary)[Min-Heap (dim $k=3$)])

    // Cella Top (minimo)
    rect((6.8, 1.3), (8.3, 1.9), fill: rgb("fee2e2"), stroke: 1.3pt + col-accent, radius: 3pt)
    content((7.55, 1.6), text(weight: "bold", size: 9pt, fill: col-accent)[10 #text(size: 7pt)[(da $P_1$)]])
    content((8.4, 1.6), text(size: 8pt, weight: "bold", fill: col-accent)[#sym.arrow.l top], anchor: "west")

    // Altri due nodi del heap
    rect((6.8, 1.2), (8.3, 0.6), fill: white, stroke: 0.8pt + luma(120), radius: 3pt)
    content((7.55, 0.9), text(size: 8pt)[5 #text(size: 6.5pt)[(da $P_2$)]])

    rect((6.8, 0.5), (8.3, -0.1), fill: rgb("ffedd5"), stroke: 1.2pt + col-ptr, radius: 3pt)
    content((7.55, 0.2), text(weight: "bold", size: 8pt, fill: col-ptr)[18 #text(size: 6.5pt)[(da $P_0$)]])
    content((8.4, 0.2), text(size: 8pt, weight: "bold", fill: col-accent)[#sym.arrow.l max], anchor: "west")
  })
]
*Valutazione pigra (lazy)*: se stiamo solo verificando che il documento soddisfi $(t_0, dots, t_(k-1)) tilde l$, l'algoritmo lavora in modo *pigro* e termina con successo non appena incontra il primo intervallo con ampiezza $<= l$, senza dover cercare necessariamente l'intervallo di lunghezza minima assoluta.

#example[
  Cerchiamo $(a, b, c) tilde 7$ sulla seguente sequenza di documento (indicizzata da $0$ a $28$):


  #align(center)[
    #cetz.canvas({
      import cetz.draw: *

      let seq = (
        "",
        "",
        "",
        "a",
        "",
        "c",
        "",
        "b",
        "",
        "b",
        "",
        "a",
        "",
        "",
        "b",
        "",
        "c",
        "",
        "c",
        "",
        "",
        "",
        "b",
        "",
        "",
        "a",
        "c",
        "",
        "",
      )
      let step = 0.42

      for (i, ch) in seq.enumerate() {
        let x = i * step
        let col = if ch != "-" { rgb("#e3f2fd") } else { luma(250) }
        rect((x, 0), (x + step, 0.45), fill: col, stroke: 0.4pt + luma(180))
        content((x + step / 2, 0.22), text(size: 7.5pt, weight: if ch != "-" { "bold" } else { "regular" })[#ch])
        if calc.rem(i, 2) == 1 or i == 14 or i == 16 or i == 22 or i == 26 {
          content((x + step / 2, -0.2), text(size: 6pt, fill: luma(100))[#i])
        }
      }
    })
  ]

  Le liste di posizioni dei tre termini sono:
  - $a: [3, 11, 25]$
  - $b: [7, 9, 14, 22]$
  - $c: [5, 16, 18, 26]$

  Simuliamo l'evoluzione della coda e della variabile `max`:

  #table(
    columns: (auto, auto, auto, auto, auto, auto),
    align: (
      center + horizon,
      left + horizon,
      left + horizon,
      center + horizon,
      center + horizon,
      center + horizon,
      left + horizon,
    ),
    stroke: 0.5pt + luma(180),
    fill: (col, row) => if row == 0 { luma(240) } else { none },
    table.header(
      [*Operazione*], [*Stato coda*], [*`top`*], [*`max`*], [*Intervallo*], [*Minimale?*]
    ),
    [Stato iniziale], [`[a: 3, c: 5, b: 7]`], [$3$], [$7$], [$[3, 7]$], [Sì (ampiezza $5 <= 7$)],
    
    [Avanzamento di $a$ ($3 -> 11$)],
    [`[c: 5, b: 7, a: 11]`],
    [$5$],
    [$11$],
    [$[5, 11]$],
    [Sì (non contiene sotto-intervalli validi)],

    [Avanzamento di $c$ ($5 -> 16$)],
    [`[b: 7, a: 11, c: 16]`],
    [$7$],
    [$16$],
    [$[7, 16]$],
    [No (contiene propriamente $[11, 16]$)],

    [Ripetizione di $b$ ($7 -> 9$)],
    [`[b: 9, a: 11, c: 16]`],
    [$9$],
    [$16$],
    [$[9, 16]$],
    [No (contiene propriamente $[11, 16]$)],

    [Avanzamento di $b$ ($9 -> 14$)],
    [`[a: 11, b: 14, c: 16]`],
    [$11$],
    [$16$],
    [$[11, 16]$],
    [Sì (nessun elemento ridondante interno)],

    [...], [], [], [], [], [],

    [Avanzamento sequenza],
    [`[b: 22, a: 25, c: 26]`],
    [$22$],
    [$26$],
    [$[22, 26]$],
    [Sì (ottimo, ampiezza minima $5$)],
  )

  #v(0.5em)
  #text(size: 0.9em, style: "italic")[
    *Nota:* a causa delle ripetizioni interne di $b$, gli intervalli $[7, 16]$ e $[9, 16]$ contengono propriamente $[11, 16]$ e pertanto non risultano minimali.
  ]
]

*Complessità*: l'algoritmo ha la stessa struttura e lo stesso costo di una fusione `OR` a $k$ vie.
Detto $n$ il numero totale di occorrenze nelle liste posizionali e $k$ il numero di termini nell'operatore, ogni occorrenza viene inserita ed estratta una sola volta da un heap di dimensione $k$, per un costo complessivo di *$O(n log k)$* (lineare in $n$ e linearitmico in $k$).

#note[
  *Composizione di operatori su regioni (anticatene di intervalli)*: se vogliamo comporre liberamente operatori di prossimità, frasi e operatori booleani — come in `((a, b, c)~3 d)` oppure `(a | b) c` — non possiamo più far restituire agli operatori semplici liste di singole posizioni, ma dobbiamo ragionare su *intervalli (regioni)* del documento.
  In particolare, la semantica di ogni espressione viene definita come un'*anticatena di intervalli minimali* (un insieme di intervalli nessuno dei quali è contenuto in un altro, il che garantisce che siano ordinati contemporaneamente sia per estremo sinistro crescente sia per estremo destro crescente).
  In questo modo gli operatori possono essere combinati tra loro fondendo l'estremo sinistro del primo intervallo con l'estremo destro dell'ultimo per generare i nuovi intervalli minimali.
]

=== Gestione degli errori di battitura (DYM - Did You Mean)

#note[
  Finora abbiamo assunto che i termini della query siano privi di errori di battitura.
  Nei motori di ricerca reali, la query inserita dall'utente in linguaggio naturale viene analizzata e corretta *prima* di essere tradotta ed eseguita come query booleana.
  Quando un termine non produce risultati o appare errato, si ricorre a indici e dizionari di correzione (*DYM index - Did You Mean*): si considera una "bolla" di *distanza di Levenshtein* (o *distanza di edit*, ovvero il numero minimo di inserimenti, cancellazioni o sostituzioni di caratteri per trasformare una parola in un'altra) di raggio $1$ o $2$ attorno alla parola digitata, si estraggono i termini validi presenti nel vocabolario che cadono nella bolla e si riformula la query con tali termini.
]

== Costruzione dell'Indice Invertito e Sorting

Vediamo ora come costruire l'indice invertito a partire dalla collezione di documenti.
Durante la scansione dei documenti (parsing), identifichiamo i termini tramite una tabella di hash del vocabolario e produciamo uno stream di terne (tuple):
$ chevron.l d, t, p chevron.r = ("ID documento", "ID termine", "posizione") $
Queste terne vengono generate naturalmente ordinate per documento $d$ crescente e, all'interno dello stesso documento, per posizione $p$ crescente.

Per costruire le liste di affissione, il passo computazionalmente dominante consiste nell'effettuare un gigantesco *ordinamento stabile* delle terne rispetto al termine $t$:
- ordinando per $t$, raggruppiamo tutte le occorrenze dello stesso termine;
- poiché l'ordinamento è *stabile*, a parità di termine $t$ le terne conservano l'ordine originario per documento $d$ crescente e posizione $p$ crescente, che è esattamente l'ordine richiesto dalle liste di affissione.

#note[
  *MapReduce e il costo della distribuzione (COST)*:
  - Proprio per eseguire questo ordinamento stabile su scala web in modo distribuito e tollerante ai guasti, Google ha introdotto il paradigma *MapReduce*, che gestisce automaticamente partizionamento, ordinamento distribuito e tripla replica dei dati (scartando i nodi che falliscono).
  - *Curiosità storica*: negli anni di massimo entusiasmo per MapReduce è stata proposta la metrica *COST* (*Configuration that Outperforms a Single Thread*), che misura quante macchine distribuite servano a un framework per battere un singolo laptop con un programma ben ottimizzato su singolo thread. Per diversi problemi su grafi e dati di medie dimensioni, l'overhead di rete e replica fa sì che anche con un numero enorme di macchine il sistema distribuito risulti più lento di un singolo thread su laptop.
]

=== Inversione in memoria (sort su Bit Stream)

Anziché generare esplicitamente tutte le tuple $chevron.l d, t, p chevron.r$ su disco e ordinarle, si effettua l'inversione direttamente in memoria centrale tramite un algoritmo di *sort* (paragonabile per certi versi a bucket sort) che costruisce le liste già compresse:

1. Poiché il numero di termini distinti (il vocabolario) è molto più piccolo del numero totale di occorrenze, manteniamo in RAM una *tabella di hash dei termini*.
2. Ogni termine $t$ nella tabella di hash punta direttamente a un *bit stream* (un buffer dinamico di byte in memoria) in cui appendiamo man mano la sua lista di affissione compressa nella forma$[chevron.l d, chevron.l p_0, p_1, dots chevron.r chevron.r]$.

3. Man mano che arrivano le terne$chevron.l d, t, p chevron.r$del documento corrente (es.$chevron.l 0, a, 0 chevron.r, chevron.l 0, b, 1 chevron.r, dots$), aggiungiamo la posizione $p$ in coda al bit stream del termine$t$:
$
  a & -> [chevron.l 0, chevron.l 0, dots chevron.r chevron.r] \
  b & -> [chevron.l 0, chevron.l 1, dots chevron.r chevron.r]
$
Quando inizia un nuovo documento $d + 1$, le liste posizionali del documento $d$ vengono chiuse e si aprono quelle per $d + 1$.

4. Quando la memoria RAM disponibile si esaurisce, ordiniamo *lessicograficamente* i termini presenti nella tabella di hash e scarichiamo su disco un segmento d'indice parziale $(T_i, I_i)$, svuotando poi la RAM per ricominciare con il blocco successivo di documenti.

#note[
  *Scelta del codice di compressione in memoria*: durante la costruzione del bit stream in RAM dobbiamo necessariamente usare *codici universali privi di parametri* (come i codici $gamma$ o $delta$ di Elias) e *non* codici parametrici come Golomb/Rice.
  Infatti, mentre i dati arrivano in streaming non conosciamo ancora la frequenza globale del termine nella collezione né la lunghezza finale della lista, parametri indispensabili per dimensionare il codice di Golomb.
]

=== Fusione lineare dei segmenti d'indice (Multi-way Merge)

Al termine della fase di inversione a blocchi, ci ritroviamo su disco con una sequenza di segmenti d'indice parziali:
$T_0 -> I_0, quad T_1 -> I_1, quad dots, quad T_(m-1) -> I_(m-1)$
dove ciascun segmento $(T_i, I_i)$ indicizza un sottoinsieme disgiunto di documenti (con ID crescenti da $I_0$ a $I (m-1)$) e uno stesso termine può comparire in più dizionari $T_i$.

#warning[
  *Assunzione fondamentale per la complessità lineare*: affinché i segmenti possano essere fusi in un unico indice globale in *tempo lineare* senza effettuare costosi accessi aleatori (*random I/O*) su disco, è essenziale che ogni dizionario $T_i$ sia stato salvato su disco in *ordine lessicografico* (operazione molto economica al momento dello scaricamento della RAM) e che le relative liste di affissione in $I_i$ siano memorizzate nello stesso ordine.
]

La fusione avviene in *streaming parallelo* utilizzando una *coda con priorità indiretta* (min-heap) contenente un cursore per ciascun segmento $i in {0, dots, m-1}$:
- Per ogni segmento $i$ manteniamo due puntatori sincronizzati che avanzano sequenzialmente su disco: uno sul termine corrente nel file dizionario $T_i$ e uno sulla corrispondente lista di affissione nel file $I_i$.
- La coda con priorità confronta i termini correnti dei vari segmenti secondo l'ordine lessicografico; *in caso di parità* (stesso termine presente in più segmenti), ha priorità il segmento con *indice $i$ minore*, poiché contiene documenti con ID inferiori.
- Ad ogni estrazione del minimo dalla coda, si copia la relativa lista di affissione nel file d'indice finale (concatenandola a quella dello stesso termine se appena estratto da un segmento precedente) e si fanno avanzare in parallelo il puntatore al dizionario $T_i$ e quello al fileI_i.

#example[
  Supponiamo di dover fondere tre segmenti d'indice i cui dizionari ordinati sono:
  - $T_0$: termini `[a, b, c]`
  - $T_1$: termini `[b, c, d]`
  - $T_2$: termini `[a, d]`

  1. *Inizializzazione*: inseriamo nella coda i primi termini di ciascun segmento: `a` (di $T_0$), `b` (di $T_1$) e `a` (di $T_2$).
  2. *Estrazione di `a`*: per la regola di spareggio tra termini uguali vince `a` (di $T_0$) rispetto ad `a` (di $T_2$). Scriviamo nell'output la lista di affissione di `a` letta da $I_0$ e facciamo avanzare il cursore di $T_0$ al termine `b`.
  3. *Concatenazione di `a`*: il nuovo minimo nella coda è `a` (di $T_2$). Appendiamo la lista di affissione di `a` letta da $I_2$ direttamente in coda a quella appena scritta per $I_0$, ottenendo la lista completa e ordinata per `a`, e facciamo avanzare il cursore di $T_2$ al termine `d`.
  4. *Passaggio a `b`*: la coda contiene ora `b` (di $T_0$), `b` (di $T_1$) e `d` (di $T_2$); il processo prosegue analogamente per `b`, poi `c` e infine `d`.
]

#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    // Segmenti a sinistra
    rect((0, 2.2), (2.6, 2.8), fill: rgb("#e3f2fd"), radius: 3pt)
    content((1.3, 2.5), text(size: 8pt)[$T_0, I_0$: `[a, b, c]`])

    rect((0, 1.2), (2.6, 1.8), fill: rgb("#e3f2fd"), radius: 3pt)
    content((1.3, 1.5), text(size: 8pt)[$T_1, I_1$: `[b, c, d]`])

    rect((0, 0.2), (2.6, 0.8), fill: rgb("#e3f2fd"), radius: 3pt)
    content((1.3, 0.5), text(size: 8pt)[$T_2, I_2$: `[a, d]`])

    // Frecce verso la coda
    line((2.6, 2.5), (4.2, 1.8), mark: (end: ">"))
    line((2.6, 1.5), (4.2, 1.5), mark: (end: ">"))
    line((2.6, 0.5), (4.2, 1.2), mark: (end: ">"))

    // Coda di priorità indiretta
    rect((4.2, 0.7), (7.6, 2.3), fill: rgb("#fff9c4"), stroke: 1pt + rgb("#f9a825"), radius: 5pt)
    content((5.9, 1.9), text(size: 8.5pt, weight: "bold")[Coda (Min-Heap)])
    content((5.9, 1.45), text(size: 8pt)[`1°: (a, I_0)`])
    content((5.9, 1.05), text(size: 8pt)[`2°: (a, I_2), 3°: (b, I_1)`])

    // Freccia verso l'indice unificato
    line((7.6, 1.5), (9.0, 1.5), mark: (end: ">"))

    // Output
    rect((9.0, 0.7), (12.2, 2.3), fill: rgb("#c8e6c9"), stroke: 1pt + rgb("#2e7d32"), radius: 5pt)
    content((10.6, 1.9), text(size: 8.5pt, weight: "bold")[Indice Finale $I$])
    content((10.6, 1.45), text(size: 8pt)[`a -> I_0(a) + I_2(a)`])
    content((10.6, 1.05), text(size: 8pt)[`b -> I_0(b) + I_1(b)`])
  })
]

Durante questa fase di fusione, poiché conosciamo finalmente la frequenza globale di ciascun termine, possiamo anche
*ricodificare* le liste di affissione sostituendo i codici universali (gamma, delta, ...) con codici parametrici più compatti (come il codice di Golomb).

#note[
  Non è sempre obbligatorio fondere immediatamente tutti i segmenti in un unico indice monolitico: nei sistemi dinamici è possibile mantenere più segmenti separati, interrogarli in parallelo a tempo di query e concatenare/fondere i risultati restituiti.
]
