#import "../template.typ": *

Basta avanzare il candidato per lo skip to dell'and, le liste possono non essere toccate. In questo modo ci risparmiamo degli avanzamenti nelle liste successivo se non c'è un mathc precedente.

== Frasi e Prossimità
Altri atomi del linguaguaggio booleane.

Frasi: sequenza di termini "$t_0, t_1, dots, t_n$" sono atomi, quindi stiamo cercando una specifica sequenza di termini.

Prossimità: i termini compaiono entro una distanza $l$ nel documento. $(t_0, dots, t_1) tilde l$. Per rispondere a questa query ci servono gli indici dei termini nel documento. Un esempio di utilizzo è ridurre i candidati di un insieme troppo grandi. Ad esempio romeo e gulietta entro tre parole.

=== Frasi

Possiamo fare un and di tutti i termini della frase, a quasto punto otteniamo per ogni termine la sua lista di posizioni.

```
    t_0: [1, 5, 10, 15]
    t_1: [2, 6, 11, 16]
    t_2: [3, 7, 12, 17]
```

Possiamo usare un qualsiasi argomento sulle intersezioni. Ad esempio possiamo vedere la lista di $t_k$ come una lista sposta di $k$ elementi rispetto alla lista di $t_0$. A questo punto possiamo fare un and tra le liste spostate. In questo modo otteniamo le posizioni in cui i termini compaiono in sequenza.

=== Prossimità

//Disegno (abc) tilde 3. Il documento è un array con posizioni numerate. L'idea è

Una prima idea è prendere le 3 liste di posizioni e fare tutte le combinazione e prendere la più piccola. Questo problema non va bene in quanto è polinomiale nel numero di occorrenze dei termini.

L'algoritmo che vedremo trova l'*intervallo minimale*. Ovvero non esiste un intervallo più piccolo di cosi che contiene tutti i termini. Tuvvavia ci possono essere più intervalli minimali.

#warning()[
  La nozione di minimo e minimale essendo un intervallo non totalmente ordinato, non è la stessa cosa. Un intervallo minimale non è detto che sia minimo. Ad esempio se abbiamo due intervalli minimali di lunghezza 3 e 4, il primo è anche minimo, ma il secondo no.
]

L'agoritmo enumera solamente gli intervalli minimali (altrimenti sarebbe polinomiale nel numero di occorrenze dei termini). Per definizione i minimali sono definiti dal loro *estremo sinistro*. Non tutti gli intervalli che generiamo in questo modo sono minimale (ci sono delle ripetizioni all'interno).

L'algorimto lavora in maniera priga, appena trova un intervallo minimale esce, non mi interessa che esso sia minimo.

==== Algoritmo

L'idea è avere una coda indiretta, come se volessimo calcolare l'or delle liste. Il top di questa lista attraversera tutti gli elementi del documento (tutti gli estremi sinistri possibili). Ad ogni istante terremo conto della posizione più avanzata che stiamo fondendo (estremo destro), puntatore all'elemento della coda $k$ che è più avanzato.

La funzione è normale, quando avanziamo il top dobbiamo aggiornare il massimo.

#example()[
  Sulla lista di prima:
  - La coda parte con a in posizione 3, b in pos 5 e b in pos 7. Il massimo è 7. Tra il top e il max abbiamo sempre un intervallo che contiene k termni. Emettiamo l'intervallo [3, 7].

  - A questo punto avanziamo il top diventa 5, il massimo è 11. emettiamo l'intervallo [5, 11].

  - Come prima avanziamo il top diventa 7, il massimo è 16. emettiamo l'intervallo [7, 16].

    Se aggiorno la funzion cambia il top m non il max. Essendoci una ripetizione di b, il top diventa 11, il massimo è 16. emettiamo l'intervallo [11, 16].
]

L'algoritmo è linearitmico nel numero dei termini e lineare nel numero di occorrenze dei termini. $log (k n)$ k è il mumero di termini all'intero dell'operatore, mentre n è il numero di occorrenze dei termini.

//riguardare
Possiamo definire un articatena di intervalli: le zone del documento (sono minimali) che rispettano l'interrogazione. Possiamo dari ad ogni termine una simentica.

Possiamo fare la funsione del primo intervallo con l'ultimo in modo tale da generare gli intervalli minimali

=== dym min

Per gli errori di battitura quello che accade è che la query essendo in linguaggio naruale e non booleano viene risolto prima. In caso di errori di battitirua potremmo usare dei dizionari (dym) di correzione. La parola viene corretta in base alla distanza di edit (il numero di operazioni per trasformare una parola in un'altra). La query in lnguaggio naturale ovviamente viene prima tradotta in query booleana.

== Sorting

A noi arriva una tupla `<d,t,p>`. Per creare questo ci serve una teballa di hash dei termini per vedere se un termine è presente nel documento.

Vogliamo fare un gigantesto sorto, vogliamo creare un ordinamento stabile per $t$. Stabile perchè vogliamo d crescente e le posizioni crescenti. Questo è stato fatto da google tramite map reduce (paradigma che fa sorting e scale in maniera distribuita e molto efficiente).

Il trucco è invertire direttamente in memoria (bucket sort custom). Dato che i termini sono pochi rispetto alle affissioni possiamo costruire direttamente in memoria le liste. Anizhchè avere uan tabelal di hash che associa ad ogni termine l'indice, quello che facciamo è avere una tabella di hash che associa ad ogni termine un vettore di byte (un bit stream) in cui scriviamo la lista compressa

#note()[
  Possiamo usare un codice senza parametri in quanto durante questa fase non sappiamo la distrivuzione dei termini, non so quanto diventano lunghe le liste
]

//aggiungere esempio
Mano a mano che arrivano i dati (in ordine) io vado a costruire le liste di posizioni. Se una lista non è ancora pronta per un documento la tengo aperta. Man mano che arriva la terna di dati `<d,t,p>` vado a scrivere la posizione `p` nella lista di posizioni del termine `t` del documento `d`. Quando arrivo ad un nuovo documento chiudo le liste del documento precedente e le scrivo su disco. In questo modo non ho bisogno di tenere in memoria tutte le liste di posizioni dei termini per tutti i documenti, ma solo quelle del documento corrente. Le liste di affissioni sono dei bit stream.


Come faccio a far diventare in tempo lineare tutti questi indici in un unico indice?
#warning()[
  L'assunzione è avere un ordine lessicografico dei termini. Gli accessi aleatori costerebbero troppi. L'assunzione è che in fase di costruzione dell'indice i termini siano stati salvati in ordine lessicografico. In questo modo possiamo fare un merge delle liste di posizioni dei termini in tempo lineare.
]
//riguardare
nella lista ci saranno il range di indici che definiscono i vari segmenti. per ognuno di questi indici fonderemo la lista dei termini. in parallelo al termine corrente teniamo nell'indice un puntatore che indica dov'è la lista di affissione di quel termine (il quale dovrà anvanzare). All'internod della coda ogni indice punta ad un termine e ogni puntatore di indic epunta ai termini

#example()[
  Supponfo di avre il seguente indice:
  - I_0 ha una lista di affissione per a, b, c
  - I_1 ha una lista di affisione epr b,c,d
  - I-2 ha una lista di affissione per a,b

  Inizialmente il top della coda punta ad a, essa contiene [a,b,a] (in caso di parità vince la posizione dell'indice minore). Per farlo estraiamo i puntatotri degli indici andranno avanti, ma dobbiamo anche spostare i puntatori alle liste di affissioni che sto leggendo, in questo modo vado a leggere interamente la lista intera di a.

  Ogni passo che estraggo un termine nella coda ho pronto il puntatore all'elemento che devo leggere. La procedura di funzione va streaming parallelo sui termini e sui indici. Consumiamo i termini dalle liste di ordine lessigografico e in parallelo consumiamo le liste di affisione degli indici.
]

Man mano che copiamo le liste di affissione nell'output possiamo andare a cambiare il formato di compressione in quanto otteniamo la frequenza totale dei termini. 