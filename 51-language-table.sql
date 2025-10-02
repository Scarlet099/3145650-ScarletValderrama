

-- Tarea con countryLanguage

-- Crear la tabla de language

-- Sequence and defined type
CREATE SEQUENCE IF NOT EXISTS language_code_seq;


-- Table Definition
CREATE TABLE "public"."language" (
    "code" int4 NOT NULL DEFAULT 	nextval('language_code_seq'::regclass),
    "name" text NOT NULL,
    PRIMARY KEY ("code")
);

-- Crear una columna en countrylanguage
ALTER TABLE countrylanguage
ADD COLUMN languagecode varchar(3);


-- Empezar con el select para confirmar lo que vamos a actualizar
-- Idiomas distintos existentes en countrylanguage (previa a poblar tabla language)
SELECT DISTINCT language AS existing_language
FROM countrylanguage
WHERE language IS NOT NULL AND language <> ''
ORDER BY existing_language;

-- Actualizar todos los registros
-- Poblar tabla language con los idiomas distintos de countrylanguage (evitar duplicados)
INSERT INTO "public"."language" ("name")
SELECT DISTINCT cl.language
FROM countrylanguage cl
LEFT JOIN "public"."language" l ON l."name" = cl.language
WHERE cl.language IS NOT NULL AND cl.language <> '' AND l."code" IS NULL;

-- Respaldar: asegurar que la secuencia esté sincronizada con el máximo código
SELECT setval('language_code_seq', COALESCE((SELECT MAX(code) FROM "public"."language"), 1));

-- Cambiar tipo de dato en countrylanguage - languagecode por int4
-- Primero, rellenar la columna languagecode con el code correspondiente en language
UPDATE countrylanguage cl
SET languagecode = l.code::varchar(3)
FROM "public"."language" l
WHERE l."name" = cl.language;

-- Ahora sí, cambiar el tipo a int4 usando conversión segura
ALTER TABLE countrylanguage
ALTER COLUMN languagecode TYPE int4 USING languagecode::int4;

-- Crear el forening key y constraints de no nulo el language_code
ALTER TABLE countrylanguage
ALTER COLUMN languagecode SET NOT NULL,
ADD CONSTRAINT countrylanguage_languagecode_fkey FOREIGN KEY (languagecode)
    REFERENCES "public"."language" (code)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;

-- Revisar lo creado
-- Comprobar registros de language
SELECT code, name FROM "public"."language" ORDER BY code LIMIT 50;

-- Comprobar mapeo en countrylanguage
SELECT countrycode, language, languagecode
FROM countrylanguage
ORDER BY countrycode, language
LIMIT 50;

-- Verificar que no haya códigos huérfanos
SELECT COUNT(*) AS missing_fk
FROM countrylanguage cl
LEFT JOIN "public"."language" l ON l.code = cl.languagecode
WHERE l.code IS NULL;
