-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S7: Indexen
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- ------------------------------------------------------------------------
-- LET OP, zoals in de opdracht op Canvas ook gezegd kun je informatie over
-- het query plan vinden op: https://www.postgresql.org/docs/current/using-explain.html


-- S7.1.
--
-- Je maakt alle opdrachten in de 'sales' database die je hebt aangemaakt en gevuld met
-- de aangeleverde data (zie de opdracht op Canvas).
--
-- Voer het voorbeeld uit wat in de les behandeld is:
-- 1. Voer het volgende EXPLAIN statement uit:
--    EXPLAIN SELECT * FROM order_lines WHERE stock_item_id = 9;
--    Bekijk of je het resultaat begrijpt. Kopieer het explain plan onderaan de opdracht

-- 2. Voeg een index op stock_item_id toe:
--    CREATE INDEX ord_lines_si_id_idx ON order_lines (stock_item_id);
-- 3. Analyseer opnieuw met EXPLAIN hoe de query nu uitgevoerd wordt
--    Kopieer het explain plan onderaan de opdracht
-- 4. Verklaar de verschillen. Schrijf deze hieronder op.

-- S7.1.1.
Seq Scan on order_lines  (cost=0.00..39.61 rows=6 width=97)
-- S7.1.3.
Bitmap Heap Scan on order_lines  (cost=4.32..19.21 rows=6 width=97)
Recheck Cond: (stock_item_id = 9)
Bitmap Index Scan on ord_lines_si_id_idx  (cost=0.00..4.32 rows=6 width=0)
Index Cond: (stock_item_id = 9)
-- S7.1.4.
doordat er in het tweede voorbeeld gebruik wordt gemaakt van een index kan de query sneller worden uitgevoerd.
Zonder index moet de database alle rijen doorlopen om de juiste te vinden. Met index hoeft dit niet en kan de database
direct de juiste rij vinden waardoor de query sneller wordt uitgevoerd wat ook te zien is in de explain plan door de lagere cost.



-- S7.2.
--
-- 1. Maak de volgende twee query’s:
-- 	  A. Toon uit de order tabel de order met order_id = 73590
-- 	  B. Toon uit de order tabel de order met customer_id = 1028
-- 2. Analyseer met EXPLAIN hoe de query’s uitgevoerd worden en kopieer het explain plan onderaan de opdracht
-- 3. Verklaar de verschillen en schrijf deze op
-- 4. Voeg een index toe, waarmee query B versneld kan worden
-- 5. Analyseer met EXPLAIN en kopieer het explain plan onder de opdracht
-- 6. Verklaar de verschillen en schrijf hieronder op

-- 7.2.2
Index Scan using pk_sales_orders on orders  (cost=0.29..8.31 rows=1 width=155)
Seq Scan on orders  (cost=0.00..1819.94 rows=107 width=155)

-- 7.2.3
Order_id is een primairy key en dus uniek daarom wordt er automatisch gebruik gemaakt van een indexscan.
Customer_id is geen primairy key en dus niet uniek daarom wordt er gebruik gemaakt van een sequentiele scan.

-- 7.2.5
Bitmap Heap Scan on orders  (cost=5.12..308.96 rows=107 width=155)
Bitmap Index Scan on orders_customer_id_idx  (cost=0.00..5.10 rows=107 width=0)

-- 7.2.6
Door het toevoegen van een index kan de database sneller de juiste rij vinden waardoor de query sneller wordt uitgevoerd.

-- S7.3.A
--
-- Het blijkt dat customers regelmatig klagen over trage bezorging van hun bestelling.
-- Het idee is dat verkopers misschien te lang wachten met het invoeren van de bestelling in het systeem.
-- Daar willen we meer inzicht in krijgen.
-- We willen alle orders (order_id, order_date, salesperson_person_id (als verkoper),
--    het verschil tussen expected_delivery_date en order_date (als levertijd),  
--    en de bestelde hoeveelheid van een product zien (quantity uit order_lines).
-- Dit willen we alleen zien voor een bestelde hoeveelheid van een product > 250
--   (we zijn namelijk. als eerste geïnteresseerd in grote aantallen want daar lijkt het vaker mis te gaan)
-- En verder willen we ons focussen op verkopers wiens bestellingen er gemiddeld langer over doen.u
-- De meeste bestellingen kunnen binnen een dag bezorgd worden, sommige binnen 2-3 dagen.
-- Het hele bestelproces is er op gericht dat de gemiddelde bestelling binnen 1.45 dagen kan worden bezorgd.
-- We willen in onze query dan ook alleen de verkopers zien wiens gemiddelde levertijd 
--  (expected_delivery_date - order_date) over al zijn/haar bestellingen groter is dan 1.45 dagen.
-- Maak om dit te bereiken een subquery in je WHERE clause.
-- Sorteer het resultaat van de hele geheel op levertijd (desc) en verkoper.
-- 1. Maak hieronder deze query (als je het goed doet zouden er 377 rijen uit moeten komen, en het kan best even duren...)
SELECT o.order_id, o.order_date, o.salesperson_person_id AS verkoper,
    (o.expected_delivery_date - o.order_date) AS levertijd,
    ol.quantity AS bestelde_hoeveelheid
FROM orders o
INNER JOIN order_lines ol ON o.order_id = ol.order_id
WHERE ol.quantity > 250
    AND o.salesperson_person_id IN (
        SELECT o2.salesperson_person_id
        FROM orders o2
        GROUP BY o2.salesperson_person_id
        HAVING AVG(o2.expected_delivery_date - o2.order_date) > 1.45
    )
ORDER BY levertijd DESC, verkoper;

-- S7.3.B
--
-- 1. Vraag het EXPLAIN plan op van je query (kopieer hier, onder de opdracht)
-- 2. Kijk of je met 1 of meer indexen de query zou kunnen versnellen
-- 3. Maak de index(en) aan en run nogmaals het EXPLAIN plan (kopieer weer onder de opdracht) 
-- 4. Wat voor verschillen zie je? Verklaar hieronder.

CREATE INDEX idx_orders_order_id ON orders(order_id);

Gather Merge  (cost=9702.31..9728.67 rows=226 width=20)
->  Sort  (cost=8702.28..8702.56 rows=113 width=20)
               ->  Hash Join  (cost=2188.42..8698.43 rows=113 width=20)
                     ->  Nested Loop  (cost=0.29..6508.61 rows=376 width=20)
                           ->  Parallel Seq Scan on order_lines ol  (cost=0.00..5051.27 rows=376 width=8)
                           ->  Index Scan using pk_sales_orders on orders o  (cost=0.29..3.88 rows=1 width=16)




EXPLAIN
SELECT o.order_id, o.order_date, o.salesperson_person_id AS verkoper,
       (o.expected_delivery_date - o.order_date) AS levertijd,
       ol.quantity AS bestelde_hoeveelheid
FROM orders o
         INNER JOIN order_lines ol ON o.order_id = ol.order_id
WHERE ol.quantity > 250
  AND o.salesperson_person_id IN (
    SELECT o2.salesperson_person_id
    FROM orders o2
    GROUP BY o2.salesperson_person_id
    HAVING AVG(o2.expected_delivery_date - o2.order_date) > 1.45
)
ORDER BY levertijd DESC, verkoper;

-- de indexen:
CREATE INDEX idx_orders_order_id ON orders(order_id);
CREATE INDEX idx_order_lines_order_id ON order_lines(order_id);
CREATE INDEX idx_orders_salesperson_person_id ON orders(salesperson_person_id);

Het explain plan is nog steeds hetzelfde

Het zou kunnen omdat de query zeer complex is met veel bewerkingen en join waardoor de indexen veel minder invloed hebben op de snelheid van de query.

-- S7.3.C
--
-- Zou je de query ook heel anders kunnen schrijven om hem te versnellen?
Ja, je zou bijvoorbeeld de subquery kunnen vervangen door een join waardoor de query minder complex wordt en de indexen meer invloed hebben op de snelheid van de query.


