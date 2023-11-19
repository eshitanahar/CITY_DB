CREATE OR REPLACE FUNCTION EMOB.DFN_ACCOUNT_AVAILABLE_BALANCE (
   pBrancd           VARCHAR2,
   pAccountTypeId    NUMBER,
   pAccountId        NUMBER)
   RETURN NUMBER
IS
   vAvailableBalance   NUMBER := 0;
BEGIN
   SELECT (cur_bal + shadow_cr) - (block_amt + shadow_dr)
     INTO vAvailableBalance
     FROM MB_ACCOUNT_BALANCE
    WHERE     BRANCH_CODE = pBrancd
          AND AC_TYPE_ID = pAccountTypeId
          AND AC_ID = pAccountId;

   RETURN vAvailableBalance;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN vAvailableBalance;
END;
/
