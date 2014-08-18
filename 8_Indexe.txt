/*INDEXE

Hier sind einige Indexe vermerkt, die bei grossem Datenvolumen sehr hilfreich sind.
Die groessten Daten sind:
	1. Reservierungen
	2. Kunden
	3. Speisen und Getraenke
	4. Zimmer
	5. bezahlen
	6. benutzen
	7. mieten
	8. konsumieren

*/


/* 1. Reservierungen*/

	CREATE INDEX index_reservierungen
	ON reservierungen (reservierungsnummer);

/* 2. Kunden */

	CREATE INDEX index_kunden
	ON kunden (kundenid);

/* 3. Speisen und Getraenke*/

	CREATE INDEX index_speisenundgetraenke
	on speisenundgetraenke (speiseid);

/* 4. Zimmer */

	CREATE INDEX index_zimmer
	on zimmer (gehoertzuhotel,zimmernummer);

/* 5.bezahlen */
	
	CREATE INDEX index_bezahlen
	on bezahlen (reservierungsnummer,kid,zeitpunkt);


/* 6.benutzen */

	CREATE INDEX index_benutzen
	on benutzen (gehoertzuhotel,aid,kid,von);


/* 7.mieten */

	CREATE INDEX index_mieten
	on mieten (gehoertzuhotel,aid,kid,von,bis);


/* 8.konsumieren */

	CREATE INDEX index_konsumieren
	on konsumieren (kid, zeitpunkt);