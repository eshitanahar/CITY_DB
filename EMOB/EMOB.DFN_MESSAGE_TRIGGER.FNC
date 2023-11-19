CREATE OR REPLACE FUNCTION EMOB.dfn_message_trigger (in_message IN VARCHAR2)
   RETURN VARCHAR2
IS
   MESSAGE   VARCHAR2 (1024);
   COUNT_MSG     NUMBER := 0;
   result    VARCHAR2 (1024);
BEGIN
   BEGIN
      SELECT SUBSTR (in_message, 11, LENGTH (in_message))
        INTO MESSAGE
        FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         result := in_message;
   END;

   BEGIN
      SELECT INSTR (MESSAGE, 'ORA-') INTO COUNT_MSG  FROM DUAL;
   EXCEPTION
      WHEN OTHERS
      THEN
         result := MESSAGE;
   END;

   IF COUNT_MSG  > 0
   THEN
      SELECT SUBSTR (MESSAGE, 1, COUNT_MSG  - 1) INTO result FROM DUAL;
   END IF;

   RETURN result;
END;
/
