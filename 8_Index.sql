/*INDEXE

Hier sind einige Indexe vermerkt, die bei grossem Datenvolumen sehr hilfreich sind.
	1. Reservierungen
	2. Kunden
	3. wirdserviertin
	4. Zimmer
	5. bezahlen
	6. benutzen
	7. mieten
	8. konsumieren

*/


/* 1. Reservierungen*/

	CREATE INDEX index_reservierungen
	ON reservierungen (anreise,abreise);

/* 2. Kunden */

	CREATE INDEX index_kunden
	ON kunden (vorname,nachname);


/* 3. Speisen und Getraenke*/

	CREATE INDEX index_wirdserviertin
	ON wirdserviertin (gehoertzuhotel,aid);
	
/* 4. Zimmer */

	CREATE INDEX index_zimmer
	ON zimmer (gehoertzuhotel,dreckig);


/* 5.bezahlen */
	
	CREATE INDEX index_bezahlen
	ON bezahlen (kid);


/* 6.benutzen */

	CREATE INDEX index_benutzen
	ON benutzen (kid);

/* 7.mieten */

	CREATE INDEX index_mieten
	ON mieten (kid);

/* 8.konsumieren */

	CREATE INDEX index_konsumieren
	ON konsumieren (kid);

