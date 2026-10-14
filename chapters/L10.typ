#import "../template.typ": *

= Codifiche entropiche

Le tecniche di codifica entropica cercano di rappresentare una stringa usando un numero di bit vicino all'entropia del sorgente. In pratica, i simboli più frequenti costano meno, quelli rari costano di più.

Ci sono due modi principali per farlo:

- *codifica aritmetica*: si costruisce un intervallo continuo;
- *codifica asimmetrica*: si aggiorna uno stato numerico intero.

L'idea di fondo è sempre la stessa: ogni nuovo simbolo fa crescere il costo in modo proporzionale alla sua rarità.

= Codifica aritmetica

La codifica aritmetica assegna a ogni simbolo un sottointervallo di $[0,1)$.
Le ampiezze dei sottointervalli sono proporzionali alla distribuzione dei simboli che rappresentano. Fissato un ordine dell'alfabeto, il sottointervallo del simbolo $s$ è $[F(s), F(s)+p(s))$, dove $F(s)$ è la somma delle probabilità dei simboli che precedono $s$.

Ipotizziamo di voler rappresentare una sequenza $s_0, s_1, ..., s_n$.

Dato il simbolo $s_0$, con distribuzione $p(s_0)$, il suo intervallo avrà ampiezza $p(s_0)$.

Per codificare il simbolo successivo, si parte dall'intervallo corrente $I=[L,U)$, di ampiezza $w=U-L$, e lo si restringe al sottointervallo relativo al simbolo:
$
  I_s = [L + w F(s), L + w (F(s) + p(s)))
$
Quindi l'intervallo rappresenta l'intero prefisso già letto, non soltanto l'ultimo simbolo. L'operazione si ripete per ogni simbolo della sequenza.

#example()[

  Dati i simboli A e B, tali che la loro distribuzione sia rispettivamente 3/4 e 1/4, l'intervallo unitario viene diviso come segue:

  #figure()[
    #cetz.canvas({
      import cetz.draw: *

      line((0, 0), (12, 0), stroke: black)
      rect((0, 0), (9, 1), fill: blue.lighten(80%), stroke: black)
      rect((9, 0), (12, 1), fill: red.lighten(80%), stroke: black)

      content((4.5, 0.5), [$A$])
      content((10.5, 0.5), [$B$])
      content((4.5, 1.5), [$p(A)=3/4$])
      content((10.5, 1.5), [$p(B)=1/4$])
      content((0, -0.6), [$0$])
      content((9, -0.6), [$3/4$])
      content((12, -0.6), [$1$])
    })
  ]

  Rappresentiamo la sequenza A A B.

  La prima A seleziona l'intervallo $[0, 3/4)$. Per leggere il simbolo successivo, dividiamo nuovamente questo intervallo nelle proporzioni $3/4$ e $1/4$: A occupa $[0, 9/16)$, mentre B occupa $[9/16, 3/4)$.

  #figure()[
    #cetz.canvas({
      import cetz.draw: *

      line((0, 0), (12, 0), stroke: black)
      rect((0, 0), (6.75, 1), fill: blue.lighten(80%), stroke: black)
      rect((6.75, 0), (9, 1), fill: red.lighten(80%), stroke: black)
      rect((9, 0), (12, 1), fill: gray.lighten(85%), stroke: black)

      content((3.375, 0.5), [$A$])
      content((7.875, 0.5), [$B$])
      content((10.5, 0.5), [resto])
      content((0, -0.6), [$0$])
      content((6.75, -0.6), [$9/16$])
      content((9, -0.6), [$3/4$])
      content((12, -0.6), [$1$])
    })
  ]

  Scegliendo la seconda A, l'intervallo diventa $[0, 9/16)$. Al suo interno A occupa $[0, 27/64)$ e B occupa $[27/64, 9/16)$.

  #figure()[
    #cetz.canvas({
      import cetz.draw: *

      line((0, 0), (12, 0), stroke: black)
      rect((0, 0), (5.0625, 1), fill: blue.lighten(80%), stroke: black)
      rect((5.0625, 0), (6.75, 1), fill: red.lighten(80%), stroke: black)
      rect((6.75, 0), (12, 1), fill: gray.lighten(85%), stroke: black)

      content((2.53125, 0.5), [$A$])
      content((5.90625, 0.5), [$B$])
      content((9.375, 0.5), [resto])
      content((0, -0.6), [$0$])
      content((5.0625, -0.6), [$27/64$])
      content((6.75, -0.6), [$9/16$])
      content((12, -0.6), [$1$])
    })
  ]

  Per l'ultimo simbolo, B, scegliamo quindi $[27/64, 9/16)=[27/64, 36/64)$. L'ampiezza è $9/64$, proprio la probabilità della sequenza:
  $
    p(A A B) = 3/4 dot 3/4 dot 1/4 = 9/64
  $
  Qualunque numero in questo intervallo identifica la sequenza, se il decoder ne conosce la lunghezza. Per esempio, $7/16=28/64$ è interno all'intervallo e in binario si scrive $0.0111_2$.

  #figure()[
    #cetz.canvas({
      import cetz.draw: *

      line((0, 0), (12, 0), stroke: black)
      rect((0, 0), (5.0625, 1), fill: gray.lighten(85%), stroke: black)
      rect((5.0625, 0), (6.75, 1), fill: red.lighten(75%), stroke: black)
      rect((6.75, 0), (12, 1), fill: gray.lighten(85%), stroke: black)

      line((5.25, -0.2), (5.25, 1.5), stroke: blue, mark: (end: "stealth"))
      content((5.90625, 0.5), [$A A B$])
      content((5.25, 1.8), [$7/16$])
      content((0, -0.6), [$0$])
      content((5.0625, -0.6), [$27/64$])
      content((6.75, -0.6), [$9/16$])
      content((12, -0.6), [$1$])
    })
  ]
]

Dopo aver letto una sequenza $s_1, s_2, dots, s_n$, il nuovo intervallo è il risultato del restringimento progressivo della partizione iniziale. Le formule e l'esempio assumono un modello con probabilità dei simboli fissate,

Se la sequenza è $x_1, x_2, dots, x_n$, allora l'ampiezza del suo intervallo finale è:
$
  P(x_1, dots, x_n) = product_{i=1}^n p(x_i)
$

Quindi il numero di bit necessari per rappresentare l'intervallo è circa:
$
  -log_2 P(x_1, dots, x_n) = -sum_{i=1}^n log_2 p(x_i)
$

Questo è il costo informativo ideale della sequenza, espresso in bit: una codifica effettiva usa un numero intero di bit e può richiedere qualche bit aggiuntivo per terminazione e sincronizzazione.

== Costo medio e distribuzione empirica
// TODO: di sta roba non ho capito niente
// Tanto c'è la review

*GUARDA QUI C'È UN COMMENTO*

Se nella sequenza il simbolo $s$ compare $n_s$ volte, il costo ideale complessivo e il costo medio per simbolo sono:
$
  L = sum_(s in S) n_s log_2(1/p(s))
  quad
  L/n = sum_(s in S) (n_s/n) log_2(1/p(s))
$
La frequenza empirica è $q(s)=n_s/n$, quindi il costo medio è $sum_s q(s) log_2(1/p(s))$. Se il modello usa proprio le frequenze empiriche, $p(s)=q(s)$, questa quantità coincide con l'entropia empirica $H(q)=-sum_s q(s) log_2 q(s)$. Se il modello non coincide con la distribuzione osservata, il costo medio dipende da entrambe e può essere maggiore.
Più precisamente, quando $q(s)>0$ implica $p(s)>0$, vale:
$
  sum_s q(s) log_2(1/p(s)) = H(q) + D_"KL"(q || p)
$
dove $D_"KL"(q || p)=sum_s q(s) log_2(q(s)/p(s)) >= 0$ misura il costo aggiuntivo dovuto alla differenza fra modello e frequenze osservate.

== Trasmissione del codice

Al termine della codifica, il decoder deve ricevere un valore che cada nell'intervallo finale. È sufficiente trasmettere un numero diadico interno, cioè un numero rappresentabile con un numero finito di bit dopo la virgola, purché il decoder conosca anche il modello di probabilità e la lunghezza del messaggio (oppure sia presente un simbolo di fine messaggio). Nell'esempio, $7/16=0.0111_2$ appartiene a $[27/64,9/16)$ e identifica quindi `AAB`.

In generale, più l'intervallo finale è stretto, più bit servono per specificare un punto al suo interno. Questo spiega il legame fra ampiezza dell'intervallo e costo informativo.

#note()[
  Più una stringa è probabile, più grande è il suo intervallo e quindi più facile da distinguere. Più una stringa è rara, più l'intervallo è piccolo e più bit servono a identificarla.
]

#example()[
  Sia l'alfabeto ${A, B}$ con probabilità $p(A)=0.75$ e $p(B)=0.25$. Per la sequenza $A A B$ si ottiene:
  $P(A A B)=0.75 dot 0.75 dot 0.25 = 0.140625$
  quindi l'intervallo finale è molto piccolo. In generale, la probabilità totale decresce esponenzialmente con la lunghezza della stringa.
]

== Legame con l'entropia

L'entropia di un sorgente $X$ è:
$
  H(X) = -sum_{s in S} p(s) log_2 p(s)
$

Per una sorgente senza memoria descritta correttamente dal modello, il costo informativo atteso per simbolo è $H(X)$. La lunghezza di una codifica concreta si avvicina a questo valore per simbolo, con una differenza dovuta alla lunghezza finita del messaggio e alla sua terminazione.

== Decodifica della codifica aritmetica

Il decoder parte dal valore trasmesso e applica la stessa partizione usata dal codificatore:

- individua in quale sottointervallo iniziale cade il valore, ottenendo il primo simbolo;
- restringe l'intervallo a quello del simbolo e ripete l'operazione per il simbolo successivo;
- continua fino a raggiungere la lunghezza nota o il simbolo di fine messaggio.

#example()[
  Il valore trasmesso è $7/16$. Per decodificare, si cerca in quale sottointervallo di $[0,1)$ cade il valore corrente. Dopo aver scelto il simbolo, si riscalano sia l'intervallo scelto sia il valore al suo interno riportandoli a $[0,1)$: se il simbolo occupa $[F, F+p)$, il nuovo valore è $(x-F)/p$.

  Con $p(A)=3/4$ e $p(B)=1/4$, i passaggi sono:
  - $x_0=7/16$ cade nell'intervallo di A, $[0,3/4)$; riscalando si ottiene $x_1=(7/16)/(3/4)=7/12$.
  - $x_1=7/12$ cade ancora nell'intervallo di A; riscalando si ottiene $x_2=(7/12)/(3/4)=7/9$.
  - $x_2=7/9$ cade nell'intervallo di B, $[3/4,1)$, quindi il terzo simbolo è B.

  #figure(caption: [A ogni passo si individua il simbolo e si riscalano a $[0,1)$ l'intervallo selezionato e il valore.])[
    #cetz.canvas({
      import cetz.draw: *

      rect((0, 4), (9, 4.7), fill: blue.lighten(75%), stroke: black)
      rect((9, 4), (12, 4.7), fill: gray.lighten(85%), stroke: black)
      content((4.5, 4.35), [$A$])
      content((10.5, 4.35), [$B$])
      line((5.25, 5), (5.25, 4.75), stroke: blue, mark: (end: "stealth"))
      content((5.25, 5.25), [$7/16$])
      content((1, 5.25), [Passo 1])
      content((0, 3.6), [$0$])
      content((9, 3.6), [$3/4$])
      content((12, 3.6), [$1$])

      rect((0, 2), (9, 2.7), fill: blue.lighten(75%), stroke: black)
      rect((9, 2), (12, 2.7), fill: gray.lighten(85%), stroke: black)
      content((4.5, 2.35), [$A$])
      content((10.5, 2.35), [$B$])
      line((7, 3), (7, 2.75), stroke: blue, mark: (end: "stealth"))
      content((7, 3.25), [$7/12$])
      content((1, 3.25), [Passo 2])
      content((0, 1.6), [$0$])
      content((9, 1.6), [$3/4$])
      content((12, 1.6), [$1$])

      rect((0, 0), (9, 0.7), fill: gray.lighten(85%), stroke: black)
      rect((9, 0), (12, 0.7), fill: red.lighten(75%), stroke: black)
      content((4.5, 0.35), [$A$])
      content((10.5, 0.35), [$B$])
      line((9.333, 1), (9.333, 0.75), stroke: red, mark: (end: "stealth"))
      content((9.333, 1.25), [$7/9$])
      content((1, 1.25), [Passo 3])

      content((0, -0.45), [$0$])
      content((9, -0.45), [$3/4$])
      content((12, -0.45), [$1$])
    })
  ]

  Il decoder ricostruisce così `AAB`. Ma il valore $7/16$ da solo non dice che il messaggio è finito: dopo aver decodificato B si arresta perché in questo esempio conosce già la lunghezza, pari a tre simboli.
  Se la lunghezza non è nota in anticipo, il messaggio deve invece includere un simbolo speciale di fine sequenza (EOF). 
]

== Precisione finita

Tramite registri di interi a dimensione fissa (es. 32/64 bit) è possibile rappresentare intervalli sempre più piccoli solo fino ad una certa soglia. Per evitare che l'intervallo diventi troppo piccolo e perda precisione, appena i due estremi  di un intervallo iniziano con lo stesso bit (entrambi 0 nella metà inferiore o entrambi 1 nella metà superiore), quel bit è ormai definitivo: viene subito scritto sul file compresso ed eliminato dal registro. Tolto il bit certo, il registro fa uno shift a sinistra (<< 1), raddoppiando l'intervallo rimasto per riportarlo a grandezza piena e fare spazio ai simboli successivi.

Se l'intervallo si restringe a cavallo della metà (es. 0111... e 1000...), il primo bit non è ancora sicuro, ma il secondo sì. L'algoritmo scala comunque l'intervallo e accumula un contatore di "bit in sospeso", che verranno scaricati tutti insieme non appena si sblocca la prima cifra certa.

#note(title: "Modello adattivo")[
  La codifica aritmetica può essere *adattiva*: se non si conosce a priori le distribuzione dei simboli, encoder e decoder possono iniziare da iniziare da una stima delle distribuzioni oppure da distribuzione equiprobabile. Durante l'elaborazione del testo essi apprendono e aggiornano la distribuzione, rimanendo sincronizzati. In questo modo ogni simbolo viene codificato e decodificato con le stesse $p$, che diventano sempre più corrette al procedere della de/codifica.
]

= Sistemmi di numerazione asimmetrica (ANS)

La codifica ANS usa uno stato numerico intero invece di un intervallo continuo. Invece di costruire un insieme di intervalli, aggiorna un valore $x$ ogni volta che legge un nuovo simbolo.

Dato un simbolo s e l'accumulatore x, l'idea è:
$
  x' approx x / p(s)
$

perché allora
$
  log_2 x' approx log_2 x + log_2 (1/p(s))
$

Quindi ogni simbolo aggiunge un costo proporzionale a $log_2 (1/p(s))$, cioè alla sua rarità.

#figure(
  caption: [ANS: il nuovo stato dipende da quello vecchio e dal simbolo letto.],
)[
  #cetz.canvas({
    import cetz.draw: *

    rect((0, 0), (2, 1), fill: gray.lighten(70%), stroke: black)
    content((1, 0.5), [$x$])

    line((2, 0.5), (4, 0.5), stroke: black, mark: (end: "stealth"))

    rect((4, 0), (7, 1), fill: blue.lighten(70%), stroke: black)
    content((5.5, 0.5), [$x' = 2x + s$])
    content((5.5, 1.6), [se $s=0$: $x' = 2x$])
    content((5.5, 2.3), [se $s=1$: $x' = 2x + 1$])
  })
]

Nel caso binario, la regola più semplice è:
$
  x' = 2x + s
$

dove $s in {0,1}$. Questa regola illustra il caso binario equiprobabile: equivale ad aggiungere il bit $s$ in fondo alla rappresentazione binaria di $x$. Non è la formula generale di ANS e, da sola, non comprime una sorgente sbilanciata.

== Intuizione con colori e ranghi

Possiamo capire l'idea dello stato ANS colorando i numeri naturali con i simboli dell'alfabeto. Per esempio, con probabilità $p(A)=3/4$ e $p(B)=1/4$, ripetiamo il blocco di colori `A A A B`:

#figure(
  caption: [Ogni numero ha un colore; sotto è indicato il suo rango fra i numeri dello stesso colore.],
)[
  #cetz.canvas({
    import cetz.draw: *

    let colors = (
      blue.lighten(75%),
      blue.lighten(75%),
      blue.lighten(75%),
      red.lighten(75%),
      blue.lighten(75%),
      blue.lighten(75%),
      blue.lighten(75%),
      red.lighten(75%),
    )
    let symbols = ("A", "A", "A", "B", "A", "A", "A", "B")
    let ranks = ("0", "1", "2", "0", "3", "4", "5", "1")

    for i in range(8) {
      let x = i * 1.2
      rect((x, 0), (x + 1.1, 1), fill: colors.at(i), stroke: black)
      content((x + 0.55, 0.72), text(size: 9pt)[#str(i)])
      content((x + 0.55, 0.25), text(size: 10pt)[#symbols.at(i)])
      content((x + 0.55, -0.35), text(size: 8pt)[rango #ranks.at(i)])
    }
  })
]

Il *rango* di un numero $y$ è il numero di numeri più piccoli che hanno lo stesso colore di $y$. Il rango è dunque numerato a partire da zero. Per esempio:

- $y=4$ è colorato con $A$ e ha rango $3$: prima di lui ci sono tre numeri colorati con $A$ ($0, 1, 2$);
- $y=7$ è colorato con $B$ e ha rango $1$: prima di lui c'è un solo numero colorato con $B$ ($3$).

=== Formula di push e pop

Nel ciclo `A A A B`, in ogni blocco ci sono $M=4$ numeri: $f_A=3$ di colore $A$ e $f_B=1$ di colore $B$. Indichiamo con $C_s$ il numero di colori che precedono $s$ nel blocco: $C_A=0$ e $C_B=3$.

In generale, si sceglie un totale di frequenze intero $M$ e si assegna a ogni simbolo una frequenza $f_s$, con $sum_s f_s=M$. La probabilità è approssimata da $p(s) approx f_s/M$. Spesso si sceglie $M=2^d$, così alcune operazioni sullo stato si possono realizzare con shift e maschere di bit. Definendo $C_s=sum_(t<s) f_t$ secondo l'ordine scelto per i simboli, a ogni simbolo corrispondono le posizioni $[C_s,C_s+f_s)$ in ciascun blocco di $M$ numeri. Il ciclo `A A A B` è il caso $M=4$, $f_A=3$, $f_B=1$.

La funzione *push* prende lo stato/rango precedente $x$ e un simbolo $s$, e restituisce il numero $y$ che ha colore $s$ e rango $x$:
$
  op("push")(x,s) = M floor(x / f_s) + C_s + (x mod f_s)
$

La funzione *pop* fa l'inverso. Dato $y$, si scrive $y = q M + r$, con $q=floor(y/M)$ e $r=y mod M$. Il colore del blocco nella posizione $r$ determina il simbolo $s$; il rango restituisce lo stato precedente:
$
  op("pop")(y) = (s, f_s q + r - C_s)
$

In altre parole, `push` inserisce il vecchio stato nella sezione riservata al simbolo; `pop` legge il simbolo dalla sezione in cui cade il nuovo stato e recupera il vecchio rango.

Questa costruzione usa frequenze intere, quindi la distribuzione effettivamente codificata è $f_s/M$: se non coincide con quella desiderata, introduce un errore di quantizzazione. Aumentare $M$ permette in genere un'approssimazione più precisa, ma richiede intervalli di stato e tabelle più grandi.

#example()[
  Per illustrare il funzionamento, partiamo dallo stato iniziale $x_0=8$, che funge da soglia di normalizzazione. Quindi il primo rango da codificare è *8*, non 0. Usiamo il ciclo di colori `A A A B` e codifichiamo `ABB`:

  - $op("push")(8,A)=4 floor(8/3) + 0 + (8 mod 3)=10$;
  - $op("push")(10,B)=4 floor(10/1) + 3 + (10 mod 1)=43$;
  - $op("push")(43,B)=4 floor(43/1) + 3 + (43 mod 1)=175$.

  Quindi lo stato finale è $175$. Facendo pop:

  - $op("pop")(175)=(B,43)$;
  - $op("pop")(43)=(B,10)$;
  - $op("pop")(10)=(A,8)$.

  La decodifica recupera i simboli nell'ordine inverso, `BBA`, e risale fino allo stato iniziale $8$. Invertendo l'ordine dei simboli si ritrova la stringa codificata `ABB`.
]

Lo stato cresce perché `push` cerca il numero con il rango richiesto fra quelli del colore scelto. In questo esempio:
$
  op("push")(x,A) approx x / p(A) = 4x/3
  quad
  op("push")(x,B) approx x / p(B) = 4x
$

Il fattore di crescita è quindi circa $1/p(s)$; in termini di informazione, l'aumento del logaritmo dello stato è circa $log_2(1/p(s))$. I simboli frequenti fanno crescere lo stato meno di quelli rari, e richiedono quindi meno bit.

#note(title: "Stato iniziale")[
  In questo esempio partiamo da $x_0=8$: è lo stato iniziale (o soglia inferiore di normalizzazione), non il rango zero. Nelle implementazioni pratiche si sceglie spesso una soglia comoda, per esempio una potenza di due; il valore preciso dipende dalla variante ANS e dalla sua normalizzazione. Il ciclo di colori qui sopra serve a illustrare l'idea, non è una regola universale per inizializzare ogni codificatore ANS.
]

#note()[
  Questo modello con colori e ranghi è un modo intuitivo di vedere la corrispondenza reversibile fra coppia (stato precedente, simbolo) e nuovo stato. Un ANS pratico realizza una mappatura analoga usando frequenze intere e, di solito, operazioni di rinormalizzazione; il semplice ciclo periodico è un esempio didattico, non un'implementazione completa.
]

=== Modello e rinormalizzazione

Il codificatore e il decodificatore devono usare gli stessi $f_s$, lo stesso ordine dei simboli e gli stessi valori cumulativi $C_s$. La tabella può essere fissata a priori oppure costruita dal messaggio: in quest'ultimo caso deve essere trasmessa o ricostruibile dal decoder, e i bit necessari a descriverla fanno parte del costo totale della compressione.

Le formule di `push` e `pop` descrivono la mappatura reversibile, ma da sole non limitano la dimensione dello stato, che cresce con i simboli codificati. Un'implementazione pratica mantiene lo stato in un intervallo numerico gestibile: quando supera la soglia prevista dalla variante, trasferisce bit fra lo stato e un flusso ausiliario; durante la decodifica quei bit vengono reinseriti in modo inverso e coordinato. Questa *rinormalizzazione* consente di usare registri a dimensione finita e non cambia la corrispondenza fra stato, simbolo e rango. I dettagli dipendono dalla variante ANS, per esempio rANS o tANS.

== Decodifica

In generale, la decodifica ANS inverte la codifica: dal nuovo stato determina il simbolo associato e il rango di quel simbolo, che restituisce lo stato precedente. Con i colori e ranghi appena definiti, questa è esattamente l'operazione `pop`. Nel caso binario equiprobabile $x'=2x+s$, invece, si riduce a:

- si recupera il simbolo con $s = x' mod 2$;
- si recupera lo stato precedente con $x = floor(x'/2)$.

La decodifica restituisce i simboli in ordine inverso rispetto alle operazioni di push. Per ricostruire la stringa nell'ordine originale, si inverte l'ordine dei simboli decodificati oppure si codifica e decodifica secondo la convenzione scelta dall'implementazione.

Per sapere quando fermarsi, il decoder deve conoscere la lunghezza della sequenza oppure incontrare un simbolo speciale di fine messaggio. Il solo stato intero non distingue sempre una sequenza vuota da una sequenza che ha raggiunto lo stesso stato dopo un push.


=== Old

#import "../template.typ": *

= Codifica aritmetica

Se abbiamo una sequenza di solito abbiamo una distribuzione empirica (non sempre è cosi). Possiamo andare a calcolare l'entropia empirica della sequenza e quindi la lunghezza minima di bit per codificare la sequenza. La codifica aritmetica ci permette di arrivare a questa lunghezza minima.
$
  log 1 / p_"si"
$
entropia della codifica del singolo simbolo. Se la probabiià della sequenza è P, allora la lunghezza minima di bit per codificare la sequenza è
$
  log 1 / P = sum_(i=1)^n log 1 / p_"si"
$

L'intervallo si restringe ogni volta in base alla probabilità del simbolo che stiamo codificando.

== Trasmissione

per trasmettere la sequenza basta trasmettere un diadico all'interno dell'intervallo finale. Conoscendo un punto dell'intervallo, conosiamo anche l'intervallo finale.

Data una sequenza $S$, possiamo riscrivere il costo come:
$
  (sum_(s in S) "#s" 1 /p_"s") / n
$
ma la cardinalità di s fratto n è letteralmente la probabilità empirica del simbolo s. Quindi se la distribuzione effettiva della sorgente è la stessa della distribuzione empirica, allora il costo medio per simbolo è l'entropia della sorgente (si semplifica nella formula sopra).




== Decodifica

Dato un punto nell'intervallo unitario (un diadico). L'ide è quel quel diadico attraversa la scalatura dei vari intervalli, partendo da quello più piccolo possiamo risalire alla sequenxza degli intervalli originali.

//rgiaurdare e completare. Aggiungere un immagine che mostra la figura non scalata e mostra il punto dell'intervallo originario che denota intervallo diversi

#note()[
  Al momento supponiamo di conoscere la distribuzione dei simboli. In realtà possiamo partire da una distribuzione uniforme e aggiornare la distribuzione dei simboli man mano che decodifichiamo e codifichiamo, fino a convergere all'entropia.
]

== Codifica in pratica

Gli estremi dell'intervallo vengono approssimati in interi a dimensione fissa. Quando i bit significativi dei due estremi coincidono non potranno più cambiare. Possiamo quindi emettere quei bit e scalare l'intervallo. In questo modo man mano che l'intervallo diventa più piccolo, possiamo emettere bit e scalare l'intervallo. In questo modo non abbiamo bisogno di una precisione infinita.

Siccome è richiesta una divisione nella fase di decodifica questa rappresentazione è molto più lenta di un codice istantaneo.

= Sistmea di numerazione aritmetica

Codifichiamo la sequenza con un intero molto grande $X$ (a differenza della codifica aritmetica che aveva un intervallo piccolo). Aggiungendo un simbolo $s$ di probabiità $p_s$ vorremmo ottenere:
$
  x^' approx x / p_s
$
In questo modo i bit che servono per specificare la nuova sequenza è dato dal logaritmo della vecchia sequenza più il logaritmo della probabilità del simbolo che stiamo aggiungendo. Quindi la lunghezza della sequenza codificata è data dalla somma dei logaritmi delle probabilità dei simboli che è esattamente l'entropia della sequenza.

=== Caso banale

Se $x$ è la codifica dei simboli visti fino ad ora, allora aggiungendo s otteniamo:
$
  x^' = 2x+s
$
ogni volta che arriva un bit moltilica per 2 e aggiunge il bit che arriva. Il risultato è l'intero che in base 2 è descritto dalla sequenza.

Per decodificare x' l'ultimo simbolo è x^' mod 2, la sequenza rimane $x^' / 2$.


#note()[
  ANS non è in grado di codificare e decodificare nella stessa direzione, decodifica al contrario.
]

Il rango si ricorda il numero di pari o dispari precedenti (sempre numero di diviso 2), il colore s è l'ultima cifra binario mod 2.

//aggiugere esempio con immagine

=== COlorazione assimetrica

I simboli più frequenti si prendono più colore. L'idea è che coloriamo i colori in modo che il colore $s$ occupi una frazione $p_s$.

Fissaimo una precisione $d$ e approssimiamo ogni probabilità con $p_s approx f_s/2^d$ darà un errore di approssimazione, ma con un d grande possiamo rendere l'errore trascurabile.

Sia c_s la cumulativa, essa mi servira per capire un intero in che blocco sta.

#example()[
  Da 0 a 8 divido gli interi inmodo proporzionale alla probabilità dei simboli. ora ho tante a un po di b e pochisseme c. Tutti gli interi sono divisi in blocchi da 2^8. Ogni blocco lo colore in modo proporzionale alla probabilità dei simboli.

  I ranghi crescono in base al blocco di a, nell'immagine c cresce di 1 alla volta.

  Quando dobbiamo codificare c dobbiamo prendere un inter molto grande in quanto il ranfo di c è cresce molto in fretta.

  C ci costa 5 volte tanto quanto a quando codifichiamo un elemento di ordine c.
]

il naturale di colore $s$ di rango $x$ è dato dat:
- si trova il blocco di indice $floor(x / f_s)$
- è il naturale di colore $s$ di rango $x mod f_s$ all'interno del blocco.
- cioè si trova in posizione $c_s + x mod f_s$

Per le devisioni le possiamo fare in modo che siano precomputate

Per tornare indietro. Il colore di $x$ è dato da $s = "sym"(x mod 2^d)$ (in questo modo trovo il simbolo, ovvero a). Devo ora trovare lo stato precedente: I naturali di colore $s$ che precedono $x$ sono:
- f_s per ognuno dei $x>>d$ blocchi precedenti
- più degli $x mod 2^d-c_s$ che lo precedono nel suo blocco.

=== Dettagli implementativi

Quando butto via i bit, vado a perdere man mano la precisione.

#warning()[
  In questo caso non possiamo più appredere la distribuzione ma dobbiamo conoscere la distribuzione. Dobbiamo salvarci i dati ancillari di un blocco (f_s) da qualche parte. Se essi occupano troppo spazio vanno a intaccare la rappresentazione dei codici. La soluzione è usare delle tecniche di packing per gli f_s
]

