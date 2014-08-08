--TRIGGER, FUNKTIONEN,RULES

-- RULES

-- belegteZimmerUpdate: Beim Update auf belegteZimmerView werden in
-- Relation Zimmer, die entsprechenden Zimmer auf dreckig gestellt. 
CREATE OR REPLACE RULE belegteZimmerUpdate AS ON UPDATE 
TO belegteZimmerView WHERE NEW.dreckig = true 
DO INSTEAD 
	UPDATE Zimmer
	SET dreckig = true
	WHERE Zimmernummer = NEW.zugewiesenesZimmer AND gehoertZuHotel = NEW.ZimmerInHotel; 


-- FUNKTIONEN 

-- ZimmerDreckig: Um 0:00 Uhr werden alle belegte Zimmer auf dreckig gestellt.
-- Simuliert hier durch eine Funktion
CREATE OR REPLACE FUNCTION ZimmerDreckig() RETURNS VOID 
AS $$
	UPDATE belegteZimmer 
	SET dreckig = TRUE
$$ LANGUAGE SQL;



-- Rechnungsposten: 




-- TRIGGER 

-- Bei Ankunft von einem Gast, der mehrere Personen im Zimmer unterbringt, muessen fuer alle 
-- Personen einen Eintrag in Kunden stattfinden. 

-- KartenAusgabe: Beim IN-HOUSE des Kunden...TODO

-- KartenRueckgab: Beim CHECK-OUT des Kunden, gibt dieser die Karte ab 
-- Alle Karten, die der Reservierung zugeteilt wurden werden 
-- aus erhalten geloescht und koennen nicht mehr die entsprechende Tuer oeffnen
CREATE OR REPLACE FUNCTION KartenRueckgabe() RETURNS TRIGGER 
AS $$
BEGIN
	DELETE FROM erhalten
	WHERE NEW.Reservierungsnummer = erhalten.Reservierungsnummer;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER KartenRueckgabe BEFORE UPDATE OF Gaestestatus ON Reservierungen
	FOR EACH ROW
	WHEN (NEW.Gaestestatus = 'CHECKED-OUT')
	EXECUTE PROCEDURE KartenRueckgabe();
	