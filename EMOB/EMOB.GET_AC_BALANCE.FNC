CREATE OR REPLACE FUNCTION EMOB.GET_AC_BALANCE (pAcNo VARCHAR2)
   RETURN NUMBER
IS
   vBalance             NUMBER;
   vFileId              NUMBER;
   vBalanceInfoRecord   EMOB.GLOBAL_CBS_ALL_API.AcBalanceRec;
   vNomInputRecord      EMOB.GLOBAL_CBS_ALL_API.AcNomRec;
   vCbsNotifyFlag       VARCHAR2 (1);
   vCbsNotifyMsg        VARCHAR2 (1024);
BEGIN
   SELECT MAX (FILE_ID) + 1 INTO vFileId FROM EMOB.MB_API_INOUT_XML_LOG;

   BEGIN
      EMOB.GLOBAL_CBS_ALL_API.BALANCE_ENQUERY_API (
         pAcNo         => pAcNo,
         pFileId       => vFileId,
         pBalanceRec   => vBalanceInfoRecord,
         pAcNomRec     => vNomInputRecord,
         pNotifyFlag   => vCbsNotifyFlag,
         pNotifyMsg    => vCbsNotifyMsg);
   EXCEPTION
      WHEN OTHERS
      THEN
         RAISE_APPLICATION_ERROR (-20001, 'Unable To Call API-' || SQLERRM);
   END;

   vBalance := vBalanceInfoRecord (1).AVAILABLE_BAL;
   RETURN vBalance;
END;
/
