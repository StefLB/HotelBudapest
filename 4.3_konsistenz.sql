/*
KONSISTENZTRIGGER
Hier werden einige Funktionen implementiert, die Funktionalitaeten eines Hotelsystems enthalten koennte, wie etwa Zimmeranfragen
oder das erstellen einer Rechnung. Weiter unten sind Konsistenztrigger aufgelistet, die einige wichtige Invarianten unserer Hoteltabellen
sicher stellen. 

Anmerkung: Fuer einige der Funktionen oder Trigger werden auf Views zurueckgegegriffen. Daher ist vor Ausfuehrung der Beispieldaten 
das Einlesen der Views in 6_LogischeDatenun.sql wichtig. 

INHALTSANGABE:
1. FUNKTIONEN
	1.1. getPreisTabelle(Hotel int) 
	1.2. berechneSaison(Anreise date,Abreise date)
	1.3. ZimmerFreiAnDate(Hotel int, Zimmerkat Zimmerkategorie, von date, bis date)
	1.4. Zimmeranfrage(Hotel int, Zimmerkategorie Zimmerkategorie, Anreise date, Abreise date, 
			Verpflegung Verpflegungsstufe, Wuensche varChar,PersonenAnzahl int, AnzahlZimmer int)
	1.5. getNextVorgemerktZimmer(Angebotsdaten Angebot)
	1.6. AblehnungAngebot( Angebotsdaten Angebot, Grund varChar)
	1.7. AnnahmeAngebot(KundenID int, Angebotsdaten Angebot)
	1.8. annahmeAngebotNeuKunde(Vorname varChar,Name VarChar,Adresse varChar, Telefonnummer int, 
							Kreditkarte bigint, Besonderheiten varChar, Angebotsdaten Angebot)
	1.9. ZimmerDreckig()
	1.10 Rechnungsposten(Hotelnummer int, Zimmernummer int)
	1.11 gourmetGast (Hotel int)
	1.12 freieSportplaetze(Hotel int)
	1.13 setArrivals()
	1.14 getnaechsteFreieKarte()

2. KONSISTENZTRIGGER
	2.1. ReservierungDeleteTrigger
	2.2. SpeiseUndGetraenkeDeleteTrigger
	2.3. AbteilungDeleteTrigger
	2.4. UeberbuchungCheckTrigger
	2.5. ReserviertVonKundeCheckTrigger




3. BEISPIELANFRAGEN



1.FUNKTIONEN 

1.1. getPreisTabelle(Hotel int) 
Returns: die Preise des Hotels aus der Preistabelle zurueck
Benoetigt fuer: die Preisberechnungen bei zimmeranfrage funktion 
*/
CREATE OR REPLACE FUNCTION getPreisTabelle(Hotelparam int) RETURNS TABLE (Posten varChar, Preis money)
AS $$	
	DECLARE Tabellennummer int;
BEGIN
	
	SELECT 	hatPreistabelle INTO Tabellennummer
	FROM 	Hotel
	WHERE 	Hotelparam = HotelID;

	RETURN 	QUERY
	SELECT 	*
	FROM 	Preistabelle
	--  
	WHERE 	Tabellennummer::text LIKE rtrim(CodeUndPosten::text , '-ABCDEFGHIJKLMNOPQRSTUVWXYZ');

END	
$$LANGUAGE plpgsql; 


/* 
1.2. berechneSaison(Anreise date,Abreise date)
Returns: die Anzahl an Haupt- und Nebensaisonaechte im Zeitraum von Anreise bis Abreise
Benoetigt fuer: die Preisberechnungen bei zimmeranfrage funktion 
*/
CREATE OR REPLACE FUNCTION berechneSaison(Anreise date,Abreise date) RETURNS AnzahlnaechteType
AS $$
	DECLARE beginHaupt date DEFAULT EXTRACT(YEAR FROM now())::text||'-01-08' ; 
		endHaupt date DEFAULT   EXTRACT(YEAR FROM now())::text||'-10-31'; 
		countHaupt int DEFAULT 0;
BEGIN

	FOR i IN 0..(Abreise-Anreise-1) LOOP
		IF (Anreise + i BETWEEN beginHaupt AND endHaupt) THEN
			countHaupt = countHaupt + 1;
		END IF;
	END LOOP;

	RETURN (countHaupt, (Abreise-Anreise-countHaupt));
	
END
$$LANGUAGE plpgsql; 


/* 
1.3. ZimmerFreiAnDate(Hotel int, Zimmerkat Zimmerkategorie, von date, bis date)
Returns: alle Zimmer einer gewuenschten Kategorie in Hotel zurueck, die frei sind von-bis, aufsteigend sortiert
Benoetigt fuer: die Vergabe von freien Zimmer bei zimmeranfrage funktion
*/
CREATE OR REPLACE FUNCTION ZimmerFreiAnDate(Hotel int, Zimmerkat Zimmerkategorie, von date, bis date) 
RETURNS TABLE (Zimmernummer  int)
AS $$	
BEGIN
	RETURN QUERY
	WITH 	freieZimmer AS(
	SELECT 	Zimmer.Zimmernummer,Zimmer.Zimmerkategorie
	FROM 	Zimmer
	WHERE 	gehoertZuHotel = Hotel 
	EXCEPT ( 
	-- Zimmer die nicht frei sind zum gegebenen Zeitraum
	SELECT 	Reservierungen.Zimmer, Reservierungen.Zimmerkategorie
	FROM 	Reservierungen 
	WHERE 	gehoertZuHotel = Hotel 
		-- muss frei sein von - bis
		AND ((von >= Anreise AND von <= Abreise) OR (bis >= Anreise AND bis <= Abreise))
		-- nur reservierte, ankommende, belegte, oder vorgemerkte Zimmer abziehen
		AND (Gaestestatus = 'RESERVED' OR Gaestestatus = 'ARRIVAL' OR Gaestestatus = 'IN-HOUSE' 
		OR Gaestestatus = 'AWAITING-CONFIRMATION')))

	SELECT 	freieZimmer.Zimmernummer
	FROM 	freieZimmer
	WHERE 	freieZimmer.Zimmerkategorie = Zimmerkat
	ORDER BY  Zimmernummer ASC;
END	
$$LANGUAGE plpgsql; 



/*
1.4. Zimmeranfrage(Hotel int, Zimmerkategorie Zimmerkategorie, Anreise date, Abreise date, 
     Verpflegung Verpflegungsstufe, Wuensche varChar,PersonenAnzahl int, AnzahlZimmer int) 
Returns: ein Angebot (Hotel int , Zimmerkategorie Zimmerkategorie, AnzahlZimmer int, Gesamtpreis money)
Info: Der Anfragende gibt seine Anfrage Parameter an, und wieviele Zimmer des Typs er reservieren moechte.
      Das Angebot das er erhaelt kann in weiteren Funktionen angenommen oder abgelehnt werden 
Benoetigt fuer: eventuell eine sinnvoll Funktionalitaet bei einem Webanfragesystem
*/ 
CREATE OR REPLACE FUNCTION Zimmeranfrage(Hotel int, Zimmerkategorie Zimmerkategorie, Anreise date, Abreise date, 
					Verpflegung Verpflegungsstufe, Wuensche varChar,PersonenAnzahl int, AnzahlZimmer int) 
RETURNS Angebot
AS $$
	DECLARE AnzahlZimmervar int; zimmervar int; preisvar money; Anzahlnaechte AnzahlnaechteType;
		Hauptsaisonzuschlag money; countMaxPersonen int; maxPersonenvar int; tempID int; nextID int;
BEGIN
	-- Hole alle freien Zimmer des gefragten typs
	CREATE TEMP TABLE temptable
		(Zimmernummer, maxPersonen)
	ON COMMIT DROP AS
	SELECT 	Zimmer.Zimmernummer, maxPersonen
	FROM  	ZimmerFreiAnDate(Hotel, Zimmerkategorie, Anreise, Abreise)
		JOIN Zimmer ON ZimmerFreiAnDate.Zimmernummer = Zimmer.Zimmernummer
	WHERE 	gehoertZuHotel = Hotel;

	-- Pruefe ob soviele Zimmer frei sind	
	SELECT 	count(*) INTO AnzahlZimmervar
	FROM 	temptable;
			
	-- Falls nicht, dann Anfragender informieren
	IF (AnzahlZimmervar < AnzahlZimmer) THEN
		RAISE EXCEPTION 'Die gewuenschte Anzahl an Zimmern ist nicht frei';
	END IF;

	-- Hole Preise aus der zum Hotel zugeordneten Tabelle
	-- und addiere diese zusammen
	SELECT 	sum(preis) INTO preisvar 
	FROM 	getPreisTabelle(Hotel) 
	WHERE 	Zimmerkategorie LIKE ltrim(Posten::text , '-0123456789')
		OR Verpflegung  LIKE ltrim(Posten::text , '-0123456789');

		
	-- Berechne Anzahl an Haupt- und Nebensaisontagen
	Anzahlnaechte = berechneSaison(Anreise,Abreise); 
	-- beruecksichtige Hauptsaisonzuschlag
	SELECT 	Preis INTO Hauptsaisonzuschlag
	FROM 	getPreisTabelle(Hotel) 
	WHERE 	'HS' LIKE  ltrim(Posten::text , '-0123456789');
	
	preisvar = (preisvar + Hauptsaisonzuschlag ) * Anzahlnaechte.AnzahlHauptsaison 
		  + preisvar * Anzahlnaechte.AnzahlNebensaison;


	-- Lege eine vorgemerkte Reservierung an,eine Reservierung pro zimmer, 
	-- heisst Reservierungen von mehreren Zimmern werden aufgesplittet. 
	FOR i IN 1..AnzahlZimmer LOOP
		SELECT 	Zimmernummer,maxPersonen INTO zimmervar,maxPersonenvar
		FROM 	temptable
		ORDER BY Zimmernummer ASC
		OFFSET i
		FETCH FIRST 1 ROWS ONLY;

		-- Benutze den temporaeren Kunden um die Reservierungen anzulegen
		SELECT KID INTO tempID
		FROM Kunden
		WHERE Vorname LIKE '' AND Nachname LIKE '';
		
		-- Lege temporaere Reservierungen an mit den gewuenschten Daten
		INSERT INTO Reservierungen VALUES (Hotel,zimmervar, preisvar, DEFAULT, Verpflegung, Zimmerkategorie,
					Anreise, Abreise, DEFAULT , tempID, 'AWAITING-CONFIRMATION', Wuensche, Personenanzahl, now());

		-- Addiere maxPersonen der vorgemerkten Zimmer 
		countmaxPersonen = countmaxPersonen + maxPersonenvar;
	END LOOP;
	
	-- Pruefe ob vergebene Zimmer die Personenanzahl beherbergen kann
	IF (countmaxPersonen < PersonenAnzahl) THEN
		RAISE EXCEPTION 'Zu viele Gaeste fuer diese Zimmerkombination';
	END IF;
	
	-- Falls alles klappt, erhaelt der Kunde ein Angebot
	RETURN (Hotel, Zimmerkategorie, AnzahlZimmer, Anreise,Abreise,  preisvar*AnzahlZimmer) ;		
END
$$ LANGUAGE plpgsql; 



/*
1.5. getNextVorgemerktZimmer(Angebotsdaten Angebot)
Returns: Reservierungsnummer eines vorgemerkten Zimmers
Info: Der Kunde hat eine Angebot angekommen und bekommt nun die vorgemerkten Zimmer
Benoetigt fuer: die Zimmervergabe bei der Ablehung oder Annahme einer Anfrage
*/
CREATE OR REPLACE FUNCTION getNextVorgemerktZimmer(Angebotsdaten Angebot)
RETURNS int
AS $$
	DECLARE vorgemerkt int;
BEGIN
	vorgemerkt = 0;
	-- Hole eine der vorgemerkten Reservierungen = Zimmer
	SELECT 	Reservierungsnummer INTO vorgemerkt
	FROM 	Reservierungen
	WHERE 	Angebotsdaten.Hotel =  Reservierungen.gehoertZuHotel 
		-- Stelle sicher dass sie in allen Punkten dem Angebot uebereinstimmen
		AND GaesteStatus = 'AWAITING-CONFIRMATION'
		AND Angebotsdaten.Zimmerkategorie = Reservierungen.Zimmerkategorie
		AND Angebotsdaten.Gesamtpreis/Angebotsdaten.Anzahlzimmer = Reservierungen.Zimmerpreis
		AND Angebotsdaten.Anreise = Reservierungen.Anreise
		AND Angebotsdaten.Abreise = Reservierungen.Abreise
	-- Herausgeben der Zimmer moeglichst zusammenhaengend waere nett, 
	ORDER BY Zimmer ASC
	-- Kunde wird den vorgemerkte zimmer zugeteilt, 
	-- Auch bei gleichzeitigen Anfragen geht die gesamtzahl auf 
	OFFSET 	0
	FETCH FIRST 1 ROWS ONLY;
	
	RETURN vorgemerkt;
END
$$LANGUAGE plpgsql;


/* 
1.6. AblehnungAngebot( Angebotsdaten Angebot, Grund varChar)
Returns: void 
Info: Der Kunde kann ein Angebot ablehnen
Benoetigt fuer: eventuell eine sinnvoll Funktionalitaet bei einem Webanfragesystem
*/
CREATE OR REPLACE FUNCTION AblehnungAngebot( Angebotsdaten Angebot, Grund varChar) RETURNS VOID 
AS $$
	DECLARE vorgemerkt int;
BEGIN
	vorgemerkt = getNextVorgemerktZimmer(Angebotsdaten);
	-- Für die gesamtanzahl an vorgemerkten Zimmer
	FOR i IN 1..Angebotsdaten.AnzahlZimmer LOOP		
		-- Dieses wird jetzt als Turn-Down eingetragen werden
		UPDATE 	Reservierungen
		SET 	GaesteStatus = 'TURN-DOWN'
		WHERE 	Reservierungen.Reservierungsnummer= vorgemerkt;

		INSERT INTO Ablehnungen VALUES (vorgemerkt, Grund);
	END LOOP;
	-- Anmerkung: bei Abgelehnten Anfragen, bleibt die temporaere KundenID eingetragen

END
$$LANGUAGE plpgsql;


/* 
1.7. AnnahmeAngebot(KundenID int, Angebotsdaten Angebot)
Returns: Void
Info: Ein Kunde mit bereits angelegter KID nimmt ein Angebot an
Benoetigt fuer: eventuell eine sinnvoll Funktionalitaet bei einem Webanfragesystem
*/
CREATE OR REPLACE FUNCTION AnnahmeAngebot(KundenID int, Angebotsdaten Angebot) RETURNS VOID 
AS $$
	DECLARE vorgemerkt int;
BEGIN
	/*Hier werden die bei der Anfrage vorgemerkte Zimmer dem Kunden zugeteilt.
	  Eventuell hat der Kunde mehrere Zimmer reserviert. Die getNextVorgemerkteZimmer
	  Funktion holt solange moeglichst zusammenhaengende vorgemerkte Zimmer, wie der 
	  Kund sie in seiner Zimmeranzahl angegeben hat. */
	FOR i IN 1..Angebotsdaten.AnzahlZimmer LOOP		
		UPDATE 	Reservierungen
		-- der temporaere Kunde wird ersetzt
		SET 	reserviertVonKunde = KundenId, GaesteStatus = 'RESERVED'
		WHERE 	Reservierungen.Reservierungsnummer= getNextVorgemerktZimmer(Angebotsdaten);
	END LOOP;
	
END
$$LANGUAGE plpgsql;


/*
1.8. annahmeAngebotNeuKunde(Vorname varChar,Name VarChar,Adresse varChar, Telefonnummer int, 
						Kreditkarte bigint, Besonderheiten varChar, Angebotsdaten Angebot)
Returns: Void
Info: Ein ganz neuer Kunde nimmt ein Angebot an
Benoetigt fuer: eventuell eine sinnvoll Funktionalitaet bei einem Webanfragesystem
*/
CREATE OR REPLACE FUNCTION annahmeAngebotNeuKunde(Vorname varChar,Name VarChar,Adresse varChar, Telefonnummer int, 
						Kreditkarte bigint, Besonderheiten varChar, Angebotsdaten Angebot) RETURNS VOID 
AS $$
	DECLARE neuID int;
BEGIN
	-- Atomizitaet wichtig, wegen ermitteln des IDs, aber Postgres meckert wecken Syntax
	-- BEGIN;
	INSERT INTO Kunden  VALUES (DEFAULT, Vorname, Name, Adresse, Telefonnummer, Kreditkarte, Besonderheiten, DEFAULT, now());
	SELECT 	KID INTO neuID
	FROM 	Kunden
	ORDER BY KID DESC
	FETCH FIRST 1 ROWS ONLY;
	
	PERFORM annahmeAngebot(neuID, Angebotsdaten);

	--COMMIT;

END
$$LANGUAGE plpgsql;



/*
1.9. ZimmerDreckig()
Returns: Void
Info: Hierdurch werden (um 0:00 Uhr) alle belegte Zimmer auf dreckig gestellt. Simuliert hier durch eine Funktion
Benoetigt fuer: Die Zimmerreinigung, die taeglich alle belegten Zimmer reinigen muss. 
*/
CREATE OR REPLACE FUNCTION ZimmerDreckig() RETURNS VOID 
AS $$
BEGIN
	UPDATE 	bewohnteZimmerView 
	SET 	dreckig = TRUE;
END
$$ LANGUAGE plpgsql;


/*
1.10. Rechnungsposten(Hotelnummer int, Zimmernummer int)
Ausammeln aller Posten, die wahrend der aktuellen Reservierung aufs Zimmer gebucht wurden
Entspricht einem Zimmerkonto 
*/
CREATE OR REPLACE FUNCTION Rechnungsposten(Hotelnummer int, Zimmernummer int) 
RETURNS TABLE(Posten varChar, Zeitpunkt timestamp, postenpreis money)
AS $$
BEGIN	
	RETURN QUERY
WITH 	Rechnungskunde AS( 
	SELECT 	reserviertvonkunde AS KIDKunde, anreise,abreise 
	FROM 	Reservierungen 
	WHERE 	Reservierungen.gehoertZuHotel = Hotelnummer AND Reservierungen.Zimmer=Zimmernummer AND reservierungen.gaestestatus='IN-HOUSE'
	)
	--zeigt den aktuellen Rechnungsposten des Gasten im Zimmer
	-- konsumierte Posten
	SELECT 	name as posten, konsumieren.Zeitpunkt, SpeisenUndGetraenke.Preis as postenpreis
	FROM 	konsumieren 
		JOIN SpeisenUndGetraenke ON konsumieren.SpeiseID = SpeisenUndGetraenke.SpeiseID
		JOIN Rechnungskunde ON Rechnungskunde.KIDKunde = konsumieren.KID
	WHERE 	konsumieren.zeitpunkt >= anreise and konsumieren.zeitpunkt <=abreise
	
	-- gemietete Posten
	UNION 
	SELECT 	name, mieten.Zeitpunkt, Preis
	FROM 	mieten 
		JOIN sporteinrichtungen ON mieten.gehoertZuHotel = sporteinrichtungen.gehoertZuHotel
		AND mieten.AID = sporteinrichtungen.AID
		JOIN Rechnungskunde ON Rechnungskunde.KIDKunde = mieten.KID
		JOIN abteilung on sporteinrichtungen.aid=abteilung.aid		
	WHERE 	mieten.zeitpunkt >= anreise and mieten.zeitpunkt<=abreise
	-- benutzte Posten
	UNION
	SELECT 	name, von, preis
	FROM 	benutzen 
		JOIN schwimmbad ON benutzen.gehoertZuHotel = schwimmbad.gehoertZuHotel
		AND benutzen.AID = schwimmbad.AID
		JOIN Rechnungskunde ON Rechnungskunde.KIDKunde = benutzen.KID
		JOIN Abteilung on schwimmbad.aid =abteilung.aid and abteilung.gehoertzuhotel=benutzen.gehoertzuhotel			
	WHERE 	Rechnungskunde.KIDkunde = benutzen.kid and von >= anreise and bis<=abreise;
END		 
$$ LANGUAGE plpgsql;

/*
1.11 gourmetGast (Hotel int)
Ein Gast moechte alle Hotel Restaurants angezeigt bekommen die mehr als 1 Stern haben,
dazu das exklusivste (Teuerste) Gericht. 
*/
CREATE OR REPLACE FUNCTION gourmetGast(Hotel int) RETURNS TABLE(Restaurantname varChar, Location varChar, Sterne int, ExklusivMenu varChar,Preis money)
AS $$
BEGIN
	RETURN QUERY
	WITH 	gourmetRestaurants AS (
	SELECT	Abteilung.gehoertZuHotel, Abteilung.AID, Name, Abteilung.Location, Restaurant.Sterne
	FROM 	Restaurant 
		JOIN Abteilung ON Restaurant.gehoertZuHotel = Abteilung.gehoertZuHotel 
		AND Restaurant.AID = Abteilung.AID
	WHERE 	Abteilung.gehoertZuHotel = Hotel AND Restaurant.Sterne >= 1),
	--Auswahl der GourmetRestaurants
	gourmetSpeiseID AS (
	SELECT  Name AS Restaurant, gourmetRestaurants.Location, SpeiseID,gourmetRestaurants.sterne
	FROM 	wirdServiertIn
		JOIN gourmetRestaurants ON wirdServiertIn.gehoertZuHotel = gourmetRestaurants.gehoertZuHotel
		AND wirdServiertIn.AID = gourmetRestaurants.AID )
	--Auswahl der GourmetSpeisen
	SELECT 	DISTINCT on (restaurant) Restaurant, gourmetSpeiseID.Location,gourmetspeiseid.Sterne,SpeisenUndGetraenke.Name,max(SpeisenUndGetraenke.Preis)	
	FROM 	gourmetSpeiseID 
		JOIN SpeisenUndGetraenke ON gourmetSpeiseID.SpeiseID = SpeisenUndGetraenke.SpeiseID 
	GROUP BY Restaurant, gourmetSpeiseID.Location, gourmetSpeiseID.Sterne,SpeisenUndGetraenke.Name, SpeisenUndGetraenke.Preis
	ORDER by restaurant, max DESC;
	--Auswahl des teuersten Gerichtes
END 
$$ LANGUAGE plpgsql;


/*1.12 freieSportplaetze(Hotel int)
-- freieSportplaetze 
-- Ein Gast moechte sehen, welche Sportplaetze am jetzigen Tag noch frei zum vermieten sind
*/
CREATE OR REPLACE FUNCTION freieSportplaetze(Hotel int) RETURNS TABLE(Sportplatz varChar, Location varChar, Oeffnungszeiten Oeffnungszeit)
AS $$
BEGIN
	RETURN 	QUERY
	WITH  sportplatzIDs AS (
 	SELECT  gehoertZuHotel,AID
 	FROM  Sporteinrichtungen
 	EXCEPT
 	SELECT  gehoertZuHotel, AID
 	FROM  mieten 
	WHERE bis > now() AND von <= (current_date + 1  || ' 00:00:00')::timestamp )
	--alle Sporteinrichtungen IDs , die nicht an mieten teilnehmen

	SELECT 	Name, Abteilung.Location, Abteilung.Oeffnungszeiten
	FROM 	Abteilung 
		JOIN sportplatzIDs ON sportplatzIDs.gehoertZuHotel = Abteilung.gehoertZuHotel 
		AND sportplatzIDs.AID = Abteilung.AID 
	WHERE 	sportplatzIDs.gehoertZuHotel = Hotel AND sportplatzIDs.AID = Abteilung.AID;
	--verfuegbare Sporteinrichtungen im Hotel
END 
$$ LANGUAGE plpgsql;

/*
1.13. setArrivals
Returns: void
Benoetigt fuer: jeden Morgen werden alle anreisende Reservierungen als solche markiert 
*/
CREATE OR REPLACE FUNCTION setArrivals() RETURNS VOID
AS $$
BEGIN
	UPDATE 	Reservierungen
	SET	Gaestestatus = 'ARRIVAL'
	WHERE	Anreise = current_date;

END
$$ LANGUAGE plpgsql;

/*
1.14. getNaechsteFreieKarte
Returns: naechste freie zimmerkarte 
Benoetigt fuer: 
*/
CREATE OR REPLACE FUNCTION getNaechsteFreieKarte() RETURNS int
AS $$
	DECLARE neuKartenID int;
BEGIN
	SELECT 	KartenID INTO neuKartenID
	FROM 	FreieKartenView
	FETCH FIRST 1 ROWS ONLY;

	RETURN neuKartenID;
END 
$$ LANGUAGE plpgsql;



/*
2.KONSISTENZTRIGGER

2.1.ReservierungDeleteTrigger
Info: Beim Loeschen einer Reservierungen muessen in Ablehnungen alle korrespondierenden Eintraege geloescht werden. 
*/
CREATE OR REPLACE FUNCTION reservierungDelete() RETURNS TRIGGER 
AS $$
BEGIN
	DELETE FROM Ablehnungen 
	WHERE OLD.Reservierungsnummer = Ablehnungen.Reservierungsnummer;
	RETURN NEW;

END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ReservierungDeleteTrigger AFTER DELETE 
ON Reservierungen 
	FOR EACH ROW
	EXECUTE PROCEDURE reservierungDelete();

/*
2.2. SpeiseUndGetraenkeDeleteTrigger
Info: Beim Loeschen einer Speise oder eines Getraenks muessen in Essen oder Trinken alle korrespondierenden Eintraege geloescht werden. 
*/
CREATE OR REPLACE FUNCTION SpeisenUndGetraenkeDelete() RETURNS TRIGGER 
AS $$
BEGIN
	--Essen
	DELETE FROM Essen 
	WHERE OLD.SpeiseId = Essen.SpeiseID;
	--Trinken
	DELETE FROM Trinken
	WHERE OLD.SpeiseId = Trinken.SpeiseID;
	RETURN NEW;

END
$$ LANGUAGE plpgsql;

CREATE TRIGGER SpeiseUndGetraenkeDeleteTrigger AFTER DELETE 
ON SpeisenUndGetraenke 
	FOR EACH ROW
	EXECUTE PROCEDURE SpeisenUndGetraenkeDelete();

/*
2.3.AbteilungDeleteTrigger
Info: Beim Loeschen einer Abteilung muessen in Restaurant, HotelBar, Schwimmbad, oder einer der Sporteinrichtungen alle korrespondierenden
Eintraege geloescht werden. 
*/
CREATE OR REPLACE FUNCTION AbteilungDelete() RETURNS TRIGGER 
AS $$
BEGIN
	--Restaurant
	DELETE FROM Restaurant 
	WHERE 	OLD.gehoertZuHotel = Restaurant.gehoertZuHotel
		AND OLD.AID = Restaurant.AID;
	--HotelBar
	DELETE FROM HotelBar 
	WHERE 	OLD.gehoertZuHotel = HotelBar.gehoertZuHotel
		AND OLD.AID = HotelBar.AID;
	--Schwimmbad
	DELETE FROM Schwimmbad 
	WHERE 	OLD.gehoertZuHotel = Schwimmbad.gehoertZuHotel
		AND OLD.AID = Schwimmbad.AID;
	--Minigolf
	DELETE FROM Minigolf
	WHERE 	OLD.gehoertZuHotel = Minigolf.gehoertZuHotel
		AND OLD.AID = Minigolf.AID;
	--Golf
	DELETE FROM Golf
	WHERE 	OLD.gehoertZuHotel = Golf.gehoertZuHotel
		AND OLD.AID = Golf.AID;
	--Fahrraeder
	DELETE FROM Fahrraeder
	WHERE 	OLD.gehoertZuHotel = Fahrraeder.gehoertZuHotel
		AND OLD.AID = Fahrraeder.AID;
	--Tennisplaetze
	DELETE FROM Tennisplaetze
	WHERE 	OLD.gehoertZuHotel = Tennisplaetze.gehoertZuHotel
		AND OLD.AID = Tennisplaetze.AID;
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER AbteilungDeleteTrigger AFTER DELETE 
ON Abteilung 
	FOR EACH ROW
	EXECUTE PROCEDURE AbteilungDelete();




/*
2.4.UeberbuchungCheckTrigger
Info: Beim Update oder Insert einer 'RESERVED' Reservierung muss sicher gestellt werden, dass nicht zwei Kunden zur 
gleichen Zeit ein und dasselbe reserviert haben. 
Benoetigt fuer: Die 1:1 Beziehung bei Zimmer wird zugewiesen Reservierungen 
*/
CREATE OR REPLACE FUNCTION UeberbuchungCheck() RETURNS TRIGGER 
AS $$
BEGIN

	PERFORM	*
	FROM 	Reservierungen
	WHERE 	NEW.gehoertZuHotel = Reservierungen.gehoertZuHotel
		AND NEW.Zimmer = Reservierungen.Zimmer
		AND NEW.Anreise = Reservierungen.Anreise
		AND Gaestestatus = 'RESERVED';

	IF(FOUND) THEN
		RAISE EXCEPTION 'Doppelbuchung!';
	END IF;

	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER UeberbuchungCheckUpdateTrigger BEFORE UPDATE OF Gaestestatus
ON Reservierungen 
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'RESERVED')
	EXECUTE PROCEDURE UeberbuchungCheck();

CREATE TRIGGER UeberbuchungCheckInsertTrigger BEFORE INSERT 
ON Reservierungen 
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'RESERVED')
	EXECUTE PROCEDURE UeberbuchungCheck();


/* 
2.5. ReserviertVonKundeCheckTrigger
Info: Da wir bei der Zimmeranfrage erlauben, dass eine Reservierung temporaer mit einem namenlosen Kunden gespeichert wird, muessen 
wir sicher stellen, dass spaetestens nach dem Update des Angebots auf Reserved, eine echter Kunde eingetragen ist. 
Benoetigt fuer: Die (1,1) MinMax Vorgabe, das jede Reservierung von mindestens einem Kunden gebucht wird. Maximal 1 Kunde wird 
durch den Primary Key bei Reservierung sichergestellt, da jede Reservierung nur einmal vorkommen kann. 
*/ 
CREATE OR REPLACE FUNCTION reserviertVonKundeCheck() RETURNS TRIGGER 
AS $$
	DECLARE vornamevar varChar; nachnamevar varChar;
BEGIN
	SELECT Vorname Nachname INTO vornamevar, nachnamevar
	FROM Kunden
	WHERE NEW.reserviertVonKunde = Kunden.KID;

	IF(vornamevar LIKE '' OR nachnamevar LIKE '') THEN
		RAISE EXCEPTION 'Kunde hat keine Daten';
	END IF;
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER ReserviertVonKundeCheckTrigger AFTER UPDATE OF Gaestestatus
ON Reservierungen 
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'RESERVED')
	EXECUTE PROCEDURE reserviertVonKundeCheck();



/*
2.6. EinCheckenTrigger
Info: Falls beim Einchecken von einem Gast, in Reservierungen mehr als ein Zimmer auf den Kunden eingetragen sind, 
muss aus Sicherheitsgruenden, pro zusaestzliches Zimmer eine Verantwortliche Person eingetragen werden. 
Anmerkung: Hier werden zwei Funktionen benoetigt. Die eventuelle Aufnahme eines Neukunden und das eigentliche Einchecken.  
*/
CREATE OR REPLACE FUNCTION checkInNeuKunde(Reservierungsnummerparam int) 
RETURNS VOID
AS $$
	DECLARE Vorname varChar; Nachname varChar; Adresse varChar; Telefonnummer int; 
		Kreditkarte bigint; Besonderheit varChar; id int; 
BEGIN
	-- Sollte natuerlich eine Consolen Ein und Ausgabe Funktion fuer die Aufnahme der Kundendaten sein. 
	-- Wir simulieren diese Situation hier mit Variablen. 
	Vorname = 'Karl';
	Nachname = 'Klummpp';
--	Adresse = 'Kronstad';
	Telefonnummer = 5551234;
--	Kreditkarte = ;
	Besonderheit = 'vegan';

	INSERT INTO Kunden VALUES (DEFAULT, Vorname, Nachname, DEFAULT, Telefonnummer, DEFAULT, Besonderheit, DEFAULT, DEFAULT)
	-- Wir merken uns die ID
	RETURNING KID INTO id;
	-- Um sie in die Reservierung einzufuegen	
	UPDATE 	Reservierungen 
	SET 	reserviertvonKunde = id
	WHERE 	Reservierungsnummerparam = Reservierungsnummer;

	--raise info 'id %',id;
	--raise info 'resnummrparam  %',Reservierungsnummerparam;


	RETURN;	


	
END
$$ LANGUAGE plpgsql;
  
CREATE OR REPLACE FUNCTION einChecken() RETURNS TRIGGER 
AS $$
	DECLARE AnzahlZimmer int; Reservierungsnummervar int; 
BEGIN
	-- Zaehle wieviele Zimmer der Kunde fuer den heutigen Tag reserviert hat
	SELECT 	count(*) INTO AnzahlZimmer
	FROM 	Reservierungen 
	WHERE 	Reservierungen.reserviertVonKunde = NEW.reserviertVonKunde AND Gaestestatus = 'IN-HOUSE';
	-- Zusaetzliche Zimmer muessen mit einem neuen Kunden versehen werde

	IF (AnzahlZimmer > 1) THEN 
		-- fuer jedes zusaetzlich zimmer also ab 2
		FOR i in 2..AnzahlZimmer LOOP
			SELECT 	Reservierungsnummer INTO Reservierungsnummervar
			FROM 	Reservierungen 
			WHERE 	Reservierungen.reserviertVonKunde = NEW.reserviertVonKunde AND Gaestestatus = 'IN-HOUSE'
			ORDER BY Reservierungsnummer
			-- erste Reservierung bleibt wie sie ist
			OFFSET 	i-1
			FETCH FIRST 1 ROWS ONLY; 
			-- Nehme neue Kundendaten auf fuer Reservierung, dazu muessen
			-- alle Kundendaten an der Rezeption aufgenommen werden	
			PERFORM checkInNeuKunde(Reservierungsnummervar);
		END LOOP;
	END IF;
	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER einCheckenTrigger AFTER UPDATE OF Gaestestatus
ON Reservierungen 
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'IN-HOUSE')
	EXECUTE PROCEDURE einChecken();


-- Kartenvergabe
-- Jeder Kunde erhaelt 2 Karten fuer Zimmer
CREATE OR REPLACE FUNCTION kartenvergabe() RETURNS TRIGGER 
AS $$
	DECLARE neuKartenID int;
BEGIN
	FOR i IN 1..2 LOOP 
		PERFORM	*
		FROM 	freieKartenView;
		-- keine freie Karten mehr im umlauf
		IF(NOT FOUND) THEN 
			-- erstelle eine neue Karte
			INSERT INTO Zimmerkarte VALUES (DEFAULT,DEFAULT);
		END IF;
		-- hole naechste freie karte
		neuKartenID = getNaechsteFreieKarte();
		INSERT INTO erhalten VALUES (NEW.reserviertVonkunde, neuKartenID,NEW.Reservierungsnummer);
	END LOOP;
	RETURN NEW;
END
$$ LANGUAGE plpgsql;


CREATE TRIGGER kartenvergabeTrigger AFTER UPDATE OF Gaestestatus
ON Reservierungen 
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'IN-HOUSE')
	EXECUTE PROCEDURE kartenvergabe();



-- Kartenverlust
-- Beim Verlust der Karte, wird diese gesperrt und aus erhalten geloescht.
-- Der Kunde bekommt eine neue
CREATE OR REPLACE FUNCTION sperreUndErsetzeZimmerkarte() RETURNS TRIGGER 
AS $$
	DECLARE neuKartenID int;kundennummervar int; revnummervar int;
BEGIN

	-- finde zur verlorenen Karte KundenID und reservierungsnummer
	SELECT 	KundenID , reservierungsnummer INTO kundennummervar,revnummervar
	FROM 	erhalten
	WHERE 	NEW.KartenID = erhalten.KartenID; 

	-- neue Karte austellen
	neuKartenID = getNaechsteFreieKarte();
	INSERT INTO erhalten VALUES (kundennummervar, neuKartenID,revnummervar);

	-- Zugangsberechtigung der alten karte loeschen
	DELETE FROM erhalten
	WHERE 	NEW.KartenID = erhalten.KartenID;

END
$$ LANGUAGE plpgsql;

CREATE TRIGGER verloreneKarteTrigger AFTER UPDATE OF gesperrt
ON Zimmerkarte 
	FOR EACH ROW
	WHEN (NEW.gesperrt = TRUE)
	EXECUTE PROCEDURE sperreUndErsetzeZimmerkarte();



-- CheckOut 
-- Beim CHECK-OUT des Kunden, gibt dieser die Karte ab 
-- Alle Karten, die der Reservierung zugeteilt wurden werden 
-- aus erhalten geloescht und koennen nicht mehr die entsprechende Tuer oeffnen
CREATE OR REPLACE FUNCTION checkOut() RETURNS TRIGGER 
AS $$
BEGIN
	DELETE FROM erhalten
	WHERE NEW.Reservierungsnummer = erhalten.Reservierungsnummer;
END
$$ LANGUAGE plpgsql;

-- Hat der auscheckende Gast bereits bezahlt?
CREATE OR REPLACE FUNCTION schonBezahlt() RETURNS TRIGGER 
AS $$
BEGIN
	SELECT Reservierungsnummer
	FROM Bezahlen
	WHERE NEW.Reservierungsnummer = Bezahlen.Reservierungsnummer;

	IF(NOT FOUND) THEN
		RAISE EXCEPTION 'Gast muss noch bezahlen';

	ELSE 
		PERFORM checkOut();
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER checkOutTrigger BEFORE UPDATE OF Gaestestatus ON Reservierungen
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'CHECKED-OUT')
	EXECUTE PROCEDURE schonBezahlt();


-- VIPTrigger
-- Bei der 100 Uebernachtung bekommt der Gast VIP Status
CREATE OR REPLACE FUNCTION checkVIP() RETURNS TRIGGER 
AS $$
	DECLARE sum int;
BEGIN
	SELECT 	sum(Abreise-Anreise) INTO sum
	FROM 	Reservierungen
	WHERE 	NEW.reserviertVonKunde = Reservierungen.reserviertVonKunde;

	IF (sum > 99 ) THEN
		UPDATE 	Kunden 
		SET 	VIP = TRUE
		WHERE	Kunden.Kid = New.reserviertVonKunde;
	END IF;

	RETURN NEW;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER VIPTrigger AFTER INSERT ON Reservierungen
	FOR EACH ROW
	EXECUTE PROCEDURE checkVIP();


-- TuerOeffner
-- Beim oeffnen einer Tuer wird die Zugangsberechtigung geprueft
-- Nur zugelassene Tueren duerfen geoeffnet werden
CREATE OR REPLACE FUNCTION checkZimmerkartenRechte() RETURNS TRIGGER 
AS $$
BEGIN
	WITH 	berechtigtesZimmer AS (
	SELECT 	gehoertZuHotel, Zimmer
	FROM 	Reservierungen
	WHERE 	Reservierungen.Reservierungsnummer = NEW.Reservierungsnummer) 
	SELECT  *
	FROM 	erhalten
	WHERE 	NEW.KartenId = erhalten.KartenId AND NEW.Zimmernummer = berechtigtesZimmer.Zimmer
		AND NEW.gehoertZuHotel = berechtigtesZimmer;

	IF (NOT FOUND) THEN
		RAISE NOTICE 'Kein Zutritt!'; 
		RAISE EXCEPTION 'Hey, du Spanner!';
	END IF;	

END
$$ LANGUAGE plpgsql;

CREATE TRIGGER oeffnenInsertTrigger BEFORE INSERT ON oeffnet
	FOR EACH ROW
	EXECUTE PROCEDURE checkZimmerkartenRechte();



-- checkZimmerOutOfOrder
-- Wenn Reservierungen auf 'ARRIVAL' geschaltet werden, muss geprüft werden, ob das Zimmer nicht doch beschädigt/nicht 
-- vermietbar ist (OUT OF ORDER)
CREATE OR REPLACE FUNCTION checkoutoforder() RETURNS TRIGGER 
AS $$
	DECLARE zimmernr int; hotelnr int; zimmerstatus boolean; newzimmer int;
BEGIN

	SELECT 	zimmer INTO Zimmernr
	FROM 	Reservierungen 
	WHERE 	Reservierungen.reservierungsnummer = NEW.reservierungsnummer;

	SELECT 	gehoertzuhotel INTO hotelnr
	FROM 	Reservierungen 
	WHERE 	Reservierungen.reservierungsnummer = NEW.reservierungsnummer;

	SELECT 	outoforder INTO zimmerstatus
	FROM 	zimmer
	WHERE 	zimmernummer=zimmernr and gehoertzuhotel=hotelnr;

	
	
	IF (zimmerstatus = 'false') THEN RETURN NEW; ELSE
		SELECT zimmernummer INTO newzimmer
		FROM ZimmerFreiAnDate (hotelnr, NEW.zimmerkategorie, NEW.anreise, NEW.abreise)
		FETCH FIRST 1 ROWS ONLY;
		
		IF NOT FOUND THEN
		UPDATE 	Reservierungen
		SET 	zimmer = NULL
		WHERE 	Reservierungen.Reservierungsnummer= new.reservierungsnummer;
		RETURN NEW; --keine Exception da automatisiert beim Wechsel des Datums
		ELSE
		UPDATE 	Reservierungen
		SET 	zimmer = newzimmer
		WHERE 	Reservierungen.Reservierungsnummer= new.reservierungsnummer;	
		RETURN NEW;
		END IF;

	END IF;

END
$$ LANGUAGE plpgsql;


CREATE TRIGGER checkoutoforder AFTER UPDATE OF Gaestestatus
ON Reservierungen 
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'ARRIVAL')
	EXECUTE PROCEDURE checkoutoforder();



/*
3.BEISPIELANFRAGEN 
Wobei die Nummern den Funktionen oder Views entsprechen

1.1. getPreisTabelle(Hotel int)
*/ 
SELECT getPreisTabelle(2);

-- 1.2. berechneSaison(Anreise date,Abreise date)
SELECT berechneSaison(current_date,current_date+30); 

-- 1.3. ZimmerFreiAnDate(Hotel int, Zimmerkat Zimmerkategorie, von date, bis date)
SELECT ZimmerFreiAnDate(1, 'EZMM', current_date, current_date+1);

-- 1.4. Zimmeranfrage(Hotel int, Zimmerkategorie Zimmerkategorie, Anreise date, Abreise date, 
					--Verpflegung Verpflegungsstufe, Wuensche varChar,PersonenAnzahl int, AnzahlZimmer int)
SELECT Zimmeranfrage(1, 'EZMM',current_date, current_date+1,'BRFST', 'nix',1, 1);

-- 1.5. getNextVorgemerktZimmer(Angebotsdaten Angebot)
SELECT getNextVorgemerktZimmer((1,'EZMM',1,current_date, current_date+1,190.00)::Angebot);

-- 1.6. AblehnungAngebot( Angebot Angebot, Grund varChar)
SELECT AblehnungAngebot((1,'EZMM',1,current_date, current_date+1,190.00)::Angebot, 'Too Expensive');

-- 1.7. AnnahmeAngebot(KundenID int, Angebotsdaten Angebot)
-- Es muss nochmal eine Anfrage gemacht werden
SELECT Zimmeranfrage(1, 'EZMM',current_date, current_date+1,'BRFST', 'nix',1, 1);
SELECT AnnahmeAngebot(102, (1,'EZMM',1,current_date, current_date+1,190.00)::Angebot);

-- 1.8. AnnahmeAngebotNeuKunde(Vorname varChar,Name VarChar,Adresse varChar, Telefonnummer int, 
				--Kreditkarte int, Besonderheiten varChar, Angebotsdaten Angebot)
-- Es muss nochmal eine Anfrage gemacht werden. 
SELECT Zimmeranfrage(1, 'EZMM',current_date+15, current_date+20,'BRFST', 'nix',1, 1);
SELECT annahmeAngebotNeuKunde('Gunnar'::varChar,'Grumpen'::varChar,'Googeytown'::varChar,5556789, 
					234357868909, 'vegan'::Besonderheit,(1,'EZMM',1,current_date, current_date+1,190.00)::Angebot );
-- 1.9.ZimmerDreckig() 
-- Hiernach sollten alle belegten Zimmer dreckig sein. 
-- Anmerkung: Hier wird auf eine View in 6_LogischeDatenun.sql zurueckgegegriffen.
SELECT ZimmerDreckig();

-- 1.10.Rechnungsposten(Hotelnummer int, Zimmernummer int) 
SELECT*
FROM Rechnungsposten(4,15);

-- 1.11. gourmetGast (Hotel int)
SELECT*
from gourmetgast(3);

--1.12. freieSportplaetze(Hotel int)
SELECT*
from freiesportplaetze(6);

--1.13. setArrivals()
SELECT setArrivals();

/*
BEISPIELANFRAGEN FUER KONSISTENZTRIGGER

2.1. ReservierungDeleteTrigger
Info: Offensichtlich muss bei einem Delete auch in Reservierungen auch die Spezifikation Ablehnungen geloescht werden.
Wir loeschen die eben getaetigte Ablehnung.
*/
DELETE FROM Reservierungen 
WHERE Reservierungsnummer = 19;


/*
2.2. SpeiseUndGetraenkeDeleteTrigger
Info: Gleiches gilt fuer alle Spezifikationen von Speisen
*/
DELETE FROM speisenundgetraenke
WHERE SpeiseID = 9;

/*
2.3.AbteilungDeleteTrigger
Info: Wir loeschen einfach mal Fahrrad 5
*/

DELETE FROM Abteilung
WHERE gehoertZuHotel = 6 AND AID = 11;

/*
2.4.UeberbuchungCheckTrigger
Info: Wir versuchen ein Zimmer zu ueberbuchen, und sehen dass es fehlschlaegt
*/
INSERT INTO Reservierungen VALUES 	(1,30,'100.00', DEFAULT,'BRFST', 'EZMM', '2015-08-01', '2015-08-02', 
					DEFAULT,102, 'RESERVED', 'nix', 1, now());
-- Zweite Reservierung sollte fehlschlagen
INSERT INTO Reservierungen VALUES 	(1,30,'100.00', DEFAULT,'BRFST', 'EZMM', '2015-08-01', '2015-08-02', 
					DEFAULT,102, 'RESERVED', 'nix', 1, now());

					
/*
2.5. ReserviertVonKundeCheckTrigger
Info: Jede Reservierung muss von einem gueltigen Kunden reserviert werden. Wir versuchen eine temporaere Anfrage auf Reserviert zu updaten, 
ohne die Angabe eines gueltigen Kunden. Das sollte fehlschlagen.
*/
SELECT 	Zimmeranfrage(1, 'EZMM',current_date, current_date+1,'BRFST', 'nix',1, 1);
UPDATE 	Reservierungen 
SET 	Gaestestatus = 'RESERVED'
WHERE 	Gaestestatus = 'AWAITING-CONFIRMATION';


/*
2.6.EinCheckenTrigger
Info: Gunnar Grumpen reserviert zwei Zimmer. Eins fuer sich und eins fuer sein Kumpel Kar.
Beim Einchecken, muss dieser Trigger erkennen, dass das zweite Zimmer einen eigenen 
Kundeneintrag braucht. Gunnars Kumpel Karl muss sich als Kunde eintragen lassen. 
*/
SELECT 	Zimmeranfrage(1, 'EZMM',current_date, current_date+1,'BRFST', 'nix',2, 2);
-- Gunnar nimmt das Angebot an
SELECT AnnahmeAngebot(105, (1,'EZMM',1,current_date, current_date+1,190.00)::Angebot);
-- Beide werden heute anreisen
SELECT setArrivals();
-- und kommen schliesslich an
UPDATE 	Reservierungen
SET 	Gaestestatus = 'IN-HOUSE' 
WHERE 	reserviertVonKunde = 105;
-- Hiernach sind beide Reservierungen auf den jeweiligen Namen.

/*
2.7.EinCheckenTrigger
Info: Gunnar Grumpen reserviert zwei Zimmer. Eins fuer sich und eins fuer sein Kumpel Kar.
Beim Einchecken, muss dieser Trigger erkennen, dass das zweite Zimmer einen eigenen 
Kundeneintrag braucht. Gunnars Kumpel Karl muss sich als Kunde eintragen lassen. 
*/




select * from reservierungen
delete from erhalten where reservierungsnummer > 24;
delete from reservierungen where reservierungsnummer > 24;
delete from kunden where kid > 105;
select * from kunden
select * from erhalten
drop trigger EinCheckenTrigger on reservierungen

--TODO: ab hier Beispielanfragen für Funktionen und Trigger

