CREATE OR REPLACE FUNCTION EMOB."DFN_CREATE_PASSWORD_ENCRYPTED" (
   userid   IN VARCHAR2,
   passwd   IN VARCHAR2)
   RETURN VARCHAR2
IS
BEGIN
   RETURN (gums.dpk_security.dfn_create_password_encrypted (userid, passwd));
END;
/
