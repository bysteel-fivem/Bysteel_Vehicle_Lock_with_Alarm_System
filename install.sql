-- =========================================================
-- BySteel Carlock - Instalação / migração da base de dados
-- Compatível com MySQL e MariaDB utilizados pelo oxmysql.
-- Pode ser executado novamente sem apagar alarmes instalados.
-- =========================================================

SET @bysteel_alarm_column_exists = (
    SELECT COUNT(*)
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'owned_vehicles'
      AND COLUMN_NAME = 'vehicle_alarm'
);

SET @bysteel_alarm_sql = IF(
    @bysteel_alarm_column_exists = 0,
    'ALTER TABLE `owned_vehicles` ADD COLUMN `vehicle_alarm` TINYINT(1) NOT NULL DEFAULT 0 AFTER `plate`',
    'SELECT ''A coluna owned_vehicles.vehicle_alarm já existe.'' AS `bysteel_carlock`'
);

PREPARE bysteel_alarm_statement FROM @bysteel_alarm_sql;
EXECUTE bysteel_alarm_statement;
DEALLOCATE PREPARE bysteel_alarm_statement;

-- Normaliza possíveis valores NULL de instalações anteriores.
UPDATE `owned_vehicles`
SET `vehicle_alarm` = 0
WHERE `vehicle_alarm` IS NULL;
