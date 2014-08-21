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
	2.1 Herr 'Hamilton', der heute im Hotel 'Budapest erwartet wird, ruft an und moechte seine An- und Abreise um einen Tag verschieben.
	2.2 Es gibt einen Rohrbruch in Herrn 'Duncans' Suit Nummer 15, der Kunde muss in eine ander Suite umziehen.
	    Da die Nummer 14 zur Verfügung steht, wird alles umgebucht und Herr Duncan erhaelt eine neue Karte.
	2.3 Frau 'Cole' geht zur Rezeption und gibt Bescheid, dass das Zimmer, was sie eigentlich reserviert hat, auf den
	    Namen ihrer Zimmergenossin laufen soll: Elisabeth Lawson, die auch bereits in der Vergangenheit die Zimmer übernommen hat.
	    Der Rezeptionist aendert es um.	
*/

/*
1. AENDERUNGSOPERATIONEN

1.1 freieZimmerAktuellView
Info: Diese View ist nur zur Ansicht und sollte nicht verändert werden koennen.
Da die View ein GROUP BY enthält, bräuchte man auch weitere Rules oder ein DO INSTEAD Trigger auf den Operationen,
damit diese funktionieren. Transaktionen sind daher auf der View ebenfalls nicht moeglich. 
Damit es aber vollstaendig ist, notieren wir die gewuenschten Operationen.
*/

	INSERT INTO freieZimmerAktuellView (hotelid,ezom,ezmm,dzom,dzmm,trom,trmm,suit) 
	VALUES (7,5,5,5,5,5,5,5);
	INSERT INTO freieZimmerAktuellView (hotelid,ezom,ezmm,dzom,dzmm,trom,trmm,suit)
	VALUES (8,7,7,7,7,7,7,7);

	UPDATE freieZimmerAktuellView
	SET ezom=0 
	WHERE hotelid=1;
	UPDATE freieZimmerAktuellView
	SET suit=0 
	WHERE hotelid=3;

	DELETE FROM freieZimmerAktuellView WHERE hotelid=1;
	DELETE FROM freieZimmerAktuellView WHERE hotelid=2;


/*
1.2. bewohnteZimmerView
Info: Ein Delete oder Insert macht bei dieser View wenig Sinn. Ein Update muss gewaehrleistet werden
da die Zimmerdreckig() Funktion um 0.00 alle bewohnten Zimmer als dreckig markiert, fuer die ReinigungspersonalView.
Damit es aber vollstaendig ist, notieren wir die gewuenschten Operationen. 
Update kann verwendet werden, um Zimmer auf gereinigt umzuschalten (dreckig=false).
*/

	INSERT INTO bewohnteZimmerView (gehoertzuhotel,zimmernummer,anreise,abreise,dreckig) 
	VALUES (1,3,'2014-09-01','2014-09-01', true);
	INSERT INTO bewohnteZimmerView (gehoertzuhotel,zimmernummer,anreise,abreise,dreckig) 
	VALUES (1,3,'2014-09-01','2014-09-01', true);

	-- Diese Zimmer sind dreckig. 
	UPDATE bewohnteZimmerView
	SET dreckig=true 
	WHERE zimmernummer=14 and gehoertzuhotel=2;
	UPDATE bewohnteZimmerView
	SET dreckig=true 
	WHERE zimmernummer=10 and gehoertzuhotel=3;

	DELETE FROM bewohnteZimmerView WHERE gehoertzuhotel=2;
	DELETE FROM bewohnteZimmerView WHERE gehoertzuhotel=5;

/*
1.3. ReinigungspersonalView
Zeigt an: alle Zimmer, die dreckig sind. Es wird angezeigt, ob ein Grossputz von Noeten ist.
Info: Obwohl ein Insert oder Delete hier nicht sinnvoll ist, macht ein Update von dreckig von true auf false Sinn, etwa
wenn das Reinigungspersonal die Arbeit an einem Zimmer beendet hat. 
*/
	INSERT INTO ReinigungspersonalView (gehoertzuhotel,zimmernummer,dreckig,grossputz) 
	VALUES (1,3,false,true);
	INSERT INTO ReinigungspersonalView (gehoertzuhotel,zimmernummer,dreckig,grossputz) 
	VALUES (6,4,true,false);

	-- Zimmerreinigung
	UPDATE ReinigungspersonalView
	SET zimmernummer=14 
	WHERE zimmernummer=14 and gehoertzuhotel=2;
	UPDATE ReinigungspersonalView
	SET zimmernummer=10 
	WHERE zimmernummer=10 and gehoertzuhotel=3;

	DELETE FROM ReinigungspersonalView WHERE gehoertzuhotel=2;
	DELETE FROM ReinigungspersonalView WHERE gehoertzuhotel=3;

/*
1.4.HotelManagerView
Info: Diese View ist nur zur Ansicht und sollte nicht verändert werden koennen. 
Aufrund der Tatsache, dass diese Sicht aus vielen Tabellen mit GROUP BY entsteht, ist kein INSERT,UPDATE,DELETE möglich.
*/

	INSERT INTO HotelManagerView (gehoertzuhotel,gesamtumsatz) 
	VALUES (7,'500,00 €');
	INSERT INTO HotelManagerView (gehoertzuhotel,gesamtumsatz) VALUES (8,'30.000,00 €');

	UPDATE HotelManagerView
	SET gesamtumsatz='5.000,00€' 
	WHERE hotelid=1;
	UPDATE HotelManagerView
	SET barumsatz='500,00€' 
	WHERE hotelid=6;

	DELETE FROM HotelManagerView WHERE hotelid=2;
	DELETE FROM HotelManagerView WHERE hotelid=3;


/*
1.5. NichtBezahltKundenView
Info: Diese View ist nur zur Ansicht und sollte nicht verändert werden koennen.
RULES entsprechend implementiert. Kein INSERT,UPDATE,DELETE. 
*/

	INSERT INTO NichtbezahltKundenview (resa, kunde) 
	VALUES(100,88);
	INSERT INTO NichtbezahltKundenview (resa, kunde) 
	VALUES(101,77);

	UPDATE NichtbezahltKundenview
	SET anreise='2014-01-05' 
	WHERE gehoertzuhotel=2;
	UPDATE NichtbezahltKundenview
	SET anreise='2014-06-05' 
	WHERE gehoertzuhotel=6;

	DELETE FROM NichtbezahltKundenview WHERE gehoertzuhotel=2;
	DELETE FROM NichtbezahltKundenview WHERE gehoertzuhotel=6;	

/*
1.6.UnbezahlteReservierungView
Info: Diese View ist nur zur Ansicht und sollte nicht verändert werden koennen.
RULES entsprechend implementiert. Kein INSERT,UPDATE,DELETE.
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

	DELETE FROM UnbezahlteReservierungView WHERE hotelid=2;
	DELETE FROM UnbezahlteReservierungView WHERE hotelid=6;


/*
1.7. AnreisendeView
Info: Ein Delete wuerde einer Stornierung gleichkommen. Ein Insert macht hier wenig Sinn, dafuer gibt es die ZimmerAnfrage-Funktion.
Ein Update koennte in Sinn machen. Beispielsweise weiss die Rezeptionsleitung, dass ein prominenter Gast anreist und moechte die VIP Austattung des 
Zimmers gewaehrleisten, und moechte den Kunden vielleicht auch in ein anderes Zimmer umbuchen. 
Sei erwaehnt, dass Sichten, die WITH enthalten, nicht automatisch aktualisierbar sind.
*/

	INSERT INTO AnreisendeView (gehoertzuhotel, zimmer) 
	VALUES(4,10);
	INSERT INTO AnreisendeView (gehoertzuhotel, zimmer) 
	VALUES(5,12);

	-- Gast ist prominent
	UPDATE AnreisendeView
	SET Vip=true
	WHERE gehoertzuhotel=1 and zimmer=10;
	-- Gast soll manuell in besseres Zimmer umgebucht werden
	UPDATE AnreisendeView
	SET Zimmernummer= 40 
	WHERE gehoertzuhotel=1 and zimmer=10 

	DELETE FROM AnreisendeView WHERE gehoertzuhotel=1 and reservierungsnummer=1;
	DELETE FROM AnreisendeView WHERE gehoertzuhotel=4 and reservierungsnummer=5;

/*
1.8. freieKartenView
Info: Da wir bei einem Insert oder Delete nicht wissen ob eine Karte ausgeteilt oder beschaedigt ist, 
koennen wir keine eindeutige Aktion ableiten. Ein Update des Karten ID macht kein Sinn. 
*/

	INSERT INTO freiekartenview (kartenid) 
	VALUES(DEFAULT);
	INSERT INTO freiekartenview (kartenid) 
	VALUES(DEFAULT);

	UPDATE freiekartenview
	SET kartenid=5
	WHERE kartenid=6;
	UPDATE freiekartenview
	SET kartenid=19
	WHERE kartenid=8;

	DELETE FROM freiekartenview WHERE kartenid=12;
	DELETE FROM freiekartenview WHERE kartenid=13;
	
/* ENDE AENDERUNGEN*/

/* 
2. Transaktionen 
*/

/*2.1 Anreise und Abreise um einen Tag verschieben */

	BEGIN;
		UPDATE anreisendeview
		SET anreise = current_date + interval '1 day'
		WHERE reservierungsnummer=1;
		--Anreise verschoeben
		UPDATE reservierungen
		SET gaestestatus='RESERVED'
		Where reservierungsnummer=1;
		-gaestestatus auf RESERVED geaendert
		UPDATE anreisendeview
		SET abreise = '2014-10-21'
		WHERE reservierungsnummer=1 and EXISTS (
		SELECT*
		from
		ZimmerFreiAnDate(1, 'DZMM', '2014-10-20', '2014-10-21')
		WHERE zimmernummer=10);
		--Abreise umaendert, wenn Zimmer frei
	COMMIT;

/*2.2 Herr Duncan muss umziehen*/

	BEGIN;
		UPDATE bewohntezimmerview
		SET zimmernummer = 14
		WHERE reserviertvonkunde = 44;
		--Zimmernummer gewechselt

		UPDATE zimmer
		SET outoforder=true
		WHERE zimmernummer = 15 and gehoertzuhotel = 4;
		-- Zimmer Nr. 15 muss out of order gestellt werden

		-- die Zimmerkarte muss nicht getauscht werden, da sie an der Reservierungsnummer gekoppelt ist, sie wird automatisch nicht mehr die 
		-- die 15 oeffnen koennen, sondern nur die 14

	COMMIT;

/*2.3 Umschreiben des Kundens von 88 auf 12, Reservierungsnummer 18*/

	BEGIN;
		UPDATE bewohntezimmerview
		SET reserviertvonkunde = 12
		WHERE reserviertvonkunde =88 and reservierungsnummer=18
		--Reservierung wird auf neuen Kunden umgeschrieben

		UPDATE erhalten
		SET kundenid=12
		WHERE Reservierungsnummer=18
		-- Karten werden umgeschrieben

		UPDATE konsumieren
		SET kid = 12
		WHERE kid=88 and zeitpunkt >= (SELECT anreise from bewohntezimmerview where reserviertvonkunde=12) 
		and zeitpunkt <= (SELECT abreise from bewohntezimmerview where reserviertvonkunde=12) 
		--konsumieren muss umgeschrieben werden

		UPDATE mieten
		SET kid = 12
		WHERE kid=88 and von >= (SELECT anreise from bewohntezimmerview where reserviertvonkunde=12) 
		and bis <= (SELECT abreise from bewohntezimmerview where reserviertvonkunde=12) 
		--mieten muss umgeschrieben werden

		--benutzen muss nicht umgeschrieben werden, da Hotel 6 kein Schwimmbad hat
	COMMIT;

