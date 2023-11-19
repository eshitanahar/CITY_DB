CREATE OR REPLACE FUNCTION EMOB.fnc_get_fulldesc (pPointId VARCHAR2)
   RETURN VARCHAR2
IS
   vFullDesc   VARCHAR2 (1000);
BEGIN
     SELECT NVL (SUM (D.BALANCE), 0) tot_balance
       INTO vFullDesc
       FROM EMOB.ST_AGENT_POINT a,
            EMOB.MB_ACCOUNT_MST b,
            EMOB.MB_PRODUCT_MST c,
            EMOB.MB_ACCOUNT_DAILY_BALANCE d
      WHERE     A.POINT_ID = B.POINT_ID
            AND B.AC_TYPE_ID = C.AC_TYPE_ID
            AND B.AC_NO = D.ACCOUNT_NO
            AND B.AC_STATUS = 'ACT'
            AND A.POINT_ID = pPointId
   GROUP BY A.POINT_ID, C.FULL_DESC;

   --ORDER BY 1 ASC

   RETURN vFullDesc;
END;
/
