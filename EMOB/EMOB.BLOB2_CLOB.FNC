CREATE OR REPLACE FUNCTION EMOB.blob2_clob (p_blob IN BLOB)
   RETURN CLOB
IS
   l_clob   CLOB;
   l_step   PLS_INTEGER := 12000; -- make sure you set a multiple of 3 not higher than 24573
BEGIN
   FOR i IN 0 .. TRUNC ( (DBMS_LOB.getlength (p_blob) - 1) / l_step)
   LOOP
      l_clob :=
         l_clob
         || REGEXP_REPLACE (
               UTL_RAW.
                cast_to_varchar2 (
                  UTL_ENCODE.
                   base64_encode (
                     DBMS_LOB.SUBSTR (p_blob, l_step, i * l_step + 1))),
               '[[:space:]]',
               NULL);                              --remove newline characters
   END LOOP;
----comment---
   RETURN l_clob;
END;
/
