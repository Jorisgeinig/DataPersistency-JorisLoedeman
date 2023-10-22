-- ------------------------------------------------------------------------
-- Data & Persistency
-- Opdracht S6: Views
--
-- (c) 2020 Hogeschool Utrecht
-- Tijmen Muller (tijmen.muller@hu.nl)
-- André Donk (andre.donk@hu.nl)
-- ------------------------------------------------------------------------


-- S6.1.
--
-- 1. Maak een view met de naam "deelnemers" waarmee je de volgende gegevens uit de tabellen inschrijvingen en uitvoering combineert:
--    inschrijvingen.cursist, inschrijvingen.cursus, inschrijvingen.begindatum, uitvoeringen.docent, uitvoeringen.locatie
-- 2. Gebruik de view in een query waarbij je de "deelnemers" view combineert met de "personeels" view (behandeld in de les):
--     CREATE OR REPLACE VIEW personeel AS
-- 	     SELECT mnr, voorl, naam as medewerker, afd, functie
--       FROM medewerkers;

CREATE OR REPLACE VIEW deelnemers AS
select inschrijvingen.cursist, inschrijvingen.cursus, inschrijvingen.begindatum,
       uitvoeringen.docent, uitvoeringen.locatie
from inschrijvingen
         join uitvoeringen on uitvoeringen.cursus = inschrijvingen.cursus and
                              uitvoeringen.begindatum = inschrijvingen.begindatum;


CREATE OR REPLACE VIEW personeel AS
SELECT mnr, voorl, naam as medewerker, afd, functie from medewerkers;


select * from deelnemers
                  join personeel on deelnemers.cursist = personeel.mnr

-- 3. Is de view "deelnemers" updatable ? Waarom ?
-- Ja, want de view eenvoudige informatie  bevat van de twee tabellen en omdat er primary keys aanwezig zijn.

-- S6.2.
--
-- 1. Maak een view met de naam "dagcursussen". Deze view dient de gegevens op te halen: 
--      code, omschrijving en type uit de tabel curssussen met als voorwaarde dat de lengte = 1. Toon aan dat de view werkt. 
-- 2. Maak een tweede view met de naam "daguitvoeringen". 
--    Deze view dient de uitvoeringsgegevens op te halen voor de "dagcurssussen" (gebruik ook de view "dagcursussen"). Toon aan dat de view werkt
-- 3. Verwijder de views en laat zien wat de verschillen zijn bij DROP view <viewnaam> CASCADE en bij DROP view <viewnaam> RESTRICT

create or replace view dagcursussen as
select cu.code, cu.omschrijving, cu.type from cursussen cu
where cu.lengte = 1;

select * from dagcursussen;

create or replace view daguitvoeringen as
select * from dagcursussen
                  join uitvoeringen u on dagcursussen.code = u.cursus;

select * from daguitvoeringen;


DROP VIEW dagcursussen cascade;
--Beide views worden verwijdert

drop view dagcursussen restrict;
--cannot drop view dagcursussen because other objects depend on it

drop view daguitvoeringen cascade;
--alleen view daguitvoeringen wordt gewist

drop view daguitvoeringen restrict;
--daguitvoeringen wordt gewist

--view daguitvoeringen kan dus los worden gewist omdat andere views/objecten niet afhankelijk zijn van de view
--integendeel tot dagcursussen, daar is daguitvoeringen van afhankelijk dus wordt die view ook gewist bij cascade,
--of het weigert te verwijderen bij de commando restrict door de afhankelijkheid.