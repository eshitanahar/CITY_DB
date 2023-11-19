CREATE OR REPLACE FUNCTION EMOB.fnc_myauth (userid VARCHAR2, restrictgrp VARCHAR2)
   RETURN VARCHAR2
IS
   vGroup   VARCHAR2 (10);
BEGIN
   BEGIN
      SELECT NVL(GROUP_CODE,'F')
        INTO vGroup
        FROM GUMS.MB_USER_GRP
       WHERE USER_ID = userid;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         vGroup := 'F';
   END;

   IF vGroup = restrictgrp
   THEN
      RETURN 'F';
   ELSE
      RETURN 'T';
   END IF;
END;
/
