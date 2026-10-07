#import "../template.typ": *

== Teorema di kraft

#theorem()[
  Permette di dire se un codice è istantaneo o meno. Essao afferma che se $C$ è istantaneo *allora* la somma di tutte le lunghezze
  dei codici deve essere minore o uguale a 1 (Disuguaglianza di Kraft).
  In formula:
  $
    C "ist" -> sum_(w in C) 2^(-|w|) <= 1
  $

  #warning()[

    Se eccediamo il budget allora il codice è sicuramente non istantaneo. Se invece siamo sotto il budget allora il codice potrebbe essere istantaneo oppure no, non possiamo dirlo. In questo caso dobbiamo guardare le parole.

    $
      "Se" sum_(w in C) 2^(-|w|) > 1 -> C "non ist"
    $
  ]

  Se $C$ è istantaneo, è anche completo *se e solo se* la somma di tutte le lunghezze dei codici è esattamente 1.
  In formula:
  $
    C "completo" <-> sum_(w in C) 2^(-|w|) = 1
  $

  Ogni parola consuma dello spazio che è $2^(-|w|)$ parole corte consumano meno spazio e parole lunghe di più. L'idea è che
  ogni parola consuma un certo budget, dobbiamo rimanere sotto il budget di 1. Se superiamo il budget allora il codice non
  è istantaneo.

]

#theorem()[
  Inoltre, data una sequenza $t_0, t_1, t_2, \t_3dots$ di lunghezze (eventualmente infinita), che soddisfa la disuguaglianza
  di Kraft

  $
    sum_(n) 2^(-t_n) <= 1
  $

  allora esiste un codice istantaneo formato da parole $w_0, w_1, w_2, \w_3dots$ dove $|w_i| = t_i$.

]

Si può dedurre informalmente è che, dato un codice che soddisfa la disuguaglianza di Kraft, se esso non è istantaneo, allora è possibile costruire un codice istantaneo con quelle lunghezze, manipolando alcuni bit.

#note()[
  Visualizziamo il codice in un intervallo unitario $[0...1)$. Ogni parola consuma dello spazio che è $2^(-|w|)$:parole corte consumano meno spazio e parole lunghe
  di più.

  L'idea è che ogni parola consumi un certo budget, dobbiamo rimanere sotto il budget di 1. Se superiamo il budget allora il codice non è istantaneo.

  Associamo ad ogni parola un determinato intervallo e ogni volta lo spezziamo in due parti. La parola vuota è l'intervallo unitario $[0...1)$.\
  Quando aggiungiamo una parola $w$, chiamiamo $x$ la parola $w$ privata dell'ultimo carattere.

  Se $x$ ha come intervallo $[a...b)$, allora $w$ avrà come intervallo:
  $
    & [a, (a+b)/2) "se" w = x 0 \
    & [(a+b)/2, b) "se" w = x 1 \
  $

  #align(center)[
    #cetz.canvas({
      import cetz.draw: *

      // L rappresenta la larghezza totale del disegno (12 unità)
      let L = 12

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

  Possiamo vederlo anche come un albero binario dove, per ogni livello, tutte le parole occupano lo stesso spazio.\

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
        spread: 1, // Aumenta la distanza orizzontale tra i nodi
        grow: 1.5, // Aumenta la distanza verticale tra i livelli
        name: "tree",
      )
    })
  ]
]

#note()[
  Consideriamo $x$ e $y$ due parole binarie e i loro intervalli $I(x)$ e $I(y)$.

  La relazione di prefisso diventa la relazione di inclusione tra intervalli, formalmente:

  $x <= y -> I(x) supset.eq I(y)$.

  Se x è un prefisso di y allora l'intervallo di x contiene l'intervallo di y.
  Siccome le parole lunghe cosumano più spazio allora il loro intervallo è più piccolo.

  Se $x$ e $y$ sono inconfrontabili allora i loro intervalli sono disgiunti $I(x) inter I(y)$.

  Questo è intuitivo se si pensa a due parole inconfrontabili come un prefisso comune ($epsilon$ nel caso base) seguite da un bit diverso, e si immagina la costruzione
  tramite B tree. A partire dal bit diverso, le due parole si diramano e quindi i loro intervalli non si intersecano più.

  In formula:
  $
    exists z in Z^* "t.c" x = z 0 x^', y = z 1 y^'
  $

  #example()[

    Consideriamo le parole $x = 010$ e $y = 011$. Il loro prefisso comune z è $01$.
    Quindi possiamo scrivere $x = z 0 x^' = 01 0 epsilon$ e $y = z 1 y^' = 01 1 epsilon$.

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
              text(fill: red)[01],
              (text(fill: red)[010]),
              (text(fill: red)[011]),
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

    I loro intervalli sono $I(x) = [2/8, 3/8)$ e $I(y) = [3/8, 4/8)$, che sono
    disgiunti, e sono inclusi nell'intervallo del prefisso comune $I(z) = [2/4, 3/4)$.

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

]

#proof()[
  Dimostro la prima parte del teorema di Kraft, cioè che se un codice è istantaneo allora la somma di tutte le lunghezze dei codici deve essere minore o uguale a 1. In formula:
  $
    C "ist" -> sum_(w in c) 2^(-|w|) <= 1
  $

  Se la sommatoria è < di 1, significa che nell'intervallo unitario c'è ancora
  spazio libero $[k 2^{-h}...(k + 1) 2^{-h})$, per qualche h e k.
  Di conseguenza, posso sicuramente aggiungere una parola di lunghezza h senza violare
  l'istantaneità, dato che l'intervallo per quella parola è libero e disgiunto da
  tutti gli altri intervalli.

  Consideriamo la seguente contronominale: 
  se la somma di tutte le lunghezze dei codici è diversa da 1 allora il codice non è completo. In formula:
  $
    sum_(w in C) 2^(-|w|) != 1 -> C "non completo"
  $
  Se c'è spazio libero, allora il codice è necessariamente non completo, perché posso aggiungere una parola senza 
  violare l'istantaneità. Quindi se la sommatoria è < di 1 allora il codice non è completo.
]

#proof()[
  // Luca qui non ho capito che cosa stai dicendo quindi vedi tu
  Se riesco a trovare due diadici consecutivi che comprendono l'intervallo per scrivere la parola $j$ posso prendere quella parola.

  la parola che $j$ rappresenta su $k$ bit allora ottengo esattamente un intervallo che parte da $j(2^k)$ e arriva esattamente a $(j+1)(2^k)$. Se riesxo a trovare due diadici consecutivi che comprono l'intervallo per scrivere la parola $j$ posso prendere quella parola.
  //riguardare e aggiungere esempio

]

=== inversione della disequaglianza di Kraft

Supponiamo di avere dei valori crescenti di lunghezza $l_1 < l_2 < ... < l_n$ e vogliamo costruire un codice istantaneo con queste lunghezze. Allora se la somma di tutte le lunghezze dei codici è minore o uguale a 1 allora possiamo costruire un codice istantaneo con queste lunghezze.

#note()[
  Non è una vera e propria inversione della disequaglianza di Kraft, perché non posso dire con certezza che il codice costruito sia istantaneo, ma l'errore non è nelle lunghezze scelte ma nella scelta dei bit associati a quelle lunghezze.
]

#proof()[
  $d_0 = 1 / 2^(t_0)$ si tratta di un diagono di ordine zero, questo intervallo rappresenta la parola vuota (tutti 0).

  il diacono consecutivo è per una parola di lunghezza t_i,vogliamo trovare il seguente intervallo:
  $
    k / 2^(t_i), dots , (k+1) / 2^(t_i)
  $
  la vera domanda è che vogliamo riscrivere $d = d/2^t_i$ come un diadico di ordine $t_i+1$, per farlo:
  $
    d = 2/2^(t_i) =
  $

  Possiamo sempre scegliere l'intervallo consecutivo in quanto possiamo interpretare il diadico con qui abbiamo appena finito come il diadico di ordine successivo.
  //add example
  #example()[
    Se devo rappresntare parole di lunghezza 1, 3, 3, 5. Allora la prima parola di lunghezza 1 è 0, uso 1/2 come intervallo. La seconda parola di lunghezza 3 è 100, uso 4/8 -> 5/8 come intervallo. La terza parola di lunghezza 3 è 101, uso 5/8 come intervallo. La quarta parola di lunghezza 5 è 10100, uso 20/32 come intervallo.
  ]

]

== Codici istantanei

=== Codice binario
Un codice binario di ampiezza $k$ è istantaneo e ogni parola ha la stessa lunghezza $k$. In questo caso la lunghezza di parole è $2^k$. Se tutti i simboli hanno la stessa frequenza allora il codice binario è ottimale.\

=== Codice unario

Abbiamo due codice $0^* 1$ e $1^* 0$.
Il codice $1^* 0$ ha un unario lessicografico, l'ordine tra le parole corrisponde all'ordine tra gli interi intesi. Se $x <= y -> 1^x 0 <= 1^y 0$

Lessicografico vuol dire che l'ordine tra le parole corrisponde all'ordine tra gli interi intesi. Se $x <= y -> 1^x 0 <= 1^y 0$. In questo caso fermo il confronto tra due parole alla prima differenza tra i due bit. Se il primo bit diverso è 0 allora la parola è minore, se il primo bit diverso è 1 allora la parola è maggiore.\

#note()[
  Questo codice unario viene usato da UTF-8 per rappresentare i caratteri.
]

Con il prino non è vero, perche 0 -> 1, 1 -> 01 cioè 0 < 1 ma 1 > 01. Quindi il codice unario non è lessicografico.

Tutte le cpu hanno delle istruzioni per trovare il primo bit a 1, se usiamo la prima codifica allora possiamo trovare il primo bit a 1 e quindi trovare la lunghezza della parola. Se usiamo la seconda codifica allora non possiamo trovare la lunghezza della parola, dobbiamo prima invertire la parola e poi trovare il primo bit a 1. Quindi la prima codifica è più efficiente della seconda.

il problema è che se voglio rappresentare un numero $k$ allora mi servono $k+1$ bit. Quindi per $k$ piccoli va bene, altrimenti no.

=== Codice elias gamma

Il numero viene scritto in binario e davanti ci metto in unario la lunghezza della parola. Dato un $x >= 0$ lo incrementiamo di 1 $x+1$, a questo punto buttiamo via il bit più significiativo.
#example()[
  - 5 -> 6 -> 110 -> 10
  - 0 -> 1 -> 1 -> $epsilon$
  1 -> 2 -> 10 -> 0
]
questa rappresentazione di chiama *codifica unaria ridotta*. Il codice è costruito cosi:
$
  0 -> 1 -> epsilon -> 1 epsilon = 1\
  1 -> 2 -> 10 -> 0 -> 010 = 010\
  2 -> 3 -> 11 -> 1 -> 011 = 011\
  3 -> 4 -> 100 -> 00 -> 001 00
$

Lunghezza e costo di una parola: lambda è la posizione del numero più significativo. La ridotta è data da $x+1$ in binario e poi butto via il bit più significativo. Il numero in unario è data dalla lunghezza della ridotta + 1 (mi serve un bit in più in unario)
$
  lambda(x+1) + lambda(x+1) + 1 \
  2 lambda(x+1) + 1 \
  2 floor(log_2(x+1)) + 1 \
$

Si tratta di un codice istantaneo, in quanto la parte dell'unaria è ovviamente istantanea e la parte ridotta è istantanea in quanto non contiene il bit più significativo.Escludendo il bit più significativo, la parte ridotta non può essere prefisso di un'altra parola, la parte ridotta è composta da parole di lunghezza $lambda(x+1) - 1$ e quindi non può essere prefisso di un'altra parola.\
