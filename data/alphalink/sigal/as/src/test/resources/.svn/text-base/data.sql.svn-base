delete from number;
delete from line_information;
delete from emergency_holiday; 
delete from emergency_translation;

-- --------------------------------------    
-- DATA
-- --------------------------------------    
    
insert into 
emergency_translation (insee_code, number, day_of_week, begin_hour, end_hour, idx, translated_number) 
values
('75001', '15', null, null, '15:39:59', 0, '33144497220'),
('75001', '15', null, '15:40:00', null, 0, '33144497221'),
('75001', '17', null, null, null, 0, '33140138901'),
('75001', '18', null, null, null, 0, '33144151107'),
('75001', '18', null, null, null, 1, '33147156990'),
('75001', '112', null, null, null, 0, '33144159739'),
('75001', '112', null, null, null, 1, '33147156991'),
('75001', '115', null, null, null, 0, '33158462000'),
('75001', '115', null, null, null, 1, '33158461001'),
('75001', '115', null, null, null, 2, '33150084067'),
('75001', '115', 0, null, null, 0, '33150084000'),
('75001', '115', 0, null, null, 1, '33150084001'),
('75001', '119', null, null, null, 0, '33153061361'),
('75001', '116000', null, null, null, 0, '33141834209')
;

insert into emergency_holiday values ('2009-07-14')
;

insert into line_information values
-- Test Dom
('0990000001099', '33970754630', 1, 1, 1, 'e164', 'e164', '1', 'alphalink.default', '1'),
-- ALPHALINK : numéro fourni à FT pour les échanges de portabilité
('0990000100000', '33970757053', 1, 1, 1, 'e164', 'e164', '1', 'alphalink.low-cost', '1'),
-- CNSI / LA POSTE : 3631 
('0990000068006', '33183754629', 1, 1, 1, 'e164', 'e164', '1', 'alphalink.default', '1')
;

insert into exchange_information values
-- Test Dom
('0991000001099', 1, 1, 1, 'e164', 'e164', '1', 'default')
;


insert into number 
(number, redirect_to, portability_prefix, presentation, insee_code, subscriber_number) 
values
-- Test Porta
('33183754625', null, '10025', '1', '75001', '33970754630'),
-- Test Redirection
('33183754626', '33123456789', null, '1', '75001', '33970754630'),
-- Test Dom
('33970754630', null, null, '1', '75001', '33970754630'),
-- ALPHALINK : numéro fourni à FT pour les échanges de portabilité
('33183754629', null, null, '1', '75001', '33183754629'),
-- ALPHALINK : numéro fourni à FT pour les échanges de portabilité
('33970757053', null, null, '1', '75001', '33970757053')
;

