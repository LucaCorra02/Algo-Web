#import "../template.typ": *

#let c-g = rgb("#bfdbfe")      
#let c-h = rgb("#fed7aa")      
#let c-c = rgb("#e9d5ff")      
#let c-new = rgb("#fde68a")    
#let c-free = rgb("#bbf7d0")  

#let col-nodo(s) = if s == "foglia" { c-new } else if s == "rimosso" { luma(225) } else if s == "libero" { c-free } else if s == "chiave" { c-g } else { white }

#let grafo(nodi, lati, w: 10.2cm, h: 1.9cm) = {
  let r = 0.4cm
  box(width: w, height: h, {
    for l in lati {
      let a = nodi.at(l.at(0))
      let b = nodi.at(l.at(1))
      let et = l.at(2, default: "")
      let st = l.at(3, default: "att")
      let tr = if st == "rem" { (paint: luma(170), thickness: 1.1pt, dash: "dashed") } else { (paint: black, thickness: 1.4pt) }
      place(top + left, line(start: (a.at(1), a.at(2)), end: (b.at(1), b.at(2)), stroke: tr))
      if et != "" {
        place(top + left,
          dx: (a.at(1) + b.at(1)) / 2 - 0.7cm,
          dy: (a.at(2) + b.at(2)) / 2 - 0.5cm,
          box(width: 1.4cm, align(center, text(size: 7pt, fill: if st == "rem" { luma(150) } else { black })[#et])))
      }
    }
    for n in nodi {
      place(top + left, dx: n.at(1) - r, dy: n.at(2) - r,
        circle(radius: r, inset: 0pt, fill: col-nodo(n.at(3, default: "norm")), stroke: 1pt,
          align(center + horizon, text(size: 8pt)[#n.at(0)])))
    }
  })
}

#let vettore(vals, evid: (), w: 1.15cm) = {
  let n = vals.len()
  grid(
    columns: (w,) * n,
    rows: (0.45cm, 0.65cm),
    ..range(n).map(i => align(center + horizon, text(size: 7.5pt, fill: luma(110))[#i])),
    ..range(n).map(i => {
      let e = evid.find(e => e.at(0) == i)
      rect(width: 100%, height: 100%, inset: 0pt, stroke: 0.8pt,
        fill: if e == none { white } else { e.at(1) },
        align(center + horizon, text(size: 9pt, font: ("DejaVu Sans Mono", "Liberation Mono"), vals.at(i))))
    }),
  )
}

#let pila(items) = box(height: 2.3cm, width: 3.3cm,
  align(bottom + center, stack(dir: btt, spacing: 1pt,
    ..items.map(it => rect(width: 3.1cm, height: 0.45cm, inset: 2pt, stroke: 0.7pt, fill: luma(245),
      align(center + horizon, text(size: 8pt, it)))),
    text(size: 7pt, fill: luma(110))[pila (cima in alto)])))

#let passo(titolo, desc, g, p) = block(breakable: false, above: 1.2em, {
  [*#titolo* #desc]
  v(2pt)
  grid(columns: (auto, auto), column-gutter: 0.8cm, align: bottom, g, pila(p))
})


#let es-nodi(stati) = {
  let xs = (0.7cm, 2.5cm, 4.3cm, 6.1cm, 9.4cm, 7.9cm)
  range(6).map(i => ($v_#i$, xs.at(i), 0.95cm, stati.at(i)))
}
#let es-lati(st) = (
  (0, 1, "cane", st.at(0)),
  (1, 2, "gatto", st.at(1)),
  (2, 3, "topo", st.at(2)),
  (3, 5, "ape", st.at(3)),
)
#let riquadro(body, fill: white) = rect(inset: 6pt, radius: 3pt, stroke: 0.8pt, fill: fill, body)


= Introduzione e Obiettivo: Funzioni Statiche vs Dizionari

Il nostro obiettivo è mappare i termini nel loro rango per poter risolvere le interrogazioni in modo efficiente. Utilizzare una tabella di hash tradizionale occuperebbe troppo spazio. 

Lo scopo principale è costruire strutture dati che memorizzino questa mappa *senza memorizzare le chiavi*. Esiste una differenza fondamentale:
- *Memorizzare una funzione* è diverso da *memorizzare un dizionario*.
- Il *dizionario* può dirci se la chiave è presente o meno nell'insieme.
- La *funzione statica* ha il solo scopo di restituire il valore associato per gli elementi appartenenti all'insieme; se interroghiamo la struttura con una chiave esterna all'insieme, il risultato è del tutto imprevedibile.

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    align: center + horizon,
    inset: 6pt,
    [], [*Funzione statica*], [*Dizionario*],
    [Interrogo con $x in X$], [restituisce $f(x)$], [restituisce $f(x)$],
    [Interrogo con $z in.not X$], [restituisce un valore *qualsiasi* (imprevedibile)], [risponde "non presente"],
  ),
  caption: [Differenza di comportamento tra funzione statica e dizionario.],
)

== Rappresentazione di una funzione statica
Supponiamo di avere $x in U$ e una funzione $f : X -> 2^b$. Vogliamo costruire una struttura dati statica (chiamata così perché dipende interamente da $f$). Questa funzione possiede un metodo `get` che, dato un elemento dell'universo $U$, restituisce un vettore di bit.

Se interroghiamo la struttura su un elemento $x$, il risultato deve essere $f(x)$, mentre non ci interessa il comportamento sul resto di $U$. Questo ci svincola dal dover memorizzare l'intero insieme $X$. 

#figure(
  grid(columns: (auto, auto, auto), column-gutter: 0.5cm, align: horizon + center,
    rect(width: 5.8cm, height: 3.3cm, radius: 4pt, stroke: 1pt, inset: 0pt, {
      place(top + left, dx: 0.2cm, dy: 0.12cm, text(size: 9pt)[$U$ (universo, enorme)])
      place(top + left, dx: 0.5cm, dy: 0.8cm,
        ellipse(width: 3cm, height: 2cm, fill: c-g, stroke: 1pt)[$X$ \ ($n$ chiavi)])
      place(top + left, dx: 4.0cm, dy: 1.9cm, text(size: 9pt)[$z in.not X$])
    }),
    stack(spacing: 3pt, text(size: 9pt)[$f$], $-->$),
    riquadro[$2^b$ \ #text(size: 9pt)[(valori di $b$ bit)]],
  ),
  caption: [La funzione $f$ è definita solo sulle $n$ chiavi di $X$; sul resto di $U$ non ci interessa cosa risponde.],
)

- Spazio teorico minimo: $log((|U|)/(|X|))$
- Spazio per l'output: $|X| b$

L'obiettivo è eliminare il termine dipendente da $|U|$ (che è molto grande) evitando di memorizzare esplicitamente l'insieme $X$.

== Utilizzo pratico
Ponendo $b = log(|T|)$, possiamo mappare ogni termine nel suo rango utilizzando $|T| log(|T|)$ bit.

= Costruzione della Funzione Statica (Sistemi Lineari e XOR)

L'idea per costruire la funzione è utilizzare un insieme di funzioni hash aleatorie. Vogliamo spendere in memoria solo i bit strettamente necessari per l'output.

Prendiamo due funzioni hash aleatorie che mappano dall'universo $U$ a un intero $m$ fissato, tale che $m > |X|$ (con $n$ chiavi):
- $g : U -> m$
- $h : U -> m$

Scriviamo il sistema aleatorio utilizzando il gruppo abeliano dato dallo XOR bit a bit (in $ZZ_2$, dove non servono coefficienti numerici oltre a $0$ e $1$):

$ v_(g(x)) xor v_(h(x)) = f(x) quad forall x in X $

Prendiamo la variabile $v$ indicizzata da $g(x)$ e quella indicizzata da $h(x)$, imponendo che il loro XOR dia la costante $f(x)$. A sinistra abbiamo le variabili, a destra la costante.

La struttura finale consisterà in:
1. Le due funzioni hash $g$ e $h$.
2. Un vettore di $m$ bit (la soluzione del sistema).

Per calcolare $f(x)$, prendiamo $g(x)$ e $h(x)$, guardiamo le posizioni corrispondenti nel vettore di bit e facciamo lo XOR tra di loro. Lo XOR può teoricamente fallire, ma esistono tecniche specifiche per risolverlo. Il vettore occupa $m b$ bit; l'obiettivo è ridurre $m$ affinché sia il più vicino possibile a $n$.

#note()[
  Dato che si tratta di una funzione statica, se interroghiamo la struttura con una chiave $z in.not X$, il risultato sarà imprevedibile. La struttura garantisce il comportamento corretto solo con la promessa che $x in X$. Se mantenuta in cache, questa struttura è nettamente più veloce di una tabella di hash per memorizzare associazioni chiave-valore.
]

=== Esempio guidato: interrogare la struttura

Vediamo come si *usa* la struttura, ipotizzando di averla già costruita (come si costruisce lo vedremo nelle sezioni successive). Prendiamo:
- $X = \{$cane, gatto, topo, ape$\}$, quindi $n = 4$;
- il rango di ciascun termine è un numero da $0$ a $3$, quindi bastano $b = 2$ bit;
- $m = 6$ variabili, ciascuna da $2$ bit.

Le funzioni hash aleatorie $g$ e $h$ danno questi valori (sono numeri da $0$ a $m - 1 = 5$):

#figure(
  table(
    columns: 5,
    align: center,
    inset: 5pt,
    [*Chiave $x$*], [*$g(x)$*], [*$h(x)$*], [*$f(x)$ (rango)*], [*$f(x)$ in binario*],
    [cane], [0], [1], [1], [`01`],
    [gatto], [1], [2], [0], [`00`],
    [topo], [2], [3], [3], [`11`],
    [ape], [3], [5], [2], [`10`],
  ),
  caption: [Dati dell'esempio: ogni chiave "punta" a due posizioni del vettore.],
)

La struttura *non* memorizza questa tabella: memorizza solo le due funzioni hash e il vettore $v$ (la soluzione del sistema):

#figure(
  vettore(("10", "11", "11", "00", "00", "10")),
  caption: [Il vettore $v$: $m = 6$ celle da $b = 2$ bit. Totale: $6 dot 2 = 12$ bit per mappare $4$ chiavi.],
)

Per rispondere a `get`$(x)$ si procede in tre passi: *(1)* si calcolano $g(x)$ e $h(x)$; *(2)* si leggono le due celle corrispondenti di $v$; *(3)* si fa lo XOR bit a bit dei due valori.

*Query "gatto"*: $g = 1$, $h = 2$. Si leggono $v_1 = $ `11` e $v_2 = $ `11`:
$ v_1 xor v_2 = 11 xor 11 = 00 = 0 quad checkmark $

*Query "cane"*: $g = 0$, $h = 1$. Si leggono $v_0 = $ `10` e $v_1 = $ `11`:
$ v_0 xor v_1 = 10 xor 11 = 01 = 1 quad checkmark $
(XOR bit a bit: bit alto $1 xor 1 = 0$, bit basso $0 xor 1 = 1$.)

*Query "topo"*: $v_2 xor v_3 = 11 xor 00 = 11 = 3$ #sym.checkmark. *Query "ape"*: $v_3 xor v_5 = 00 xor 10 = 10 = 2$ #sym.checkmark.

#figure(
  grid(columns: (2.3cm, auto), column-gutter: 0.4cm, row-gutter: 0.3cm, align: left + horizon,
    [cane #text(size: 8pt)[(0, 1)]], vettore(("10", "11", "11", "00", "00", "10"), evid: ((0, c-g), (1, c-h))),
    [gatto #text(size: 8pt)[(1, 2)]], vettore(("10", "11", "11", "00", "00", "10"), evid: ((1, c-g), (2, c-h))),
    [topo #text(size: 8pt)[(2, 3)]], vettore(("10", "11", "11", "00", "00", "10"), evid: ((2, c-g), (3, c-h))),
    [ape #text(size: 8pt)[(3, 5)]], vettore(("10", "11", "11", "00", "00", "10"), evid: ((3, c-g), (5, c-h))),
    [*pippo* #text(size: 8pt)[(0, 4)]], vettore(("10", "11", "11", "00", "00", "10"), evid: ((0, c-g), (4, c-h))),
  ),
  caption: [Per ogni chiave si leggono due celle ($g(x)$ in azzurro, $h(x)$ in arancio) e se ne fa lo XOR. L'ultima riga è una chiave *non* in $X$.],
)

#warning()[
  *Chiave estranea:* con $x = $ "pippo" supponiamo $g = 0$ e $h = 4$. Si ottiene $v_0 xor v_4 = 10 xor 00 = 10 = 2$: la struttura risponde "rango $2$" (che è il rango di "ape") *senza segnalare alcun errore*. Una funzione statica non ha modo di accorgersi che la chiave non appartiene a $X$.
]

= Risolubilità del Sistema e Teoria dei Grafi

Perché il sistema è risolvibile? Se $m$ è abbastanza grande, il sistema ammette soluzione. 

Possiamo visualizzare il sistema come un grafo con $m$ nodi (variabili) in cui ogni chiave rappresenta un collegamento (lato) tra due nodi. Costruiamo il grafo inserendo tutte le chiavi.

#example()[
  *Esempio di grafo associato a un sistema lineare:*
  Siano $X = \{k_1, k_2, k_3\}$ tre chiavi e $m = 4$ variabili nel vettore ($v_1, v_2, v_3, v_4$). Supponiamo che le funzioni hash associno:
  - $k_1 -> g(k_1)=1, quad h(k_1)=2 -> v_1 xor v_2 = f(k_1)$
  - $k_2 -> g(k_2)=2, quad h(k_2)=3 -> v_2 xor v_3 = f(k_2)$
  - $k_3 -> g(k_3)=1, quad h(k_3)=3 -> v_1 xor v_3 = f(k_3)$
  
  Nel grafo corrispondente, i nodi sono $\{1, 2, 3, 4\}$ e i lati sono i collegamenti $\{1,2\}$, $\{2,3\}$ e $\{1,3\}$. Il nodo $4$ risulta isolato (variabile libera).
]

#figure(
  grafo(
    (($v_1$, 0.9cm, 0.7cm, "norm"), ($v_2$, 3.5cm, 0.7cm, "norm"), ($v_3$, 2.2cm, 2.5cm, "norm"), ($v_4$, 5.5cm, 1.6cm, "libero")),
    ((0, 1, $k_1$), (1, 2, $k_2$), (0, 2, $k_3$)),
    w: 6.4cm, h: 3.1cm),
  caption: [Il grafo dell'esempio: ogni chiave è un lato. I tre lati formano un *ciclo* ($v_1, v_2, v_3$); $v_4$ (verde) è isolato.],
)

#note()[
  *Perché un ciclo può essere un problema.* Sommando (XOR) le tre equazioni del triangolo ogni variabile compare due volte e sparisce: resta $0 = f(k_1) xor f(k_2) xor f(k_3)$. Il sistema è risolvibile solo se i valori di $f$ rispettano per caso questa relazione, cosa che in generale non possiamo garantire. Un grafo *senza cicli* (una foresta) non ha questo problema.
]

== L'Esfoliazione (Peeling)
L'idea consiste nel rimuovere iterativamente le foglie dal grafo (vertici con grado $<= 1$). La foglia non compare in nessun'altra equazione, quindi la rimuoviamo mettendo da parte la chiave corrispondente in una pila. Scannerizzando la pila in ordine inverso, troviamo equazioni che contengono ogni volta una singola variabile libera.

Il problema principale è la presenza di cicli: il grafo deve essere aciclico affinché il sistema sia triangolarizzabile (e quindi risolvibile in modo lineare).

#note()[
  Esfoliare è un'operazione lineare, il che rappresenta un enorme vantaggio per la triangolarizzazione del sistema.
]

#warning()[
  Dobbiamo ricordarci di memorizzare con un bit l'informazione sulla variabile dell'equazione che era una foglia.
]

#example()[
  *Esempio passo-passo del processo di Peeling:*
  1. *Individuazione delle foglie:* Cerchiamo un vertice con grado $<= 1$ (es. un nodo connesso a una sola chiave).
  2. *Rimozione:* Rimuoviamo il vertice e l'equazione associata, spingendola su una pila.
  3. *Aggiornamento:* Il grado dei nodi adiacenti diminuisce, rivelando nuove foglie.
  4. *Risoluzione greedy (ritorno dallo stack):* Estraendo le equazioni dalla pila in ordine inverso, ogni equazione conterrà una sola variabile non ancora assegnata, ricavando immediatamente il valore tramite XOR. Le variabili libere rimanenti vengono impostate a $0$.
]

=== Esempio guidato: peeling su un grafo vero

Riprendiamo le $4$ chiavi dell'esempio precedente. Ogni chiave è un lato tra le sue due posizioni $g(x)$ e $h(x)$:
cane $= {v_0, v_1}$, gatto $= {v_1, v_2}$, topo $= {v_2, v_3}$, ape $= {v_3, v_5}$. La variabile $v_4$ non compare in nessuna equazione.

Legenda dei colori: *giallo* = foglia (grado $<= 1$ tra i lati rimasti), *grigio* = vertice già rimosso, *verde* = variabile libera, lato tratteggiato = lato già rimosso.

#passo([Passo 0 — grafo iniziale.],
  [Gradi: $v_0 = 1$, $v_1 = 2$, $v_2 = 2$, $v_3 = 2$, $v_4 = 0$, $v_5 = 1$. Le foglie sono $v_0$ e $v_5$. Il vertice $v_4$ ha grado $0$: nessuna equazione lo usa, è una variabile libera. La pila è vuota.],
  grafo(es-nodi(("foglia", "norm", "norm", "norm", "libero", "foglia")), es-lati(("att", "att", "att", "att"))),
  ())

#passo([Passo 1 — rimuovo $v_0$.],
  [L'unica equazione che contiene $v_0$ è quella di "cane": la rimuovo e la metto in pila, annotando che la variabile "foglia" di quell'equazione è $v_0$. Il grado di $v_1$ scende a $1$: ora anche $v_1$ è una foglia.],
  grafo(es-nodi(("rimosso", "foglia", "norm", "norm", "libero", "foglia")), es-lati(("rem", "att", "att", "att"))),
  ([cane → $v_0$],))

#passo([Passo 2 — rimuovo $v_5$.],
  [$v_5$ compare solo in "ape". Pila: aggiungo "ape → $v_5$". Il grado di $v_3$ scende da $2$ a $1$. Foglie disponibili: $v_1$ (gatto) e $v_3$ (topo).],
  grafo(es-nodi(("rimosso", "foglia", "norm", "foglia", "libero", "rimosso")), es-lati(("rem", "att", "att", "rem"))),
  ([cane → $v_0$], [ape → $v_5$]))

#passo([Passo 3 — rimuovo $v_1$.],
  [Scelgo la foglia $v_1$ (potevo scegliere anche $v_3$: l'ordine tra foglie è libero). Si rimuove "gatto" e si mette in pila. Il grado di $v_2$ scende a $1$.],
  grafo(es-nodi(("rimosso", "rimosso", "foglia", "foglia", "libero", "rimosso")), es-lati(("rem", "rem", "att", "rem"))),
  ([cane → $v_0$], [ape → $v_5$], [gatto → $v_1$]))

#passo([Passo 4 — rimuovo $v_2$ e il grafo è vuoto.],
  [Resta il solo lato "topo" = ${v_2, v_3}$: entrambi gli estremi sono foglie. Scelgo $v_2$ come variabile foglia. Ora $v_3$ ha grado $0$ e diventa libera, come $v_4$. Non è rimasto nessun lato: *il grafo era aciclico e il peeling è riuscito*.],
  grafo(es-nodi(("rimosso", "rimosso", "rimosso", "libero", "libero", "rimosso")), es-lati(("rem", "rem", "rem", "rem"))),
  ([cane → $v_0$], [ape → $v_5$], [gatto → $v_1$], [topo → $v_2$]))

#v(0.6em)
*Cosa succede se c'è un ciclo?* Nel triangolo $v_1, v_2, v_3$ visto prima ogni vertice ha grado $2$: *non esiste nessuna foglia* da cui partire, il peeling si blocca con dei lati rimasti. In quel caso si scartano le funzioni hash, se ne scelgono di nuove (nuovo seme) e si ricostruisce il grafo.

#figure(
  grid(columns: (auto, auto), column-gutter: 1.2cm, align: horizon + center,
    grafo(
      (($v_1$, 0.9cm, 0.7cm, "norm"), ($v_2$, 3.0cm, 0.7cm, "norm"), ($v_3$, 1.95cm, 2.4cm, "norm")),
      ((0, 1, $k_1$), (1, 2, $k_2$), (0, 2, $k_3$)),
      w: 3.9cm, h: 2.9cm),
    [Tutti i vertici hanno grado $2$: \ nessuna foglia, \ *il peeling si blocca*.],
  ),
  caption: [Un ciclo impedisce l'esfoliazione.],
)

== Procedura di Risoluzione (Greedy)
La procedura visita il grafo seguendo le foglie. Risolvendo in modo *greedy* le equazioni dallo stack dall'alto verso il basso, assegniamo i valori a tutte le variabili. Nelle variabili che rimangono libere (non cardine) mettiamo $0$, poiché non necessarie.

=== Esempio guidato: risoluzione dalla pila

Partiamo dalla pila ottenuta dal peeling (dal fondo alla cima): cane → $v_0$, ape → $v_5$, gatto → $v_1$, topo → $v_2$. Ricordiamo i valori richiesti: $f($cane$) = 01$, $f($gatto$) = 00$, $f($topo$) = 11$, $f($ape$) = 10$.

*Inizializzazione:* le variabili libere ($v_3$ e $v_4$) si pongono a $00$. Le altre sono ancora sconosciute (`?`).

Si estrae dalla cima (ordine inverso rispetto al peeling). Ogni equazione estratta contiene *una sola* incognita: la sua variabile foglia. Tutte le altre sono già note (libere o calcolate prima).

#figure(
  grid(columns: (1fr, auto), column-gutter: 0.5cm, row-gutter: 0.45cm, align: left + horizon,
    [*Inizio.* Libere: $v_3 = v_4 = 00$.],
    vettore(("?", "?", "?", "00", "00", "?"), evid: ((3, c-free), (4, c-free)), w: 1.1cm),
    [*Estraggo "topo → $v_2$":* $v_2 xor v_3 = 11$, quindi $v_2 = 11 xor 00 = 11$.],
    vettore(("?", "?", "11", "00", "00", "?"), evid: ((2, c-new),), w: 1.1cm),
    [*Estraggo "gatto → $v_1$":* $v_1 xor v_2 = 00$, quindi $v_1 = 00 xor 11 = 11$.],
    vettore(("?", "11", "11", "00", "00", "?"), evid: ((1, c-new),), w: 1.1cm),
    [*Estraggo "ape → $v_5$":* $v_3 xor v_5 = 10$, quindi $v_5 = 10 xor 00 = 10$.],
    vettore(("?", "11", "11", "00", "00", "10"), evid: ((5, c-new),), w: 1.1cm),
    [*Estraggo "cane → $v_0$":* $v_0 xor v_1 = 01$, quindi $v_0 = 01 xor 11 = 10$.],
    vettore(("10", "11", "11", "00", "00", "10"), evid: ((0, c-new),), w: 1.1cm),
  ),
  caption: [Il vettore si riempie estraendo le equazioni dalla pila. In giallo la cella appena calcolata, in verde le variabili libere.],
)

Il risultato è esattamente il vettore $v = (10, 11, 11, 00, 00, 10)$ usato nell'esempio di interrogazione. Notiamo che:
- le variabili libere ($v_3$, $v_4$) valgono $0$ perché nessuno le ha mai dovute "decidere";
- ogni cella viene scritta *una sola volta*;
- il costo totale è lineare: una scansione della pila.

#note()[
  *Trucco informatico:* Nella rappresentazione del grafo, invece di mantenere liste di vicini, facciamo lo XOR di tutte le liste insieme. Poiché lo XOR di un elemento con se stesso è zero, man mano che rimuoviamo i vertici aggiorniamo il valore tramite XOR ottenendo direttamente ciò che serve. Il grafo viene rappresentato semplicemente con un vettore di interi.
]

=== Esempio guidato: il trucco dello XOR sul grafo

Numeriamo i lati: cane $= 1$, gatto $= 2$, topo $= 3$, ape $= 4$. Per ogni vertice memorizziamo soltanto *due numeri*: il *grado* e lo *XOR degli identificatori dei lati incidenti*.

#figure(
  table(
    columns: 7,
    align: center,
    inset: 5pt,
    [], [$v_0$], [$v_1$], [$v_2$], [$v_3$], [$v_4$], [$v_5$],
    [lati incidenti], [1], [1, 2], [2, 3], [3, 4], [—], [4],
    [grado], [1], [2], [2], [2], [0], [1],
    [XOR dei lati], [`001`], [`001`$xor$`010` $=$ `011`], [`010`$xor$`011` $=$ `001`], [`011`$xor$`100` $=$ `111`], [`000`], [`100`],
  ),
  caption: [Stato iniziale del grafo: due soli interi per vertice, nessuna lista di vicini.],
)

Quando un vertice ha grado $1$, il suo XOR è *direttamente l'identificatore del suo unico lato* (perché gli altri sono "spariti" per XOR):
- $v_0$ ha grado $1$ e XOR $= 1$: il suo lato è "cane". Lo rimuovo. L'altro estremo di "cane" è $v_1$: aggiorno grado $2 -> 1$ e XOR $= 3 xor 1 = 2$. Ora $v_1$ "sa" che il suo unico lato è il $2$ (gatto).
- $v_5$ ha XOR $= 4$: lato "ape". Altro estremo $v_3$: grado $2 -> 1$, XOR $= 7 xor 4 = 3$ (topo).
- $v_1$ ha grado $1$, XOR $= 2$: lato "gatto". Altro estremo $v_2$: grado $2 -> 1$, XOR $= 1 xor 2 = 3$ (topo).
- $v_2$ ha grado $1$, XOR $= 3$: lato "topo". Altro estremo $v_3$: grado $1 -> 0$, XOR $= 3 xor 3 = 0$.

In questo modo non servono liste di adiacenza: bastano due vettori di interi e si riesce a trovare *in tempo costante* quale lato rimuovere da una foglia.

#note()[
  *Nota terminologica:* Nella teoria dei grafi standard, $m$ indica i lati e $n$ i vertici (anche se a volte si inverte la notazione, l'importante è ricordarsi la distinzione concettuale).
]

== La Soglia di Erdős-Rényi
Se il numero di vertici è sufficientemente più grande del numero di lati (grafo sparso), il grafo è aciclico. Per i grafi, se $n >= (2 + epsilon) m$, la probabilità che il grafo sia aciclico è data da:

$ ( sqrt(epsilon (2 + epsilon)) ) / ( 1 + epsilon ) $

Ad esempio, si usa spesso un fattore come $2.09$ per avere circa il $30%$ di probabilità. Facendo $3$ o $4$ tentativi in media troviamo un grafo aciclico valido.

Il costo della struttura è quindi il numero di variabili moltiplicato per $b$: $(2 + epsilon) n b$. Avere un grafo esfoliabile significa trovarsi di fronte a una foresta. Strutture di questo tipo hanno una costruzione probabilistica ma una risposta deterministica.

#note()[
  La probabilità di successo è positiva, indipendente da $m$ e $n$, e limitata inferiormente da una costante positiva.
]

= Ottimizzazione con gli Ipergrafi (3 Funzioni di Hash)

Come possiamo ridurre il fattore $(2 + epsilon) n b$? Estendendo il modello a tre funzioni di hash:

$ v_(g(x)) xor v_(h(x)) xor v_(c(x)) = f(x) quad forall x in X $

In questo caso utilizziamo *ipergrafi*. Le foglie diventano i vertici coinvolti in un solo iperlato. 

#example()[
  *Rappresentazione con gli ipergrafi (3 hash):*
  Ogni chiave $x$ connette tre nodi anziché due ($g(x), h(x), c(x)$). L'iperlato collega tre variabili nel sistema XOR:
  $ v_(g(x)) xor v_(h(x)) xor v_(c(x)) = f(x) $
  Questo riduce drasticamente il numero di nodi $m$ necessari per mantenere la proprietà di esfoliabilità.
]

Con gli ipergrafi a 3 funzioni, la soglia per l'esfoliabilità scende a $1.22$, portando il costo a circa $1.23 |X| b$. 

L'utilizzo di $3$ funzioni è la soluzione ideale, poiché con $4$ funzioni la situazione peggiora. Superata la soglia di esfoliazione non abbiamo più una garanzia di probabilità strettamente positiva, ma la certezza asintotica ("quasi sempre"). Con mille chiavi, solitamente funziona al primo colpo.

#note()[
  *Soglie:* Le soglie di risolubilità sono più basse di quelle di esfoliabilità. Al crescere di $k$ (numero di funzioni hash), la risolubilità diventa sempre più facile, l'esfoliazione diventa più difficile. Aumentare il numero di funzioni aumenta però gli accessi in memoria e la complessità di risoluzione del sistema lineare.
]

=== Esempio guidato: un ipergrafo con 3 funzioni hash

Prendiamo tre chiavi $A$ = cane, $B$ = gatto, $C$ = topo, con $b = 2$ e $m = 7$ variabili. Ogni chiave ha tre posizioni:
$A = {v_0, v_1, v_2}$, $B = {v_2, v_3, v_4}$, $C = {v_4, v_5, v_6}$ e valori $f(A) = 11$, $f(B) = 10$, $f(C) = 00$.

#figure(
  grafo(
    (
      ($v_0$, 0.7cm, 2.1cm, "foglia"), ($v_1$, 2.3cm, 2.1cm, "foglia"), ($v_2$, 3.9cm, 2.1cm, "norm"),
      ($v_3$, 5.5cm, 2.1cm, "foglia"), ($v_4$, 7.1cm, 2.1cm, "norm"), ($v_5$, 8.7cm, 2.1cm, "foglia"),
      ($v_6$, 10.3cm, 2.1cm, "foglia"),
      ($A$, 2.3cm, 0.5cm, "chiave"), ($B$, 5.5cm, 0.5cm, "chiave"), ($C$, 8.7cm, 0.5cm, "chiave"),
    ),
    ((7, 0), (7, 1), (7, 2), (8, 2), (8, 3), (8, 4), (9, 4), (9, 5), (9, 6)),
    w: 11cm, h: 2.7cm),
  caption: [Ipergrafo: ogni chiave (azzurro) è un iperlato che collega *tre* variabili. In giallo i vertici di grado $1$ (foglie).],
)

*Peeling.* Un vertice è foglia se compare in un solo iperlato.
+ $v_0$ è foglia (solo in $A$): metto "$A -> v_0$" in pila. Togliendo $A$, $v_2$ compare solo in $B$.
+ $v_2$ è ora foglia: metto "$B -> v_2$" in pila. Togliendo $B$, $v_4$ compare solo in $C$.
+ $v_4$ è ora foglia: metto "$C -> v_4$" in pila. Non restano iperlati: successo.

Le variabili mai scelte come foglia ($v_1, v_3, v_5, v_6$) sono libere e valgono $00$.

*Risoluzione dalla pila* (si parte dalla cima):
- $C$: $v_4 xor v_5 xor v_6 = 00$, con $v_5 = v_6 = 00$: $v_4 = 00$.
- $B$: $v_2 xor v_3 xor v_4 = 10$, con $v_3 = v_4 = 00$: $v_2 = 10$.
- $A$: $v_0 xor v_1 xor v_2 = 11$, con $v_1 = 00$ e $v_2 = 10$: $v_0 = 11 xor 00 xor 10 = 01$.

#figure(
  vettore(("01", "00", "10", "00", "00", "00", "00"), evid: ((0, c-new), (2, c-new), (4, c-new)), w: 1.1cm),
  caption: [Vettore finale (in giallo le tre celle calcolate dalla pila; le altre sono libere, a $0$).],
)

*Interrogazione di $B$* (gatto): si leggono *tre* celle e si fa lo XOR: $v_2 xor v_3 xor v_4 = 10 xor 00 xor 00 = 10 = f(B)$ #sym.checkmark.

#figure(
  vettore(("01", "00", "10", "00", "00", "00", "00"), evid: ((2, c-g), (3, c-h), (4, c-c)), w: 1.1cm),
  caption: [`get`(gatto) con tre hash: $g = 2$ (azzurro), $h = 3$ (arancio), $c = 4$ (viola). Costo: *tre* accessi in memoria invece di due.],
)

= Applicazioni e Dizionari Compatti

Useremo questo approccio per mappare le parole nel loro rango. Tuttavia, se l'utente inserisce una parola non valida (es. "pippo"), dobbiamo sapere se fa parte dell'indice, altrimenti otterremmo risultati imprevedibili.

== Aggiunta di Firme (Fingerprints)
Per trasformare la funzione statica in un dizionario, aggiungiamo delle *firme*:
1. Prendiamo una buona funzione di hash e memorizziamo in un vettore le firme per ciascun termine.
2. Quando arriva una chiave $x$, calcoliamo $f(x)$ (la funzione statica) e controlliamo se $F(f(x)) = S(x)$.

#example()[
  *Esempio di query con firme (Fingerprints):*
  - Arriva la chiave $x = "cane"$.
  - Calcoliamo la funzione statica $f("cane") = "rango" 12$.
  - Controlliamo il vettore delle firme $F$ alla posizione $12$: verifichiamo se $F[12] == S("cane")$.
  - Se il controllo fallisce (o se inseriamo una chiave estranea come $x = "pippo"$), la struttura riconosce che la chiave non appartiene all'insieme $X$.
]

=== Esempio guidato con i numeri di prima

Riprendiamo la funzione statica dell'esempio a due hash (ranghi: gatto $= 0$, cane $= 1$, ape $= 2$, topo $= 3$) e aggiungiamo un vettore di firme $F$ da $8$ bit (scritte in esadecimale). In posizione $r$ c'è la firma della chiave che ha rango $r$:

#figure(
  vettore(("3c", "a7", "51", "e2"), w: 1.3cm),
  caption: [Vettore $F$: $F[0] = S("gatto")$, $F[1] = S("cane")$, $F[2] = S("ape")$, $F[3] = S("topo")$.],
)

*Query "cane"* (chiave presente):
+ funzione statica: $f("cane") = v_0 xor v_1 = 10 xor 11 = 01 = 1$;
+ leggo $F[1] = $ `a7`;
+ calcolo $S("cane") = $ `a7`. Coincidono: *presente* #sym.checkmark.

*Query "pippo"* (chiave estranea):
+ funzione statica: $f("pippo") = v_0 xor v_4 = 10 xor 00 = 10 = 2$ (rango spurio);
+ leggo $F[2] = $ `51` (la firma di "ape");
+ calcolo $S("pippo") = $ `9d`. Sono diverse: *assente*, come volevamo.

#figure(
  grid(columns: (auto, auto, auto, auto, auto, auto, auto), column-gutter: 0.35cm, align: horizon + center,
    riquadro[$x$], $-->$, riquadro[$f(x)$ \ rango], $-->$, riquadro[$F[f(x)]$], $=?=$, riquadro[$S(x)$],
  ),
  caption: [Schema della verifica: si confronta la firma memorizzata nella posizione $f(x)$ con la firma calcolata di $x$.],
)

Può comunque capitare che una chiave estranea dia per caso la stessa firma: con firme di $r$ bit la probabilità è circa $2^(-r)$ (con $r = 8$, circa $1/256$). Più bit di firma significano meno falsi positivi, ma anche più spazio.

Questo costa uno spazio proporzionale alla lunghezza dei termini, ma molto meno di una tabella di hash tradizionale. 

La funzione statica deve restituire una permutazione di $n$ (nel range $0 ... n$), diventando così una *Funzione di Hash Minimale Perfetta* (MPH), in particolare monotona.

== Filtri di Bloom Statici e Dizionari Compatti

Se vogliamo solo l'identità insiemistica senza recuperare l'output della funzione statica:
- Possiamo costruire un filtro di Bloom statico o un dizionario statico associando a ogni chiave un hash crittografico $S(x)$.
- La funzione statica mappa ogni chiave nella sua firma. Se interroghiamo con una chiave non presente, $g(x)$ restituirà un vettore casuale di $b$ bit.
- Confrontando $g(x)$ con la firma crittografica $S(x)$, possiamo determinare con altissima probabilità se la chiave appartiene all'insieme originario.

Questo approccio permette di scendere a circa $1.44 n b$ o addirittura $1.01 n b$ bit (valori utilizzati attualmente in sistemi come RocksDB), ottenendo un dizionario statico valutabile in tempo costante e molto più compatto di un filtro di Bloom tradizionale.

#note()[
  *Nota concettuale:* $S(x)$ (la funzione hash/firma) è un algoritmo, mentre $G(X)$ è la struttura dati che memorizza effettivamente le informazioni.
]