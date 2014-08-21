/* 
LOGISCHE DATENUNABHAENGIGKEIT
Hier sind einige Views und Rules unseres Hotelsystems. 

INHALTSANGABE

1.VIEWS
	1.1. freieZimmerAktuellView
	1.2. bewohnteZimmerView
	1.3. ReinigungspersonalView
	1.4. HotelManagerView
	1.5. NichtBezahltKundenView
	1.6. UnbezahlteReservierungView
	1.7. AnreisendeView
	1.8. freieKartenView

2.RULES
	2.1. freieZimmerView
	2.2. bewohnteZimmerView
	2.3. ReinigungspersonalView
	2.4. HotelManagerView
	2.5. NichtBezahltKundenView
	2.6. UnbezahlteReservierungView
	2.7. AnreisendeView
	2.8. freieKartenView
	2.9. kartenGueltigInsert


1.VIEWS

1.1. freieZimmerAktuellView
Zeigt an: Hotels, die noch aktuell freie Zimmer haben, mit Kategorie und Anzahlzimmer in Kategorie
Benoetigt fuer: Statistiken bzgl. Auslastung oder kurzfristige Umbuchungen
*/
CREATE OR REPLACE VIEW freieZimmerAktuellView AS
	SELECT hotelid, count(CASE WHEN zimmerkategorie='EZOM' THEN 1 ELSE NULL END) as ezom, 
			count(CASE WHEN zimmerkategorie='EZMM' THEN 1 ELSE NULL END) as ezmm, 
			count(CASE WHEN zimmerkategorie='DZOM' THEN 1 ELSE NULL END) as dzom, 
			count(CASE WHEN zimmerkategorie='DZMM' THEN 1 ELSE NULL END) as dzmm, 
			count(CASE WHEN zimmerkategorie='TROM' THEN 1 ELSE NULL END) as trom, 
			count(CASE WHEN zimmerkategorie='TRMM' THEN 1 ELSE NULL END) as trmm, 
			count(CASE WHEN zimmerkategorie='SUIT' THEN 1 ELSE NULL END) as suit
			FROM	(SELECT*
				FROM
				(SELECT gehoertzuhotel as hotelid, zimmernummer, zimmerkategorie
				FROM 	zimmer) AS AlleZimmer -- allezimmer in allen hotels
				EXCEPT 	
				(SELECT gehoertzuhotel, zimmer, zimmerkategorie
				FROM 	reservierungen
				WHERE 	Anreise=current_date AND zimmer!= NULL 
					OR Gaestestatus = 'IN-HOUSE' 
					OR Gaestestatus='CANCELED' 
					OR Gaestestatus='TURN-DOWN')) as SELEKTION--BelegteZimmer)
			GROUP BY hotelid
			ORDER BY hotelid;


/*
1.2. bewohnteZimmerView
Zeigt an: alle Zimmer in der ein Gast zur Zeit anwesend ist. 
Benoetigt fuer: die Funktion Zimmerdreckig() die in der Nacht alle bewohnten Zimmer auf dreckig umstellt, sowie
ReinigungspersonalView. 
*/
CREATE OR REPLACE VIEW bewohnteZimmerView AS
	SELECT	Zimmer.gehoertZuHotel, Zimmernummer, reserviertVonKunde, Anreise, Abreise, dreckig
	FROM 	Reservierungen 
	JOIN 	Zimmer ON (Reservierungen.Zimmer= Zimmer.Zimmernummer 
		AND  Reservierungen.gehoertZuHotel = Zimmer.gehoertZuHotel) 
	WHERE 	GaesteStatus = 'IN-HOUSE';


/*
1.3. ReinigungspersonalView
Zeigt an: alle Zimmer, die dreckig sind, sowie ob ein Grossputz von Noeten ist. 
ReserviertVonKunde wird dem Reinigungspersonal bewusst nicht angezeigt um Diskretion zu gewaehrleisten. 
Benoetigt fuer: Das Reinigunspersonal bekommt diese angezeigt, sortiert nach Hotel und Zimmernummer
*/
CREATE OR REPLACE VIEW ReinigungspersonalView AS

	SELECT AlledreckigenZimmer.gehoertzuhotel, Alledreckigenzimmer.zimmernummer, COALESCE(grossputz, 'false') as grossputz
	FROM
	(SELECT  Zimmer.gehoertZuHotel, Zimmer.Zimmernummer
	FROM 	Zimmer
	WHERE 	Zimmer.dreckig=true) as AlleDreckigenZimmer
	-- Wahl aller dreckigen Zimmer

	LEFT OUTER JOIN

	(SELECT gehoertzuhotel,zimmernummer, CASE WHEN ((current_date - Anreise > 14)
		OR abreise = current_date) THEN TRUE ELSE FALSE END AS grossputz
	from bewohntezimmerview) as DerGrossputz
	ON AlledreckigenZimmer.gehoertzuhotel = DerGrossputz.gehoertzuhotel  and Alledreckigenzimmer.zimmernummer = dergrossputz.zimmernummer
	-- Wahl der Zimmer, die Grossputz benoetigen
	ORDER BY Alledreckigenzimmer.gehoertZuHotel ASC, alledreckigenzimmer.ZimmerNummer ASC;

/*
1.4. HotelManagerView
Zeigt an: Hotels sortiert nach Umsatz, mit dazugehoerigen Bars sortiert nach Umsatz, dazu die beliebteste Zimmerkategorie
*/ 
CREATE OR REPLACE VIEW HotelmanagerView AS
	SELECT hotelid, (umsatzrooms+konsumumsatz+mietumsatz+benutzenumsatz) as gesamtumsatz,umsatzrooms,barumsatz,konsumumsatz,
		mietumsatz,benutzenumsatz,
		ezom,ezmm,dzom,dzmm,trom,trmm,suit
		--Auswahl aller gewuenschten Posten
	FROM
		(SELECT Umsatznaechte.gehoertzuhotel as hotelid,COALESCE (naechteumsatz, '0,00€') as umsatzrooms, 
			COALESCE (umsatzbar, '0,00€') as Barumsatz, COALESCE(konsumumsatz, '0,00 €') as konsumumsatz , 
			COALESCE(mietumsatz, '0,00 €') as mietumsatz , COALESCE (benutzenumsatz, '0,00 €') as benutzenumsatz ,
			ezom,ezmm,dzom,dzmm,trom,trmm,suit
		--Fuellen der leeren Spalten mit 0,00 € beim Selektieren
		FROM
		(WITH Naechteumsatz as(
			WITH UmsatzZimmerCheckedOut as(
			SELECT gehoertzuhotel,((abreise-anreise)*zimmerpreis) as gesamtbetrag
			FROM reservierungen 
			LEFT OUTER JOIN (Select hotelid from hotel) AS Hotels
			ON gehoertzuhotel=hotelid
			WHERE gaestestatus = 'CHECKED-OUT'
			ORDER BY gehoertzuHotel),
			--Berechnung Naechteumsatz aller Checked-Out Zimmer

			UmsatzZimmerInhouse as(
			SELECT gehoertzuhotel,((current_date-anreise)*zimmerpreis) as gesamtbetrag
			FROM reservierungen 
			LEFT OUTER JOIN (Select hotelid from hotel) AS Hotels
			on gehoertzuhotel=hotelid
			WHERE  gaestestatus = 'IN-HOUSE'
			ORDER BY gehoertzuHotel)
			--Berechnung Naechteumsatz aller In-House Zimmer
			SELECT *
			from Umsatzzimmercheckedout union  SELECT* from UmsatzZimmerInhouse)
		SELECT gehoertzuhotel,sum(gesamtbetrag) as Naechteumsatz
		from Naechteumsatz
		GROUP by gehoertzuhotel) as Umsatznaechte
		--Aufsummierung aller Naechteumsaetze
		
	LEFT OUTER JOIN
		(WITH Kunden as (
			SELECT gehoertzuhotel, reserviertvonkunde, anreise, abreise, reservierungsnummer, gaestestatus
			FROM reservierungen
			WHERE gaestestatus = 'CHECKED-OUT' OR gaestestatus = 'IN-HOUSE' OR gaestestatus='ARRIVAL'
			ORDER BY gehoertzuHotel)
			--Auswahl der Kunden
		SELECT konsumieren.imhotel as gehoertzuhotel, sum(preis) as Konsumumsatz
		FROM konsumieren 
		JOIN Kunden
		ON Kunden.reserviertvonkunde = konsumieren.kid AND konsumieren.zeitpunkt >= Anreise AND konsumieren.zeitpunkt<=abreise
		JOIN speisenundgetraenke
		ON speisenundgetraenke.speiseid = konsumieren.Speiseid
		GROUP BY konsumieren.imhotel) as Umsatzkonsum
		--Berechnung der Konsumumsaetze
		on Umsatznaechte.gehoertzuhotel = Umsatzkonsum.gehoertzuhotel

	LEFT OUTER JOIN
		(WITH Kunden as (
			SELECT gehoertzuhotel, reserviertvonkunde, anreise, abreise, reservierungsnummer, gaestestatus
			FROM reservierungen
			WHERE gaestestatus = 'CHECKED-OUT' OR gaestestatus = 'IN-HOUSE' OR gaestestatus='ARRIVAL'
			ORDER BY gehoertzuHotel)
			--Auswahl der teilnehmenden Kunden
		SELECT mieten.gehoertzuhotel, sum(preis) as Mietumsatz
		from mieten JOIN Kunden
		ON Kunden.reserviertvonkunde = mieten.kid AND mieten.von >= Anreise AND bis<=abreise
		JOIN sporteinrichtungen
		ON sporteinrichtungen.aid = mieten.aid
		GROUP BY mieten.gehoertzuhotel) as Umsatzmieten
		--Berechnung Mietumsaetze
		ON Umsatznaechte.gehoertzuhotel=Umsatzmieten.gehoertzuhotel 

	LEFT OUTER JOIN
		(WITH Kunden as (
			SELECT gehoertzuhotel, reserviertvonkunde, anreise, abreise, reservierungsnummer, gaestestatus
			FROM reservierungen
			WHERE gaestestatus = 'CHECKED-OUT' OR gaestestatus = 'IN-HOUSE' OR gaestestatus='ARRIVAL'
			ORDER BY gehoertzuHotel)
		SELECT benutzen.gehoertzuhotel, sum(preis) as Benutzenumsatz
		FROM benutzen 
		JOIN Kunden
		ON Kunden.reserviertvonkunde = benutzen.kid AND benutzen.von >= Anreise AND benutzen.bis<=abreise
		JOIN schwimmbad
		ON schwimmbad.aid = benutzen.aid
		GROUP BY benutzen.gehoertzuhotel) as Umsatzbenutzen
		--Berechnung der Beutzenumsaetze
		on Umsatznaechte.gehoertzuhotel=Umsatzbenutzen.gehoertzuhotel 

	LEFT  OUTER JOIN
		(SELECT gehoertzuhotel, count(CASE WHEN zimmerkategorie='EZOM' THEN 1 ELSE NULL END) as ezom, count(CASE WHEN zimmerkategorie='EZMM' THEN 1 ELSE NULL END) as ezmm, count(CASE WHEN zimmerkategorie='DZOM' THEN 1 ELSE NULL END) as dzom, count(CASE WHEN zimmerkategorie='DZMM' THEN 1 ELSE NULL END) as dzmm, count(CASE WHEN zimmerkategorie='TROM' THEN 1 ELSE NULL END) as trom, count(CASE WHEN zimmerkategorie='TRMM' THEN 1 ELSE NULL END) as trmm, count(CASE WHEN zimmerkategorie='SUIT' THEN 1 ELSE NULL END) as suit
		FROM reservierungen
		WHERE gaestestatus = 'CHECKED-OUT' OR gaestestatus = 'IN-HOUSE' OR gaestestatus='ARRIVAL'
		GROUP BY gehoertzuhotel
		ORDER BY gehoertzuhotel) as TotalZimmer 
		--alle Kategorieszimmerreservierungen checked-out und in-house und arrival, aufgezaehlt
		ON Umsatznaechte.gehoertzuhotel=Totalzimmer.gehoertzuhotel 

		LEFT OUTER JOIN
		(SELECT imhotel, sum(preis) UmsatzBar
		FROM (konsumieren join hotelbar ON imhotel=hotelbar.gehoertzuhotel and verspeistin = hotelbar.aid) as Hotelbars
		JOIN speisenundgetraenke
		ON Hotelbars.speiseid = speisenundgetraenke.speiseid
		GROUP BY imhotel) as Barumsatz
		--Berechnung Barumsaetze
		on Umsatznaechte.gehoertzuhotel=Barumsatz.imhotel
		ORDER BY hotelid ASC) as alles;

/*
1.5 NichtBezahltKundenView
Zeigt an: Reservierungen mit den dazugehörigen Kundenummern,Anreise,Abreise und Hotel, die noch nicht bezahlt haben
Verwendet fuer UnbezahlteReservierungView
*/
CREATE or REPLACE VIEW NichtBezahltKundenView AS
WITH Nichtbezahlt as
	(SELECT reservierungsnummer,reserviertvonkunde as kunde
	FROM reservierungen
	WHERE gaestestatus='IN-HOUSE'
	EXCEPT
	SELECT reservierungsnummer,kid
	from bezahlen)	
SELECT reservierungen.reservierungsnummer as resa,kunde, anreise, abreise, reservierungen.gehoertzuhotel
FROM Nichtbezahlt join reservierungen ON Nichtbezahlt.kunde = reservierungen.reserviertvonkunde;


/*
1.6. UnbezahlteReservierungView
Zeigt an: Kundennummer und Gesamtrechnungspreis von allen eingecheckten Kunden die ihre Rechnungen noch nicht bezahlt haben
*/
CREATE OR REPLACE VIEW UnbezahlteReservierungView AS
	SELECT hotelid, reservierungsnummer, reserviertvonkunde as kunde, 
		(konsumiert+gemietet+benutzt+naechteumsatz) as Gesamtoffen,  konsumiert,gemietet,benutzt,naechteumsatz
	FROM
		(SELECT NichtbezahltKundenView.resa as resa, NichtbezahltKundenView.kunde as kunde, COALESCE(sum(preis),'0,00€') as Konsumiert
		FROM NichtbezahltKundenView 
		LEFT OUTER JOIN konsumieren ON konsumieren.kid=NichtbezahltKundenView.kunde and zeitpunkt>=anreise and zeitpunkt <=abreise
		LEFT OUTER JOIN speisenundgetraenke ON speisenundgetraenke.speiseid=konsumieren.speiseid
		GROUP BY NichtbezahltKundenView.resa, NichtbezahltKundenView.kunde, NichtbezahltKundenView.gehoertzuhotel) as Konsum
		--Berechnung der konsumierten Gueter

	LEFT OUTER JOIN
		(SELECT NichtbezahltKundenView.resa, NichtbezahltKundenView.kunde, COALESCE(sum(preis),'0,00€') as gemietet
		FROM NichtbezahltKundenView 
		LEFT OUTER JOIN mieten ON mieten.kid=NichtbezahltKundenView.kunde and von>=anreise and bis <=abreise
		LEFT OUTER JOIN sporteinrichtungen ON sporteinrichtungen.aid=mieten.aid and sporteinrichtungen.gehoertzuhotel = mieten.gehoertzuhotel
		GROUP BY NichtbezahltKundenView.resa, NichtbezahltKundenView.kunde, NichtbezahltKundenView.gehoertzuhotel) as Gemietet
		--Berechnung der gemieteten Gueter
	ON Konsum.resa = Gemietet.resa

	LEFT OUTER JOIN
		(SELECT NichtbezahltKundenView.resa, NichtbezahltKundenView.kunde, COALESCE(sum(preis),'0,00€') as benutzt
		from NichtbezahltKundenView 
		LEFT OUTER JOIN benutzen ON benutzen.kid=NichtbezahltKundenView.kunde and von>=anreise and bis <=abreise
		LEFT OUTER JOIN schwimmbad ON schwimmbad.aid=benutzen.aid and schwimmbad.gehoertzuhotel = benutzen.gehoertzuhotel
		GROUP BY NichtbezahltKundenView.resa, NichtbezahltKundenView.kunde, NichtbezahltKundenView.gehoertzuhotel) as Benutztes
		--Berechnung der benutzten Gueter
	ON Konsum.resa = benutztes.resa

	LEFT OUTER JOIN
		(SELECT reservierungen.gehoertzuhotel as hotelid,reservierungsnummer, reserviertvonkunde, COALESCE(((current_date-reservierungen.anreise)*zimmerpreis), '0,00€') as naechteumsatz
		FROM reservierungen JOIN NichtbezahltKundenView on NichtbezahltKundenView.resa = reservierungen.reservierungsnummer) as Naechteumsatz
		--Berechnung der bisher erbrachten Naechteumsatz
	ON Konsum.resa=Naechteumsatz.reservierungsnummer
	ORDER BY reservierungsnummer ASC;

/*
1.7. AnreisendeView
Zeigt an:  Kundenname und Zimmer aller anreisenden Gaeste des Tages an und ob der Kunde VIP ist, sortiert nach Hotel und Kunden Nachname
*/
CREATE OR REPLACE VIEW AnreisendeView AS
WITH Anreisende AS (
	SELECT gehoertZuHotel, Zimmer, reserviertvonkunde, reservierungsnummer, anreise, abreise
	FROM Reservierungen
	WHERE Gaestestatus = 'ARRIVAL' )

	SELECT 	gehoertZuHotel, Zimmer, reservierungsnummer, reserviertVonKunde, Nachname, anreise,abreise, VIP 
	FROM 	Anreisende 
		JOIN Kunden ON Anreisende.reserviertvonkunde = Kunden.KID;

/*
1.8. freieKartenView
Zeigt an: die verfügbaren Karten
Benoetigt fuer: die Zimmerkartenvergabe
*/ 
CREATE OR REPLACE VIEW FreieKartenView AS
	  SELECT  KartenID
	  FROM  ZimmerKarte
	  WHERE  gesperrt = FALSE
	  EXCEPT ALL
	  -- ausser Karten schon im Umlauf
	  SELECT  KartenID
	  FROM  erhalten ORDER BY kartenid;


-- 2. RULES

/*
2.1. freieZimmerView
Info: Diese View ist nur zur Ansicht und sollte nicht verändert werden koennen. 
*/
CREATE OR REPLACE RULE freieZimmerUpdate AS ON UPDATE 
TO freieZimmerAktuellView
DO NOTHING;
CREATE OR REPLACE RULE freieZimmerInsert AS ON INSERT 
TO freieZimmerAktuellView
DO NOTHING;
CREATE OR REPLACE RULE freieZimmerDelete AS ON DELETE 
TO freieZimmerAktuellView
DO NOTHING;

/*
2.2. bewohnteZimmerView
Info: Ein Delete oder Insert macht bei dieser View wenig Sinn: Die View soll die Gaesteverteilung anzeigen, nicht reglementieren. 
Dafuer braucht man mehr Informationen als die View zu Verfuegung stellt, und es sind Trigger hierfuer zustaendig. 
Ein Update muss gewaehrleistet werden, da die Zimmerdreckig() Funktion um 0.00 alle bewohnten Zimmer als dreckig markiert, fuer die ReinigungspersonalView.
*/
CREATE OR REPLACE RULE bewohnteZimmerUpdate AS ON UPDATE 
TO bewohnteZimmerView 
DO INSTEAD 
	UPDATE 	Zimmer
	SET 	dreckig = true
	WHERE 	Zimmer.Zimmernummer = NEW.Zimmernummer AND Zimmer.gehoertZuHotel = NEW.gehoertZuHotel; 

CREATE OR REPLACE RULE bewohnteZimmerInsert AS ON INSERT 
TO bewohnteZimmerView
DO NOTHING;
CREATE OR REPLACE RULE bewohnteZimmerDelete AS ON DELETE 
TO bewohnteZimmerView
DO NOTHING;

/*
2.3. ReinigungspersonalView
Info: Obwohl ein Insert oder Delete hier nicht sinnvoll ist, macht ein Update von dreckig von true auf false Sinn, etwa
wenn das Reinigungspersonal die Arbeit an einem Zimmer beendet hat. 
*/
CREATE OR REPLACE RULE ReinigungspersonalUpdate AS ON UPDATE
TO ReinigungspersonalView 
DO INSTEAD
	UPDATE 	Zimmer
	SET 	dreckig = false
	WHERE 	Zimmer.Zimmernummer = NEW.Zimmernummer AND Zimmer.gehoertZuHotel = NEW.gehoertZuHotel; 

CREATE OR REPLACE RULE ReinigungspersonalInsert AS ON INSERT 
TO ReinigungspersonalView
DO NOTHING;
CREATE OR REPLACE RULE ReinigungspersonalDelete AS ON DELETE 
TO ReinigungspersonalView
DO NOTHING;

/*
2.4.HotelManagerView
Info: Diese View ist nur zur Ansicht und sollte nicht verändert werden koennen. 
*/
CREATE OR REPLACE RULE HotelManagerUpdate AS ON UPDATE 
TO HotelManagerView
DO NOTHING;
CREATE OR REPLACE RULE HotelManagerInsert AS ON INSERT 
TO HotelManagerView
DO NOTHING;
CREATE OR REPLACE RULE HotelManagerDelete AS ON DELETE 
TO HotelManagerView
DO NOTHING;

/*
2.5. NichtBezahltKundenView
Info: Diese View ist nur zur Ansicht und sollte nicht verändert werden koennen. 
*/
CREATE OR REPLACE RULE NichtBezahltKundenUpdate AS ON UPDATE 
TO NichtBezahltKundenView
DO NOTHING;
CREATE OR REPLACE RULE NichtBezahltKundenInsert AS ON INSERT 
TO NichtBezahltKundenView
DO NOTHING;
CREATE OR REPLACE RULE NichtBezahltKundenDelete AS ON DELETE 
TO NichtBezahltKundenView
DO NOTHING;

/*
2.6.UnbezahlteReservierungView
Info: Diese View ist nur zur Ansicht und sollte nicht verändert werden koennen. 
*/
CREATE OR REPLACE RULE UnbezahlteReservierungUpdate AS ON UPDATE 
TO UnbezahlteReservierungView
DO NOTHING;
CREATE OR REPLACE RULE UnbezahlteReservierungInsert AS ON INSERT 
TO UnbezahlteReservierungView
DO NOTHING;
CREATE OR REPLACE RULE UnbezahlteReservierungDelete AS ON DELETE 
TO UnbezahlteReservierungView
DO NOTHING;


/*
2.7. AnreisendeView
Info: Ein Delete wuerde einer Stornierung gleichkommen. Ein Insert macht hier wenig Sinn, dafuer gibt es die ZimmerAnfrage-Funktion.
in Update koennte in Sinn machen. Beispielsweise weiss die Rezeptionsleitung, dass ein prominenter Gast anreist und moechte die VIP Austattung des 
Zimmers gewaehrleisten, und moechte den Kunden vielleicht auch in ein anderes Zimmer umbuchen. 
*/

CREATE OR REPLACE RULE AnreisendeUpdateVip AS ON UPDATE   
TO AnreisendeView WHERE OLD.VIP = false AND NEW.VIP = true
DO INSTEAD
	UPDATE 	Kunden
	SET 	VIP = true
	WHERE	KID = NEW.reserviertVonKunde;

CREATE OR REPLACE RULE AnreisendeUpdateAnreise AS ON UPDATE   
TO AnreisendeView 
DO INSTEAD
	UPDATE 	reservierungen
	SET 	anreise = New.anreise
	WHERE	Old.reservierungsnummer = reservierungen.reservierungsnummer;

CREATE OR REPLACE RULE AnreisendeUpdateAbreise AS ON UPDATE   
TO AnreisendeView 
DO INSTEAD
	UPDATE 	reservierungen
	SET 	abreise = New.abreise
	WHERE	Old.reservierungsnummer = reservierungen.reservierungsnummer;

CREATE OR REPLACE RULE AnreisendeUpdateZimmer AS ON UPDATE   
TO AnreisendeView WHERE OLD.Zimmer !=  NEW.Zimmer
DO INSTEAD
	UPDATE 	Reservierungen
	SET 	Zimmer = NEW.Zimmer
	WHERE	Zimmer = OLD.Zimmer;
		
CREATE OR REPLACE RULE AnreisendeInsert AS ON INSERT 
TO AnreisendeView
DO NOTHING;
CREATE OR REPLACE RULE AnreisendeDelete AS ON DELETE 
TO AnreisendeView
DO INSTEAD
	UPDATE 	Reservierungen
	SET 	Stornierungsnummer = nextval('IDSequenz'), gaestestatus='CANCELED'
	WHERE 	OLD.gehoertZuhotel = Reservierungen. gehoertZuhotel
		AND OLD.Zimmer = Reservierungen.Zimmer and OLD.reservierungsnummer = Reservierungen.reservierungsnummer;

/*
2.8. freieKartenView
Info: Da wir bei einem Insert oder Delete nicht wissen ob eine Karte ausgeteilt oder beschaedigt ist, 
koennen wir keine eindeutige Aktion ableiten. Ein Update des Karten ID macht kein Sinn. 
*/
CREATE OR REPLACE RULE freieKartenUpdate AS ON UPDATE 
TO freieKartenView
DO NOTHING;
CREATE OR REPLACE RULE freieKartenInsert AS ON INSERT 
TO freieKartenView
DO NOTHING;
CREATE OR REPLACE RULE freieKartenDelete AS ON DELETE 
TO freieKartenView
DO NOTHING;

/*
2.9.kartenGueltigInsert
Info: Bei der Ausgabe einer Zimmerkarte, darf diese nicht gesperrt sein.
Offentsichtlich kann nur eine wiedergefundene karte ausgehaendigt werden
*/
CREATE OR REPLACE RULE kartenGueltigInsert AS ON INSERT
TO erhalten 
DO ALSO 
	UPDATE 	Zimmerkarte
	SET 	gesperrt = FALSE 
	WHERE 	NEW.KartenID = Zimmerkarte.KartenID;
