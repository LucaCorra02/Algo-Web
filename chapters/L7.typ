#import "../template.typ": *

== Disuguaglianza di Kraft

#theorem(title: "Disuguaglianza di Kraft")[
  La disuguaglianza di Kraft permette di asserire se un codice è *non istantaneo*.

  Essa afferma che se $C$ è un codice istantaneo, *allora* la somma di tutte le lunghezze delle parole del codice deve essere minore o uguale a 1.
  In formula:
  $
    C "ist" -> sum_(w in C) 2^(-|w|) <= 1
  $

  #note()[
    $2^(-|w|)$ o $1/2^(|w|)$ rappresenta lo spazio che la parola $w$ occupa nell'intervallo unitario $[0...1)$. Parole con una *lunghezza minore occupano più spazio* (invalidano più rapidamente la scelta di altre parole) e parole con una *lunghezza maggiore occupano meno spazio*.

    Ad esempio, scegliano una parola di lunghezza $1$ che inizia con $0$, andiamo a "bloccare" tutte le stringhe che iniziano per $0$, consumandone il 50% ($2^(-1)$)
  ]

  #warning()[
    Se eccediamo il budget ($> 1$) allora il codice è *sicuramente non istantaneo*. Se invece rispettiamo il budget ($<=1$) allora il codice potrebbe essere istantaneo oppure no, non possiamo dirlo con certezza. In questo caso dobbiamo considerare le possibili combinazioni di parole:
    $
      "Se" sum_(w in C) 2^(-|w|) > 1 -> C "non ist"
    $
  ]

  Dall'equazione precedente, possiamo dedurre che se $C$ è istantaneo, esso è anche completo *se e solo se* la somma di tutte le lunghezze dei codici è esattamente 1:
  $
    C "completo" <-> sum_(w in C) 2^(-|w|) = 1
  $
]

La disuguaglianza di Kraft è molto utile in quanto ci permette di verificare solamente tramite una somma se un codice non è istantaneo, senza dover considerare tutte le possibili combinazioni di parole. In questo modo possiamo evitare di fare un'analisi combinatoria che sarebbe molto più complessa.

#theorem(title: "Implicazione di Kraft")[
  Un implicazione della disuguaglianza di kraft è che considerando una sequenza di lunghezze $t_0, t_1, t_2, t_3dots$ (eventualmente infinita), che soddisfa la disuguaglianza di Kraft:
  $
    sum_(n) 2^(-t_n) <= 1
  $
  *Esiste* un codice istantaneo formato da parole $w_0, w_1, w_2, w_3dots$ dove $|w_i| = t_i$.
]

Si può quindi dedurre informalmente che, dato un codice che soddisfa la disuguaglianza di Kraft, se esso non è istantaneo, allora è *possibile costruire un codice istantaneo con quelle lunghezze*, manipolando alcuni bit.



=== Visione ad albero binario

Possiamo vedere l'assegnamento di una parola del codice come un sotto-intervallo dell'intervallo unitario $[0...1)$. Ogni parola $w$ di lunghezza $|w|$ occupa uno spazio pari a $2^(-|w|)$. L'idea è quella di associare ad ogni parola un determinato intervallo (ogni volta lo spezziamo in due parti). La parola vuota è l'intervallo unitario $[0...1)$.

Quando aggiungiamo una parola $w$, chiamiamo $x$ la parola $w$ privata dell'ultimo carattere. Se $x$ ha come intervallo $[a...b)$, allora $w$ avrà come intervallo:
$
  & [a, (a+b)/2) "se" w = x 0 \
  & [(a+b)/2, b) "se" w = x 1 \
$

#align(center)[
  #cetz.canvas({
    import cetz.draw: *

    // L rappresenta la larghezza totale del disegno (12 unità)
    let L = 10

    // 1. LIVELLO SUPERIORE: Intervallo totale
    line((0, 3), (L, 3), mark: (start: "|", end: "|"), stroke: 1pt)
    content((L / 2, 3.4), [Spazio unario $[0, 1)$ - parola vuota $epsilon$])

    // 2. LIVELLO INTERMEDIO: La parola x (e il resto dello spazio)
    line((0, 1.5), (L / 2, 1.5), mark: (start: "|", end: "|"), stroke: 1pt)
    content((L / 4, 1.9), [$x = [0, 1/2)$])

    // Disegniamo in grigio l'altra metà per chiarezza di contesto
    line((L / 2, 1.5), (L, 1.5), mark: (start: "|", end: "|"), stroke: (paint: gray, thickness: 1pt))
    content((L * 0.75, 1.9), text(fill: gray)[$[1/2, 1)$])

    // 3. LIVELLO INFERIORE: Divisione in x0 e x1
    line((0, 0), (L / 4, 0), mark: (start: "|", end: "|"), stroke: 1pt)
    content((L / 8, 0.4), [$x 0 = [0, 1/4)$])

    line((L / 4, 0), (L / 2, 0), mark: (start: "|", end: "|"), stroke: 1pt)
    content((L * 0.375, 0.4), [$x 1 = [1/4, 1/2)$])

    // 4. LINEE DI PROIEZIONE E ASSE
    // Linee tratteggiate per guidare l'occhio sulle divisioni
    let dashed = (dash: "dashed", paint: gray, thickness: 0.5pt)
    line((0, 3.2), (0, -0.5), stroke: dashed)
    line((L / 4, 1.5), (L / 4, -0.5), stroke: dashed)
    line((L / 2, 3.2), (L / 2, -0.5), stroke: dashed)
    line((L, 3.2), (L, 1.5), stroke: dashed)

    // Etichette dei valori matematici in fondo
    content((0, -0.8), [$0$])
    content((L / 4, -0.8), [$1/4$])
    content((L / 2, -0.8), [$1/2$])
    content((L, -0.8), [$1$])
  })
]



Tramite un'altra visione, possiamo vedere un codice istantaneo come un *albero binario*: Assegnare una parola $w$ al codice significa scegliere un nodo a profonidità $|w|$. A causa della regola del prefisso, una volta scelto un nodo come parola, non è possibile usare nessuno dei suoi *discendenti* (come se avessimo "prenotato" il sotto-albero che parte da quel nodo)

#align(center)[
  #cetz.canvas({
    import cetz.draw: *
    import cetz.tree: *

    set-style(content: (padding: 6pt))

    // Configurazione dei nodi dell'albero
    let data = (
      [$epsilon$],
      ([0], ([00], [000], [001]), ([01], [010], [011])),
      ([1], ([10], [100], [101]), ([11], [110], [111])),
    )

    // Disegno dell'albero
    tree(
      data,
      spread: 0.9, // Aumenta la distanza orizzontale tra i nodi
      grow: 1, // Aumenta la distanza verticale tra i livelli
      name: "tree",
    )
  })
]

Pensando all'abero in termini di *budget* (l'intero albero vale 1), possiamo:
- Scegliere un nodo a profondità $1$ (lunghezza $1$) ellimina metà albero $2^(-1)$ del budget
- Scegliere un nodo a profondità $2$ (lunghezza $2$) ellimina un quarto dell'albero $2^(-2)$ del budget
- in generale scegliere un nodo a profondità $k$ (lunghezza $k$) ellimina $1/2^k$ dell'albero $2^(-k)$ del budget


=== Dimostrazione della disuguaglianza di Kraft

Consideriamo due parole binarie $x$ e $y$ e i loro rispettivi intervalli $I(x)$ e $I(y)$.

#theorem(title: "Prefisso insiemistico")[
  La relazione di *prefisso* tra due parole binarie $x$ e $y$ è equivalente alla relazione di *inclusione* tra i loro intervalli:
  $
    x <= y <-> I(x) supset.eq I(y)
  $
  Se $x$ è un prefisso di $y$ allora l'intervallo di $x$ contiene l'intervallo di $y$, siccome le parole più corte occupano più spazio e quindi contengono le parole più lunghe che iniziano con esse.
]

#theorem(title: "Confrontabilità insiemistica")[
  Se $x$ e $y$ sono *inconfrontabili* allora i loro intervalli sono *disgiunti*:
  $
    x || y -> I(x) inter I(y) = emptyset
  $

  Questo è intuitivo se si pensa a due parole inconfrontabili come un prefisso comune ($epsilon$ nel caso base) seguite da un bit diverso, e si immagina la costruzione tramite B tree. A partire dal bit diverso, le due parole si diramano e quindi i loro intervalli non si intersecano più. In formula:
  $
    exists z in Z^* "t.c" x = z 0 x^', y = z 1 y^'
  $

  #example()[

    Consideriamo le parole $x = mb(01) mr(0)$ e $y = mb(01) mr(1)$. Il loro prefisso comune z è $mb(01)$.
    Quindi possiamo scrivere
    $
      mo(x) & = mb(z) mr(0) epsilon = mb(01) mr(0) epsilon \
      mg(y) & = mb(z) mr(1) epsilon = mb(01) mr(1) epsilon
    $

    #align(center)[
      #cetz.canvas({
        import cetz.draw: *
        import cetz.tree: *

        set-style(content: (padding: 6pt))

        // 1. Definiamo i dati dell'albero: i nodi del percorso sono rossi, gli altri neri
        let data = (
          text(fill: red)[$epsilon$],
          (
            text(fill: red)[0],
            ([00], [000], [001]),
            (
              text(fill: blue)[01 = z],
              (text(fill: orange)[010]),
              (text(fill: green)[011]),
            ),
          ),
          ([1], ([10], [100], [101]), ([11], [110], [111])),
        )

        tree(
          data,
          spread: 1,
          grow: 1.5,
          name: "tree",

          // 2. Colora SOLO gli archi (edges) del percorso in rosso.
          // Utilizziamo un controllo flessibile sui nomi generati da CeTZ per i nodi.
          draw-edge: (source, target, ..args) => {
            let s = str(source)
            let t = str(target)

            // Definiamo con precisione le coppie "Sorgente -> Destinazione"
            // che formano i rami (gli archi) che vogliamo evidenziare.
            let is-red-edge = (
              // epsilon (tree-0) -> 0 (tree-0-0)
              (s.ends-with("tree-0") and t.ends-with("tree-0-0"))
                or
                // 0 (tree-0-0) -> 01 (tree-0-0-1)
                (s.ends-with("tree-0-0") and t.ends-with("tree-0-0-1"))
                or
                // 01 (tree-0-0-1) -> 010 (tree-0-0-1-0)
                (s.ends-with("tree-0-0-1") and t.ends-with("tree-0-0-1-0"))
                or
                // 01 (tree-0-0-1) -> 011 (tree-0-0-1-1)
                (s.ends-with("tree-0-0-1") and t.ends-with("tree-0-0-1-1"))
            )

            if is-red-edge {
              // Se fa parte del percorso, l'arco è rosso e più spesso
              line(source, target, stroke: red + 1.8pt)
            } else {
              // Altrimenti, l'arco è nero standard
              line(source, target, stroke: black + 0.8pt)
            }
          },
        )
      })
    ]
    Dal prefisso comune $mb(z)$ le due parole si *diramano*, quindi i loro intervalli sono disgiunti. I loro intervalli sono $I(x) = [2/8, 3/8)$ e $I(y) = [3/8, 4/8)$, che sono
    disgiunti, e sono inclusi nell'intervallo del prefisso comune $I(z) = [1/4, 1/2)$.

    #v(1.5em)

    #align(center)[
      #cetz.canvas({
        import cetz.draw: *

        let L = 14

        // --- VARIABILI PER LE ALTEZZE (MODIFICA QUESTE) ---
        // Avvicinando questi valori, riduci lo spazio verticale tra i segmenti
        let y0 = 3.6 // Altezza Livello 0 (epsilon)
        let y1 = 2.4 // Altezza Livello 1 (0 e 1)
        let y2 = 1.2 // Altezza Livello 2 (00, 01, ecc.)
        let y3 = 0 // Altezza Livello 3 (000, 001, ecc.)
        let y_asse = -0.8 // Altezza dell'asse inferiore dei numeri

        // STILE GENERALE
        let dashed = (dash: "dashed", paint: gray.lighten(20%), thickness: 0.5pt)
        let line-main = (mark: (start: "|", end: "|"), stroke: 1.2pt)
        let line-sub = (mark: (start: "|", end: "|"), stroke: 0.8pt)

        // 1. LIVELLO 0
        line((0, y0), (L, y0), ..line-main)
        content((L / 2, y0 + 0.3), [$epsilon = [0, 1)$])

        // 2. LIVELLO 1
        line((0, y1), (L / 2, y1), ..line-main)
        content((L / 4, y1 + 0.4), [$0 = [0, 1/2)$])

        line((L / 2, y1), (L, y1), ..line-main)
        content((L * 0.75, y1 + 0.4), [$1 = [1/2, 1)$])

        // 3. LIVELLO 2
        line((0, y2), (L / 4, y2), ..line-sub)
        content((L / 8, y2 + 0.4), [$00 = [0, 1/4)$])

        line((L / 4, y2), (L / 2, y2), ..line-sub)
        content((L * 0.375, y2 + 0.4), [$01 = [1/4, 1/2)$])

        line((L / 2, y2), (L * 0.75, y2), ..line-sub)
        content((L * 0.625, y2 + 0.4), [$10 = [1/2, 3/4)$])

        line((L * 0.75, y2), (L, y2), ..line-sub)
        content((L * 0.875, y2 + 0.4), [$11 = [3/4, 1)$])

        // 4. LIVELLO 3
        let span = L / 8
        line((0, y3), (span, y3), ..line-sub)
        content((span * 0.5, y3 + 0.4), [$000$])

        line((span, y3), (span * 2, y3), ..line-sub)
        content((span * 1.5, y3 + 0.4), [$001$])

        line((span * 2, y3), (span * 3, y3), ..line-sub)
        content((span * 2.5, y3 + 0.4), [$010$])

        line((span * 3, y3), (span * 4, y3), ..line-sub)
        content((span * 3.5, y3 + 0.4), [$011$])

        line((span * 4, y3), (span * 5, y3), ..line-sub)
        content((span * 4.5, y3 + 0.4), [$100$])

        line((span * 5, y3), (span * 6, y3), ..line-sub)
        content((span * 5.5, y3 + 0.4), [$101$])

        line((span * 6, y3), (span * 7, y3), ..line-sub)
        content((span * 6.5, y3 + 0.4), [$110$])

        line((span * 7, y3), (L, y3), ..line-sub)
        content((span * 7.5, y3 + 0.4), [$111$])

        // 5. LINEE DI PROIEZIONE E ASSE INFERIORE
        for i in range(9) {
          let x = (L / 8) * i
          // Le linee tratteggiate ora partono da poco sopra y0 e finiscono poco sopra y_asse
          line((x, y0 + 0.1), (x, y_asse + 0.2), stroke: dashed)
        }

        // Etichette matematiche sull'asse
        content((0, y_asse), [$0$])
        content((span, y_asse), [$1/8$])
        content((span * 2, y_asse), [$2/8$])
        content((span * 3, y_asse), [$3/8$])
        content((span * 4, y_asse), [$4/8$])
        content((span * 5, y_asse), [$5/8$])
        content((span * 6, y_asse), [$6/8$])
        content((span * 7, y_asse), [$7/8$])
        content((L, y_asse), [$1$])
      })
    ]
  ]
]<teo-conf>

La dimostrazione della disuguaglianza di Kraft si divide in due parti:
- Dimostrazione della limitazione superiore ($<= 1$)
- Dimostrazione della completezza ($= 1$)

#proof(title: "Dimostrazione della limitazione superiore (<= 1)")[
  Ogni parola $w$ del codice $C$ viene mappata in un intervallo di lunghezza $2^(-|w|)$ all'interno dello spazio totale $[0, 1)$.

  Poiché il codice è *istantaneo* (privo di prefissi), per il Teorema della *Confrontabilità Insiemistica* sappiamo che nessuna parola è contenuta nell'intervallo di un'altra. Di conseguenza, tutti gli intervalli associati alle parole di $C$ sono *a due a due disgiunti*.

  Essendo disgiunti, la somma delle loro lunghezze non può fisicamente superare l'ampiezza dell'intervallo che li contiene tutti, ovvero 1:
  $ sum_(w in C) 2^(-|w|) <= 1 $
]

Per comprendere a fondo la dimostrazione di completezza, dobbiamo introdurre il concetto di *numero diadico*. Un diadico è un razionale della forma: $ k 2^(-h) = k 1 / 2^h $

Questi numeri rappresentano tutti i *punti di "taglio"* che si ottengono dividendo a metà, in modo ricorsivo, l'intervallo unitario $[0, 1)$.

Un *intervallo diadico* è lo spazio compreso tra due diadici consecutivi dello stesso "livello" $h$:
$
  [k 2^(-h), (k+1) 2^(-h))
$

#note()[
  Tali intervalli presentano una proprietà fondamentale: Dato un qualunque intervallo diadico $[k 2^(-h), (k+1) 2^(-h))$, esiste *un'unica parola di lunghezza $h$* a cui è associato l'intervallo.

  Ad esempio, l'intervallo $[1/4, 2/4)$ è un intervallo diadico di livello $h=2$ (poiché $1/4 = 1/2^2$ e $2/4 = 2/2^2$). La singola parola associata ad esso è `01`.
]








Vogliamo dimostrare che un codice istantaneo $C$ è completo *se e solo se* la somma delle lunghezze dei suoi intervalli è esattamente 1.

#proof()[
  *Parte 1: Se la somma è $< 1$ allora il codice NON è completo.* \
  Se la sommatoria è strettamente minore di uno, deve esserci un intervallo scoperto (cioè uno spazio "vuoto" non assegnato ad alcuna parola), diciamo $[x, y)$[cite: 1].
  Poiché la scomposizione diadica può procedere all'infinito scendendo di livello (aumentando $h$), questo intervallo $[x, y)$ contiene necessariamente un sottointervallo diadico della forma $[k 2^(-h), (k+1)2^(-h))$ per qualche $h$ e $k$[cite: 1].
  Sappiamo che a questo intervallo diadico corrisponde un'esatta parola binaria. Poiché l'intervallo si trova in uno spazio completamente "vuoto", questa parola non si sovrappone a nessuna di quelle esistenti. Ma allora la parola associata a quest'ultimo potrebbe essere aggiunta al codice (essendo inconfrontabile con tutte le altre), che quindi risulta incompleto[cite: 1].

  *Parte 2: Se il codice NON è completo allora la somma è $< 1$.* \
  D'altra parte, se il codice è incompleto, l'intervallo corrispondente a una parola inconfrontabile con tutte quelle del codice è necessariamente scoperto[cite: 1]. La presenza di questo nuovo intervallo fisico completamente libero rende la somma totale delle frazioni di spazio precedentemente occupate strettamente minore di 1[cite: 1].
]

*Implicazione della disequaglianza di Kraft*

Supponiamo di avere una sequenza di lunghezze $t_0, t_1, t_2, t_3dots$ (eventualmente infinita) ordinata in modo crescente,
e di voler costruire un codice istantaneo con queste lunghezze. Se la somma di tutte le lunghezze dei codici è minore o
uguale a 1 allora possiamo costruire un codice con queste lunghezze in maniera miope (greedy).

#note()[
  Che il codice sia istantaneo non è una vera e propria implicazione della disequaglianza di Kraft, perché non posso dire con certezza che il codice
  costruito sia istantaneo, ma se non è così, l'errore non è nelle lunghezze scelte ma nella scelta dei bit delle parole
  associate a quelle lunghezze.
]

#proof()[
  Sia 𝑑 l’estremo destro della parte di intervallo unitario correntemente coperta dagli intervalli associati alle parole già
  generate. Vogliamo dimostrare che, per qualche intero $k$, l'invariante $𝑑 = k / 2^(t_i)$ sia vero sempre.

  Il caso base è $d_0 = 0$.

  L'intervallo diadico per una parola di lunghezza $t_i$ sarà:
  $
    [ k / 2^(t_i), (k+1) / 2^(t_i) )
  $
  per un certo $k$ intero, ossia di lunghezza k.

  Se $𝑑 = k / 2^(t_i)$ è vero, dopo l'inserimento della parola $w_n$, d sarà dunque $(k+1) / 2^(t_i)$.

  $
    (k+1) 2^(-t_i)
  $

  Moltiplico $2^(-t_i)$ per $2^(-t_(i+1)) * 2^(t_(i+1))$, ottenendo:

  $
    underbrace((k+1) * 2^(t_(i+1) - t_i), k) 2^(-t_(i+1))
  $

  Dove $t_(i+1) >= t_i$

  L'invariante è dunque mantenuto.

  #example()[
    Consideriamo la rappresentazione di un codice C, contenente parole di lunghezza 1, 3, 3 e 5.
    Calcoliamo la diseguaglianza di Kraft:
    $
      2^(-1) + 2^(-3) + 2^(-3) + 2^(-5) = 25/32 < 1
    $

    Consideriamo come prima parola 0, di lunghezza 1; il suo intervallo è $[0, 1/2)$.
    Dopo l'inserimento della prima parola, si ottiene dunque d = 1/2 = 4/8.

    Come seconda parola prendiamo 100, di lunghezza 3, quindi il suo intervallo sarà $[d, d + 1/8) = [4/8, 5/8)$.
    Dopo l'inserimento otteniamo d = 5/8.

    Come terza parola scegliamo 101, sempre di lunghezza 3, con intervallo $[d, d + 1/8) = [5/8, 6/8)$.
    Si ottiene d = 6/8 = 24/32.

    Proviamo ad usare come quarta parola 11000, di lunghezza 5. Il suo intervallo è $[d, d + 1/32) = [24/32, 25/32)$.

    In questo ultimo caso, ad esempio, non avremmo potuto scegliere 10101, in quanto confrontabile con 101.
    Come si evince dal teorema di Kraft infatti, la somma delle lunghezze dei codici è minore di 1, quindi è sempre
    possibile costruire un codice istantaneo con queste lunghezze, ma non tutti i codici con queste lunghezze sono istantanei.
  ]

]


== Codici istantanei

=== Codice binario
Un codice binario di ampiezza $k$ è istantaneo e ogni parola ha la stessa lunghezza $k$. In questo caso la lunghezza di parole è $2^k$. Se tutti i simboli hanno la stessa frequenza allora il codice binario è ottimale. \

=== Codice unario

Esistono due tipologie di codice unario: $1^* 0$ e $0^* 1$.

Il codice $1^* 0$ ha ordine lessicografico: l'ordine tra le parole corrisponde all'ordine tra la gli interi da essi rappresentati. Formalmente se $x <= y -> 1^x 0 <= 1^y 0$
Per effettuare il confronto tra due parole basta confrontare i bit uno alla volta, fino a trovare il primo bit a 1.
La parola con il primo bit a 1 più a sinistra è maggiore.

#note()[
  Questo codice unario viene usato da UTF-8 per rappresentare i caratteri.
]

Il codice $0^* 1$ invece non ha ordine lessicografico.
Il suo vantaggio risiede nelle operazioni di lettura del codice.
Consideriamo infatti un codice unario rappresentato in little-endian. Per leggere il numero, è necessario calcolarne la
sua lunghezza, ossia trovare la posizione del primo bit a 1.
Nelle CPU moderne, esistono delle singole istruzioni per trovare il primo bit a 1, rendendo questa operazione molto più efficiente.


Il problema dei codici unari è che, per rappresentare un numero $k$, servono $k+1$ bit. Quindi è utilizzabile solo per $k$ piccoli.

=== Codice elias $gamma$ (gamma)
Per codificare un intero x con questo codice, è necessario prima calcolare la sua "rappresentazione binaria ridotta", ottenuta
codificando $x + 1$ in binario e rimuovendo il bit più significativo.

#example()[
  - 0 -> 1 -> 1 -> $epsilon$
  - 1 -> 2 -> 10 -> 0
  - 5 -> 6 -> 110 -> 10
]

Elias $gamma$ codifica un intero x concatenando la lunghezza della sua rappresentazione binaria ridotta in unario con la
sua rappresentazione binaria ridotta.

#example()[
  - *Codifica di $n = 0$:* \
    Ridotta: $0 arrow.r 1 arrow.r epsilon$ \
    Lunghezza in unario ($0$ bit): $1$ \
    Codice finale: $1 space epsilon = 1$
    
  - *Codifica di $n = 1$:* \
    Ridotta: $1 arrow.r 2 arrow.r 10 arrow.r 0$ \
    Lunghezza in unario ($1$ bit): $01$ \
    Codice finale: $01 space 0 = 010$
    
  - *Codifica di $n = 2$:* \
    Ridotta: $2 arrow.r 3 arrow.r 11 arrow.r 1$ \
    Lunghezza in unario ($1$ bit): $01$ \
    Codice finale: $01 space 1 = 011$
    
  - *Codifica di $n = 3$:* \
    Ridotta: $3 arrow.r 4 arrow.r 100 arrow.r 00$ \
    Lunghezza in unario ($2$ bit): $001$ \
    Codice finale: $001 space 00 = 00100$
]

Lunghezza e costo di una parola: $lambda$ è la posizione del numero più significativo. La rappresentazione binaria ridotta è
data da $x+1$ in binario e poi butto via il bit più significativo.

Il numero in unario è data dalla lunghezza della ridotta + 1.

$
  lambda(x+1) + lambda(x+1) + 1 \
  2 lambda(x+1) + 1 \
  2 floor(log_2(x+1)) + 1 \
$

La parte in unario è istantanea per definizione. La rappresentazione binaria ridotta è istantanea in quanto non contiene 
il bit più significativo. Escludendo il bit più significativo infatti la parte ridotta non può essere prefisso di un'altra 
parola, perchè è composta da parole di lunghezza $lambda(x+1) - 1$ e quindi non può essere prefisso di un'altra parola.

Essendo formato da due parti istantanee, il codice Elias $gamma$ è istantaneo.
\
