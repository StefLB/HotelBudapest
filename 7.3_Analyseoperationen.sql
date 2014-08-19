/* ANALYSOPERATIONEN



	1. Wir wollen die Hotels betrachten, die mehr als 10.000 EUR Umsatz erzielt haben.
	2. 
Welche Anreisenden Gaeste werden mehr als 100 Tage bei uns uebernachten.
	3. Wieviele Gaeste pro Hotel gibt es, die mehr als 4000 EUR noch nicht bezahlte Rechnungen haben?	
	4.
 Die Zimmerbelegung aller Häuser in Prozent
	5.

*/


/* 1. Gesamtumsatz */

	SELECT sum(gesamtumsatz) as grosshotels
	FROM hotelmanagerview
	GROUP BY gesamtumsatz
	HAVING gesamtumsatz > '10.000,00 €';

/*2. Auswahl Gaeste, die merh als 100 Tage uebernachten werden*/

	
	SELECT gehoertzuhotel, zimmernummer, anreise, abreise, dreckig, max(abreise-anreise)
	from bewohntezimmerview
	GROUP BY gehoertzuhotel, zimmernummer, anreise, abreise, dreckig
	HAVING (abreise-anreise) > 100;

/*3. Anzahl der nichtbezahlten Gaeste */

	SELECT hotelid, count(kunde)
	FROM unbezahltereservierungview
	GROUP BY hotelid, gesamtoffen
	HAVING gesamtoffen > '4.000,00 €';

/*4. Zimerbelegung */

	WITH Gesamtezimmer as (SELECT gehoertzuhotel, count (zimmerkategorie) as Gesamtzimmeranzahl
	from zimmer
	GROUP BY gehoertzuhotel
	ORDER BY gehoertzuhotel), BelegteZimmer as
	(SELECT gehoertzuhotel, count (zimmernummer) as belegtezimmeranzahl
	from bewohntezimmerview
	GROUP BY gehoertzuhotel
	ORDER BY gehoertzuhotel)

	SELECT gesamtezimmer.gehoertzuhotel, gesamtzimmeranzahl, COALESCE(belegtezimmeranzahl,0) as belegtezimmeranzahl, (belegtezimmeranzahl*100/gesamtzimmeranzahl) as zimmerbelegung 
	FROM Gesamtezimmer
	LEFT OUTER JOIN
	BelegteZimmer
	on gesamtezimmer.gehoertzuhotel = BelegteZimmer.gehoertzuhotel;

/*5. */


