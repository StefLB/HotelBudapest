/*
AENDERUNGSOPERATIONEN
Hier sind einige Aenderungsoperationen.

INHALTSANGABE

1.1. freieZimmerAktuellView
1.2. bewohnteZimmerView
1.3. ReinigungspersonalView
1.4. HotelManagerView
1.5. NichtBezahltKundenView
1.6. UnbezahlteReservierungView
1.7. AnreisendeView
1.8. freieKartenView


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

	UPDATE bewohnteZimmerView
	SET dreckig=false 
	WHERE zimmernummer=14 and gehoertzuhotel=2;
	UPDATE bewohnteZimmerView
	SET dreckig=false 
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

	UPDATE ReinigungspersonalView
	SET zimmernummer=14 
	WHERE zimmernummer=14 and gehoertzuhotel=2;
	UPDATE ReinigungspersonalView
	SET zimmernummer=10 
	WHERE zimmernummer=10 and gehoertzuhotel=3;

	DELETE FROM ReinigungspersonalView WHERE gehoertzuhotel=2;
	DELETE FROM ReinigungspersonalView WHERE gehoertzuhotel=3;










