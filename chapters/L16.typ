#import "../template.typ": *

#set text(lang: "it")
#let U = 1cm
#let pt(x, y) = (x * U, y * U)

#let c-in = rgb("#1f6fb2")
#let c-out = rgb("#d35400")
#let c-ev = rgb("#c0392b")
#let c-ok = rgb("#1e8449")
#let c-soft = rgb("#d6eaf8")
#let c-hl = rgb("#fadbd8")

#let arco(p, q, r, dir, col, w, dash) = {
  let dx = q.at(0) - p.at(0)
  let dy = q.at(1) - p.at(1)
  let len = calc.sqrt(dx * dx + dy * dy)
  let ux = dx / len
  let uy = dy / len
  let s = (p.at(0) + ux * r, p.at(1) + uy * r)
  let e = (q.at(0) - ux * r, q.at(1) - uy * r)
  let hd = if dir { 0.22 } else { 0 }
  let b = (e.at(0) - ux * hd, e.at(1) - uy * hd)
  place(top + left, line(
    start: pt(..s),
    end: pt(..b),
    stroke: (paint: col, thickness: w, dash: dash),
  ))
  if dir {
    place(top + left, polygon(
      fill: col,
      stroke: none,
      pt(..e),
      pt(b.at(0) - uy * 0.09, b.at(1) + ux * 0.09),
      pt(b.at(0) + uy * 0.09, b.at(1) - ux * 0.09),
    ))
  }
}

#let grafo(w, h, nodi, archi, dir: true, r: 0.28, testi: ()) = {
  let P(i) = (nodi.at(i).at(0), h - nodi.at(i).at(1))
  box(width: w * U, height: h * U, {
    for a in archi {
      let col = if a.len() > 2 { a.at(2) } else { black }
      let dash = if a.len() > 3 { a.at(3) } else { none }
      arco(P(a.at(0)), P(a.at(1)), r, dir, col, 0.9pt, dash)
    }
    for (i, n) in nodi.enumerate() {
      let c = P(i)
      let fill = if n.len() > 3 { n.at(3) } else { white }
      place(top + left, dx: (c.at(0) - r) * U, dy: (c.at(1) - r) * U, circle(
        radius: r * U,
        fill: fill,
        stroke: 0.9pt,
        inset: 0pt,
        align(center + horizon, text(size: 8pt, n.at(2))),
      ))
    }
    for t in testi {
      place(top + left, dx: t.at(0) * U - 2cm, dy: (h - t.at(1)) * U - 0.4em, box(
        width: 4cm,
        align(center, text(size: 8pt, t.at(2))),
      ))
    }
  })
}


#let pentagono(cx, cy, R, a0) = range(5).map(k => (
  cx + R * calc.cos(a0 + k * 72deg),
  cy + R * calc.sin(a0 + k * 72deg),
))

#let clique-archi(base) = {
  let out = ()
  for i in range(5) {
    for j in range(i + 1, 5) { out.push((base + i, base + j)) }
  }
  out
}

= Ranking Esogeno

Vogliamo attribuire un'importanza (o *punteggio di rilevanza*) alle pagine web o ai nodi di una rete sfruttando la struttura dei loro collegamenti (archi/link).

Per conoscere gli *archi in entrata* (*indegree*) di una pagina, teoricamente dovremmo scansionare e analizzare un'immensa porzione di Web. Questo aspetto è fondamentale perché tutto ciò che affronteremo può essere diviso in due prospettive:

- *Prospettiva Positiva (Archi Uscenti / Outdegree):* Archi che partono dal nodo analizzato. Sono elementi sotto il diretto e facile controllo dell'ente proprietario della pagina. Se la centralità si basasse sul semplice conteggio dei link contenuti in una pagina web, basterebbero 3 secondi per fare *spam*: riempio la pagina di link uscenti e ne aumento artificialmente il valore.
- *Prospettiva Negativa (Archi Entranti / Indegree):* Archi che arrivano al nodo. È ciò che ci interessa davvero, poiché rappresenta una sorta di "voto" o riconoscimento espresso da terzi, quindi difficilmente manipolabile dal singolo nodo.

#figure(
  grafo(
    6.4, 3.4,
    (
      (3.2, 1.7, $v$, c-soft),
      (0.4, 3.0, $a$), (0.4, 1.7, $b$), (0.4, 0.4, $c$),
      (6.0, 2.5, $d$), (6.0, 0.9, $e$),
    ),
    (
      (1, 0, c-in), (2, 0, c-in), (3, 0, c-in),
      (0, 4, c-out), (0, 5, c-out),
    ),
  ),
  caption: [Il nodo $v$ ha #text(fill: c-in)[3 archi entranti] ($"indegree" = 3$, il "voto" di terzi) e #text(fill: c-out)[2 archi uscenti] ($"outdegree" = 2$, deciso da $v$ stesso).],
)

#note[
  *Nota sui Grafi Non Orientati:*
  In generale, passare dagli archi entranti a quelli uscenti equivale a _trasporre la matrice di adiacenza_ del grafo. Se il grafo non è orientato (es. la rete di amicizie su Facebook) la matrice di adiacenza è simmetrica, quindi coincide con la sua trasposta: archi in entrata e in uscita coincidono nell'unico concetto di *grado* ($d(v)$) e la distinzione sparisce.
]

Nella stragrande maggioranza delle applicazioni pratiche (es. ranking di scacchi, citation network, ranking web) ci interessa analizzare la _centralità "negativa"_ (ovvero la centralità basata su chi o cosa punta _verso_ di noi).


== Centralità Elementari (Grado)

L'*indegree* e l'*outdegree* rappresentano le forme più elementari di centralità:
- *Punto di forza:* Possono essere calcolate in maniera estremamente _locale_ (basta guardare il vicinato immediato di un nodo). Questo è molto utile quando si possiede l'intero grafo in memoria (es. dati interni di Facebook).
- *Primo Difetto (Spammabilità):* A causa della loro natura locale, sono facilmente manipolabili (*link farming*, creazione di network di siti civetta che si scambiano link).
- *Secondo Difetto (Voti tutti uguali):* Ogni link in entrata conta uno, indipendentemente dall'importanza di chi lo emette. Questo problema porterà alle centralità spettrali.


== Centralità Geometriche

Cosa possiamo fare introducendo la nozione di _distanza_ ($d(x, y)$) tra i nodi? Dato che ci interessa la centralità "negativa", useremo le distanze _verso_ $x$, cioè $d(y, x)$: quanto è lontano $x$ da chi può raggiungerlo.

=== 1. Closeness Centrality (Centralità di Vicinanza)
Idea introdotta alla fine degli anni '40 / anni '50 nell'ambito della sociometria e dello studio della comunicazione nei piccoli gruppi (Bavelas).

Definiamo la _perifericità_ di un nodo $x$ come la somma delle distanze da tutti gli altri vertici del grafo a $x$:
$ p(x) = sum_y d(y, x) $

La *Closeness Centrality* è definita come l'inverso della perifericità:
$ C(x) = 1 / (p(x)) = 1 / (sum_y d(y, x)) $

Se questo valore è piccolo, significa che $x$ è molto lontano da molti nodi (si trova in una regione periferica del grafo). Se è grande, $x$ è vicino a tutti e centrale.

- *Il problema dei Grafi Non Connessi (Web):* Nel Web le distanze possono essere _infinite_ ($d(y, x) = oo$) se un nodo $y$ non può raggiungere $x$. Questo renderebbe il denominatore infinito e la centralità pari a $0$.
- *Pezza impropria:* Considerare solamente i nodi raggiungibili (distanze finite).
- *Difetto della pezza:* I nodi che non mi raggiungono smettono di essere conteggiati e non contribuiscono ad abbassare la mia centralità, mentre dovrebbero penalizzarmi.

#figure(
  grafo(
    7.4, 2.4,
    (
      (0.6, 1.2, $b$), (2.7, 1.2, $a$), (4.8, 1.2, $x$, c-soft), (6.9, 1.2, $y$),
    ),
    ((0, 1), (1, 2), (2, 3)),
    testi: (
      (0.6, 0.3, $d(b, x) = 2$),
      (2.7, 0.3, $d(a, x) = 1$),
      (6.9, 0.3, $d(y, x) = oo$),
    ),
  ),
  caption: [Con la closeness, il solo nodo $y$ (che non raggiunge $x$) manda $p(x) = oo$ e quindi $C(x) = 0$, nonostante $a$ e $b$ siano vicini a $x$.],
)

=== 2. Harmonic Centrality (Centralità Armonica)
Per risolvere elegantemente il problema degli outlier e dei nodi non connessi, anziché sommare le distanze e poi prenderne il reciproco, invertiamo le distanze _prima_ di sommare (è la _media armonica_ delle distanze, a meno di una costante).

Anziché calcolare $sum_y d(y, x)$, facciamo la somma dei reciproci delle distanze:
$ H(x) = sum_(y : y != x) 1 / (d(y, x)) $

Se un nodo $y$ non raggiunge $x$, la sua distanza è $d(y, x) = oo$, quindi il contributo $1 / oo = 0$. Il nodo irraggiungibile semplicemente non fornisce punteggio, senza mandare in blocco la formula. Nell'esempio della figura precedente: $H(x) = 1/1 + 1/2 + 0 = 3/2$.

Raggruppando i termini dello stesso valore (stessa distanza $t$), la formula diventa:
$ H(x) = sum_(t > 0) 1/t |{y in V : d(y, x) = t}| $

#informally[
  *Interpretazione a "Bolle" o Sfere di Raggio $t$:*
  - Sfera di raggio $t=1$ (gli amici diretti): ciascuno contribuisce con $1/1 = 1$.
  - Sfera di raggio $t=2$ (gli amici degli amici): ciascuno contribuisce con $1/2$.
  - Sfera di raggio $t=3$: ciascuno contribuisce con $1/3$, e così via.
]

#figure(
  {
    let cx = 3.3
    let cy = 3.3
    let nodo(x, y, col, rr: 0.17) = place(top + left, dx: (x - rr) * U, dy: (6.6 - y - rr) * U, circle(radius: rr * U, fill: col, stroke: 0.8pt))
    box(width: 6.6 * U, height: 6.6 * U, {
      for (R, col) in ((0.95, c-in), (1.9, c-out), (2.85, c-ok)) {
        place(top + left, dx: (cx - R) * U, dy: (6.6 - cy - R) * U, circle(
          radius: R * U,
          stroke: (paint: col, thickness: 0.9pt, dash: "dashed"),
        ))
      }
      for k in range(3) {
        nodo(cx + 0.95 * calc.cos(90deg + k * 120deg), cy + 0.95 * calc.sin(90deg + k * 120deg), c-in)
      }
      for k in range(4) {
        nodo(cx + 1.9 * calc.cos(45deg + k * 90deg), cy + 1.9 * calc.sin(45deg + k * 90deg), c-out)
      }
      for k in range(3) {
        nodo(cx + 2.85 * calc.cos(30deg + k * 120deg), cy + 2.85 * calc.sin(30deg + k * 120deg), c-ok)
      }
      place(top + left, dx: (cx - 0.28) * U, dy: (6.6 - cy - 0.28) * U, circle(
        radius: 0.28 * U, fill: c-soft, stroke: 0.9pt, inset: 0pt,
        align(center + horizon, text(size: 9pt, $x$)),
      ))
    })
  },
  caption: [Sfere di raggio $t$ attorno a $x$ (un nodo è nella sfera $t$ se dista $t$ da $x$). Qui $H(x) = underbrace(3 dot 1, t=1) + underbrace(4 dot 1/2, t=2) + underbrace(3 dot 1/3, t=3) = 6$.],
)

#note[
  La centralità armonica risolve in modo efficace i problemi della *Closeness Centrality* sui grafi non orientati e orientati, fornendo una nozione di centralità robusta ed estendibile a tutto il grafo.
]

- *Il limite computazionale:* Per calcolare la distanza esatta da tutti i vertici a tutti gli altri è necessario eseguire una visita in ampiezza (*BFS*) a partire da ogni singolo nodo (sul grafo trasposto, se si vogliono le distanze _verso_ $x$). Su scale giganti (come la struttura del Web) il costo computazionale diventa improponibile per un calcolo frequente.

=== 3. Betweenness Centrality (Centralità di Intermediazione)
L'idea fondamentale della *Betweenness* è rendere importanti i vertici rilevanti per le _comunicazioni_, ovvero quei nodi che si trovano sul percorso di molti _cammini minimi_ (*geodesici*).

Siano $sigma_(y z)$ il numero totale di cammini minimi tra il nodo $y$ e il nodo $z$, e $sigma_(y z)(x)$ il numero di questi cammini minimi che passano per il vertice intermedio $x$. La *Betweenness Centrality* è definita come:

$ B(x) = sum_(y != z, space y\,z != x) (sigma_(y z)(x)) / (sigma_(y z)) $

(si sommano le coppie $y, z$ distinte e diverse da $x$, e con $sigma_(y z) > 0$).

Se vogliamo interrompere la rete o alzare nel modo più rapido possibile il _diametro armonico_, eliminare i nodi con la *Betweenness* più alta è la scelta strategica migliore.

==== Problemi e Limiti della Betweenness:
1. *Applicabilità al Web:* Applicata al Web dà risultati insensati e privi di utilità pratica. Ha avuto enorme successo soprattutto nella network analysis e sociologia.
2. *Costo Computazionale:* L'algoritmo classico di *Brandes* calcola la Betweenness in tempo $O(n m)$ (dove $n$ è il numero di nodi e $m$ è il numero di archi, nel caso non pesato). Perfetto per grafi medio-piccoli, ma proibitivo per dimensioni di scala Web.
3. *Instabilità e Fragilità (Esempio del "Grafo a Manubrio"):*
   Immaginiamo due grandi *clique* (sottografi completi, densamente connessi) collegate tra loro esclusivamente tramite un singolo nodo centrale $c$, a sua volta collegato a un solo nodo $a_0$ della prima clique e a un solo nodo $b_0$ della seconda.
   Tutti i cammini minimi da una clique all'altra devono per forza attraversare $c$, garantendogli un punteggio di *Betweenness* altissimo.
   Se tuttavia _aggiungiamo un solo arco_ che collega direttamente $a_0$ a $b_0$, _tutti_ questi cammini minimi deviano sul nuovo arco, saltando $c$. La *Betweenness* di $c$ crolla bruscamente a zero, dimostrando una forte _instabilità strutturale_.

#figure(
  {
    let A = pentagono(1.55, 1.9, 1.1, 0deg)
    let B = pentagono(5.45, 1.9, 1.1, 180deg)
    let nodi = A.enumerate().map(((i, p)) => (p.at(0), p.at(1), if i == 0 { $a_0$ } else { [] })) + B.enumerate().map(((i, p)) => (p.at(0), p.at(1), if i == 0 { $b_0$ } else { [] })) + ((3.5, 0.5, $c$, c-hl),)
    let base = clique-archi(0) + clique-archi(5)
    let prima = base + ((0, 10, c-ev), (5, 10, c-ev))
    let dopo = prima + ((0, 5, c-ok, "dashed"),)
    grid(
      columns: 2,
      column-gutter: 0.8cm,
      align: center,
      grafo(7, 3.2, nodi, prima, dir: false, r: 0.24),
      grafo(7, 3.2, nodi, dopo, dir: false, r: 0.24, testi: ((3.5, 2.55, text(fill: c-ok)[nuovo arco $a_0 b_0$]),)),
      [Prima: ogni cammino minimo tra le clique passa per $c$.],
      [Dopo: tutti i cammini minimi saltano $c$, e $B(c) = 0$.],
    )
  },
  caption: [Grafo a manubrio: due clique da 5 nodi unite da $c$ (collegato a $a_0$ e $b_0$). Un solo arco aggiunto basta ad azzerare la betweenness di $c$.],
)


== Riepilogo Confronto Centralità Geometriche

#table(
  columns: (1fr, 1.5fr, 1.5fr),
  align: (left, left, left),
  table.hline(),
  [*Tipo Centralità*], [*Meccanismo Base*], [*Limiti / Criticità*],
  table.hline(),
  [*Indegree*], [Conteggio archi entranti locali (troncata a raggio 1)], [Facilmente spammabile (link farming)],
  [*Closeness*], [Inverso della somma delle distanze], [Fallisce su grafi non connessi ($d=oo$)],
  [*Harmonic*], [Somma dei reciproci delle distanze $sum 1/t$], [Richiede BFS per ogni nodo ($O(n m)$)],
  [*Betweenness*], [Conteggio frazionale di cammini minimi passanti per $x$], [Iper-sensibile alle modifiche (instabile), insensata sul Web],
  table.hline(),
)


== Centralità Spettrali e Algebra Lineare

Le centralità geometriche (come *Indegree*, *Closeness* o *Betweenness*) valutano la posizione dei nodi basandosi esclusivamente sul conteggio o sulla lunghezza dei cammini. Trovano però un grosso limite: _trattano tutti i vicini allo stesso modo_. Nella realtà, ricevere un link o un voto da un nodo molto importante deve valere molto di più che riceverlo da un nodo periferico o irrilevante.

Per superare questo problema si usano le *Centralità Spettrali*, la cui idea di base (sviluppata inizialmente per la classifica dei tornei sportivi) è ricorsiva:
#quote(block: true)[
  *"L'importanza di un nodo dipende dall'importanza dei nodi che lo puntano o che lo votano."*
]

Per comprendere queste centralità occorre richiamare alcuni concetti fondamentali di algebra lineare.

=== Richiami di Algebra Lineare: Autovalori e Autovettori

Quando applichiamo una trasformazione lineare (rappresentata da una matrice $M$) a un vettore $v$, nella maggior parte dei casi il vettore cambia sia in _lunghezza_ (modulo) sia in _direzione_.

Esistono tuttavia dei vettori speciali che, presi dalla matrice, _non cambiano mai direzione_: vengono unicamente allungati, accorciati o ribaltati lungo la loro stessa retta di appartenenza. Questi vettori (non nulli) si chiamano *autovettori*, e il fattore di scala di cui vengono allungati o accorciati è il relativo *autovalore* ($lambda$).

A seconda di come applichiamo la moltiplicazione, distinguiamo due forme:

- *Autovettore Sinistro:*
  $ v M = lambda v $
  Il vettore riga $v$ moltiplica la matrice $M$ da sinistra.
- *Autovettore Destro:*
  $ M v^T = lambda v^T $
  Il vettore colonna $v^T$ moltiplica la matrice $M$ da destra.

#figure(
  {
    let h = 3.9
    let O = (0.6, 0.5)
    let P(x, y) = (O.at(0) + x, h - (O.at(1) + y))
    let T(x, y, body) = place(top + left, dx: x * U, dy: (h - y) * U - 0.5em, body)
    box(width: 5.2 * U, height: h * U, {
      place(top + left, line(start: pt(..P(-0.3, 0)), end: pt(..P(4.4, 0)), stroke: 0.5pt + gray))
      place(top + left, line(start: pt(..P(0, -0.3)), end: pt(..P(0, 3.3)), stroke: 0.5pt + gray))
      arco(P(0, 0), P(1, 0), 0, true, c-in, 1.3pt, none)
      arco(P(0, 0), P(2, 1), 0, true, c-in, 1.3pt, "dashed")
      arco(P(0, 0), P(1, 1), 0, true, c-ev, 1.3pt, none)
      arco(P(0, 0), P(3, 3), 0, true, c-ev, 1.3pt, "dashed")
      T(P(1, 0).at(0) + 0.05, h - P(1, 0).at(1) - 0.35, text(fill: c-in, size: 8pt)[$u$])
      T(P(2, 1).at(0) + 0.1, h - P(2, 1).at(1) + 0.1, text(fill: c-in, size: 8pt)[$M u$])
      T(P(1, 1).at(0) - 0.45, h - P(1, 1).at(1) + 0.15, text(fill: c-ev, size: 8pt)[$v$])
      T(P(3, 3).at(0) + 0.1, h - P(3, 3).at(1) + 0.15, text(fill: c-ev, size: 8pt)[$M v = 3 v$])
    })
  },
  caption: [Con $M = mat(2, 1; 1, 2)$: un vettore generico $u = (1, 0)$ viene ruotato (#text(fill: c-in)[blu]), mentre l'autovettore $v = (1, 1)$ resta sulla propria retta e viene solo scalato di $lambda = 3$ (#text(fill: c-ev)[rosso]).],
)

#note[
  *Proprietà e Notazioni:*
  - *Kernel / Nucleo:* Se esiste un vettore $v != bold(0)$ che viene mappato nel vettore nullo ($M v^T = bold(0)$), allora $lambda = 0$ è un autovalore della matrice.
  - *Raggio Spettrale $rho(M)$:* È il massimo modulo tra tutti gli autovalori di $M$, ossia $rho(M) = max_i |lambda_i|$. Rappresenta il tasso limite di accrescimento/espansione della matrice quando viene elevata a potenza.
  - *Autovalore Dominante:* È l'autovalore con il modulo più grande in assoluto ($|lambda_(max)| = rho(M)$). Indica la direzione lungo la quale la trasformazione produce la massima crescita. Ci possono essere più autovalori con lo stesso modulo massimo, ma la presenza di un autovalore dominante unico garantisce la convergenza dei metodi iterativi.
]

=== Motivazione Introduttiva: La Classifica dei Tornei di Scacchi

Per capire l'origine storica delle centralità spettrali, consideriamo la necessità di stilare una classifica equa per un *torneo di scacchi* (o qualsiasi torneo sportivo tutti-contro-tutti).

Rappresentiamo i risultati del torneo con una matrice $M$, dove l'elemento $M_(j i)$ esprime il risultato dello scontro tra il giocatore $j$ e il giocatore $i$:
- $1$ se $j$ vince contro $i$;
- $1/2$ se c'è una patta;
- $0$ se $j$ perde contro $i$.

==== 1. Il Primo Tentativo (Contare le Vittorie):
Il modo più semplice per calcolare il punteggio di ciascun giocatore è contare quante partite ha vinto, cioè sommare gli elementi di ciascuna riga. In algebra lineare, sommare le righe di $M$ equivale a moltiplicare la matrice per il vettore colonna composto interamente da uni $bold(1) = (1, 1, dots, 1)^T$:

$ x^((1)) = M bold(1) $

*Limite del metodo:* Questo approccio considera ogni vittoria identica. Battere il campione del mondo assegna lo stesso punteggio che battere l'ultimo classificato.

==== 2. Il Secondo Tentativo (Pesare le Vittorie):
Per migliorare la classifica, possiamo premiare chi ha battuto giocatori a loro volta forti. Moltiplichiamo quindi il risultato ottenuto al passo precedente ($x^((1))$) nuovamente per la matrice dei risultati $M$:

$ x^((2)) = M x^((1)) = M (M bold(1)) = M^2 bold(1) $

In questo modo, battere un avversario che ha ottenuto molti punti al primo turno farà salire notevolmente il punteggio.

=== Il Problema delle Iterazioni e l'Intuizione di Landau

Possiamo continuare ad iterare questo procedimento applicando la matrice $M$ più volte:

$ x^((k)) = M^k bold(1) $

Tuttavia sorge una domanda fondamentale: *quando ci fermiamo? Quante volte dobbiamo iterare?*

Se ci fermiamo a un numero arbitrario di passi $k$, la classifica finale può variare enormemente al variare di $k$. Con tornei fittizi o piccoli campionati, la graduatoria dei giocatori può ribaltarsi a seconda che si scelga $k=2$, $k=3$ o $k=10$.

==== La Soluzione Spettrale (Edmund Landau, 1895):
Qui interviene il matematico Edmund Landau con un'intuizione fondamentale: anziché applicare $M$ un numero discreto di volte e fermarsi arbitrariamente, cerchiamo uno _stato limite o di equilibrio_ che non cambi più la forma della classifica se re-applicato all'infinito.

Matematicamente, cerchiamo un vettore di punteggi $v$ tale che, applicando la matrice dei risultati $M$, il vettore rimanga parallelo a se stesso:

$ M v = lambda v $

Ovvero, cerchiamo un *autovettore* $v$ della matrice $M$.

In questo modo:
1. Applicare nuovamente la matrice $M$ scala solamente i punteggi di un fattore costante $lambda$, _senza alterare l'ordine o le proporzioni_ della classifica.
2. Possiamo idealmente applicare l'operazione infinite volte: il rapporto relativo tra i punteggi dei giocatori rimarrà perfettamente stabile e convergente.

#warning[
  *Il Requisito Fondamentale dell'Autovettore Positivo:*
  Affinché un vettore di punteggi $v$ rappresenti una classifica valida nel mondo reale, _tutti i suoi elementi devono essere positivi o nulli_ ($v_i >= 0$). Non avrebbe senso assegnare un punteggio o una centralità negativa ad un giocatore o ad una pagina web.

  Garantire l'esistenza e la positività di tale autovettore dominante $v$ (e le condizioni sulla matrice $M$ necessarie ad ottenerlo) sarà esattamente il ruolo del *Teorema di Perron-Frobenius*, che costituisce il fondamento matematico di algoritmi come l'_Eigenvector Centrality_, *Katz Centrality* e *PageRank*.
]