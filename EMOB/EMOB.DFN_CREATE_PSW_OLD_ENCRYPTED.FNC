CREATE OR REPLACE FUNCTION EMOB."DFN_CREATE_PSW_OLD_ENCRYPTED" (
   userid   IN VARCHAR2,
   passwd   IN VARCHAR2)
   RETURN VARCHAR2
IS
BEGIN
   RETURN (gums.dpk_security.dfn_create_psw_old_encrypted (userid, passwd));
END;
/
