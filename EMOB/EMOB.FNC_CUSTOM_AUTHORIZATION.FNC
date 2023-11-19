CREATE OR REPLACE FUNCTION EMOB.fnc_custom_authorization (pUserId       VARCHAR2,
                                                     pAppPageId    VARCHAR2)
   RETURN VARCHAR2
IS
   vADDSTS      VARCHAR2 (1);
   vMODSTS      VARCHAR2 (1);
   vENQSTS      VARCHAR2 (1);
   vGroupCode   VARCHAR2 (2);
BEGIN
   BEGIN
      SELECT DISTINCT A.GROUP_CODE
        INTO vGroupCode
        FROM gums.MB_USER_GRP a
       WHERE A.USER_ID = pUserId;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         raise_application_error (-20001, 'User group code not found....');
   END;

   SELECT NVL (ADDSTATS, 'N') ADDSTS,
          NVL (MODSTATS, 'N') MODSTS,
          NVL (ENQSTATS, 'N') ENQSTS
     INTO vADDSTS, vMODSTS, vENQSTS
     FROM gums.syrights
    WHERE     PROGCODE = (SELECT PROGCODE
                            FROM GUMS.SYMENTRE
                           WHERE APP_CODE = 'AGC' AND PAGEID = pAppPageId)
          AND GROUPCODE = vGroupCode    --userid=16, progcode=1685, goupcode=1
   UNION
   SELECT ADDSTATS, MODSTATS, ENQSTATS
     FROM gums.syrights_user
    WHERE     USER_ID = pUserId
          AND PROGCODE = (SELECT PROGCODE
                            FROM GUMS.SYMENTRE
                           WHERE APP_CODE = 'AGC' AND PAGEID = pAppPageId);

   RETURN vADDSTS;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      vADDSTS := 'N';
      vMODSTS := 'N';
      vENQSTS := 'N';
      RETURN vADDSTS;
--DBMS_OUTPUT.PUT_LINE (vADDSTS || '-' || vMODSTS || '-' || vENQSTS);
END;
/
