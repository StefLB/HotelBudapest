--TRIGGER, FUNKTIONEN,RULES

-- RULES

-- belegteZimmerUpdate 
-- Beim Update auf belegteZimmerView werden in
-- Relation Zimmer, die entsprechenden Zimmer auf dreckig gestellt. 
CREATE OR REPLACE RULE belegteZimmerUpdate AS ON UPDATE 
TO belegteZimmerView WHERE NEW.dreckig = true 
DO INSTEAD 
	UPDATE Zimmer
	SET dreckig = true
	WHERE Zimmernummer = NEW.zugewiesenesZimmer AND gehoertZuHotel = NEW.ZimmerInHotel; 

-- kartenGueltigInsert
-- Bei der Ausgabe einer Zimmerkarte, darf diese nicht gesperrt sein





-- FUNKTIONEN 

-- Zimmeranfrage
-- 





-- ZimmerDreckig
-- Um 0:00 Uhr werden alle belegte Zimmer auf dreckig gestellt.
-- Simuliert hier durch eine Funktion
CREATE OR REPLACE FUNCTION ZimmerDreckig() RETURNS VOID 
AS $$
	UPDATE belegteZimmer 
	SET dreckig = TRUE
$$ LANGUAGE SQL;



-- Rechnungsposten
-- Ausammeln aller Posten, die wahrend des Aufenthalts auf einer Reservierung gebucht wurden
-- Entspricht ein Zimmerkonto 





-- GourmetGast
-- Ein Gast moechte alle Hotel Restaurants angezeigt bekommen die mehr als 3 Sterne haben



-- FreieSportplaetze 
-- Ein Gast moechte sehen, welche Sportplaetze am jetzigen Tag noch zu vermieten sind





-- TRIGGER 

-- EinChecken
-- Beim Einchecken von einem Gast, muessen fuer alle 
-- zusaetzlichen einen Eintrag in Kunden stattfinden
-- Allen Gaesten des Zimmers wird eine Karte ausgehaendigt TODO: ER Modell anpassen, aus 1 wird 0!





-- Bezahlen






-- Kartenverlust
-- Beim Verlust der Karte, wird diese gesperrt und aus erhalten geloescht.
-- Der Kunde bekommt eine neue




-- CheckOut 
-- Beim CHECK-OUT des Kunden, gibt dieser die Karte ab 
-- Alle Karten, die der Reservierung zugeteilt wurden werden 
-- aus erhalten geloescht und koennen nicht mehr die entsprechende Tuer oeffnen
CREATE OR REPLACE FUNCTION CheckOut() RETURNS TRIGGER 
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

	IF(!FOUND) THEN
		RAISE EXCEPTION 'Gast muss noch bezahlen';
	END IF;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER CheckOutTrigger BEFORE UPDATE OF Gaestestatus ON Reservierungen
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'CHECKED-OUT')
	EXECUTE PROCEDURE schonBezahlt();
	EXECUTE PROCEDURE KartenRueckgabe();


-- VIP
-- Bei der 100 Uebernachtung bekommt der Gast VIP Status





-- TuerOeffner
-- Beim oeffnen einer Tuer wird die Zugangsberechtigung geprueft
-- Nur zugelassene Tueren duerfen geoeffnet werden


