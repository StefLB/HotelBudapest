/*
AENDERUNGSOPERATIONEN
Hier sind einige Aenderungsoperationen.

INHALTSANGABE

1. AENDERUNGSOPERATIONEN
	1.1. freieZimmerAktuellView
	1.2. bewohnteZimmerView
	1.3. ReinigungspersonalView
	1.4. HotelManagerView
	1.5. NichtBezahltKundenView
	1.6. UnbezahlteReservierungView
	1.7. AnreisendeView
	1.8. freieKartenView

2. TRANSAKTIONEN
	2.1. Herr Hamilton, der heute im Hotel Budapest erwartet wird, ruft an und moechte seine An- und Abreise um einen Tag verschieben.
	2.2. Es gibt einen Rohrbruch in Herrn Duncans Suit Nummer 15, der Kunde muss in eine ander Suite umziehen.
	     Da die Nummer 14 zur Verfügung steht, wird alles umgebucht und Herr Duncan erhaelt eine neue Karte.
	2.3. Frau Cole geht zur Rezeption und gibt Bescheid, dass das Zimmer, was sie eigentlich reserviert hat, auf den
	     Namen ihrer Zimmergenossin laufen soll: Elisabeth Lawson, die auch bereits in der Vergangenheit die Zimmer übernommen hat.
	     Der Rezeptionist aendert es um.	
	2.4. Ein Kunde moechte fuer sein Zimmer mehr Karten erhalten, dafuer muessen im Gegenzug neue Karten dem System zugefuegt werden, da 
	     keine freien Karten zur Verfügung stehen.
*/

/*
1. AENDERUNGSOPERATIONEN

1.1 freieZimmerAktuellView
Info: Diese View ist nur zur Ansicht und sollte nicht veraendert werden koennen. 
Damit es aber vollstaendig ist, notieren wir die gewuenschten Operationen.
*/

	INSERT INTO freieZimmerAktuellView (hotelid,ezom,ezmm,dzom,dzmm,trom,trmm,suit) 
	VALUES (7,5,5,5,5,5,5,5);
	INSERT INTO freieZimmerAktuellView (hotelid,ezom,ezmm,dzom,dzmm,trom,trmm,suit)
	VALUES (8,7,7,7,7,7,7,7);

	UPDATE 	freieZimmerAktuellView
	SET 	ezom=0 
	WHERE 	hotelid=1;
	UPDATE 	freieZimmerAktuellView
	SET 	suit=0 
	WHERE 	hotelid=3;

	DELETE FROM freieZimmerAktuellView WHERE hotelid=1;
	DELETE FROM freieZimmerAktuellView WHERE hotelid=2;



/*
1.2. bewohnteZimmerView
Info: Ein Delete oder Insert macht bei dieser View wenig Sinn. Ein Update muss gewaehrleistet werden
da die Zimmerdreckig() Funktion um 0.00 alle bewohnten Zimmer als dreckig markiert, fuer die ReinigungspersonalView. Ebenso koennen 
Reservierungen auf andere Kunden umgeschrieben werden. 
*/

	INSERT INTO bewohnteZimmerView (gehoertzuhotel,zimmernummer,anreise,abreise,dreckig) 
	VALUES (1,3,'2014-09-01','2014-09-01', true);
	INSERT INTO bewohnteZimmerView (gehoertzuhotel,zimmernummer,anreise,abreise,dreckig) 
	VALUES (1,3,'2014-09-01','2014-09-01', true);

	-- Dieses Zimmer ist dreckig. 
	UPDATE 	bewohnteZimmerView
	SET 	dreckig=true 
	WHERE 	zimmernummer=14 and gehoertzuhotel=2;
	-- Ms. West moechte ihr Zimmer ueber ihre Partnerin Ms. Kelly laufen lassen
	UPDATE 	bewohnteZimmerView
	SET 	reserviertVonKunde = 27 
	WHERE 	reserviertVonKunde = 8;

	DELETE FROM bewohnteZimmerView WHERE gehoertzuhotel=2;
	DELETE FROM bewohnteZimmerView WHERE gehoertzuhotel=5;

/*
1.3. ReinigungspersonalView
Info: Obwohl ein Insert oder Delete hier nicht sinnvoll ist, macht ein Update von dreckig = false Sinn, etwa
wenn das Reinigungspersonal die Arbeit an einem Zimmer beendet hat. 
*/
	INSERT INTO ReinigungspersonalView (gehoertzuhotel,zimmernummer,grossputz) 
	VALUES (1,3,true);
	INSERT INTO ReinigungspersonalView (gehoertzuhotel,zimmernummer,grossputz) 
	VALUES (6,4,false);

	-- Zimmerreinigung
	UPDATE 	ReinigungspersonalView
	SET 	zimmernummer=14 
	WHERE 	zimmernummer=14 and gehoertzuhotel=2;
	UPDATE 	ReinigungspersonalView
	SET 	zimmernummer=10 
	WHERE 	zimmernummer=10 and gehoertzuhotel=3;

	DELETE FROM ReinigungspersonalView WHERE gehoertzuhotel=2;
	DELETE FROM ReinigungspersonalView WHERE gehoertzuhotel=3;

/*
1.4.HotelManagerView
Info: Diese View ist nur zur Ansicht und sollte nicht veraendert werden koennen. 
Aufgrund der Tatsache, dass diese Sicht aus vielen Tabellen mit GROUP BY entsteht, ist kein INSERT,UPDATE,DELETE moeglich.
*/

	INSERT INTO HotelManagerView (hotelID,gesamtumsatz) VALUES (7,'500,00 €');
	INSERT INTO HotelManagerView (hotelID,gesamtumsatz) VALUES (8,'30.000,00 €');

	UPDATE 	HotelManagerView
	SET 	gesamtumsatz='5.000,00€' 
	WHERE 	hotelid=1;
	UPDATE 	HotelManagerView
	SET 	barumsatz='500,00€' 
	WHERE 	hotelid=6;

	DELETE FROM HotelManagerView WHERE hotelid=2;
	DELETE FROM HotelManagerView WHERE hotelid=3;


/*
1.5. NichtBezahltKundenView
Info: Diese View ist nur zur Ansicht und sollte nicht veraendert werden koennen.
Die RULES sind entsprechend implementiert, sodass kein INSERT,UPDATE,DELETE moeglich ist. 
*/

	INSERT INTO NichtbezahltKundenview (resa, kunde) 
	VALUES(100,88);
	INSERT INTO NichtbezahltKundenview (resa, kunde) 
	VALUES(101,77);

	UPDATE 	NichtbezahltKundenview
	SET 	anreise='2014-01-05' 
	WHERE 	gehoertzuhotel=2;
	UPDATE 	NichtbezahltKundenview
	SET 	anreise='2014-06-05' 
	WHERE 	gehoertzuhotel=6;

	DELETE FROM NichtbezahltKundenview WHERE gehoertzuhotel=2;
	DELETE FROM NichtbezahltKundenview WHERE gehoertzuhotel=6;	

/*
1.6.UnbezahlteReservierungView
Ein Insert oder Update in dieser View ist nicht moeglich. Ein Delete entspricht dem bezahlen einer Rechnung.
*/

	INSERT INTO UnbezahlteReservierungView (hotelid, reservierungsnummer) 
	VALUES(7,77);
	INSERT INTO UnbezahlteReservierungView (hotelid, reservierungsnummer) 
	VALUES(8,88);

	UPDATE UnbezahlteReservierungView
	SET konsumiert='50,00 €' 
	WHERE reservierungsnummer=8;
	UPDATE UnbezahlteReservierungView
	SET gemietet='18,00 €' 
	WHERE reservierungsnummer=12;

	-- Ms. Reed und Mr. Riley haben ihre Rechnung bezahlt 
	DELETE FROM UnbezahlteReservierungView WHERE kunde=89;
	DELETE FROM UnbezahlteReservierungView WHERE reservierungsnummer=25;

/*
1.7. AnreisendeView
Info: Ein Delete wuerde einer Stornierung gleichkommen. Ein Insert macht hier wenig Sinn, dafuer gibt es die ZimmerAnfrage-Funktion.
Ein Update koennte in Sinn machen. Beispielsweise weiss die Rezeptionsleitung, dass ein prominenter Gast anreist und moechte die VIP Austattung des 
Zimmers gewaehrleisten, und moechte den Kunden vielleicht auch in ein anderes Zimmer umbuchen. 
Es sei erwaehnt, dass Sichten, die WITH enthalten, nicht automatisch aktualisierbar sind.
*/

	INSERT INTO AnreisendeView (gehoertzuhotel, zimmer) 
	VALUES(4,10);
	INSERT INTO AnreisendeView (gehoertzuhotel, zimmer) 
	VALUES(5,12);

	-- Herr Frazier ist prominent
	UPDATE AnreisendeView
	SET Vip=true
	WHERE gehoertzuhotel=1 and zimmer=1;
	-- Herr Hamilton soll manuell in besseres Zimmer umgebucht werden
	UPDATE AnreisendeView
	SET Zimmer= 40 
	WHERE gehoertzuhotel=1 and zimmer=10;

	-- Stornierung
	DELETE FROM AnreisendeView WHERE gehoertzuhotel=1 and reservierungsnummer=1;
	DELETE FROM AnreisendeView WHERE gehoertzuhotel=4 and reservierungsnummer=5;

/*
1.8. freieKartenView
Info: Wir koennen mit Insert neue Karten ins System einspeisen. Kaputte Karten koennen wir mit Delete loeschen. 
Ein Update des Karten ID macht kein Sinn. 
*/

	-- Wir erzeugen ein Paar neue Karten
	INSERT INTO freiekartenview (kartenid) 
	VALUES(DEFAULT);
	INSERT INTO freiekartenview (kartenid) 
	VALUES(DEFAULT);

	UPDATE 	freiekartenview
	SET 	kartenid=5
	WHERE 	kartenid=6;
	UPDATE 	freiekartenview
	SET 	kartenid=19
	WHERE 	kartenid=8;

	-- die eben erzeugten karten sind in Schwefelsauere gefallen. 
	DELETE FROM freiekartenview WHERE kartenid IN (SELECT kartenid  FROM freiekartenview ORDER BY kartenID DESC FETCH FIRST 1 ROWS ONLY);
	DELETE FROM freiekartenview WHERE kartenid IN (SELECT kartenid  FROM freiekartenview ORDER BY kartenID DESC FETCH FIRST 1 ROWS ONLY);

/* ENDE AENDERUNGEN*/

/* 
2. Transaktionen 
*/

/*2.1 Anreise und Abreise um einen Tag verschieben */

	BEGIN;
		UPDATE 	anreisendeview
		SET 	anreise = current_date + interval '1 day'
		WHERE 	reservierungsnummer=1;
		-- Anreise verschoeben
		UPDATE 	reservierungen
		SET 	gaestestatus='RESERVED'
		Where 	reservierungsnummer=1;
		-- Gaestestatus auf RESERVED geaendert
		UPDATE 	anreisendeview
		SET 	abreise = '2014-10-21'
		WHERE 	reservierungsnummer=1 AND EXISTS (
		SELECT	*
		FROM	ZimmerFreiAnDate(1, 'DZMM'::Zimmerkategorie, '2014-10-20'::date, '2014-10-21'::date)
		WHERE 	zimmernummer=10);
		-- Abreise umaendert, wenn Zimmer frei
	COMMIT;

/*2.2 Herr Duncan muss umziehen*/

	BEGIN;
		UPDATE 	bewohntezimmerview
		SET 	zimmernummer = 14
		WHERE 	reserviertvonkunde = 44;
		--Zimmernummer gewechselt

		UPDATE 	zimmer
		SET 	outoforder=true
		WHERE 	zimmernummer = 15 AND gehoertzuhotel = 4;
		-- Zimmer Nr. 15 muss out of order gestellt werden

		-- die Zimmerkarte muss nicht getauscht werden, da sie an der Reservierungsnummer gekoppelt ist, sie wird automatisch nicht mehr die 
		-- die 15 oeffnen koennen, sondern nur die 14
	COMMIT;

/*2.3 Umschreiben des Kundens von 88 auf 12, Reservierungsnummer 18*/

	BEGIN;
		UPDATE 	bewohntezimmerview
		SET 	reserviertvonkunde = 12
		WHERE 	reserviertvonkunde =88 AND reservierungsnummer=18;
		--Reservierung wird auf neuen Kunden umgeschrieben

		UPDATE 	erhalten
		SET 	kundenid=12
		WHERE 	Reservierungsnummer=18;
		-- Karten werden umgeschrieben

		UPDATE 	konsumieren
		SET 	kid = 12
		WHERE 	kid=88 AND zeitpunkt >= (SELECT anreise FROM bewohntezimmerview WHERE reserviertvonkunde=12) 
			AND zeitpunkt <= (SELECT abreise FROM bewohntezimmerview WHERE reserviertvonkunde=12);
		--konsumieren muss umgeschrieben werden

		UPDATE mieten
		SET kid = 12
		WHERE kid=88 AND von >= (SELECT anreise FROM bewohntezimmerview WHERE reserviertvonkunde=12) 
		and bis <= (SELECT abreise FROM bewohntezimmerview WHERE reserviertvonkunde=12) ;
		--mieten muss umgeschrieben werden

		--benutzen muss nicht umgeschrieben werden, da Hotel 6 kein Schwimmbad hat
	COMMIT;

/*2.4 Ausgabe und hinzufuegen von 3 Karten für Kunde 86 mit der Reservierngsnummer 26*/

	BEGIN;
		INSERT INTO freiekartenView VALUES
		(DEFAULT),
		(DEFAULT),
		(DEFAULT);

		INSERT INTO erhalten (kundenid,kartenid,reservierungsnummer) VALUES
		(86, (SELECT kartenid FROM freiekartenView FETCH FIRST 1 ROWS ONLY), 26);

		INSERT INTO erhalten (kundenid,kartenid,reservierungsnummer) VALUES
		(86, (SELECT kartenid FROM freiekartenView FETCH FIRST 1 ROWS ONLY), 26);

		INSERT INTO erhalten (kundenid,kartenid,reservierungsnummer) VALUES
		(86, (SELECT kartenid FROM freiekartenView FETCH FIRST 1 ROWS ONLY), 26);

	COMMIT;
	

