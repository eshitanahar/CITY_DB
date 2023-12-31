CREATE OR REPLACE FUNCTION EMOB.GET_ACCOUNT_NO (pAccountId NUMBER)
   RETURN VARCHAR2
IS
   vAccountNo   VARCHAR2 (100);
BEGIN
   SELECT ac_no
     INTO vAccountNo
     FROM MB_ACCOUNT_MST
    WHERE AC_ID = pAccountId;

   RETURN vAccountNo;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN vAccountNo;
END;
/
